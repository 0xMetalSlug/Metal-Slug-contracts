use starknet::ContractAddress;

#[starknet::interface]
trait IMetalSlugWeapon<TContractState> {
    fn update_system_address(ref self: TContractState, system_address: ContractAddress);
    fn graft_weapon(ref self: TContractState, receiver: ContractAddress) -> u256;
    fn get_system_address(self: @TContractState) -> ContractAddress;
    fn get_new_token_id(self: @TContractState) -> u256;
}
