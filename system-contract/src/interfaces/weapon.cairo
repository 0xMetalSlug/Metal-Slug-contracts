use starknet::ContractAddress;

#[starknet::interface]
trait IMetalSlugWeapon<TContractState> {
    fn update_system_address(ref self: TContractState, system_address: ContractAddress);
    fn graft_weapon(
        ref self: TContractState, weapon_id: u256, value: u256, receiver: ContractAddress
    );

    fn get_system_address(self: @TContractState) -> ContractAddress;
}
