extends RefCounted
class_name ItemEffects

# field 0 masks
const ITEM0_DIRE_HIT: int = 0x30 # Works the same way as the move Focus Energy.
const ITEM0_SACRED_ASH: int = 0x40
const ITEM0_INFATUATION: int = 0x80

# new field 1 masks
# Nota: Se usan los valores numéricos estándar de pokeemerald para los stats.
# Si tienes una clase "Stats" definida, puedes reemplazarlos por Stats.ATK, Stats.DEF, etc.
const ITEM1_X_ATTACK: int = 1   # STAT_ATK
const ITEM1_X_DEFENSE: int = 2  # STAT_DEF
const ITEM1_X_SPEED: int = 3    # STAT_SPEED
const ITEM1_X_SPATK: int = 4    # STAT_SPATK
const ITEM1_X_SPDEF: int = 5    # STAT_SPDEF
const ITEM1_X_ACCURACY: int = 6 # STAT_ACC

# field 3 masks
const ITEM3_CONFUSION: int = 0x1
const ITEM3_PARALYSIS: int = 0x2
const ITEM3_FREEZE: int = 0x4
const ITEM3_BURN: int = 0x8
const ITEM3_POISON: int = 0x10
const ITEM3_SLEEP: int = 0x20
const ITEM3_LEVEL_UP: int = 0x40
const ITEM3_GUARD_SPEC: int = 0x80 # Works the same way as the move Mist.

const ITEM3_STATUS_ALL: int = ITEM3_CONFUSION | ITEM3_PARALYSIS | ITEM3_FREEZE | ITEM3_BURN | ITEM3_POISON | ITEM3_SLEEP

# field 4 masks
const ITEM4_EV_HP: int = 0x1
const ITEM4_EV_ATK: int = 0x2
const ITEM4_HEAL_HP: int = 0x4
const ITEM4_HEAL_PP: int = 0x8
const ITEM4_HEAL_PP_ONE: int = 0x10
const ITEM4_PP_UP: int = 0x20
const ITEM4_REVIVE: int = 0x40
const ITEM4_EVO_STONE: int = 0x80

# field 5 masks
const ITEM5_EV_DEF: int = 0x1
const ITEM5_EV_SPEED: int = 0x2
const ITEM5_EV_SPDEF: int = 0x4
const ITEM5_EV_SPATK: int = 0x8
const ITEM5_PP_MAX: int = 0x10
const ITEM5_FRIENDSHIP_LOW: int = 0x20
const ITEM5_FRIENDSHIP_MID: int = 0x40
const ITEM5_FRIENDSHIP_HIGH: int = 0x80

const ITEM5_FRIENDSHIP_ALL: int = ITEM5_FRIENDSHIP_LOW | ITEM5_FRIENDSHIP_MID | ITEM5_FRIENDSHIP_HIGH

const ITEM10_IS_VITAMIN: int = 0x1

# fields 6 and onwards (except field 10) are item-specific arguments
const ITEM_EFFECT_ARG_START: int = 6

# Special HP recovery amounts for ITEM4_HEAL_HP
# En C, (u8)-1 equivale a 255, (u8)-2 a 254, etc.
const ITEM6_HEAL_HP_FULL: int = 255
const ITEM6_HEAL_HP_HALF: int = 254
const ITEM6_HEAL_HP_LVL_UP: int = 253
const ITEM6_HEAL_HP_QUARTER: int = 252

# Special PP recovery amounts for ITEM4_HEAL_PP
const ITEM6_HEAL_PP_FULL: int = 0x7F

# Amount of EV modified by ITEM4_EV_HP, ITEM4_EV_ATK, ITEM5_EV_DEF, ITEM5_EV_SPEED, ITEM5_EV_SPDEF and ITEM5_EV_SPATK
const ITEM6_ADD_EV: int = 10
const ITEM6_SUBTRACT_EV: int = -10
const ITEM6_ADD_ONE_EV: int = 1
const ITEM6_RESET_EV: int = 0

# Used for GetItemEffectType.
enum ItemEffectType {
	ITEM_EFFECT_X_ITEM,
	ITEM_EFFECT_RAISE_LEVEL,
	ITEM_EFFECT_HEAL_HP,
	ITEM_EFFECT_CURE_POISON,
	ITEM_EFFECT_CURE_SLEEP,
	ITEM_EFFECT_CURE_BURN,
	ITEM_EFFECT_CURE_FREEZE_FROSTBITE,
	ITEM_EFFECT_CURE_PARALYSIS,
	ITEM_EFFECT_CURE_CONFUSION,
	ITEM_EFFECT_CURE_INFATUATION,
	ITEM_EFFECT_SACRED_ASH,
	ITEM_EFFECT_CURE_ALL_STATUS,
	ITEM_EFFECT_ATK_EV,
	ITEM_EFFECT_HP_EV,
	ITEM_EFFECT_SPATK_EV,
	ITEM_EFFECT_SPDEF_EV,
	ITEM_EFFECT_SPEED_EV,
	ITEM_EFFECT_DEF_EV,
	ITEM_EFFECT_EVO_STONE,
	ITEM_EFFECT_PP_UP,
	ITEM_EFFECT_PP_MAX,
	ITEM_EFFECT_HEAL_PP,
	ITEM_EFFECT_NONE,
}

# The amount of bonus friendship gained when an item is used on a Pokémon whose met location matches the current map section.
const ITEM_FRIENDSHIP_MAPSEC_BONUS: int = 1

# The amount of bonus friendship gained when a Pokémon is in the Luxury Ball.
const ITEM_FRIENDSHIP_LUXURY_BONUS: int = 1

# Since X item stat increases are now handled by battle scripts, the friendship increase effect is now handled by the battle controller in HandleAction_UseItem.
# The amount of friendship gained by using an X item on a Pokémon in battle.
const X_ITEM_FRIENDSHIP_INCREASE: int = 1

# Friendship threshold at which Pokémon stop receiving a friendship increase from using X items on them in battle.
const X_ITEM_MAX_FRIENDSHIP: int = 200
