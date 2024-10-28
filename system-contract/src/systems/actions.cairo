// dojo decorator
#[dojo::contract]
mod MetalSlug {
    use starknet::{
        ContractAddress, get_contract_address, get_block_timestamp, get_tx_info, get_caller_address
    };
    use array::{Array, ArrayTrait};
    use metalslug::models::system::{SystemManager, ValidatorSignature};
    use metalslug::models::player::PlayerData;
    use metalslug::interfaces::system::IMetalSlugImpl;
    use metalslug::interfaces::account::{AccountABIDispatcher, AccountABIDispatcherTrait};
    use metalslug::interfaces::chest::{IMetalSlugChestDispatcher, IMetalSlugChestDispatcherTrait};
    use core::pedersen::PedersenTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};

    const STARKNET_DOMAIN_TYPE_HASH: felt252 =
        selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

    const U256_TYPE_HASH: felt252 = selector!("u256(low:felt,high:felt)");

    const END_MATCH_REWARD_TYPE_HASH: felt252 =
        selector!(
            "EndMatchReward(player:ContractAddress,treasury:u256,match_level:u32,salt_nonce:u64)u256(low:felt,high:felt)"
        );

    const GRAFT_TREASURE_CHEST_TYPE_HASH: felt252 =
        selector!(
            "TreasureChest(player:ContractAddress,chest_address:ContractAddress,chest_id:u256,amount:u256,salt_nonce:u64)u256(low:felt,high:felt)"
        );

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

    // ============ External Functions ============
    #[abi(embed_v0)]
    impl MetalSlugImpl of IMetalSlugImpl<ContractState> {
        fn initialize(ref world: IWorldDispatcher, validator_address: ContractAddress) {
            let system: SystemManager = get!(world, get_contract_address(), (SystemManager));
            assert(system.validator_address.is_zero(), 'System already initialized');
            assert(!validator_address.is_zero(), 'Invalid validator address');

            set!(world, (SystemManager { system: get_contract_address(), validator_address }));
            emit!(world, (UpdateValidator { validator_address, update_at: get_block_timestamp() }));
        }

        fn update_validator_address(
            ref world: IWorldDispatcher, validator_address: ContractAddress
        ) {
            let system: SystemManager = get!(world, get_contract_address(), (SystemManager));
            InternalImpl::assert_initialized(system);

            assert(!validator_address.is_zero(), 'Invalid validator address');
            assert(system.validator_address != validator_address, 'Same validator address');

            set!(world, (SystemManager { system: get_contract_address(), validator_address }));
            emit!(world, (UpdateValidator { validator_address, update_at: get_block_timestamp() }));
        }

        fn claim_end_match_reward(
            ref world: IWorldDispatcher,
            treasury: u256,
            match_level: u32,
            salt_nonce: u64,
            sign: Array<felt252>
        ) {
            let system: SystemManager = get!(world, get_contract_address(), (SystemManager));
            InternalImpl::assert_initialized(system);

            let player: ContractAddress = get_caller_address();

            let reward = EndMatchReward { player, treasury, match_level, salt_nonce };
            let message_hash = InternalImpl::compute_message_hash(reward, system.validator_address);

            InternalImpl::assert_valid_sign(system.validator_address, message_hash, sign);
            let validator_sign: ValidatorSignature = get!(
                world, (get_contract_address(), message_hash), (ValidatorSignature)
            );
            assert(!validator_sign.is_used, 'Sign already used');

            set!(
                world,
                (ValidatorSignature {
                    system: get_contract_address(), msg_hash: message_hash, is_used: true
                })
            );

            let mut player_detail: PlayerData = get!(world, player, (PlayerData));
            player_detail.treasury += treasury;
            if match_level > player_detail.highest_match_level {
                player_detail.highest_match_level = match_level;
            }

            set!(world, (player_detail));
            emit!(
                world,
                (ClaimEndMatchReward {
                    player, treasury, match_level, claimed_at: get_block_timestamp()
                })
            );
        }

        fn graft_treasure_chest(
            ref world: IWorldDispatcher,
            chest_address: ContractAddress,
            chest_id: u256,
            amount: u256,
            salt_nonce: u64,
            sign: Array<felt252>
        ) {
            let system: SystemManager = get!(world, get_contract_address(), (SystemManager));
            InternalImpl::assert_initialized(system);

            let player: ContractAddress = get_caller_address();
            let treasure_chest = TreasureChest {
                player, chest_address, chest_id, amount, salt_nonce
            };
            let message_hash = InternalImpl::compute_message_hash(
                treasure_chest, system.validator_address
            );

            InternalImpl::assert_valid_sign(system.validator_address, message_hash, sign);
            let validator_sign: ValidatorSignature = get!(
                world, (get_contract_address(), message_hash), (ValidatorSignature)
            );
            assert(!validator_sign.is_used, 'Sign already used');

            set!(
                world,
                (ValidatorSignature {
                    system: get_contract_address(), msg_hash: message_hash, is_used: true
                })
            );

            let chest_dispatcher = IMetalSlugChestDispatcher { contract_address: chest_address };
            chest_dispatcher.graft_treasure_chest(chest_id, amount, player);

            emit!(
                world,
                (GraftTreasureChest {
                    player, chest_address, chest_id, amount, claimed_at: get_block_timestamp()
                })
            );
        }

        fn get_system_manager(ref world: IWorldDispatcher) -> SystemManager {
            let system: SystemManager = get!(world, get_contract_address(), (SystemManager));
            system
        }

        fn get_player_data(ref world: IWorldDispatcher, address: ContractAddress) -> PlayerData {
            let player: PlayerData = get!(world, address, (PlayerData));
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
        fn assert_initialized(system: SystemManager) {
            assert(!system.validator_address.is_zero(), 'System not initialized');
        }

        fn assert_valid_sign(
            validator: ContractAddress, message_hash: felt252, sign: Array<felt252>
        ) {
            let account: AccountABIDispatcher = AccountABIDispatcher {
                contract_address: validator
            };
            assert(account.is_valid_signature(message_hash, sign) == 'VALID', 'Invalid signature');
        }

        fn compute_message_hash<T, impl TStrucHash: IStructHash<T>, impl TDrop: Drop<T>>(
            data: T, validator: ContractAddress
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
    }
}

