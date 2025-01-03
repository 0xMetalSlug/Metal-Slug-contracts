use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct SeasonDetail {
    #[key]
    pub season_id: u32,
    pub start_time: u64,
    pub end_time: u64,
    pub total_points: u256,
    pub is_active: bool,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct PlayerPoint {
    #[key]
    pub season_id: u32,
    #[key]
    pub player: ContractAddress,
    pub points: u256,
}
