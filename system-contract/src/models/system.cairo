use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct ValidatorSignature {
    #[key]
    pub system: ContractAddress,
    #[key]
    pub msg_hash: felt252,
    pub is_used: bool,
}
