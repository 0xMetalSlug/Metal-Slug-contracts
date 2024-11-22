use starknet::ContractAddress;
use metalslug::models::player::PlayerData;

#[starknet::interface]
trait IMetalSlugImpl<TState> {
    /// Initializes the actions contract with validator contract address.
    ///
    /// Requirements:
    ///
    /// - `owner` The address of the owner
    /// - `validator_address` The address of the validator
    /// - `vrf_provider_address` The address of the vrf provider
    fn initialize(
        ref self: TState,
        owner: ContractAddress,
        validator_address: ContractAddress,
        vrf_provider_address: ContractAddress
    );

    /// Updates the validator address.
    ///
    /// Requirements:
    ///
    /// - `validator_address` The address of the validator contract
    fn update_validator_address(ref self: TState, validator_address: ContractAddress);

    /// Updates the vrf provider address.
    ///
    /// Requirements:
    ///
    /// - `vrf_provider_address` The address of the vrf provider contract
    fn update_vrf_provider_address(ref self: TState, vrf_provider_address: ContractAddress);

    /// Transfers ownership of the contract to a new address.
    ///
    /// Requirements:
    ///
    /// - `new_owner` The address of the new owner
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);

    /// Claims the reward at the end of a match, sending the reward to the treasury.
    ///
    /// Requirements:
    ///
    /// - `treasury` The amount of reward that is claimed and sent to the treasury.
    /// - `match_level` The level of the match from which the reward is being claimed.
    /// - `salt_nonce` The salt nonce used to generate the signature.
    /// - `sign` represents the cryptographic signature of validator to validate the reward claim
    /// and not ues twice.
    ///
    /// Emits a `ClaimEndMatchReward` event.
    fn claim_end_match_reward(
        ref self: TState, treasury: u256, match_level: u32, salt_nonce: u64, sign: Array<felt252>
    );

    /// Grafts a treasure chest by verifying a signature.
    ///
    /// Requirements:
    ///
    /// - `chest_address` the address of treasure chest that can be claimed
    /// - `chest_id` the id of treasure chest that can be claimed
    /// - `amount` the amount of treasure chest that can be claimed
    /// - `salt_nonce` The salt nonce used to generate the signature.
    /// - `sign` represents the cryptographic signature of validator to validate the treasure chest
    /// grafting and not ues twice.
    ///
    /// Emits a `GraftTreasureChest` event.
    fn graft_treasure_chest(
        ref self: TState,
        chest_address: ContractAddress,
        chest_id: u256,
        amount: u256,
        salt_nonce: u64,
        sign: Array<felt252>
    );

    /// Opens a treasure chest.
    ///
    /// Requirements:
    ///
    /// - `chest_address` the address of treasure chest
    /// - `chest_id` the id of treasure chest that can be claimed
    /// - `receiver` the address of the player that receives the treasure chest
    ///
    /// Emits a `OpenTreasureChest` event.
    fn open_treasure_chest(ref self: TState, chest_address: ContractAddress, chest_id: u256);

    /// Returns the owner address
    fn get_owner(self: @TState) -> ContractAddress;

    /// Returns the validator address.
    fn get_validator(self: @TState) -> ContractAddress;

    /// Returns the vrf provider address.
    fn get_vrf_provider(self: @TState) -> ContractAddress;

    /// Returns the player data.
    ///
    /// Requirements:
    ///
    /// - `address` The address of the player.
    fn get_player_data(self: @TState, address: ContractAddress) -> PlayerData;
}
