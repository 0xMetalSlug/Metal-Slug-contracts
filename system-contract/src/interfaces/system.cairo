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

    /// Updates the rarity bonus.
    ///
    /// Requirements:
    ///
    /// - `rarity` The rarity of the equipment
    /// - `min_bonus` The minimum bonus value
    /// - `max_bonus` The maximum bonus value
    fn update_rarity_bonus(ref self: TState, rarity: felt252, min_bonus: u16, max_bonus: u16);

    /// Updates the chest address.
    ///
    /// Requirements:
    ///
    /// - `chest_address` The address of the treasure chest
    /// - `is_allowed` The boolean value indicating whether the chest address is allowed or not
    fn update_chest_address(ref self: TState, chest_address: ContractAddress, is_allowed: bool);

    /// Updates the equipment address.
    ///
    /// Requirements:
    ///
    /// - `equipment_address` The address of the equipment
    /// - `is_allowed` The boolean value indicating whether the equipment address is allowed or not
    fn update_equipment_address(
        ref self: TState, equipment_address: ContractAddress, is_allowed: bool
    );

    /// Appends new equipment ids.
    ///
    /// Requirements:
    ///
    /// - `equipment_address` The address of the equipment
    /// - `equipment_ids` The array of equipment ids
    fn append_equipment_ids(
        ref self: TState, equipment_address: ContractAddress, equipment_ids: Array<u256>
    );

    /// Removes equipment id.
    ///
    /// Requirements:
    ///
    /// - `equipment_address` The address of the equipment
    /// - `equipment_id` The id of the equipment
    fn remove_equipment_id(
        ref self: TState, equipment_address: ContractAddress, equipment_id: u256
    );

    /// Equips a weapon.
    ///
    /// Requirements:
    ///
    /// - `weapon_slot` The slot where the weapon is equipped.
    /// - `weapon_id` The id of the weapon.
    /// - `weapon_address` The address of the weapon.
    ///
    /// Emits a `EquipWeapon` event.
    // fn equip_weapon(
    //     ref self: TState, weapon_slot: u8, weapon_id: u256, weapon_address: ContractAddress
    // );

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

    /// Claims points.
    ///
    /// Requirements:
    ///
    /// - `points` The amount of points that is claimed.
    /// - `salt_nonce` The salt nonce used to generate the signature.
    /// - `sign` represents the cryptographic signature of validator to validate the points
    /// claim and not ues twice.
    ///
    /// Emits a `ClaimPoints` event.
    fn claim_points(ref self: TState, points: u256, salt_nonce: u64, sign: Array<felt252>);

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
    /// - `equipment_address` the address of equipment
    ///
    /// Emits a `OpenTreasureChest` event.
    fn open_treasure_chest(
        ref self: TState,
        chest_address: ContractAddress,
        chest_id: u256,
        equipment_address: ContractAddress
    );

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

    /// Return rarity bonus
    ///
    /// Requirements:
    ///
    /// - `rarity` the type of rarity
    fn get_rarity_bonus(self: @TState, rarity: felt252) -> (u16, u16);

    fn get_equipment_ids(self: @TState, equipment_address: ContractAddress) -> Span<u256>;
}
