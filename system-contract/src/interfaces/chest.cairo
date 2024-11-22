use starknet::ContractAddress;

#[starknet::interface]
trait IMetalSlugChest<TContractState> {
    fn update_system_address(ref self: TContractState, system_address: ContractAddress);
    fn graft_treasure_chest(
        ref self: TContractState, chest_id: u256, value: u256, receiver: ContractAddress
    );
    fn open_treasure_chest(ref self: TContractState, chest_id: u256, player: ContractAddress);
    fn balance_of(self: @TContractState, accounht: ContractAddress, token_id: u256) -> u256;
    fn get_system_address(self: @TContractState) -> ContractAddress;
}
