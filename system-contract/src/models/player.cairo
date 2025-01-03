use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct PlayerData {
    #[key]
    pub address: ContractAddress,
    treasury: u256,
    highest_match_level: u32,
    total_points: u256,
}

#[derive(Drop, Copy, Serde, Introspect)]
pub struct EquippedWeapon {
    index: u8,
    weapon_address: ContractAddress,
    weapon_id: u256,
}
