#[starknet::contract]
mod MetalSlugWeapon {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;
    use metalslug_weapon::interface::weapon::IMetalSlugWeapon;
    use starknet::{ContractAddress, get_caller_address, get_tx_info};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry, Vec, VecTrait,
        MutableVecTrait
    };

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC721 Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        system_addres: ContractAddress,
        new_token_id: u256,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        token_uri: ByteArray,
        owner: ContractAddress,
        system_address: ContractAddress,
    ) {
        self.erc721.initializer(name, symbol, token_uri);
        self.ownable.initializer(owner);
        self.system_addres.write(system_address);
        self.new_token_id.write(1);
    }

    #[abi(embed_v0)]
    impl MetalSlugChestImpl of IMetalSlugWeapon<ContractState> {
        fn update_system_address(ref self: ContractState, system_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.system_addres.write(system_address);
        }

        fn graft_weapon(ref self: ContractState, receiver: ContractAddress) -> u256 {
            self.assert_only_owner_or_system();
            let token_id = self.get_new_token_id();

            self.new_token_id.write(token_id + 1);
            self.erc721.mint(receiver, token_id);
            token_id
        }


        fn get_system_address(self: @ContractState) -> ContractAddress {
            self.system_addres.read()
        }

        fn get_new_token_id(self: @ContractState) -> u256 {
            self.new_token_id.read()
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
    }
}
