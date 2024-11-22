// dojo decorator
#[dojo::contract]
mod MetalSlug {
    use starknet::{
        ContractAddress, get_contract_address, get_block_timestamp, get_tx_info, get_caller_address
    };
    use array::{Array, ArrayTrait};
    use metalslug::models::system::ValidatorSignature;
    use metalslug::models::player::PlayerData;
    use metalslug::interfaces::system::IMetalSlugImpl;
    use metalslug::interfaces::account::{AccountABIDispatcher, AccountABIDispatcherTrait};
    use metalslug::interfaces::chest::{IMetalSlugChestDispatcher, IMetalSlugChestDispatcherTrait};
    use metalslug::interfaces::weapon::{
        IMetalSlugWeaponDispatcher, IMetalSlugWeaponDispatcherTrait
    };
    use cartridge_vrf::{Source, IVrfProviderDispatcherTrait, IVrfProviderDispatcher};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry
    };
    use core::pedersen::PedersenTrait;
    use hash::{HashStateTrait, HashStateExTrait};
    use poseidon::PoseidonTrait;

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    const MAXIMUN_CUMULATIVE_VALUE: u16 = 10_000;
    const STARKNET_DOMAIN_TYPE_HASH: felt252 =
        selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

    const U256_TYPE_HASH: felt252 = selector!("u256(low:felt,high:felt)");

    const END_MATCH_REWARD_TYPE_HASH: felt252 =
        selector!(
            "EndMatchReward(player:felt,treasury:u256,match_level:felt,salt_nonce:felt)u256(low:felt,high:felt)"
        );

    const GRAFT_TREASURE_CHEST_TYPE_HASH: felt252 =
        selector!(
            "TreasureChest(player:felt,chest_address:felt,chest_id:u256,amount:u256,salt_nonce:felt)u256(low:felt,high:felt)"
        );

    // ============ Storage ============
    #[storage]
    struct Storage {
        is_initialized: bool,
        owner: ContractAddress,
        validator_address: ContractAddress,
        vrf_provider_address: ContractAddress,
        treasure_chest_addresses: Map::<ContractAddress, bool>,
        weapon_addresses: Map::<ContractAddress, bool>,
    }

    // ============ Structs ============
    #[derive(Drop, Copy, Hash)]
    struct StarknetDomain {
        name: felt252,
        version: felt252,
        chain_id: felt252,
    }

    #[derive(Drop, Copy, Hash)]
    struct EndMatchReward {
        player: ContractAddress,
        treasury: u256,
        match_level: u32,
        salt_nonce: u64,
    }

    #[derive(Drop, Copy, Hash)]
    struct TreasureChest {
        player: ContractAddress,
        chest_address: ContractAddress,
        chest_id: u256,
        amount: u256,
        salt_nonce: u64,
    }

    // ============ Events ============
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct UpdateValidator {
        #[key]
        validator_address: ContractAddress,
        update_at: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct ClaimEndMatchReward {
        #[key]
        player: ContractAddress,
        treasury: u256,
        match_level: u32,
        claimed_at: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct GraftTreasureChest {
        #[key]
        player: ContractAddress,
        chest_address: ContractAddress,
        chest_id: u256,
        amount: u256,
        claimed_at: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct OpenTreasureChest {
        #[key]
        player: ContractAddress,
        chest_address: ContractAddress,
        chest_id: u256,
        weapon_id: u256,
        weapon_address: ContractAddress,
    }

    // ============ External Functions ============
    #[abi(embed_v0)]
    impl MetalSlugImpl of IMetalSlugImpl<ContractState> {
        fn initialize(
            ref self: ContractState,
            owner: ContractAddress,
            validator_address: ContractAddress,
            vrf_provider_address: ContractAddress
        ) {
            assert(!self.is_initialized.read(), 'System already initialized');
            assert(!owner.is_zero(), 'Invalid owner address');
            assert(!validator_address.is_zero(), 'Invalid validator address');
            assert(!vrf_provider_address.is_zero(), 'Invalid vrf provider address');
            let mut world = self.world_default();

            self.is_initialized.write(true);
            self.owner.write(owner);
            self.validator_address.write(validator_address);
            self.vrf_provider_address.write(vrf_provider_address);

            world
                .emit_event(
                    @UpdateValidator { validator_address, update_at: get_block_timestamp() }
                );
        }

        fn update_validator_address(ref self: ContractState, validator_address: ContractAddress) {
            self.assert_initialized();
            self.assert_only_owner();
            let mut world = self.world_default();
            assert(!validator_address.is_zero(), 'Invalid validator address');
            assert(self.validator_address.read() != validator_address, 'Same validator address');

            self.validator_address.write(validator_address);
            world
                .emit_event(
                    @UpdateValidator { validator_address, update_at: get_block_timestamp() }
                );
        }

        fn update_vrf_provider_address(
            ref self: ContractState, vrf_provider_address: ContractAddress
        ) {
            self.assert_initialized();
            self.assert_only_owner();
            assert(!vrf_provider_address.is_zero(), 'Invalid vrf provider address');
            assert(
                self.vrf_provider_address.read() != vrf_provider_address,
                'Same vrf provider address'
            );

            self.vrf_provider_address.write(vrf_provider_address);
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.assert_initialized();
            self.assert_only_owner();
            assert(!new_owner.is_zero(), 'Invalid new owner address');
            assert(self.owner.read() != new_owner, 'Same new owner address');

            self.owner.write(new_owner);
        }

        fn update_chest_address(
            ref self: ContractState, chest_address: ContractAddress, is_allowed: bool
        ) {
            self.assert_initialized();
            self.assert_only_owner();
            assert(!chest_address.is_zero(), 'Invalid chest address');
            assert(
                self.treasure_chest_addresses.entry(chest_address).read() != is_allowed,
                'Address Already Updated'
            );

            self.treasure_chest_addresses.entry(chest_address).write(is_allowed);
        }

        fn update_weapon_address(
            ref self: ContractState, weapon_address: ContractAddress, is_allowed: bool
        ) {
            self.assert_initialized();
            self.assert_only_owner();
            assert(!weapon_address.is_zero(), 'Invalid weapon address');
            assert(
                self.weapon_addresses.read(weapon_address) != is_allowed, 'Address Already Updated'
            );

            self.weapon_addresses.write(weapon_address, is_allowed);
        }

        fn claim_end_match_reward(
            ref self: ContractState,
            treasury: u256,
            match_level: u32,
            salt_nonce: u64,
            sign: Array<felt252>
        ) {
            self.assert_initialized();
            let mut world = self.world_default();

            let player: ContractAddress = get_caller_address();

            let reward = EndMatchReward { player, treasury, match_level, salt_nonce };
            let validator_address = self.validator_address.read();
            let message_hash = self.compute_message_hash(reward, validator_address);

            self.assert_valid_sign(validator_address, message_hash, sign);
            let validator_sign: ValidatorSignature = world
                .read_model((get_contract_address(), message_hash));
            assert(!validator_sign.is_used, 'Sign already used');

            world
                .write_model(
                    @ValidatorSignature {
                        system: get_contract_address(), msg_hash: message_hash, is_used: true
                    }
                );

            let mut player_detail: PlayerData = world.read_model(player);
            player_detail.treasury += treasury;
            if match_level > player_detail.highest_match_level {
                player_detail.highest_match_level = match_level;
            }

            world.write_model(@player_detail);
            world
                .emit_event(
                    @ClaimEndMatchReward {
                        player, treasury, match_level, claimed_at: get_block_timestamp()
                    }
                );
        }

        fn graft_treasure_chest(
            ref self: ContractState,
            chest_address: ContractAddress,
            chest_id: u256,
            amount: u256,
            salt_nonce: u64,
            sign: Array<felt252>
        ) {
            self.assert_initialized();
            self.assert_only_allowed_chest(chest_address);
            let mut world = self.world_default();

            let player: ContractAddress = get_caller_address();
            let treasure_chest = TreasureChest {
                player, chest_address, chest_id, amount, salt_nonce
            };
            let validator_address = self.validator_address.read();
            let message_hash = self.compute_message_hash(treasure_chest, validator_address);

            self.assert_valid_sign(validator_address, message_hash, sign);
            let validator_sign: ValidatorSignature = world
                .read_model((get_contract_address(), message_hash));
            assert(!validator_sign.is_used, 'Sign already used');

            world
                .write_model(
                    @ValidatorSignature {
                        system: get_contract_address(), msg_hash: message_hash, is_used: true
                    }
                );

            let chest_dispatcher = IMetalSlugChestDispatcher { contract_address: chest_address };
            chest_dispatcher.graft_treasure_chest(chest_id, amount, player);

            world
                .emit_event(
                    @GraftTreasureChest {
                        player, chest_address, chest_id, amount, claimed_at: get_block_timestamp()
                    }
                );
        }

        fn open_treasure_chest(
            ref self: ContractState,
            chest_address: ContractAddress,
            chest_id: u256,
            weapon_address: ContractAddress
        ) {
            self.assert_initialized();
            self.assert_only_allowed_chest(chest_address);
            self.assert_only_allowed_weapon(weapon_address);

            let mut world = self.world_default();
            let player: ContractAddress = get_caller_address();
            let chest_dispatcher = IMetalSlugChestDispatcher { contract_address: chest_address };

            chest_dispatcher.open_treasure_chest(chest_id, player);
            let vrf_provider = IVrfProviderDispatcher {
                contract_address: self.vrf_provider_address.read()
            };
            let random_word = vrf_provider.consume_random(Source::Nonce(player));

            let mut hash = PoseidonTrait::new();
            hash = hash.update_with(random_word);
            hash = hash.update_with(chest_id);
            hash = hash.update_with(player);
            hash = hash.update_with(weapon_address);
            let random_value: u256 = hash.finalize().into();
            let draw_value: u16 = (random_value % MAXIMUN_CUMULATIVE_VALUE.into() + 1)
                .try_into()
                .unwrap();
            // 70%, 20%, 9%, 1% chance to get token id 1, 2, 3, 4 represpectively from chest
            let mut weapon_id = 0;
            if draw_value <= 7_000 {
                weapon_id = 1;
            } else if draw_value <= 9_000 {
                weapon_id = 2;
            } else if draw_value <= 9_900 {
                weapon_id = 3;
            } else {
                weapon_id = 4
            };

            let weapon_dispatcher = IMetalSlugWeaponDispatcher { contract_address: weapon_address };
            weapon_dispatcher.graft_weapon(weapon_id, 1, player);

            world
                .emit_event(
                    @OpenTreasureChest {
                        player, chest_address, chest_id, weapon_id, weapon_address
                    }
                );
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn get_validator(self: @ContractState) -> ContractAddress {
            self.validator_address.read()
        }

        fn get_vrf_provider(self: @ContractState) -> ContractAddress {
            self.vrf_provider_address.read()
        }

        fn get_player_data(self: @ContractState, address: ContractAddress) -> PlayerData {
            let world = self.world_default();
            let player: PlayerData = world.read_model(address);
            player
        }
    }

    // ============ Utils ============
    trait IStructHash<T> {
        fn hash_struct(self: @T) -> felt252;
    }

    impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
        fn hash_struct(self: @StarknetDomain) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(STARKNET_DOMAIN_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(4);
            state.finalize()
        }
    }

    impl StructHashU256 of IStructHash<u256> {
        fn hash_struct(self: @u256) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(U256_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(3);
            state.finalize()
        }
    }

    impl StructHashEndMatchReward of IStructHash<EndMatchReward> {
        fn hash_struct(self: @EndMatchReward) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(END_MATCH_REWARD_TYPE_HASH);
            state = state.update_with(*self.player);
            state = state.update_with(self.treasury.hash_struct());
            state = state.update_with(*self.match_level);
            state = state.update_with(*self.salt_nonce);
            state = state.update_with(5);
            state.finalize()
        }
    }

    impl StructHashTreasureChest of IStructHash<TreasureChest> {
        fn hash_struct(self: @TreasureChest) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(GRAFT_TREASURE_CHEST_TYPE_HASH);
            state = state.update_with(*self.player);
            state = state.update_with(*self.chest_address);
            state = state.update_with(self.chest_id.hash_struct());
            state = state.update_with(self.amount.hash_struct());
            state = state.update_with(*self.salt_nonce);
            state = state.update_with(6);
            state.finalize()
        }
    }

    // ============ Internal Functions ============

    #[generate_trait]
    impl InternalImpl of InternalImplTrait {
        fn assert_initialized(self: @ContractState) {
            assert(self.is_initialized.read(), 'System not initialized');
        }

        fn assert_only_owner(self: @ContractState) {
            assert(self.owner.read() == get_caller_address(), 'Only owner');
        }

        fn assert_only_allowed_chest(self: @ContractState, chest_address: ContractAddress) {
            assert(
                self.treasure_chest_addresses.entry(chest_address).read() == true,
                'Not allowed chest'
            );
        }

        fn assert_only_allowed_weapon(self: @ContractState, weapon_address: ContractAddress) {
            assert(
                self.weapon_addresses.entry(weapon_address).read() == true, 'Not allowed weapon'
            );
        }

        fn assert_valid_sign(
            self: @ContractState,
            validator: ContractAddress,
            message_hash: felt252,
            sign: Array<felt252>
        ) {
            let account: AccountABIDispatcher = AccountABIDispatcher {
                contract_address: validator
            };
            assert(account.is_valid_signature(message_hash, sign) == 'VALID', 'Invalid signature');
        }

        fn compute_message_hash<T, impl TStrucHash: IStructHash<T>, impl TDrop: Drop<T>>(
            self: @ContractState, data: T, validator: ContractAddress
        ) -> felt252 {
            let domain = StarknetDomain {
                name: 'metalslug', version: 1, chain_id: get_tx_info().unbox().chain_id
            };
            let mut state = PedersenTrait::new(0);
            state = state.update_with('StarkNet Message');
            state = state.update_with(domain.hash_struct());
            state = state.update_with(validator);
            state = state.update_with(data.hash_struct());
            state = state.update_with(4);
            state.finalize()
        }

        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"metalslug")
        }
    }
}

