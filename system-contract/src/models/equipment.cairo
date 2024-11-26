use starknet::ContractAddress;

#[derive(Serde, Copy, Drop, Introspect)]
pub struct WeaponDefine {
    bonusBulletDamage: u16,
    bonusAttackSpeed: u16,
    bonusMagazineSize: u16,
    bonusReloadSpeed: u16,
    bonusCritRate: u16,
    bonusCritDamage: u16,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum EquipmentType {
    Weapon,
    Armor,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum EquipmentRarity {
    Common,
    Great,
    Rare,
    Epic,
    Legendary,
    Mythical,
}

impl EquipmentTypeFelt252 of Into<EquipmentType, felt252> {
    fn into(self: EquipmentType) -> felt252 {
        match self {
            EquipmentType::Weapon => 'weapon',
            EquipmentType::Armor => 'armor',
        }
    }
}

impl EquipmentRarityFelt252 of Into<EquipmentRarity, felt252> {
    fn into(self: EquipmentRarity) -> felt252 {
        match self {
            EquipmentRarity::Common => 'common',
            EquipmentRarity::Great => 'great',
            EquipmentRarity::Rare => 'rare',
            EquipmentRarity::Epic => 'epic',
            EquipmentRarity::Legendary => 'legendary',
            EquipmentRarity::Mythical => 'mythical',
        }
    }
}
