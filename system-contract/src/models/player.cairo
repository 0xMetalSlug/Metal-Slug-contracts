use starknet::ContractAddress;

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct PlayerData {
    #[key]
    pub address: ContractAddress,
    treasury: u256,
    highest_match_level: u32,
}
