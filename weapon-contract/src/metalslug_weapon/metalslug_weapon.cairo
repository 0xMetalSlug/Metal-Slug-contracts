#[starknet::contract]
mod MetalSlugWeapon {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc1155::{ERC1155Component, ERC1155HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;
    use metalslug_weapon::interface::weapon::IMetalSlugWeapon;
    use starknet::{ContractAddress, get_caller_address, get_tx_info};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry, Vec, VecTrait,
        MutableVecTrait
    };

    component!(path: ERC1155Component, storage: erc1155, event: ERC1155Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC1155 Mixin
    #[abi(embed_v0)]
    impl ERC1155MixinImpl = ERC1155Component::ERC1155MixinImpl<ContractState>;
    impl ERC1155InternalImpl = ERC1155Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        system_addres: ContractAddress,
        tier: Map::<u256, Vec<u256>>,
        weapon_tier: Map::<u256, u256>,
        weapon_counter: Map::<u256, u256>,
        #[substorage(v0)]
        erc1155: ERC1155Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC1155Event: ERC1155Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token_uri: ByteArray,
        owner: ContractAddress,
        system_address: ContractAddress,
    ) {
        self.erc1155.initializer(token_uri);
        self.ownable.initializer(owner);
        self.system_addres.write(system_address);
    }

    #[abi(embed_v0)]
    impl MetalSlugChestImpl of IMetalSlugWeapon<ContractState> {
        fn update_system_address(ref self: ContractState, system_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.system_addres.write(system_address);
        }

        fn graft_weapon(
            ref self: ContractState, weapon_id: u256, value: u256, receiver: ContractAddress
        ) {
            self.assert_only_owner_or_system();
            assert(self.get_weapon_tier(weapon_id) != 0, 'Weapon not classified');

            self
                .weapon_counter
                .entry(weapon_id)
                .write(self.weapon_counter.entry(weapon_id).read() + value);

            self
                .erc1155
                .mint_with_acceptance_check(
                    receiver, weapon_id, value, ArrayTrait::<felt252>::new().span()
                );
        }

        fn append_weapons(ref self: ContractState, tier: u256, weapon_ids: Array<u256>) {
            self.ownable.assert_only_owner();
            for weapon_id in weapon_ids
                .span() {
                    assert(*weapon_id != 0, 'Invalid weapon id');
                    self.assert_not_duplicate_weapon(*weapon_id);
                    self.weapon_tier.entry(*weapon_id).write(tier);
                    self.tier.entry(tier).append().write(*weapon_id);
                }
        }

        fn remove_weapon(ref self: ContractState, weapon_id: u256) {
            self.ownable.assert_only_owner();
            let weapon_counter = self.weapon_counter.entry(weapon_id).read();
            assert(weapon_counter == 0, 'Weapon already minted');

            let tier = self.weapon_tier.entry(weapon_id).read();
            assert(tier != 0, 'Weapon not classified');

            self.weapon_tier.entry(weapon_id).write(0);

            for i in 0
                ..self
                    .tier
                    .entry(tier)
                    .len() {
                        if self.tier.entry(tier).at(i).read() == weapon_id {
                            self.tier.entry(tier).at(i).write(0);
                            break;
                        }
                    }
        }

        fn get_weapons_from_tier(self: @ContractState, tier: u256) -> Span<u256> {
            let mut weapon_ids = array![];
            for i in 0
                ..self
                    .tier
                    .entry(tier)
                    .len() {
                        let weapon_id = self.tier.entry(tier).at(i).read();
                        if weapon_id != 0 {
                            weapon_ids.append(weapon_id);
                        }
                    };
            weapon_ids.span()
        }

        fn get_weapon_tier(self: @ContractState, weapon_id: u256) -> u256 {
            self.weapon_tier.entry(weapon_id).read()
        }

        fn get_system_address(self: @ContractState) -> ContractAddress {
            self.system_addres.read()
        }

        fn get_weapon_counter(self: @ContractState, weapon_id: u256) -> u256 {
            self.weapon_counter.entry(weapon_id).read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalImplTrait {
        fn assert_only_owner_or_system(self: @ContractState) {
            let caller = get_caller_address();
            assert(
                caller == self.ownable.owner() || caller == self.get_system_address(),
                'Only owner or system'
            );
        }

        fn assert_not_duplicate_weapon(self: @ContractState, weapon_id: u256) {
            assert!(
                self.weapon_tier.entry(weapon_id).read() == 0,
                "Weapon id {} already classified",
                weapon_id
            );
        }
    }
}
