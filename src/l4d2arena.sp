#pragma semicolon 1

#include <l4d2_direct>
#include <l4d2weapons>
#include <left4downtown>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

/* To-do:
 * - Make it so tank stops rock sequence when shoved since the rock disappears.
 * - Do something similar about smoker movement after firing tongue, since it was choppy. Or maybe that as just my insane lag.
 * - Make jockey damage itself while riding.
 * - Make adrenaline give its already planned death protection.
 * - Make spitter initial hit do damage.
 * - Make spitter not be slowed down by spitting.
 * - Use spitter spit cvars to reduce delay between clicking on mouse button and actually spitting.
 * - Maybe make spitter spit more often.
 * - Add the already planned ability for spitter scratches to increase damage taken.
 * - Remove all natural SI and survivor slowdown (if it's actually still there, not sure).
 * - See if it's possible to make classes attack faster:
 * 	- boomer!
 *  - maybe spitter?
 *  - maybe jockey?
 *  - why not all of them?
 * - Increase jockey control a tiny bit beyond regular confogl.
 * - See if it's possible to reduce delay between mouse click and punch on tank.
 * - Make sure si being able to respawn is fixed.
 * - Make incendiary glow orange instead of pink.
 * - Make adrenaline glow the same color as defib.
 * - Make pills glow the same color as medkit.
 * - Add glows to players who have picked up powerups:
 *  - Orange for incendiary.
 * 	- Red for explosive.
 *  - Blue for shielded.
 *  - Violet for red + blue.
 *  - Pink for orange + blue.
 *  - Teal for adrenaline with nothing else.
 * - Remove regular glows from survivors so no one can see anyone through walls.
 * - Make smoker tongue damage increase with distance.
 * - Do the planned tank rock damage changes.
 * - See if point_proximity_sensor could be used to replace touchentities for powerups
 * 
 * - https://developer.valvesoftware.com/wiki/Player use this for health of players
 * - Add props to cemetery.
 * - See if you can add strafe jumping for a tiny little boost of speed (further increased by actual bhopping).
 * - Fix some powerups being unusable at random times for random amounts of time before becoming usable again.
 * - Test new survivor weapon damages.
 * - Look at survivor MVP plugin to fix and improve scoring system.
 * - Add tracking of death jockeys and death charges (already taken care of death impact charges, missing the carried survivor)
 * - Add glitch fixes from promod to the config.
 * 
 * - Think more about what to do with charger.
 * - Add 4 survivor classes. Use these weapons:
 * 	- HR, smg or silenced smg, desert rifle, +1
 * 	- machete, dual pistols, +2
 * - Maybe give tank control of what kind of rock he throws. Maybe make rock throws be faster if it's possible.
 * 
 * - for apocalypse: test SetHUDVisibility from player entity
 * - for apocalypse: DisableFlashlight and EnableFlashlight from player entity to make flashlights have batteries
 * - for apocalypse: use fgd to look into getting default value of sun light for map 
 */


/*	L4D2 constants	*/
//weapons
#define WEP_TANK_CLAW		38
#define WEP_HUNTER_CLAW		39
#define WEP_CHARGER_CLAW	40
#define WEP_BOOMER_CLAW		41
#define WEP_SMOKER_CLAW		42
#define WEP_SPITTER_CLAW	43
#define WEP_JOCKEY_CLAW		44
#define WEP_HUNTER_POUNCE	48
#define WEP_JOCKEY_LUNGE	49
#define WEP_SMOKER_PULL		50
#define WEP_TANK_ROCK		52
//ammo offsets
#define OFFSET_ASSAULT_RIFLE_IAMMO		12
#define OFFSET_SMG_IAMMO				20
#define OFFSET_PUMPSHOTGUN_IAMMO		28
#define OFFSET_AUTO_SHOTGUN_IAMMO		32
#define OFFSET_HUNTING_RIFLE_IAMMO		36
#define OFFSET_MILITARY_SNIPER_IAMMO	40
#define OFFSET_GRENADE_LAUNCHER_IAMMO	68
//teams
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
//ZCs
#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_TANK                 8
//saferoom door states
#define DOOR_UNLOCK             0
#define DOOR_LOCK               1
#define DOOR_CLOSED             0
#define DOOR_OPENING            1
#define DOOR_OPEN               2
#define DOOR_CLOSING            3
/* Arena constants */
//directory of keyvalues file
#define DIR_KV	"cfg/l4d2arena_kv.txt"
//radius within which to look for enemies when checking if a spawn point is clear
#define RANGE_DETECT_ENEMIES_FOR_SPAWN	800.0
//class indexing
#define CLASS_NONE			0
#define CLASS_HUNTER		1
#define CLASS_CHARGER		2
#define CLASS_JOCKEY		3
#define CLASS_SMOKER		4
#define CLASS_TANK			5
#define CLASS_BOOMER		6
#define CLASS_SPITTER		7
#define CLASS_SHARPSHOOTER	8
#define CLASS_JUGGERNAUT	9
#define CLASS_NINJA			10
#define CLASS_COUNT			11
//respawn timers
#define DURATION_RESPAWN			8.0
#define DURATION_RESPAWN_DEFIB		0.1
#define DURATION_RESPAWN_KAMIKAZE	5.0
//si abilities
#define DAMAGE_SCRATCH_HUNTER		13.0
#define DAMAGE_SPECIAL_HUNTER		50.0	//base damage on pounce
#define	DAMAGE_SPECIAL_HUNTER_EXTRA	0.0		//distance-based maximum extra damage
#define DAMAGE_SCRATCH_CHARGER			10.0
#define DAMAGE_SPECIAL_CHARGER			7.0	//damage on pound
#define DAMAGE_SPECIAL_CHARGER_SECOND	15.0	//damage from secondary impacts on double/triple/quad charges
#define DURATION_SPECIAL_CHARGER		1.0
#define COOLDOWN_SPECIAL_CHARGER		1.5
#define SPEED_SPECIAL_CHARGER			500.0
#define DAMAGE_SCRATCH_JOCKEY		8.0
#define DAMAGE_SPECIAL_JOCKEY		3.0		//dmg to victim
#define DAMAGE_SPECIAL_JOCKEY_SELF	9.0		//dmg on the jockey while riding
#define DURATION_SPECIAL_JOCKEY		1.0		//time between damage ticks
#define DAMAGE_SCRATCH_SMOKER	2.0
#define DAMAGE_SPECIAL_SMOKER	18.0	//damage on tongue hit
#define RANGE_SPECIAL_SMOKER	2048.0	//range of smoker tongue
#define SPEED_SPECIAL_SMOKER	750.0	//velocity of smoker tongue
#define COOLDOWN_SPECIAL_SMOKER	2.0	
#define DURATION_SPECIAL_SMOKER	10.0	//duration of debuff
#define DAMAGE_SCRATCH_BOOMER	8.0
#define DURATION_SPECIAL_BOOMER	
#define DAMAGE_SCRATCH_SPITTER		4.0
#define DAMAGE_SPECIAL_SPITTER		25.0	//damage on spit direct hit
#define SPEED_SPECIAL_SPITTER		2000.0
#define COOLDOWN_SPECIAL_SPITTER	4.0
#define DAMAGE_SCRATCH_TANK				10.0
#define DAMAGE_SPECIAL_TANK_MIN			10.0 //rock min damage
#define DAMAGE_SPECIAL_TANK_MAX			25.0 //rock max damage
#define DAMAGE_SPECIAL_TANK_MINRANGE	256.0	//range at which rock damage increase starts 
#define DAMAGE_SPECIAL_TANK_MAXRANGE	1536.0	//range at which max rock damage is reached
//survivor m2 delays
#define DURATION_M2_SHARPSHOOTER		6.0
#define DURATION_M2_JUGGERNAUT			4.0
#define DURATION_M2_NINJA				7.0
#define DURATION_M2_NINJA_BEFOREDELAY	2.0		//if the ninja does less than SPECIAL_M2_NINJA shoves in this interval, he does not need get the delay
#define SPECIAL_M2_NINJA				3		//amount of shoves ninja can do before delay
#define SPECIAL_M2_JUGGERNAUT_DIVISOR	4		//how much juggernaut's health is divided by before applying it as damage
//important models
#define MODEL_PILLS			"models/w_models/weapons/w_eq_painpills.mdl"
#define MODEL_MEDKIT		"models/w_models/weapons/w_eq_medkit.mdl"
#define MODEL_ADRENALINE	"models/w_models/weapons/w_eq_adrenaline.mdl"
#define MODEL_DEFIB			"models/w_models/weapons/w_eq_defibrillator.mdl"
#define MODEL_INCENDIARY	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
#define MODEL_EXPLOSIVE		"models/w_models/weapons/w_eq_explosive_ammopack.mdl"
#define MODEL_SHIELD		"models/weapons/melee/w_riotshield.mdl"
#define MODEL_GNOME			"models/props_junk/gnome.mdl"
//time-related powerup constants
#define DURATION_ADRENALINE				20.0
#define DURATION_ADRENALINE_SPECIAL		3.0
#define DURATION_INCENDIARY				30.0
#define DURATION_EXPLOSIVE				20.0
#define DURATION_SHIELD					60.0
//percentage bonuses
#define PERCENTG_ADRENALINE_BONUS_SPEED		0.3
#define PERCENTG_INCENDIARY_BONUS_DAMAGE	0.2
#define PERCENTG_EXPLOSIVE_BONUS_DAMAGE		1.0
#define PERCENTG_SHIELD_BONUS_PROTECTION	0.25
//absolute bonuses
#define ABSOLUTE_PILLS_BONUS_HEALTH		30
#define ABSOLUTE_MEDKIT_BONUS_HEALTH	60
//powerup respawn tiers
#define DURATION_RESPAWN_POWERUP_QUICK	20.0
#define DURATION_RESPAWN_POWERUP_MID	60.0
#define DURATION_RESPAWN_POWERUP_LONG	150.0
//colors
#define COLOR_BLUE			"0 0 255"
#define COLOR_TEAL			"0 255 255"
#define COLOR_TEAL_LIGHT	"0 255 128"
#define COLOR_GREEN			"0 255 0"
#define COLOR_GREEN_LIGHT	"80 255 80"
#define COLOR_ORANGE		"255 80 80"
#define COLOR_RED			"255 0 0"
#define COLOR_WHITE			"255 255 255"
//causes of death
#define	COD_PWNT		0	//killed by an enemy
#define COD_FF			1	//killed by an ally
#define COD_KAMIKAZE	2	//hunter special ability, death charges, etc
#define COD_WORLD		3	//other kills

#define SOUND_ITEMSPAWN "/items/suitchargeok1.wav"
#define SOUND_ITEMGRAB	"/items/itempickup.wav"

static const String:g_sArSIBlockedSounds[][PLATFORM_MAX_PATH] = 
{	/* BOOMER */
	//warning
//	"player/boomer/voice/warn/female_boomer_warning_01.wav",	"player/boomer/voice/warn/female_boomer_warning_12.wav",	"player/boomer/voice/warn/female_boomer_warning_13.wav",
//	"player/boomer/voice/warn/female_boomer_warning_14.wav",	"player/boomer/voice/warn/female_boomer_warning_15.wav",	"player/boomer/voice/warn/female_boomer_warning_16.wav",
//	"player/boomer/voice/warn/female_boomer_warning_17.wav",	"player/boomer/voice/warn/male_boomer_warning_01.wav",		"player/boomer/voice/warn/male_boomer_warning_12.wav",
//	"player/boomer/voice/warn/male_boomer_warning_13.wav",		"player/boomer/voice/warn/male_boomer_warning_14.wav",		"player/boomer/voice/warn/male_boomer_warning_15.wav",
//	"player/boomer/voice/warn/male_boomer_warning_16.wav",		"player/boomer/voice/warn/male_boomer_warning_17.wav",
	//alert
	"player/boomer/voice/alert/female_boomer_warning_04.wav",	"player/boomer/voice/alert/female_boomer_warning_05.wav",	"player/boomer/voice/alert/female_boomer_warning_07.wav",
	"player/boomer/voice/alert/female_boomer_warning_10.wav",	"player/boomer/voice/alert/female_boomer_warning_11.wav",	"player/boomer/voice/alert/female_boomer_warning_12.wav",
	"player/boomer/voice/alert/female_boomer_warning_13.wav",	"player/boomer/voice/alert/female_boomer_warning_14.wav",	"player/boomer/voice/alert/female_boomer_warning_15.wav",
	"player/boomer/voice/alert/male_boomer_warning_04.wav",		"player/boomer/voice/alert/male_boomer_warning_05.wav",		"player/boomer/voice/alert/male_boomer_warning_07.wav",
	"player/boomer/voice/alert/male_boomer_warning_10.wav",		"player/boomer/voice/alert/male_boomer_warning_11.wav",		"player/boomer/voice/alert/male_boomer_warning_12.wav",
	"player/boomer/voice/alert/male_boomer_warning_13.wav",		"player/boomer/voice/alert/male_boomer_warning_14.wav",		"player/boomer/voice/alert/male_boomer_warning_15.wav"	,
	//idle
	"player/Boomer/voice/idle/female_boomer_Lurk_01.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_02.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_03.wav",
	"player/Boomer/voice/idle/female_boomer_Lurk_04.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_05.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_06.wav",
	"player/Boomer/voice/idle/female_boomer_Lurk_07.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_08.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_09.wav",
	"player/Boomer/voice/idle/female_boomer_Lurk_10.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_11.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_12.wav",
	"player/Boomer/voice/idle/female_boomer_Lurk_13.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_14.wav",		"player/Boomer/voice/idle/female_boomer_Lurk_15.wav",
	"player/Boomer/voice/idle/male_boomer_Lurk_01.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_02.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_03.wav",
	"player/Boomer/voice/idle/male_boomer_Lurk_04.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_05.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_06.wav",
	"player/Boomer/voice/idle/male_boomer_Lurk_07.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_08.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_09.wav",
	"player/Boomer/voice/idle/male_boomer_Lurk_10.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_11.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_12.wav",
	"player/Boomer/voice/idle/male_boomer_Lurk_13.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_14.wav",			"player/Boomer/voice/idle/male_boomer_Lurk_15.wav",
	"player/Boomer/voice/idle/indigestion_loop.wav",
	/* CHARGER */
	//warning
	"player/charger/voice/warn/charger_warn1.wav",				"player/charger/voice/warn/charger_warn2.wav",				"player/charger/voice/warn/charger_warn3.wav",
	//alert
	"player/charger/voice/alert/charger_alert_01.wav",			"player/charger/voice/alert/charger_alert_01.wav",	
	//idle
	"player/charger/voice/idle/charger_spotprey_01.wav",		"player/charger/voice/idle/charger_spotprey_02.wav",		"player/charger/voice/idle/charger_spotprey_03.wav",
	"player/charger/voice/idle/Charger_lurk_01.wav",			"player/charger/voice/idle/Charger_lurk_02.wav",			"player/charger/voice/idle/Charger_lurk_03.wav",
	"player/charger/voice/idle/Charger_lurk_04.wav",			"player/charger/voice/idle/Charger_lurk_05.wav",			"player/charger/voice/idle/Charger_lurk_06.wav",
	"player/charger/voice/idle/Charger_lurk_07.wav",			"player/charger/voice/idle/Charger_lurk_08.wav",			"player/charger/voice/idle/Charger_lurk_09.wav",
	"player/charger/voice/idle/Charger_lurk_10.wav",			"player/charger/voice/idle/Charger_lurk_11.wav",			"player/charger/voice/idle/Charger_lurk_12.wav",
	"player/charger/voice/idle/Charger_lurk_13.wav",			"player/charger/voice/idle/Charger_lurk_14.wav",			"player/charger/voice/idle/Charger_lurk_15.wav",
	"player/charger/voice/idle/Charger_lurk_16.wav",			"player/charger/voice/idle/Charger_lurk_17.wav",			"player/charger/voice/idle/Charger_lurk_18.wav",
	"player/charger/voice/idle/Charger_lurk_19.wav",			"player/charger/voice/idle/Charger_lurk_20.wav",			"player/charger/voice/idle/Charger_lurk_21.wav",
	"player/charger/voice/idle/Charger_lurk_22.wav",			"player/charger/voice/idle/Charger_lurk_23.wav",
	/* HUNTER */
	//warning
	/* dont know what these sounds are, they seem to just be clones of his pounce sounds that are stored in another directory (player/PZ/... */
	//alert
	/* i dont know what their alert sounds are, dont think they're used */
	//idle
	/* hunter idle sounds are the ones played while cruoching: keep them in to encourage wall kicking*/
	/* JOCKEY */
	//warning
	"player/jockey/voice/warn/jockey_06.wav",					"player/jockey/voice/warn/jockey_08.wav",	
	//alert
	"player/jockey/voice/alert/jockey_02.wav",					"player/jockey/voice/alert/jockey_04.wav",
	//idle
	"player/jockey/voice/idle/jockey_spotprey_01.wav",			"player/jockey/voice/warn/jockey_spotprey_02.wav",
//	"player/jockey/voice/idle/jockey_lurk_01.wav",				"player/jockey/voice/idle/jockey_lurk_03.wav",				"player/jockey/voice/idle/jockey_lurk_04.wav",
//	"player/jockey/voice/idle/jockey_lurk_05.wav",				"player/jockey/voice/idle/jockey_lurk_06.wav",				"player/jockey/voice/idle/jockey_lurk_07.wav",
//	"player/jockey/voice/idle/jockey_lurk_09.wav",				"player/jockey/voice/idle/jockey_lurk_11.wav",
	"player/jockey/voice/idle/Jockey_Recognize02.wav",			"player/jockey/voice/idle/Jockey_Recognize06.wav",			"player/jockey/voice/idle/Jockey_Recognize07.wav",
	"player/jockey/voice/idle/Jockey_Recognize08.wav",			"player/jockey/voice/idle/Jockey_Recognize09.wav",			"player/jockey/voice/idle/Jockey_Recognize10.wav",
	"player/jockey/voice/idle/Jockey_Recognize11.wav",			"player/jockey/voice/idle/Jockey_Recognize12.wav",			"player/jockey/voice/idle/Jockey_Recognize13.wav",
	"player/jockey/voice/idle/Jockey_Recognize15.wav",			"player/jockey/voice/idle/Jockey_Recognize16.wav",			"player/jockey/voice/idle/Jockey_Recognize17.wav",
	"player/jockey/voice/idle/Jockey_Recognize18.wav",			"player/jockey/voice/idle/Jockey_Recognize19.wav",			"player/jockey/voice/idle/Jockey_Recognize20.wav",
	"player/jockey/voice/idle/Jockey_Recognize24.wav",
	/* SMOKER */
	//warning
	//alert
	//idle
	"player/smoker/voice/idle/Smoker_Lurk_01.wav",				"player/smoker/voice/idle/Smoker_Lurk_03.wav",				"player/smoker/voice/idle/Smoker_Lurk_04.wav",
	"player/smoker/voice/idle/Smoker_Lurk_06.wav",				"player/smoker/voice/idle/Smoker_Lurk_08.wav",				"player/smoker/voice/idle/Smoker_Lurk_09.wav",
	"player/smoker/voice/idle/Smoker_Lurk_10.wav",				"player/smoker/voice/idle/Smoker_Lurk_11.wav",				"player/smoker/voice/idle/Smoker_Lurk_12.wav",
	"player/smoker/voice/idle/Smoker_Lurk_13.wav",
	/* SPITTER */
	//warning
	//alert
	//idle
	"player/spitter/voice/idle/Spitter_Lurk_01.wav",			"player/spitter/voice/idle/Spitter_Lurk_02.wav",			"player/spitter/voice/idle/Spitter_Lurk_03.wav",
	"player/spitter/voice/idle/Spitter_Lurk_04.wav",			"player/spitter/voice/idle/Spitter_Lurk_05.wav",			"player/spitter/voice/idle/Spitter_Lurk_06.wav",
	"player/spitter/voice/idle/Spitter_Lurk_07.wav",			"player/spitter/voice/idle/Spitter_Lurk_08.wav",			"player/spitter/voice/idle/Spitter_Lurk_09.wav",
	"player/spitter/voice/idle/Spitter_Lurk_10.wav",			"player/spitter/voice/idle/Spitter_Lurk_11.wav",			"player/spitter/voice/idle/Spitter_Lurk_12.wav",
	"player/spitter/voice/idle/Spitter_Lurk_14.wav",			"player/spitter/voice/idle/Spitter_Lurk_15.wav",			"player/spitter/voice/idle/Spitter_Lurk_16.wav",
	"player/spitter/voice/idle/Spitter_Lurk_17.wav",			"player/spitter/voice/idle/Spitter_Lurk_18.wav",			"player/spitter/voice/idle/Spitter_Lurk_19.wav",
	"player/spitter/voice/idle/Spitter_Lurk_20.wav",
	/* TANK */
	//warning
	//alert
	//idle
	"player/tank/voice/idle/Tank_Breathe_01.wav",				"player/tank/voice/idle/Tank_Breathe_02.wav",				"player/tank/voice/idle/Tank_Breathe_03.wav",
	"player/tank/voice/idle/Tank_Breathe_04.wav",				"player/tank/voice/idle/Tank_Breathe_05.wav",				"player/tank/voice/idle/Tank_Breathe_06.wav",
	"player/tank/voice/idle/Tank_Breathe_07.wav",				"player/tank/voice/idle/Tank_Breathe_08.wav",
	"player/tank/voice/idle/Tank_Growl_01.wav",					"player/tank/voice/idle/Tank_Growl_02.wav",					"player/tank/voice/idle/Tank_Growl_03.wav",
	"player/tank/voice/idle/Tank_Growl_09.wav",					"player/tank/voice/idle/Tank_Growl_10.wav",					"player/tank/voice/idle/Tank_Growl_11.wav",	
	"player/tank/voice/idle/Tank_Growl_12.wav"
};

static const g_iArMaxHealthOfClass[CLASS_COUNT] = 
{	//none		//hunter	//charger	//jockey	
	0,			100,		200,		100,
	//smoker	//tank		//boomer	//spitter
	100,		80,			80,			100,
	
	//shrpshter	//jugg		//ninja
	100,		150,		80
};
static const Float:g_fArMaxSpeedOfClass[CLASS_COUNT] =
{	//none		//hunter	//charger	//jockey	
	0.0,		312.0,		252.0,		300.0,	
	//smoker	//tank		//boomer	//spitter
	276.0,		312.0,		350.0,		300.0,
							/*336.0 boomer original*/
	//shrpshter	//jugg		//ninja
	276.0,		300.0,		324.0
};

new 		g_iOffsetAbility;
new Handle:	g_hConfigFile = INVALID_HANDLE;
new Handle:	g_hSDKCallRespawn = INVALID_HANDLE;
new Handle:	g_hSDKCallSetClass = INVALID_HANDLE;
new Handle: g_hSDKCallCreateAbility = INVALID_HANDLE;

new Handle:	g_hArrayPowerupEntities = INVALID_HANDLE;
new Handle:	g_hArrayPowerupTouchEntities = INVALID_HANDLE;
new Handle:	g_hTriePowerupModels = INVALID_HANDLE;
new Handle: g_hTrieMeleeWeaponDamages = INVALID_HANDLE;
new Handle: g_hTrieMeleeWeaponHitRayLimits = INVALID_HANDLE;
new Handle:	g_hTrieSoundsBlocked = INVALID_HANDLE;

new			g_iArScoreOf[MAXPLAYERS + 1];	//control this by steam id later, to set it to normal when a player reconnects instead of setting to 0 on put in server
new 		g_iArClassOf[MAXPLAYERS + 1];
new 		g_iArClassToChangeToOnDeath[MAXPLAYERS + 1];
new			g_iArCauseOfDeath[MAXPLAYERS + 1];
new			g_iArWorldDeathCauserOf[MAXPLAYERS + 1];

new Float:	g_fArTimeSmokerSlowdownEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeAdrenalineEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeIncendiaryAmmoEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeExplosiveAmmoEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeShieldEndsAt[MAXPLAYERS + 1];
new 		g_iArDefibCount[MAXPLAYERS + 1];

/*
iTimesScratchedBySpitter[MAXPLAYERS + 1];	//will affect damage received, ticks down via timers
fTimeSinceLaserSightsUsed[MAXPLAYERS + 1];
*/

/*
 * for blocking infected glows: use glow properties, if not possible use cl commands for glows 
 * and see if you can make them disappear - ofc you have to add the cheat flag to those commands
 * otherwise people will change it
 * 
 * */

public Plugin:myinfo = 
{
	name = "Left 4 Dead 2 Arena",
	author = "Stabby",
	description = "Has all the features of L4D2A: respawning, classes, scoring, etc.",
	version = "0.1",
	url = "none"
}

public OnPluginEnd()
{
	ResetCvars();
	ResetWeaponAttributes();
}

public OnPluginStart()
{
	PrecacheThings();
	SetCvars();
	SetWeaponAttributes();
	HookThings();
	PrepAllSDKCalls();
	RegisterCommands();
	InitialiseTries();
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_ATTACK2 && GetClientTeam(client) == TEAM_SURVIVOR && L4D2Direct_GetNextShoveTime(client) <= GetGameTime())
	{
		switch (g_iArClassOf[client])
		{
			case CLASS_JUGGERNAUT:
			{
				L4D2Direct_SetNextShoveTime(client, GetGameTime() + DURATION_M2_JUGGERNAUT);
			}
			case CLASS_SHARPSHOOTER:
			{
				L4D2Direct_SetNextShoveTime(client, GetGameTime() + DURATION_M2_SHARPSHOOTER);
			}
			case CLASS_NINJA:
			{
				CreateTimer(DURATION_M2_NINJA_BEFOREDELAY, Timed_DelayNinjaM2, client);
			}
		}
	}
}

public Action:Timed_DelayNinjaM2(Handle:timer, any:client)
{
	L4D2Direct_SetNextShoveTime(client, GetGameTime() + DURATION_M2_SHARPSHOOTER);
}

stock PostSpawnGearPlayerByClass(client)
{
	switch (GetClientTeam(client))
	{
		case TEAM_SURVIVOR:
		{
			new WeaponIndex;
			for (new slot = 0; slot < 5; slot++)
			{
				while ((WeaponIndex = GetPlayerWeaponSlot(client, slot)) != -1)
				{
					RemovePlayerItem(client, WeaponIndex);
					RemoveEdict(WeaponIndex);
				}
			}
			
			switch (g_iArClassOf[client])
			{
				case CLASS_JUGGERNAUT:
				{
					GiveItem(client, "weapon_pumpshotgun");
					GiveItem(client, "weapon_melee", "fireaxe");
				}
				case CLASS_NINJA:
				{
					GiveItem(client, "weapon_shotgun_chrome");
					GiveItem(client, "weapon_melee", "katana");
				}
				case CLASS_SHARPSHOOTER:
				{
					GiveItem(client, "weapon_sniper_awp");
					GiveItem(client, "weapon_pistol_magnum");
				}
			}
			
			SetEntityHealth(client, g_iArMaxHealthOfClass[g_iArClassOf[client]]);
		}
		case TEAM_INFECTED:
		{
			new WeaponIndex;
			while ((WeaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			{
				RemovePlayerItem(client, WeaponIndex);
				RemoveEdict(WeaponIndex);
			}
			
			switch (g_iArClassOf[client])
			{
				case CLASS_BOOMER:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_BOOMER);
				}
				case CLASS_CHARGER:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_CHARGER);			
				}
				case CLASS_HUNTER:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_HUNTER);			
				}
				case CLASS_JOCKEY:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_JOCKEY);			
				}
				case CLASS_SMOKER:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_SMOKER);			
				}
				case CLASS_SPITTER:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_SPITTER);			
				}
				case CLASS_TANK:
				{
					SDKCall(g_hSDKCallSetClass, client, ZC_TANK);			
				}				
			}
			
			AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
			SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hSDKCallCreateAbility, client), g_iOffsetAbility));
		}
	}
}

stock GiveItem(client, const String:weaponname[], const String:meleename[] = "frying_pan")
{
	decl Float:clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	new entity = CreateEntityByName(weaponname);
	if (IsValidEntity(entity))
	{
		new bool:isMelee = StrEqual(weaponname, "weapon_melee");
		if (isMelee)
		{	//"fireaxe""frying_pan""machete""baseball_bat""crowbar""tonfa""katana""electric_guitar""golfclub"	
			DispatchKeyValue(entity, "melee_script_name", meleename);
		}
		DispatchSpawn(entity);
		TeleportEntity(entity, clientOrigin, NULL_VECTOR, NULL_VECTOR);
		EquipPlayerWeapon(client, entity);
		
		new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
		if (StrEqual(weaponname, "weapon_pumpshotgun") || StrEqual(weaponname, "weapon_shotgun_chrome"))
		{
			SetEntData(client, (iAmmoOffset + OFFSET_PUMPSHOTGUN_IAMMO), 150*L4D2_GetIntWeaponAttribute(weaponname, L4D2IWA_ClipSize), 4, true);
		}
		else if (StrEqual(weaponname, "weapon_sniper_awp"))
		{
			SetEntData(client, (iAmmoOffset + OFFSET_MILITARY_SNIPER_IAMMO), 150*L4D2_GetIntWeaponAttribute(weaponname, L4D2IWA_ClipSize), 4, true);
		}
		
		SDKHook(entity, SDKHook_Reload, OnReload);	//Hook for reload animation glitch semi-fix
		
//		ResetAmmo(client);
//		SDKHook(entity, SDKHook_ReloadPost, PostReload);
	}
}

public Action:ChooseTeam(client, args)
{
	if (IsPlayerAlive(client))
	{
		PrintToChat(client, "Can't change team while alive.");
	}
	else
	{
		ShowTeamMenu(client);
	}
}

public Action:ChooseClass(client, args)
{
	if (args < 1)
	{
		ShowClassMenu(client);
	}
	else
	{
		decl String:class[32];
		GetCmdArg(1, class, 32);
		
		SetClass(client, class);
	}
}

stock SetClass(client, const String:class[])
{
	switch (GetClientTeam(client))
	{
		case TEAM_INFECTED:
		{
			if (StrEqual(class, "boomer", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_BOOMER;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_BOOMER;
				}
			}
			else if (StrEqual(class, "charger", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_CHARGER;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_CHARGER;
				}
			}
			else if (StrEqual(class, "hunter", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_HUNTER;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_HUNTER;
				}
			}
			else if (StrEqual(class, "jockey", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_JOCKEY;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_JOCKEY;
				}
			}
			else if (StrEqual(class, "smoker", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_SMOKER;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_SMOKER;
				}
			}
			else if (StrEqual(class, "spitter", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_SPITTER;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_SPITTER;
				}
			}
			else if (StrEqual(class, "tank", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_TANK;
				}
				else
				{
					if (g_iArClassOf[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_TANK;
				}
			}
			else
			{
				PrintToChat(client, "Invalid class name.");
			}
		}
		case TEAM_SURVIVOR:
		{
			if (StrEqual(class, "juggernaut", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_JUGGERNAUT;
				}
				else
				{
					if (g_iArClassOf[client] == 0)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_JUGGERNAUT;
				}
			}
			else if (StrEqual(class, "ninja", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_NINJA;
				}
				else
				{
					if (g_iArClassOf[client] == 0)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_NINJA;
				}
			}
			else if (StrEqual(class, "sharpshooter", false))
			{
				if (IsPlayerAlive(client))
				{
					g_iArClassToChangeToOnDeath[client] = CLASS_SHARPSHOOTER;
				}
				else
				{
					if (g_iArClassOf[client] == 0)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClassOf[client] = CLASS_SHARPSHOOTER;
				}
			}
			else
			{
				PrintToChat(client, "Invalid class name.");
			}			
		}
	}
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	{
		KickClient(client);
	}
	
	g_iArClassOf[client] = CLASS_NONE;
	g_iArScoreOf[client] = 0;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);
	
	decl Float:position[3];
	
	
	decl String:mapname[64];
	GetCurrentMap(mapname, 64);
	
	KvJumpToKey(kv, mapname, true);		//go to map props -> if first time on this map, it'll be created
	KvGetVector(kv, "center", position);
	
	KvRewind(kv);
	CloseHandle(kv);
	
	TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);

	ChangeClientTeam(client, TEAM_SPECTATOR);
	CreateTimer(2.0, Timed_ShowTeamMenuOnConnect, client);
}

public Action:Timed_ShowTeamMenuOnConnect(Handle:timer, any:client)
{
	ShowTeamMenu(client);
}

stock ShowTeamMenu(client)
{
	new Handle:menu = CreateMenu(Menu_TeamSelection);
	SetMenuTitle(menu, "Select your team:");
	AddMenuItem(menu, "2", "Survivor");
	AddMenuItem(menu, "3", "Infected");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 600);
}

public Menu_TeamSelection(Handle:menu, MenuAction:action, param1, param2)
{
	if (param1 <= 0 || param1 > MaxClients)
	{
		return;
	}
	if (!IsClientInGame(param1))
	{
		return;
	}
	
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		if (GetMenuItem(menu, param2, info, sizeof(info)))
		{
			if (IsPlayerAlive(param1))
			{
				PrintToChat(param1, "Can't change team while alive.");
			}
			else
			{
				new team = StringToInt(info);
				
				decl Float:pos[3], Float:ang[3], Float:vec[3];
				GetClientAbsOrigin(param1, pos);
				GetClientEyeAngles(param1, ang);
				GetEntPropVector(param1, Prop_Data, "m_vecVelocity", vec); 
				
				ChangeClientTeam(param1, team);
				g_iArClassOf[param1] = CLASS_NONE;
				
				if (team == TEAM_SURVIVOR)	//stop from warping to saferoom
				{
					TeleportEntity(param1, pos, ang, vec);
				}
				
				ShowClassMenu(param1);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToChat(param1, "You can reopen the team selection menu at any time by saying !team.");
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock ShowClassMenu(client)
{
	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		return;
	}
	
	new Handle:menu = CreateMenu(Menu_ClassSelection);
	SetMenuTitle(menu, "Select your class:");
	switch (GetClientTeam(client))
	{
		case TEAM_INFECTED:
		{
			AddMenuItem(menu, "hunter", "Hunter");
			AddMenuItem(menu, "jockey", "Jockey");
			AddMenuItem(menu, "charger", "Charger");
			AddMenuItem(menu, "smoker", "Smoker");
			AddMenuItem(menu, "boomer", "Boomer");
			AddMenuItem(menu, "spitter", "Spitter");
			AddMenuItem(menu, "tank", "Tank");
		}
		case TEAM_SURVIVOR:
		{
			AddMenuItem(menu, "juggernaut", "Juggernaut");
			AddMenuItem(menu, "sharpshooter", "Sharpshooter");
			AddMenuItem(menu, "ninja", "Ninja");
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 600);	
}

public Menu_ClassSelection(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		if (GetMenuItem(menu, param2, info, sizeof(info)))
		{
			SetClass(param1, info);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToChat(param1, "You can reopen the class selection menu at any time by saying !class. To change class more quickly, say !class <class name>.");
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);		
	}
}

stock Float:GetDamageAfterPowerups(attacker, victim, Float:damage)
{
	new Float:time = GetGameTime();
		
	if (g_fArTimeShieldEndsAt[victim] > time)
	{
		damage *= (1.0 - PERCENTG_SHIELD_BONUS_PROTECTION);
	}
	if (g_fArTimeIncendiaryAmmoEndsAt[attacker] > time)
	{
		damage *= (1.0 + PERCENTG_INCENDIARY_BONUS_DAMAGE);
	}
	if (g_fArTimeExplosiveAmmoEndsAt[attacker] > time)
	{
		damage *= (1.0 + PERCENTG_EXPLOSIVE_BONUS_DAMAGE);
	}
	
	return damage;
}

/*		This crashes the server instantly for some reason
public PostReload(weapon, bool:bSuccessful)
{
	if (bSuccessful)		//keepig this here in case i ever want to try and figure out how to make it so reserve ammo is always equal to clipsize
	{
//		PrintToChatAll("%d",GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity"));
//		ResetAmmo();
	}
}
*/

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "witch"))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:OnWeaponDrop(client, weapon)
{
//	SDKUnhook(weapon, SDKHook_ReloadPost, PostReload);
	return Plugin_Handled;
}

public Action:OnReload(weapon)	//minor semi-fix for reload glitch with non-default clipsizes
{
	decl String:classname[64];
	GetEntityClassname(weapon, classname, 64);
	if (GetEntProp(weapon, Prop_Send, "m_iClip1") == L4D2_GetIntWeaponAttribute(classname, L4D2IWA_ClipSize))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//	PrintToChatAll("attacker %d inflictor %d damage %.2f type %d weapon %d force %.2f %.2f %.2f",attacker, inflictor, damage, damagetype, weapon, damageForce[0], damageForce[1], damageForce[2]);

	if (attacker > 0 && attacker <= MaxClients && victim != attacker)
	{
		damage = GetDamageAfterPowerups(attacker, victim, damage);
		
		if (g_iArClassOf[attacker] == CLASS_SHARPSHOOTER)
		{
			new buttons = GetClientButtons(attacker);
			if (buttons & IN_DUCK)
			{
				PrintToChatAll("sharpshooter crouched, increasing damage by 10%");
				damage *= 1.10;
			}
			if (buttons & IN_ZOOM)
			{
				PrintToChatAll("sharpshooter zoomed, increasing damage by 10%");
				damage *= 1.10;
			}
		}
		
		return Plugin_Changed;
	}	
	
	return Plugin_Continue;
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!IsValidEntity(inflictor))
	{
		return Plugin_Continue;
	}
	
	decl String:classname[48];
	GetEntityClassname(inflictor, classname, 48);
	
	if (StrEqual(classname, "weapon_melee"))
	{
		decl String:modelname[64];
		GetEntPropString(inflictor, Prop_Data, "m_ModelName", modelname, 64);
		
		if (GetTrieValue(g_hTrieMeleeWeaponDamages, modelname, damage))
		{
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Scores(client, args)
{
	decl topEight[8], String:playerNames[8][64];
	GetTopEight(topEight);

	for (new n = 0; n < 8; n++)
	{
		GetClientName(topEight[n], playerNames[n], 64);
		PrintToConsole(client, "#%d - %s with %d kills (%s).", n + 1, playerNames[topEight[n]], g_iArScoreOf[topEight[n]], GetClientTeam(topEight[n]) == TEAM_SURVIVOR ? "SURVIVOR" : GetClientTeam(topEight[n]) == TEAM_INFECTED ? "INFECTED" : "NOT IN A TEAM");
		if (n < 3 || topEight[n] == client)
		{
			PrintToChat(client, "#%d - %s with %d kills (%s).", n + 1, playerNames[topEight[n]], g_iArScoreOf[topEight[n]], GetClientTeam(topEight[n]) == TEAM_SURVIVOR ? "SURVIVOR" : GetClientTeam(topEight[n]) == TEAM_INFECTED ? "INFECTED" : "NOT IN A TEAM");
		}
	}
}

stock GetTopEight(topEight[8])
{
	topEight[0] = 0;
	g_iArScoreOf[0] = -100;
	for (new n = 1; n <= MaxClients; n++)
	{
		if (IsClientInGame(n))
		{
			if (g_iArScoreOf[n] > g_iArScoreOf[topEight[0]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = topEight[2];
				topEight[2] = topEight[1],
				topEight[1] = topEight[0];
				topEight[0] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[1]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = topEight[2];
				topEight[2] = topEight[1];
				topEight[1] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[2]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = topEight[2];
				topEight[2] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[3]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[4]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[5]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[6]])
			{
				topEight[7] = topEight[6];
				topEight[6] = n;
			}
			else if (g_iArScoreOf[n] > g_iArScoreOf[topEight[7]])
			{
				topEight[7] = n;
			}
		}
	}
}

public Event_ChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	g_iArWorldDeathCauserOf[victim] = attacker;
}
	
public Event_TongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	SDKHooks_TakeDamage(victim, attacker, attacker, GetDamageAfterPowerups(attacker, victim, DAMAGE_SPECIAL_SMOKER));
	g_fArTimeSmokerSlowdownEndsAt[victim] = GetGameTime() + DURATION_SPECIAL_SMOKER;
	
	SetCommandFlags("tongue_force_break", GetCommandFlags("tongue_force_break") & ~FCVAR_CHEAT);
	ServerCommand("tongue_force_break 1");
	SetCommandFlags("tongue_force_break", GetCommandFlags("tongue_force_break") & FCVAR_CHEAT);
}

public Event_PounceLanded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	SDKHooks_TakeDamage(victim, attacker, attacker, GetDamageAfterPowerups(attacker, victim, DAMAGE_SPECIAL_HUNTER));
	SDKHooks_TakeDamage(attacker, attacker, attacker, 512.0);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (client == 0)	//for some reason worldspawn dies sometimes
	{
		return;
	}
	
	if (attacker == client)
	{
//		PrintToChatAll("Kamikaze Kill");
		g_iArCauseOfDeath[client] = COD_KAMIKAZE;
	}
	else
	{
		if (attacker > 0 && attacker <= MaxClients)
		{
			if (GetClientTeam(client) == GetClientTeam(attacker))
			{
//				PrintToChatAll("FF Kill");
				g_iArCauseOfDeath[client] = COD_FF;
			}
			else
			{
//				PrintToChatAll("Normal Kill");
				g_iArCauseOfDeath[client] = COD_PWNT;
			}
		}
		else
		{	//gonna have to enforce COD_KAMIKAZE for death charges and shit
			if (g_iArWorldDeathCauserOf[client] != 0)
			{
//				PrintToChatAll("Normal Kill (forced world death)");
				g_iArCauseOfDeath[client] = COD_PWNT;
				g_iArWorldDeathCauserOf[client] = 0;
			}
			else
			{
//				PrintToChatAll("World Kill (accidental/suicide)");
				g_iArCauseOfDeath[client] = COD_WORLD;
			}			
		}
	}
	
	switch (g_iArCauseOfDeath[client])
	{
		case COD_FF:
		{
			g_iArScoreOf[attacker]--;
		}
		case COD_PWNT:
		{
			g_iArScoreOf[attacker]++;
		}
		case COD_WORLD:
		{
			g_iArScoreOf[client]--;
		}
	}
	
	if (g_iArDefibCount[client] > 0)
	{
		g_iArDefibCount[client]--;
		StartSpawnTimer(DURATION_RESPAWN_DEFIB, client);
	}
	else if (g_iArCauseOfDeath[client] == COD_KAMIKAZE)
	{
		StartSpawnTimer(DURATION_RESPAWN_KAMIKAZE, client);
	}
	else
	{
		StartSpawnTimer(DURATION_RESPAWN, client);
	}
	
	if (g_iArClassToChangeToOnDeath[client] != CLASS_NONE)
	{
		g_iArClassOf[client] = g_iArClassToChangeToOnDeath[client];
		g_iArClassToChangeToOnDeath[client] = CLASS_NONE;
	}
}

stock StartSpawnTimer(Float:duration, client)
{
	CreateTimer(duration, Timed_Respawn, client);
}

public Action:Timed_Respawn(Handle:timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) != TEAM_SPECTATOR && g_iArClassOf[client] != 0)
	{
		Respawn(client);
	}
}

stock Respawn(respawnee)
{
	decl n, i; //for looping and indexing
	decl Float:fArSpawnPosition[3], Float:fArSpawnAngles[3]; //where the player is going to spawn
	decl String:sBuffer[64];	//so we can get the coords for spawn positions
	GetCurrentMap(sBuffer, 64);
	
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);	//get keyvalues file
	KvJumpToKey(kv, sBuffer, false);	//go to info related to this map
	KvJumpToKey(kv, "spawns", false);	//go to info related to spawns
	new iCount = KvGetNum(kv, "count");	//get spawn count
	
	//create a dynamic array for all possible spawn positions
	new Handle:hSpawnIndexArray = CreateArray(1, iCount);
	for (n = 0; n < iCount; n++)
	{
		SetArrayCell(hSpawnIndexArray, n, n);
	}
	
	//initialise enemy position array with positions for all enemies
	new Handle:hEnemyPositionArray = CreateArray(3);
	decl Float:fArEnemyPositionBuffer[3];
	i = 0;
	for (n = 1; n <= MaxClients; n++)
	{
		if (IsClientInGame(n) && IsPlayerAlive(n) && GetClientTeam(n) != GetClientTeam(respawnee))
		{
			GetClientAbsOrigin(n, fArEnemyPositionBuffer);
			ResizeArray(hEnemyPositionArray, i + 1);
			SetArrayArray(hEnemyPositionArray, i, fArEnemyPositionBuffer);
			i++;
		}
	}
	
	//now let's find some random spawn positions and take the first one that is clear of enemies!
	decl String:sSpawnKey[64];
	new bool:bSpawnFound = false;
	while (GetArraySize(hSpawnIndexArray) > 0 && !bSpawnFound) //if every spawn is unavailable, just spawn at the last checked one
	{	//choose which spawn point to try
		sSpawnKey = "spawn";
		n = GetRandomInt(0, GetArraySize(hSpawnIndexArray) - 1);
		IntToString(GetArrayCell(hSpawnIndexArray, n), sBuffer, 64);
		StrCat(sSpawnKey, 64, sBuffer);
		
		//get its coordinates
		KvJumpToKey(kv, sSpawnKey, false);
		KvGetVector(kv, "position", fArSpawnPosition);
		
		//check those coordinates for proximity to enemies
		decl bool:bEnemyFound;
		bEnemyFound = false;
		for (i = 0; i < GetArraySize(hEnemyPositionArray); i++)
		{
			GetArrayArray(hEnemyPositionArray, i, fArEnemyPositionBuffer);
			if (GetVectorDistance(fArEnemyPositionBuffer, fArSpawnPosition) <= RANGE_DETECT_ENEMIES_FOR_SPAWN)
			{
				RemoveFromArray(hSpawnIndexArray, n);
				bEnemyFound = true;
				break;
			}
		}
		if (!bEnemyFound)
		{
			bSpawnFound = true;
		}
		
		KvGoBack(kv);	//go back so we can actually move to a new spawn
	}
	KvGetVector(kv, "angles", fArSpawnAngles);
	
	//time to spawn and teleport!
	SDKCall(g_hSDKCallRespawn, respawnee);
	PostSpawnGearPlayerByClass(respawnee);
	TeleportEntity(respawnee, fArSpawnPosition, fArSpawnAngles, NULL_VECTOR);
	EmitSoundToClient(respawnee, "/ui/pickup_scifi37.wav"); //louder for SI than survivors for some reason
//	EmitSoundToClient(respawnee, "/ui/pickup_guitarriff10.wav");	//can't be precached for some reason
	
	KvRewind(kv);
	CloseHandle(kv);
	CloseHandle(hEnemyPositionArray);
	CloseHandle(hSpawnIndexArray);	
}

public Action:SaveArenaCenter(client, args)
{
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);
	
	decl Float:position[3];
	GetClientAbsOrigin(client, position);
	
	decl String:mapname[64];
	GetCurrentMap(mapname, 64);
	
	KvJumpToKey(kv, mapname, true);		//go to map props -> if first time on this map, it'll be created
	KvSetVector(kv, "center", position);
	
	KvRewind(kv);
	KeyValuesToFile(kv, DIR_KV);
	CloseHandle(kv);
	
	return Plugin_Handled;
}

public Action:SavePlayerSpawn(client, args)
{
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);
	
	decl Float:position[3];
	decl Float:angles[3];
	GetClientAbsOrigin(client, position);
	GetClientEyeAngles(client, angles);
	
	decl String:mapname[64];
	GetCurrentMap(mapname, 64);
	
	KvJumpToKey(kv, mapname, true);		//go to map props -> if first time on this map, it'll be created
	KvJumpToKey(kv, "spawns", true);	//... create the spawns subkey	
	if (KvGetNum(kv, "count", -1) == -1)
	{
		KvSetNum(kv, "count", 0);	//... create the count subkey and set it to 0
	}
	
	decl String:sCount[8];
	KvGetString(kv, "count", sCount, 8, "_ERROR");
	
	//create spawnX (X = count)
	new String:spawnkey[64] = "spawn";
	StrCat(spawnkey, 64, sCount);
	KvJumpToKey(kv, spawnkey, true);
	
	//store position and angles inside of spawnX
	KvGotoFirstSubKey(kv, true);
	KvSetVector(kv, "position", position);
	KvSetVector(kv, "angles", angles);
	KvGoBack(kv);
	
	new iCount = KvGetNum(kv, "count");
	iCount++;
	KvSetNum(kv, "count", iCount);
	
	KvRewind(kv);
	KeyValuesToFile(kv, DIR_KV);
	CloseHandle(kv);
	
	return Plugin_Handled;
}

public Action:SavePowerupSpawn(client, args)
{
	if (args < 1)
	{
		return Plugin_Handled;
	}
	
	//fetch arguments
	decl String:type[64];
	GetCmdArg(1, type, 64);
	decl Float:position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 45.0;	
	
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);
	
	decl String:mapname[64];
	GetCurrentMap(mapname, 64);
	
	KvJumpToKey(kv, mapname, true);		//go to map props -> if first time on this map, it'll be created
	KvJumpToKey(kv, "powerups", true);	//create powerups or go to it if it exists
	if (KvGetNum(kv, "count", -1) == -1)
	{
		KvSetNum(kv, "count", 0);	//... create the count subkey and set it to 0
	}
	
	decl String:sCount[8];
	KvGetString(kv, "count", sCount, 8, "_ERROR");
	
	//create powerupX (X = count)
	new String:powerupkey[64] = "powerup";
	StrCat(powerupkey, 64, sCount);
	KvJumpToKey(kv, powerupkey, true);
	
	//store type, spawndelay, position and angles inside of powerupX
	KvGotoFirstSubKey(kv, true);
	KvSetString(kv, "type", type);
	KvSetVector(kv, "position", position);
	KvGoBack(kv);
	
	new iCount = KvGetNum(kv, "count");
	iCount++;
	KvSetNum(kv, "count", iCount);
	
	KvRewind(kv); 
	KeyValuesToFile(kv, DIR_KV);
	CloseHandle(kv);
	
	return Plugin_Handled;
}

public Action:L4D_OnGetRunTopSpeed(client, &Float:retVal)
{	//max speed depends on class
	retVal = g_fArMaxSpeedOfClass[g_iArClassOf[client]];
	
	//but then can be affected by the smoker's ability
	new Float:buffer = g_fArTimeSmokerSlowdownEndsAt[client] - GetGameTime();
	if (buffer > 0.0)
	{
		retVal *= 1.0 - Pow(buffer/100.0, 2.0);
	}
	
	//and it can also be affected by adrenaline
	if (g_fArTimeAdrenalineEndsAt[client] >= GetGameTime())
	{
		retVal *= 1.0 + PERCENTG_ADRENALINE_BONUS_SPEED;
	}
	
	return Plugin_Handled;
}

public Event_PlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_iArClassOf[victim] == CLASS_TANK) //make tanks m2able
	{
		L4D_StaggerPlayer(victim, attacker, NULL_VECTOR);
	}

	if (g_iArClassOf[attacker] == CLASS_JUGGERNAUT)	//special juggernaut abilities
	{
		if (g_iArClassOf[victim] == CLASS_CHARGER)	//can m2 chargers
		{
			L4D_StaggerPlayer(victim, attacker, NULL_VECTOR);
		}
		SDKHooks_TakeDamage(victim, attacker, attacker, float(GetClientHealth(attacker)/SPECIAL_M2_JUGGERNAUT_DIVISOR));	//hurts zombies with shoves
	}
}

stock SpawnAllPowerups()
{
	for (new n = 0; n < GetArraySize(g_hArrayPowerupEntities); n++)
	{
		if (GetArrayCell(g_hArrayPowerupEntities, n) != -1)
		{
			SpawnPowerup(n);
		}
	}
}

stock RemovePowerup(index)
{
	new entity = GetArrayCell(g_hArrayPowerupEntities, index);
	if (entity != -1)
	{
		SetArrayCell(g_hArrayPowerupEntities, index, -1);
		AcceptEntityInput(entity, "Kill");
	}
	entity = GetArrayCell(g_hArrayPowerupTouchEntities, index);
	if (entity != -1)
	{
		SetArrayCell(g_hArrayPowerupEntities, index, -1);
		SDKUnhook(entity, SDKHook_StartTouch, OnStartTouch);
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:Timed_RespawnPowerup(Handle:timer, any:powerupIndex)
{
	SpawnPowerup(powerupIndex);
}

public OnMapStart()
{
	PrecacheThings();
	
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1)
	{
		if (GetEntProp(entity, Prop_Data, "m_hasUnlockSequence") == DOOR_UNLOCK)
		{                          // this gives errors (on some maps), maybe do some sort of check?
			AcceptEntityInput(entity, "Lock");
			new doorState = GetEntProp(entity, Prop_Data, "m_eDoorState");
			if (doorState == DOOR_CLOSED || doorState == DOOR_CLOSING)
			{
				AcceptEntityInput(entity, "ForceClosed");
			}
			else
			{
				AcceptEntityInput(entity, "ForceOpen");
			}
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", DOOR_LOCK);
			SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
			break;
		}
	}
	
	L4D_SetVersusMaxCompletionScore(0);
	
	decl String:mapname[64];
	GetCurrentMap(mapname, 64);
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);	
	KvJumpToKey(kv, mapname, true);
	KvJumpToKey(kv, "powerups", true);
	new count = KvGetNum(kv, "count");
	g_hArrayPowerupEntities = CreateArray(1, count);
	g_hArrayPowerupTouchEntities = CreateArray(1, count);
	KvRewind(kv);
	CloseHandle(kv);
	
	SpawnAllPowerups();
	CreateTimer(4.0, Timed_PostMapStart);
}

public Action:Timed_PostMapStart(Handle:timer)
{
	decl String:classname[64];
	new entityCount = GetEntityCount();
	for (new entity = MaxClients + 1; entity < entityCount; entity++)
	{
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 64);
			
			if (StrContains(classname, "weapon_", false) != -1)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
}

stock SpawnPowerup(powerupIndex)
{
	decl String:indexstring[8];
	IntToString(powerupIndex, indexstring, 8);
	
	new Float:fArSpawnAngles[3];
	decl Float:fArSpawnPosition[3], String:sBuffer[64], String:color[32];
	GetCurrentMap(sBuffer, 64);
	
	new Handle:kv = CreateKeyValues("L4D2Arena");
	FileToKeyValues(kv, DIR_KV);
	KvJumpToKey(kv, sBuffer, false);
	KvJumpToKey(kv, "powerups", false);
	
	new String:sPowerupKey[64] = "powerup";
	StrCat(sPowerupKey, 64, indexstring);
	KvJumpToKey(kv, sPowerupKey, false);
	
	KvGetString(kv, "type", sBuffer, 64);
	if (StrEqual(sBuffer, "medkit"))
	{
		fArSpawnAngles[0] = 30.0;
		fArSpawnAngles[2] = 90.0;
		color = COLOR_GREEN;
	}
	else if (StrEqual(sBuffer, "defib"))
	{
		fArSpawnAngles[2] = 60.0;
		color = COLOR_TEAL;
	}
	else if (StrEqual(sBuffer, "pills"))
	{
	 	fArSpawnAngles[0] = -30.0;
		color = COLOR_GREEN_LIGHT;
	}
	else if (StrEqual(sBuffer, "adrenaline"))
	{
		fArSpawnAngles[2] = 60.0;
		color = COLOR_TEAL_LIGHT;
	}
	else if (StrEqual(sBuffer, "incendiary"))
	{
		fArSpawnAngles[2] = 45.0;
		color = COLOR_ORANGE;
	}
	else if (StrEqual(sBuffer, "explosive"))
	{
		fArSpawnAngles[2] = 45.0;
		color = COLOR_RED;
	}
	else if (StrEqual(sBuffer, "shield"))
	{
		fArSpawnAngles[0] = -30.0;
		color = COLOR_BLUE;
	}
	else if (StrEqual(sBuffer, "gnome"))
	{
		color = COLOR_WHITE;
	}
	decl String:model[64];
	GetTrieString(g_hTriePowerupModels, sBuffer, model, 64);
	KvGetVector(kv, "position", fArSpawnPosition);
	
	KvRewind(kv);
	CloseHandle(kv);
	
	new entity = CreateEntityByName("prop_dynamic");
//	DispatchKeyValue(entity, "parentname", "entRot");
	DispatchKeyValue(entity, "model", model);
	DispatchKeyValueVector(entity, "origin", fArSpawnPosition);
	DispatchKeyValueVector(entity, "angles", fArSpawnAngles);
	DispatchKeyValue(entity, "glowcolor", color);
	DispatchKeyValue(entity, "fadescale", "0");
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
	SetEntProp(entity, Prop_Send, "m_bFlashing", true);
	
	fArSpawnPosition[2] -= 25.0;
	
	new touchEntity = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(touchEntity, "model", MODEL_PILLS);
	DispatchKeyValueVector(touchEntity, "origin", fArSpawnPosition);
	DispatchKeyValue(touchEntity, "solid", "6");
	DispatchSpawn(touchEntity);
	SetEntityRenderMode(touchEntity, RENDER_NONE);
	
/*	new funcRot = CreateEntityByName("func_rotating");
	DispatchKeyValue(funcRot, "maxspeed", "700");
	DispatchKeyValue(funcRot, "spawnflags", "517");
	DispatchKeyValue(funcRot, "targetname", "entRot");
	DispatchSpawn(funcRot);
	ActivateEntity(funcRot);
	
	AcceptEntityInput(funcRot, "Start");
	SetVariantString("1");
	AcceptEntityInput(funcRot, "SetSpeed");
*/

	SetArrayCell(g_hArrayPowerupEntities, powerupIndex, entity);	
	SetArrayCell(g_hArrayPowerupTouchEntities, powerupIndex, touchEntity);
	SDKHook(touchEntity, SDKHook_StartTouch, OnStartTouch);
	
	EmitSoundToAll(SOUND_ITEMSPAWN, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 10.0);
}

public Action:OnStartTouch(touchEntity, player)
{
	new index = FindValueInArray(g_hArrayPowerupTouchEntities, touchEntity);
	if (index != -1)
	{
		new entity = GetArrayCell(g_hArrayPowerupEntities, index);
		
		if (player > 0 && player <= MaxClients)
		{
			decl String:modelname[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 64);
			
			if (StrEqual(modelname, MODEL_MEDKIT, false))
			{
				HealPlayer(player, ABSOLUTE_MEDKIT_BONUS_HEALTH);
				CreateTimer(DURATION_RESPAWN_POWERUP_QUICK, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a first aid kit: +%d health.", ABSOLUTE_MEDKIT_BONUS_HEALTH);
			}
			else if (StrEqual(modelname, MODEL_DEFIB, false))
			{
				g_iArDefibCount[player]++;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a defibrillator: +1 instant respawn.".);
			}
			else if (StrEqual(modelname, MODEL_PILLS, false))
			{
				HealPlayer(player, ABSOLUTE_PILLS_BONUS_HEALTH);
				CreateTimer(DURATION_RESPAWN_POWERUP_QUICK, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a bottle of pills: +%d health.", ABSOLUTE_PILLS_BONUS_HEALTH);
			}
			else if (StrEqual(modelname, MODEL_ADRENALINE, false))
			{
				g_fArTimeAdrenalineEndsAt[player] = GetGameTime() + DURATION_ADRENALINE;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a shot of adrenaline: +%d%% speed for %d seconds.", PERCENTG_ADRENALINE_BONUS_SPEED, DURATION_ADRENALINE);
			}
			else if (StrEqual(modelname, MODEL_INCENDIARY, false))
			{
				g_fArTimeIncendiaryAmmoEndsAt[player] = GetGameTime() + DURATION_INCENDIARY;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up an incendiary ammo pack: +%d%% damage for %d%% seconds.");
			}
			else if (StrEqual(modelname, MODEL_EXPLOSIVE, false))
			{
				g_fArTimeExplosiveAmmoEndsAt[player] = GetGameTime() + DURATION_EXPLOSIVE;
				CreateTimer(DURATION_RESPAWN_POWERUP_LONG, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up an explosive ammo pack: +%d%% damage for %d%% seconds.");
			}
			else if (StrEqual(modelname, MODEL_SHIELD, false))
			{
				g_fArTimeShieldEndsAt[player] = GetGameTime() + DURATION_SHIELD;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a riot shield: +%d%% damage protection for %d%% seconds.");
			}
			
			RemovePowerup(index);
			EmitSoundToAll(SOUND_ITEMGRAB, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 10.0);
		}
	}
}

stock HealPlayer(client, amount)
{
	new currentHealth = GetClientHealth(client);
	if (currentHealth + amount > g_iArMaxHealthOfClass[g_iArClassOf[client]])
	{
		SetEntityHealth(client, g_iArMaxHealthOfClass[g_iArClassOf[client]]);
	}
	else
	{
		SetEntityHealth(client, currentHealth + amount);
	}
}

stock GetNumberOfEnemies(client)
{
	if (client > 0 && client < MaxClients && GetClientTeam(client) == TEAM_SPECTATOR)
	{
		new count;
		for (new n = 1; n <= MaxClients; n++)
		{
			if (GetClientTeam(client) != GetClientTeam(n) && 
			GetClientTeam(n) != TEAM_SPECTATOR
			&& IsClientInGame(n))
			{
				count++;
			}
		}
	}
	return count;
}

public Action:Sound_Normal(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	decl trash;
	if (GetTrieValue(g_hTrieSoundsBlocked, sample, trash))
	{
		return Plugin_Stop;
	}
	if (StrContains(sample, "player/") != -1 && StrContains(sample, "step") == -1)
	{
		PrintToChatAll("%s",sample);
	}	
	return Plugin_Continue;
}

stock HookThings()
{
	HookEvent("player_shoved", Event_PlayerShoved);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("lunge_pounce", Event_PounceLanded);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("charger_impact", Event_ChargerImpact);
	
	AddNormalSoundHook(Sound_Normal);
}

stock SetCvars()
{
	SetConVarFloat(FindConVar("spitter_pz_claw_dmg"), DAMAGE_SCRATCH_SPITTER);
	SetConVarFloat(FindConVar("hunter_pz_claw_dmg"), DAMAGE_SCRATCH_HUNTER);
	SetConVarFloat(FindConVar("boomer_pz_claw_dmg"), DAMAGE_SCRATCH_BOOMER);
	SetConVarFloat(FindConVar("jockey_pz_claw_dmg"), DAMAGE_SCRATCH_JOCKEY);
	SetConVarFloat(FindConVar("smoker_pz_claw_dmg"), DAMAGE_SCRATCH_SMOKER);
	//no cvar for charger damage, but default is good for now
	SetConVarFloat(FindConVar("vs_tank_damage"), DAMAGE_SCRATCH_TANK);
	SetConVarInt(FindConVar("z_spitter_health"), g_iArMaxHealthOfClass[CLASS_SPITTER]);
	SetConVarInt(FindConVar("z_hunter_health"), g_iArMaxHealthOfClass[CLASS_HUNTER]);
	SetConVarInt(FindConVar("z_exploding_health"), g_iArMaxHealthOfClass[CLASS_BOOMER]);
	SetConVarInt(FindConVar("z_jockey_health"), g_iArMaxHealthOfClass[CLASS_JOCKEY]);
	SetConVarInt(FindConVar("z_gas_health"), g_iArMaxHealthOfClass[CLASS_SMOKER]);
	SetConVarInt(FindConVar("z_charger_health"), g_iArMaxHealthOfClass[CLASS_CHARGER]);
	SetConVarInt(FindConVar("z_tank_health"), g_iArMaxHealthOfClass[CLASS_TANK]*2/3);
	SetConVarFloat(FindConVar("z_tank_attack_interval"), 1.5);
	SetConVarInt(FindConVar("z_tank_rock_radius"), 50);
	SetConVarInt(FindConVar("z_tank_throw_force"), 1200);
	SetConVarInt(FindConVar("z_tank_throw_health"), 10);
	SetConVarInt(FindConVar("z_tank_throw_interval"), 6);
	
	SetConVarFloat(FindConVar("z_jockey_ride_damage"), DAMAGE_SPECIAL_JOCKEY);
	SetConVarFloat(FindConVar("z_jockey_ride_damage_interval"), DURATION_SPECIAL_JOCKEY);
	SetConVarFloat(FindConVar("z_hunter_max_pounce_bonus_damage"), DAMAGE_SPECIAL_HUNTER_EXTRA);
	SetConVarFloat(FindConVar("z_charger_pound_dmg"), DAMAGE_SPECIAL_CHARGER);
	SetConVarFloat(FindConVar("z_charge_max_damage"), DAMAGE_SPECIAL_CHARGER_SECOND);
	SetConVarFloat(FindConVar("z_charge_duration"), DURATION_SPECIAL_CHARGER);
	SetConVarFloat(FindConVar("z_charge_interval"), COOLDOWN_SPECIAL_CHARGER);
	SetConVarFloat(FindConVar("z_charge_start_speed"), g_fArMaxSpeedOfClass[CLASS_CHARGER]);
	SetConVarFloat(FindConVar("z_charge_max_speed"), SPEED_SPECIAL_CHARGER);
	SetConVarFloat(FindConVar("tongue_range"), RANGE_SPECIAL_SMOKER);
	SetConVarFloat(FindConVar("tongue_fly_speed"), SPEED_SPECIAL_SMOKER);
	SetConVarFloat(FindConVar("tongue_hit_delay"), COOLDOWN_SPECIAL_SMOKER);
	SetConVarFloat(FindConVar("tongue_miss_delay"), COOLDOWN_SPECIAL_SMOKER);
	SetConVarFloat(FindConVar("z_spit_interval"), COOLDOWN_SPECIAL_SPITTER);
	SetConVarFloat(FindConVar("z_spit_velocity"), SPEED_SPECIAL_SPITTER);
	//dont forget cvar to make spitter not get slowed down after spitting
	
	SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 0);
	SetConVarInt(FindConVar("vs_max_team_switches"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);
	SetConVarInt(FindConVar("z_frustration"), 0);
	SetConVarInt(FindConVar("versus_tank_chance"), 0);
	SetConVarInt(FindConVar("versus_tank_chance_finale"), 0);
	SetConVarInt(FindConVar("versus_tank_chance_intro"), 0);
	SetConVarInt(FindConVar("versus_witch_chance"), 0);
	SetConVarInt(FindConVar("versus_witch_chance_finale"), 0);
	SetConVarInt(FindConVar("versus_witch_chance_intro"), 0);
	SetConVarInt(FindConVar("versus_marker_num"), 0);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 1.0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_amt_penalty"), 0.0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_cooldown"), 0.0);
	SetConVarInt(FindConVar("z_gun_swing_vs_max_penalty"), 50);
	SetConVarInt(FindConVar("z_gun_swing_vs_min_penalty"), 0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_restore_time"), 10.0);
	SetConVarInt(FindConVar("z_respawn_distance"), 20000);
	SetConVarInt(FindConVar("z_respawn_interval"), 20000);
	
	SetConVarFlags(FindConVar("sb_all_bot_game"), GetConVarFlags(FindConVar("sb_all_bot_game")) & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar("sb_all_bot_game"), 1);
	SetConVarFlags(FindConVar("director_no_specials"), GetConVarFlags(FindConVar("director_no_specials")) & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar("director_no_specials"), 1);
	SetConVarFlags(FindConVar("director_no_death_check"), GetConVarFlags(FindConVar("director_no_death_check")) & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar("director_no_death_check"), 1);
}

stock ResetCvars()
{
	SetConVarFloat(FindConVar("spitter_pz_claw_dmg"), 4.0);
	SetConVarFloat(FindConVar("hunter_pz_claw_dmg"), 6.0);
	SetConVarFloat(FindConVar("boomer_pz_claw_dmg"), 4.0);
	SetConVarFloat(FindConVar("jockey_pz_claw_dmg"), 4.0);
	SetConVarFloat(FindConVar("smoker_pz_claw_dmg"), 4.0);
	//no cvar for charger damage, but default is good for now
	SetConVarFloat(FindConVar("vs_tank_damage"), 24.0);
	SetConVarInt(FindConVar("z_spitter_health"), 100);
	SetConVarInt(FindConVar("z_hunter_health"), 250);
	SetConVarInt(FindConVar("z_exploding_health"), 50);
	SetConVarInt(FindConVar("z_jockey_health"), 325);
	SetConVarInt(FindConVar("z_gas_health"), 250);
	SetConVarInt(FindConVar("z_charger_health"), 600);
	SetConVarInt(FindConVar("z_tank_health"), 4000);
	SetConVarFloat(FindConVar("z_tank_attack_interval"), 1.5);
	SetConVarInt(FindConVar("z_tank_rock_radius"), 100);
	SetConVarInt(FindConVar("z_tank_throw_force"), 800);
	SetConVarInt(FindConVar("z_tank_throw_health"), 50);
	SetConVarInt(FindConVar("z_tank_throw_interval"), 5);
	
	SetConVarFloat(FindConVar("z_jockey_ride_damage"), 4.0);
	SetConVarFloat(FindConVar("z_jockey_ride_damage_interval"), 1.0);
	SetConVarFloat(FindConVar("z_hunter_max_pounce_bonus_damage"), 24.0);
	SetConVarFloat(FindConVar("z_charger_pound_dmg"), 15.0);
	SetConVarFloat(FindConVar("z_charge_max_damage"), 10.0);
	SetConVarFloat(FindConVar("z_charge_duration"), 2.5);
	SetConVarFloat(FindConVar("z_charge_interval"), 12.0);
	SetConVarFloat(FindConVar("z_charge_start_speed"), 250.0);
	SetConVarFloat(FindConVar("z_charge_max_speed"), 500.0);
	SetConVarFloat(FindConVar("tongue_range"), 750.0);
	SetConVarFloat(FindConVar("tongue_fly_speed"), 1000.0);
	SetConVarFloat(FindConVar("tongue_hit_delay"), 20.0);
	SetConVarFloat(FindConVar("tongue_miss_delay"), 15.0);
	SetConVarFloat(FindConVar("z_spit_interval"), 20.0);
	SetConVarFloat(FindConVar("z_spit_velocity"), 900.0);
	//dont forget cvar to make spitter not get slowed down after spitting
	
	SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
	SetConVarInt(FindConVar("vs_max_team_switches"), 1);
	SetConVarInt(FindConVar("z_common_limit"), 30);
	SetConVarInt(FindConVar("z_frustration"), 1);
	SetConVarFloat(FindConVar("versus_tank_chance"), 0.75);
	SetConVarFloat(FindConVar("versus_tank_chance_finale"), 0.1);
	SetConVarFloat(FindConVar("versus_tank_chance_intro"), 0.3);
	SetConVarFloat(FindConVar("versus_witch_chance"), 0.75);
	SetConVarFloat(FindConVar("versus_witch_chance_finale"), 0.1);
	SetConVarFloat(FindConVar("versus_witch_chance_intro"), 0.3);
	SetConVarInt(FindConVar("versus_marker_num"), 3);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
	SetConVarFloat(FindConVar("z_gun_swing_vs_amt_penalty"), 1.0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_cooldown"), 1.0);
	SetConVarInt(FindConVar("z_gun_swing_vs_max_penalty"), 6);
	SetConVarInt(FindConVar("z_gun_swing_vs_min_penalty"), 3);
	SetConVarFloat(FindConVar("z_gun_swing_vs_restore_time"), 4.0);
	SetConVarInt(FindConVar("z_respawn_distance"), 100);
	SetConVarInt(FindConVar("z_respawn_interval"), 10);
	
	SetConVarFlags(FindConVar("sb_all_bot_game"), GetConVarFlags(FindConVar("sb_all_bot_game")) & FCVAR_CHEAT);
	SetConVarInt(FindConVar("sb_all_bot_game"), 0);
	SetConVarFlags(FindConVar("director_no_specials"), GetConVarFlags(FindConVar("director_no_specials")) & FCVAR_CHEAT);
	SetConVarInt(FindConVar("director_no_specials"), 0);
	SetConVarFlags(FindConVar("director_no_death_check"), GetConVarFlags(FindConVar("director_no_death_check")) & FCVAR_CHEAT);
	SetConVarInt(FindConVar("director_no_death_check"), 0);
}	

stock SetWeaponAttributes()
{
	L4D2_SetIntWeaponAttribute(  "weapon_sniper_awp", L4D2IWA_Damage, 20);
	L4D2_SetIntWeaponAttribute(  "weapon_sniper_awp", L4D2IWA_ClipSize, 4);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_RangeModifier, 0.8);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_SpreadPerShot, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MaxSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_SpreadDecay, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MinStandingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MinInAirSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MaxMovementSpread, 0.0);
	L4D2_SetIntWeaponAttribute(  "weapon_pistol_magnum", L4D2IWA_Damage, 6);
//	L4D2_SetIntWeaponAttribute(  "weapon_pistol_magnum", L4D2IWA_ClipSize, 8);
//	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_RangeModifier, 0.75);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_SpreadPerShot, 2.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MaxSpread, 15.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_SpreadDecay, 5.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MinStandingSpread, 0.5);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MinInAirSpread, 1.5);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MaxMovementSpread, 1.5);
	
	L4D2_SetIntWeaponAttribute(  "weapon_pumpshotgun", L4D2IWA_Damage, 3);
	L4D2_SetIntWeaponAttribute(  "weapon_pumpshotgun", L4D2IWA_Bullets, 12);
	L4D2_SetIntWeaponAttribute(  "weapon_pumpshotgun", L4D2IWA_ClipSize, 4);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_RangeModifier, 0.75);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_SpreadPerShot, 1.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MaxSpread, 4.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_SpreadDecay, 4.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MinStandingSpread, 1.5);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MinInAirSpread, 1.5);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MaxMovementSpread, 1.5);
	L4D2_SetIntWeaponAttribute(  "weapon_shotgun_chrome", L4D2IWA_Damage, 6);
	L4D2_SetIntWeaponAttribute(  "weapon_shotgun_chrome", L4D2IWA_Bullets, 6);
	L4D2_SetIntWeaponAttribute(  "weapon_shotgun_chrome", L4D2IWA_ClipSize, 3);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_RangeModifier, 0.75);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_SpreadPerShot, 1.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MaxSpread, 6.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_SpreadDecay, 6.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MinStandingSpread, 1.5);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MinInAirSpread, 1.5);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MaxMovementSpread, 1.5);
}

stock ResetWeaponAttributes()
{
	L4D2_SetIntWeaponAttribute(  "weapon_sniper_awp", L4D2IWA_Damage, 115);
	L4D2_SetIntWeaponAttribute(  "weapon_sniper_awp", L4D2IWA_ClipSize, 20);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_RangeModifier, 1.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_SpreadPerShot, 1.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MaxSpread, 15.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_SpreadDecay, 8.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MinStandingSpread, 0.1);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MinInAirSpread, 1.5);
	L4D2_SetFloatWeaponAttribute("weapon_sniper_awp", L4D2FWA_MaxMovementSpread, 3.0);
	L4D2_SetIntWeaponAttribute(  "weapon_pistol_magnum", L4D2IWA_Damage, 80);
//	L4D2_SetIntWeaponAttribute(  "weapon_pistol_magnum", L4D2IWA_ClipSize, 8);
//	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_RangeModifier, 0.75);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_SpreadPerShot, 2.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MaxSpread, 30.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_SpreadDecay, 5.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MinDuckingSpread, 0.5);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MinStandingSpread, 1.25);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MinInAirSpread, 3.0);
	L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_MaxMovementSpread, 3.0);
	
	L4D2_SetIntWeaponAttribute(  "weapon_pumpshotgun", L4D2IWA_Damage, 25);
	L4D2_SetIntWeaponAttribute(  "weapon_pumpshotgun", L4D2IWA_Bullets, 10);
	L4D2_SetIntWeaponAttribute(  "weapon_pumpshotgun", L4D2IWA_ClipSize, 8);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_RangeModifier, 0.69);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_SpreadPerShot, 1.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MaxSpread, 5.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_SpreadDecay, 5.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MinStandingSpread, 0.8);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MinInAirSpread, 2.5);
	L4D2_SetFloatWeaponAttribute("weapon_pumpshotgun", L4D2FWA_MaxMovementSpread, 1.5);
	L4D2_SetIntWeaponAttribute(  "weapon_shotgun_chrome", L4D2IWA_Damage, 31);
	L4D2_SetIntWeaponAttribute(  "weapon_shotgun_chrome", L4D2IWA_Bullets, 8);
	L4D2_SetIntWeaponAttribute(  "weapon_shotgun_chrome", L4D2IWA_ClipSize, 8);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_RangeModifier, 0.69);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_SpreadPerShot, 1.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MaxSpread, 5.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_SpreadDecay, 5.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MinDuckingSpread, 0.0);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MinStandingSpread, 0.8);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MinInAirSpread, 2.5);
	L4D2_SetFloatWeaponAttribute("weapon_shotgun_chrome", L4D2FWA_MaxMovementSpread, 1.5);	
}

stock PrepAllSDKCalls()
{
	g_hConfigFile = LoadGameConfigFile("l4d2arena");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hConfigFile, SDKConf_Signature, "RoundRespawn");
	g_hSDKCallRespawn = EndPrepSDKCall();
	
	g_iOffsetAbility = GameConfGetOffset(g_hConfigFile, "Ability");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(g_hConfigFile, SDKConf_Signature, "CreateAbility");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCallCreateAbility = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hConfigFile, SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKCallSetClass = EndPrepSDKCall();
}

stock InitialiseTries()
{
	g_hTrieSoundsBlocked = CreateTrie();
	
	decl String:buffer[PLATFORM_MAX_PATH];
	new size = sizeof(g_sArSIBlockedSounds);
	for (new n = 0; n < size; n++)
	{
		buffer = g_sArSIBlockedSounds[n];
		SetTrieValue(g_hTrieSoundsBlocked, buffer, true);
	}
	
	g_hTriePowerupModels = CreateTrie();
	SetTrieString(g_hTriePowerupModels, "pills", MODEL_PILLS);
	SetTrieString(g_hTriePowerupModels, "medkit", MODEL_MEDKIT); 
	SetTrieString(g_hTriePowerupModels, "adrenaline", MODEL_ADRENALINE);
	SetTrieString(g_hTriePowerupModels, "defib", MODEL_DEFIB); 
	SetTrieString(g_hTriePowerupModels, "incendiary", MODEL_INCENDIARY);	
	SetTrieString(g_hTriePowerupModels, "explosive", MODEL_EXPLOSIVE);	
	SetTrieString(g_hTriePowerupModels, "shield", MODEL_SHIELD);
	SetTrieString(g_hTriePowerupModels, "gnome", MODEL_GNOME);	
	
	g_hTrieMeleeWeaponDamages = CreateTrie();
	SetTrieValue(g_hTrieMeleeWeaponDamages, "models/weapons/melee/w_katana.mdl", 3.5);	//10 rays, sometimes 12; limit to 8. 28/8 = 3.5
	SetTrieValue(g_hTrieMeleeWeaponDamages, "models/weapons/melee/w_fireaxe.mdl", 1.0);	//14 rays: limit to 12
	//tonfa: 6 rays, often a 7, 8, or more
	//guitar: 13?
	
	g_hTrieMeleeWeaponHitRayLimits = CreateTrie();
	SetTrieValue(g_hTrieMeleeWeaponHitRayLimits, "models/weapons/melee/w_katana.mdl", 8);
	SetTrieValue(g_hTrieMeleeWeaponHitRayLimits, "models/weapons/melee/w_fireaxe.mdl", 12);
}	

stock PrecacheThings()
{
	PrecacheModel(MODEL_ADRENALINE, true);
	PrecacheModel(MODEL_DEFIB, true);
	PrecacheModel(MODEL_EXPLOSIVE, true);
	PrecacheModel(MODEL_INCENDIARY, true);
	PrecacheModel(MODEL_PILLS, true);
	PrecacheModel(MODEL_MEDKIT, true);
	PrecacheModel(MODEL_SHIELD, true);
	PrecacheModel(MODEL_GNOME, true);

	PrecacheModel("models/weapons/melee/w_katana.mdl", true);
	PrecacheModel("models/weapons/melee/v_katana.mdl", true);
	PrecacheGeneric("scripts/melee/katana.txt", true);
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
	PrecacheGeneric("scripts/melee/fireaxe.txt", true);
	
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	new tmpEnt = CreateEntityByName("weapon_sniper_awp");
	DispatchSpawn(tmpEnt);
	RemoveEdict(tmpEnt);

	PrecacheSound("/ui/pickup_scifi37.wav", true);
	PrecacheSound("/ui/pickup_guitarriff10.wav", true);	
	PrecacheSound(SOUND_ITEMGRAB, true);
	PrecacheSound(SOUND_ITEMSPAWN, true);	
}

stock RegisterCommands()
{
	RegConsoleCmd("sm_savearenacenter", SaveArenaCenter);
	RegConsoleCmd("sm_saveplayerspawn", SavePlayerSpawn);
	RegConsoleCmd("sm_savepowerupspawn", SavePowerupSpawn);
	RegConsoleCmd("sm_class", ChooseClass);
	RegConsoleCmd("sm_team", ChooseTeam);
	RegConsoleCmd("sm_score", Scores);
}

/*stock ResetAmmo(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0);
	decl String:weaponname[64];
	GetEntityClassname(weapon, weaponname, 64);
	decl offset;
	if (StrEqual(weaponname, "weapon_sniper_awp"))
	{
		offset = OFFSET_MILITARY_SNIPER_IAMMO;
	}
	else if (StrEqual(weaponname, "weapon_pumpshotgun") || StrEqual(weaponname, "weapon_shotgun_chrome"))
	{
		offset = OFFSET_PUMPSHOTGUN_IAMMO;
	}
	new iAmmoOffset = FindDataMapOffs(weapon, "m_iAmmo");
	SetEntData(client, (iAmmoOffset + offset), L4D2_GetIntWeaponAttribute(weaponname, L4D2IWA_ClipSize), 4, true);
}*/

/*damage info
			 smoker
			 scratch 4.00 dmg , force != 0,0,0, type 128
			 choke   5.00 dmg , force == 0,0,0, type 1048576
			 drag	 3.00 dmg , force == 0,0,0, type 1048576
			 boomer
			 scratch 4.00 dmg , force != 0,0,0, type 128
			 jockey
			 scratch 4.00 dmg , force != 0,0,0, type 128
			 pounce  4.00 dmg , force != 0,0,0, type 128
			 ride	4.00 dmg , force == 0,0,-X, type 128
			 charger
			 scratch 10.00 dmg, force != 0,0,0, type 128
			 double	10.00 dmg, force != 0,0,0, type 128
			 slam	10.00 dmg, force == 0,0,0, type 128
			 pound	15.00 dmg, force == 0,0,0, type 128
			 hunter
			 scratch 6.00 dmg , force != 0,0,0, type 128
			 others  !=6.00 dmg, force == ?, type 128
			 spitter
			 scratch 4.00 dmg , force != 0,0,0, type 128
			 spit    0.00-6.00, force == 0,0,0, type 265216		<- 0.00 to 6.00 on bots
	
		z_spit_latency		<- time before spit comes out of spitter's mouth after being fired
		z_spit_spread_delay	<- time before VISUAL spread begins. people take damage anyway


		  */

		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  

		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  














