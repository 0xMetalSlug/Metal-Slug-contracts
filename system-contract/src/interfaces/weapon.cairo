use starknet::ContractAddress;

#[starknet::interface]
trait IMetalSlugWeapon<TContractState> {
    fn update_system_address(ref self: TContractState, system_address: ContractAddress);
    fn graft_weapon(
        ref self: TContractState, weapon_id: u256, value: u256, receiver: ContractAddress
    );
    fn append_weapons(ref self: TContractState, tier: u256, weapon_ids: Array<u256>);
    fn remove_weapon(ref self: TContractState, weapon_id: u256);
    fn get_weapons_from_tier(self: @TContractState, tier: u256) -> Span<u256>;
    fn get_weapon_tier(self: @TContractState, weapon_id: u256) -> u256;
    fn get_system_address(self: @TContractState) -> ContractAddress;
    fn get_weapon_counter(self: @TContractState, weapon_id: u256) -> u256;
}
