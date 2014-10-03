#pragma semicolon 1

#include <l4d2_direct>
#include <l4d2weapons>
#include <left4downtown>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

/* VERSION HISTORY
 * test: L4D2Arena is born
 * 0.1:
 * 		- Fully functional spawning system for players.
 * 			- Works for both infected and survivors.
 * 			- Finds random spawns, accepting the first one that is clear of enemies.
 * 			- Including easy to use spawn-storing system to ease map development.
 * 		- Fully functional powerup system.
 * 			- Including easy to use spawn-storing system to ease map development.
 * 			- 8 different types:
 * 				- medkits: +60 health, green glow
 * 				- pills: +30 health, light green glow
 * 				- defib: +1 instant respawn, teal glow
 * 				- adrenaline: +30% speed for 20 seconds, light teal glow
 * 				- shield: -25% damage taken for 60 seconds, blue glow
 * 				- incendiary: +20% damage for 30 seconds, pink glow
 * 				- explosive: +100% damage for 20 seconds, red glow
 * 				- the holy gnome: not implemented, white glow
 * 			- respawn times:
 * 				20 secs: pills, medkit
 * 				60 secs: defib, adrenaline, shield, incendiary
 * 				150 secs: explosive
 * 		- Created keyvalues structure to store spawns and powerups, as well as arena center, where players are teleported to as spectator on connect.
 * 		- Blocked all witches, including unusual non-cvar-respecting witch spawns.
 * 		- Removed common infected.
 * 		- Removed all items from maps.
 * 		- Set up parish 3's cemetery as the first arena map.
 * 			- 25 player spawns.
 * 			- 15 powerup spawns:
 * 				- 2 Incendiary
 * 				- 1 Explosive
 * 				- 2 Defibs
 * 				- 2 Medkits
 * 				- 2 Shields
 * 				- 2 Adrenalines
 * 				- 4 Pills
 * 		- All 7 si classes defined, 3 survivor classes (jug, nin, sha)
 * 			- No slowdown on anything because of the way max speed is set.
 * 			- Juggernaut
 * 				- 150 health, 300 speed
 * 				- Can shove only once per 4 seconds
 * 					- Shoves do 25% of jug's current health as damage
 * 				- Pump shotgun
 * 					- Moderately reduced spread
 * 					- Decreased range modifier to 0.45 (default 0.69)
 * 					- Clipsize 4, 600 ammo
 * 					- Damage: 15 pellets 2 damage
 * 				- Axe does 1.0 damage per hit ray (about 14 hit rays but varying, function to cap them isn't implemented yet)
 * 			- Ninja
 * 				- 80 health, 325 speed
 * 				- Can shove only once per 7 seconds
 * 					- Except he can shove up to 3 extra times in the first 2 seconds
 * 				- Chrome shotgun
 * 					- Slightly increased spread
 * 					- Decreased range modifier to 0.45 (default 0.69)
 * 					- Clipsize 3, 450 ammo
 * 					- Damage: 6 pellets 4 damage
 * 				- Katana does 3.5 damage per hit ray (about 10 hit rays but varied, function to cap them not yet implemented)
 * 			- Sharpshooter
 * 				- 100 health, 275 speed
 * 				- Can shove only once per 6 seconds
 * 				- Damage while crouched increases by 10%.
 * 				- Damage while scoped increases by 10%. (not working)
 * 				- AWP:
 * 					- Removed all spread.
 * 					- Range modifier decreased to 0.9 (default 1.0)
 * 					- Clipsize is 4, 600 ammo
 * 					- 30 damage
 * 				- Deagle does
 * 					- Decreased spread
 * 					- Range modifier still 0.75
 * 					- Clipsize still 8
 * 					- Damage is 6
 * 			- Hunter
 * 				- 100 health, 312.5 speed
 * 				- Hunters scratches for 13 damage
 * 				- Hunter dies when pouncing a survivor, dealing 50 damage to him
 * 					- Does not do extra damage from long distance pounces
 * 					- Faster respawn for hunter from this, and his death does not affect score (but the kill does)
 * 			- Jockey
 * 				- 100 health, 300 speed
 * 				- Scratches for 8 damage
 * 				- Jockey can ride players normally, for 4 damage every 1 second
 * 			- Smoker
 * 				- 100 health, 275 speed
 * 				- scratches for 2 damage
 * 				- tongue breaks on contact but deals 18 damage
 * 				- tongue can be used every 2 seconds
 * 				- tongue moves slowly but has a very long range
 * 			- Tank:
 * 				- 80 health, 312.5 speed
 * 				- Punches for 10 damage
 * 				- Can be shoved.
 * 				- Rock health reduced to 10 (Default 50)
 * 				- Rocks are thrown with a greater force
 * 				- Rock interval increased to 6
 * 				- Rock radius decreased to 50 (default 75)
 * 				- Disabled frustration on tanks.
 * 			- Boomer
 * 				- 80 health, 350 speed
 * 				- Scratches for 8 damage
 * 			- Spitter
 * 				- 100 health, 300 speed
 * 				- Scratches for 4 damage
 * 				- Spit has an extremely long range and travels at high speeds
 * 				- Spitter can spit every 4 seconds
 * 			- Charger:
 * 				- 200 health, 270 speed
 * 				- Chargers punch for 10 damage
 * 				- Chargers do 15 damage on secondary impacts
 * 				- Charge pound damage is 7
 * 				- Charges only last 1 second but can be used again after 1.5 seconds
 * 				- Impact death charges are tracked as player kills rather than world kills
 * 				- Can only be shoved by jugs.
 * 		- Muted all idle SI sounds.
 * 		- Disabled SI getting natural spawns.
 * 		- Blocked natural team change.
 * 		- Added menus/commands for team change and class change.
 * 		- Blocked survivors dropping weapons on death.
 * 		- Blocked end saferoom door from being closed.
 * 		- Added shitty basic scoring system to track individual kills.
 * 		- Added public sounds for item spawning and item grabbing, and a private sound for spawning.
 * 		- Set survivor FF to 100%
 * 		- Disabled flow tanks.
 * 		- Set max distance score for all maps to 0.
 * 		- Bots are kicked on connect.
 * 		- Game does not end when there are no players.
 * 		- Game does not end by survivor wipe.
 * 		- Disabled versus markers.
 * 0.2:
 * 		- Powerups:
 * 			- pills now have the same green glow as medkits instead of light green
 * 			- adrenaline now has the same teal glow as defibs, instead of light teal
 * 			- incendiary now has an orange glow instead of pink
 * 			- respawn times:
 * 				- medkits are now in the 60 second group
 * 				- adrenaline is now in the 20 second group
 * 			- pills health amount decreased to 25 from 30
 * 			- added adrenaline damage immunity:
 * 				- if a player reaches 0 health while under the effects of adrenaline, he will lose the speed buff and become immune to damage for 2 seconds
 * 		- Classes
 * 			- Juggernaut
 * 				- Pump shotgun
 * 					- Increased range modifier to 0.75
 * 					- Decreased pellets to 12 (from 15)
 * 					- Increased damage to 3 (from 2)
 * 			- Ninja
 * 				- Chrome shotgun
 * 					- Increased range modifier to 0.75
 * 					- Increased damage to 6 (from 4)
 * 			- Sharpshooter
 * 				- AWP:
 * 					- Range modifier decreased to 0.8
 * 					- Damage decreased to 20
 * 			- Jockey
 * 				- Jockeys now damage themselves while riding for 9 damage per second
 * 				- Increased jockey control min/max to 0.9, decreased variance to 0.1
 * 				- Death jockeys are now tracked as kills
 * 			- Smoker
 * 				- Scratch damage increased to 4
 * 			- Boomer
 * 				- Scratch damage increased to 11.5
 * 			- Spitter 
 * 				- Spitter response time to special ability command is now shorter, and spit begins to visually spread more quickly
 * 				- Spitter spit interval reduced to 3 seconds
 * 			- Charger
 * 				- Death charges by carry are now tracked as kills
 * 			- Tank
 * 				- Increased fist radius from 15 to 25
 * 				- Disabled tank props fading, just in case.
 * 		- Added hint messages on powerup grab to explain their effects.
 * 0.3:
 * 		- Classes
 * 			- Changed the way m2 delay works so that it is used for all classes now as well, including SI.
 * 				- Set attack speed of all SI to 1.0. Tank is set to 3.5 for testing.
 * 			- Ninja
 * 				- Fixed a typo that caused ninjas to use juggernauts' m2 delay
 * 				- Reduced m2 delay to 4 seconds from 7 (for a total 6 after initial m2, allowing for up to 3 extra m2's during the first 2 seconds)
 * 			- Spitter 
 * 				- fixed spitter damage multiplier being applied from spit damage rather than scratch
 * 				- increased said multiplier to 1.2 from 1.1
 * 				- decreased spit cooldown to 2.5 from 3.0
 * 			- Tank
 * 				- fixed tank getting m2d while throwing a rock to cause the rock to disappear without the animation ending (and being replaced by stagger)
 * 		- Enabled team changes while players are alive, delayed until next death like with class change.
 * 		- Added support for multiple arenas on a single map.
 */


 //maybe hook settransmit and use IsClientVisible or whatever to remvoe glows!
 
/* To-do:
 * x Implement ninja special ability
 * x Remove regular glows from survivors so no one can see anyone through walls. 
 * x Make it so players can change team while alive like with class, but it only goes through after they die.
 * x Add tracking of death jockeys and death charges (already taken care of death impact charges, missing the carried survivor)
 * x Fix adrenaline death protection always firing
 * x Add the already planned ability for spitter scratches to increase damage taken.
 * x See if custom SI attack speeds work
 * x Fix double respawn from team change. 
 * 	- might have been accidentally fixed by allowing living players to change team?
 * x Increase tank punch range, maybe also increase interval while increasing damage
 *  - Test tank_swing_range (default 56)
 * x Decrease rate at which boomer vomit fades on survivors
 *  - Test cvars
 * x Make it so tank stops rock sequence when shoved since the rock disappears.
 *  - Could also optionally make tank immune to shoves while throwing a rock. Maybe
 * - Do something similar about smoker movement after firing tongue, since it was choppy. Or maybe that was just my insane lag.
 * x See if it's possible to reduce delay between mouse click and punch on tank.
 *  - test tank_swing_duration default 0.2, probably like m2 duration but see how it goes
 *  - also try setting punch sequence ahead of its value, see if it skips part of it and punches sooner
 * - Cap maximum number of hit ray hits per strike on melees
 * ? Make spitter initial hit do damage.
 * 	- Low damage at close range because of quick spits to cover the entire area, but higher damage at long range to make spitter a viable sniper.
 * ? Make spitter not be slowed down by spitting.
 * - Fix si being able to respawn
 * - Add glows to players who have picked up powerups:
 *  - Orange for incendiary.
 * 	- Red for explosive.
 *  - Blue for shielded.
 *  - Violet for red + blue.
 *  - Pink for orange + blue.
 *  - Teal for adrenaline with nothing else.
 * 		- maybe make it so that when the timer is running low the glow starts flashing, like during the last 3 seconds
 * - Make smoker tongue damage increase with distance.
 * - Do the planned tank rock damage changes.
 * - See if point_proximity_sensor could be used to replace touchentities for powerups
 * 	- If so, maybe make it so that powerups go invisible when grabbed and then visible again on spawn
 * - Remove survivor speech sounds (instanced_scripted_scene entities)
 * - Use info_director entity for cool stuff! check fgd, not the valve dev community
 * - Make FF count hitgroup. Might have to use trace attack
 * - SetHUDVisibility from player entity, see if it can be used to hide scoreboard when people press tab
 * - https://developer.valvesoftware.com/wiki/Player use this for health of players
 * - Add props to cemetery.
 *  - Maybe reduce defibs to 1 and put it on the north corner.
 *  - Maybe move explosive ammo to southern incendiary ammo spawn.
 * 		- Maybe make it so that the hill slows players down as they climb it, with a point_playermoveconstraint
 * - See if you can add strafe jumping for a tiny little boost of speed (further increased by actual bhopping).
 * - Fix some powerups being unusable at random times for random amounts of time before becoming usable again.
 * - Look at survivor MVP plugin to fix and improve scoring system.
 * - Add glitch fixes from promod to the config.
 * - Maybe increase model scale size of powerups (only a bit)
 * 
 * - Work on a way to make the whole game structure more competitive, with a match mode that makes everyone get their first spawn at the same time, with powerups starting on their respective spawn timers instead of pre-spawned
 * - Create a new arena that's more suited for 1v1/2v2 in another map.
 * - Make sure team changes with players alive don't bug out if the player doesnt select a class.
 * - See if it's possible to show spawn timers to survivors the way infected usually see theirs (probably not). If it is show spawn timers.
 *  - Otherwise show players how long they have to wait before their next spawn in hint text or something similar.
 * - Think more about what to do with charger.
 * - Add 4 survivor classes. Use these weapons:
 * 	- HR, smg or silenced smg, desert rifle, +1
 * 	- machete, dual pistols, +2
 * - Maybe give tank control of what kind of rock he throws. Maybe make rock throws have a shorter duration if it's possible.
 * 
 * - Make FFA and varied teams of survivor and infected, or more than 2 teams, a viable option
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
//sequences
#define SEQ_TANK_ROCK_OVERHEAD	51
#define SEQ_TANK_ROCK_OVERHAND	49
#define SEQ_TANK_ROCK_UNDERHAND	50
#define SEQ_TANK_STAGGER		?
#define SEQ_TANK_IDLE			?
//ammo offsets
#define OFFSET_ASSAULT_RIFLE_IAMMO		12
#define OFFSET_SMG_IAMMO				20
#define OFFSET_PUMPSHOTGUN_IAMMO		28
#define OFFSET_AUTO_SHOTGUN_IAMMO		32
#define OFFSET_HUNTING_RIFLE_IAMMO		36
#define OFFSET_MILITARY_SNIPER_IAMMO	40
#define OFFSET_GRENADE_LAUNCHER_IAMMO	68
//teams
#define TEAM_NONE		0
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
//sound volume
#define SNDVOL_MAX	1.0
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
#define DAMAGE_SCRATCH_SMOKER	4.0
#define DAMAGE_SPECIAL_SMOKER	18.0	//damage on tongue hit
#define RANGE_SPECIAL_SMOKER	2048.0	//range of smoker tongue
#define SPEED_SPECIAL_SMOKER	750.0	//velocity of smoker tongue
#define COOLDOWN_SPECIAL_SMOKER	2.0	
#define DURATION_SPECIAL_SMOKER	10.0	//duration of debuff
#define DAMAGE_SCRATCH_BOOMER	11.5
#define DURATION_SPECIAL_BOOMER	
#define DAMAGE_SCRATCH_SPITTER		4.0
#define DAMAGE_DIRECT_SPITTER		10.0	//damage on spit direct hit
#define DAMAGE_SPECIAL_SPITTER_MULT	1.2
#define DURATION_DEBUFF_SPITTER		6.0		//how long it takes after a scratch for the variable to decrement
#define SPEED_SPECIAL_SPITTER		2000.0
#define COOLDOWN_SPECIAL_SPITTER	2.5
#define DAMAGE_TANK						10.0
#define DAMAGE_TANK_ROCK_MAX			25.0 //rock max damage
#define DAMAGE_SPECIAL_TANK_MINRANGE	256.0	//range at which rock damage increase starts 
#define DAMAGE_SPECIAL_TANK_MAXRANGE	1536.0	//range at which max rock damage is reached
//survivor m2 delays
#define SPECIAL_M2_NINJA_BURST_TIME		2.0		//duration for which ninja can m2 before delay kicks in
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
#define DURATION_ADRENALINE_SPECIAL		2.0
#define DURATION_INCENDIARY				30.0
#define DURATION_EXPLOSIVE				20.0
#define DURATION_SHIELD					60.0
//percentage bonuses
#define PERCENTG_ADRENALINE_BONUS_SPEED		0.3
#define PERCENTG_INCENDIARY_BONUS_DAMAGE	0.2
#define PERCENTG_EXPLOSIVE_BONUS_DAMAGE		1.0
#define PERCENTG_SHIELD_BONUS_PROTECTION	0.25
//absolute bonuses
#define ABSOLUTE_PILLS_BONUS_HEALTH		25
#define ABSOLUTE_MEDKIT_BONUS_HEALTH	60
//powerup respawn tiers
#define DURATION_RESPAWN_POWERUP_QUICK	20.0
#define DURATION_RESPAWN_POWERUP_MID	60.0
#define DURATION_RESPAWN_POWERUP_LONG	150.0
//colors
#define COLOR_BLACK		"0 0 0" //are there actually black glows?
#define COLOR_GREEN		"0 255 0"
#define COLOR_TEAL		"0 255 255"
#define COLOR_BLUE		"0 0 255"
#define COLOR_VIOLET	"143 0 255"
#define COLOR_PURPLE	"128 0 128"
#define COLOR_RED		"255 0 0"
#define COLOR_ORANGE	"255 127 0"
#define COLOR_YELLOW	"255 255 0"
#define COLOR_PINK		"255 192 203"
#define COLOR_WHITE		"255 255 255"
//causes of death
#define	COD_PWNT		0	//killed by an enemy
#define COD_FF			1	//killed by an ally
#define COD_KAMIKAZE	2	//hunter special ability, death charges, etc
#define COD_WORLD		3	//other kills
//sounds
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
	"player/boomer/voice/alert/female_boomer_alert_04.wav",		"player/boomer/voice/alert/female_boomer_alert_05.wav",		"player/boomer/voice/alert/female_boomer_alert_07.wav",
	"player/boomer/voice/alert/female_boomer_alert_10.wav",		"player/boomer/voice/alert/female_boomer_alert_11.wav",		"player/boomer/voice/alert/female_boomer_alert_12.wav",
	"player/boomer/voice/alert/female_boomer_alert_13.wav",		"player/boomer/voice/alert/female_boomer_alert_14.wav",		"player/boomer/voice/alert/female_boomer_alert_15.wav",
	"player/boomer/voice/alert/male_boomer_alert_04.wav",		"player/boomer/voice/alert/male_boomer_alert_05.wav",		"player/boomer/voice/alert/male_boomer_alert_07.wav",
	"player/boomer/voice/alert/male_boomer_alert_10.wav",		"player/boomer/voice/alert/male_boomer_alert_11.wav",		"player/boomer/voice/alert/male_boomer_alert_12.wav",
	"player/boomer/voice/alert/male_boomer_alert_13.wav",		"player/boomer/voice/alert/male_boomer_alert_14.wav",		"player/boomer/voice/alert/male_boomer_alert_15.wav"	,
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
//	"player/charger/voice/warn/charger_warn1.wav",				"player/charger/voice/warn/charger_warn2.wav",				"player/charger/voice/warn/charger_warn3.wav",
	//alert
	"player/charger/voice/alert/Charger_alert_01.wav",			"player/charger/voice/alert/Charger_alert_02.wav",	
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
//	"player/jockey/voice/warn/jockey_06.wav",					"player/jockey/voice/warn/jockey_08.wav",	
	//alert - played on spawn
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
	"player/smoker/voice/alert/smoker_alert_01.wav",			"player/smoker/voice/alert/smoker_alert_02.wav",			"player/smoker/voice/alert/smoker_alert_03.wav",
	"player/smoker/voice/alert/smoker_alert_04.wav",			"player/smoker/voice/alert/smoker_alert_05.wav",			"player/smoker/voice/alert/smoker_alert_06.wav",
	//idle
	"player/smoker/voice/idle/Smoker_Lurk_01.wav",				"player/smoker/voice/idle/Smoker_Lurk_03.wav",				"player/smoker/voice/idle/Smoker_Lurk_04.wav",
	"player/smoker/voice/idle/Smoker_Lurk_06.wav",				"player/smoker/voice/idle/Smoker_Lurk_08.wav",				"player/smoker/voice/idle/Smoker_Lurk_09.wav",
	"player/smoker/voice/idle/Smoker_Lurk_10.wav",				"player/smoker/voice/idle/Smoker_Lurk_11.wav",				"player/smoker/voice/idle/Smoker_Lurk_12.wav",
	"player/smoker/voice/idle/Smoker_Lurk_13.wav",
	/* SPITTER */
	//warning
	//alert
	"player/spitter/voice/alert/Spitter_Alert_01.wav",			"player/spitter/voice/alert/Spitter_Alert_02.wav",
	//idle
	"player/spitter/voice/idle/Spitter_Lurk_01.wav",			"player/spitter/voice/idle/Spitter_Lurk_02.wav",			"player/spitter/voice/idle/Spitter_Lurk_03.wav",
	"player/spitter/voice/idle/Spitter_Lurk_04.wav",			"player/spitter/voice/idle/Spitter_Lurk_05.wav",			"player/spitter/voice/idle/Spitter_Lurk_06.wav",
	"player/spitter/voice/idle/Spitter_Lurk_07.wav",			"player/spitter/voice/idle/Spitter_Lurk_08.wav",			"player/spitter/voice/idle/Spitter_Lurk_09.wav",
	"player/spitter/voice/idle/Spitter_Lurk_10.wav",			"player/spitter/voice/idle/Spitter_Lurk_11.wav",			"player/spitter/voice/idle/Spitter_Lurk_12.wav",
	"player/spitter/voice/idle/Spitter_Lurk_14.wav",			"player/spitter/voice/idle/Spitter_Lurk_15.wav",			"player/spitter/voice/idle/Spitter_Lurk_16.wav",
	"player/spitter/voice/idle/Spitter_Lurk_17.wav",			"player/spitter/voice/idle/Spitter_Lurk_18.wav",			"player/spitter/voice/idle/Spitter_Lurk_19.wav",
	"player/spitter/voice/idle/Spitter_Lurk_20.wav",
	/* TANK */
	//idle
	"player/tank/voice/idle/Tank_Breathe_01.wav",				"player/tank/voice/idle/Tank_Breathe_02.wav",				"player/tank/voice/idle/Tank_Breathe_03.wav",
	"player/tank/voice/idle/Tank_Breathe_04.wav",				"player/tank/voice/idle/Tank_Breathe_05.wav",				"player/tank/voice/idle/Tank_Breathe_06.wav",
	"player/tank/voice/idle/Tank_Breathe_07.wav",				"player/tank/voice/idle/Tank_Breathe_08.wav",
	"player/tank/voice/idle/Tank_Growl_01.wav",					"player/tank/voice/idle/Tank_Growl_02.wav",					"player/tank/voice/idle/Tank_Growl_03.wav",
	"player/tank/voice/idle/Tank_Growl_09.wav",					"player/tank/voice/idle/Tank_Growl_10.wav",					"player/tank/voice/idle/Tank_Growl_11.wav",	
	"player/tank/voice/idle/Tank_Growl_12.wav"
};

static const g_iArMaxHealthOfClass[CLASS_COUNT] = 
{	//none	//hun	//cha	//joc
	0,		100,	200,	100,
	//smo	//tan	//boo	//spi
	100,	80,		80,		100,
	//sha	//jug	//nin
	100,	150,	80
};
static const Float:g_fArMaxSpeedOfClass[CLASS_COUNT] =
{	//none	//hun	//cha	//joc
	0.0,	312.5,	270.0,	300.0,
	//smo	//tan	//boo	//spi
	275.0,	312.5,	350.0,	300.0,
	//sha	//jug	//nin
	275.0,	300.0,	325.0
};
static const Float:g_fArM2IntervalOfClass[CLASS_COUNT] =
{	//none	//hun	//cha	//joc
	0.0,	1.0,	1.0,	1.0,
	//smo	//tan	//boo	//spi
	1.0,	3.5,	1.0,	1.0,
	//sha	//jug	//nin
	6.0,	4.0,	4.0
};
//gamedata things
new 		g_iOffsetAbility;
new Handle:	g_hConfigFile = INVALID_HANDLE;
new Handle:	g_hSDKCallRespawn = INVALID_HANDLE;
new Handle:	g_hSDKCallSetClass = INVALID_HANDLE;
new Handle: g_hSDKCallCreateAbility = INVALID_HANDLE;
//dynamic structures
new Handle:	g_hArrayPowerupEntities = INVALID_HANDLE;
new Handle:	g_hArrayPowerupTouchEntities = INVALID_HANDLE;
new Handle:	g_hTriePowerupModels = INVALID_HANDLE;
new Handle: g_hTrieMeleeWeaponDamages = INVALID_HANDLE;
new Handle: g_hTrieMeleeWeaponHitRayLimits = INVALID_HANDLE;
new Handle:	g_hTrieSoundsBlocked = INVALID_HANDLE;
//general world-related
new	String:	g_sCurrentArena[64];
//general player-related
new			g_iArScore[MAXPLAYERS + 1];	//control this by steam id later, to set it to normal when a player reconnects instead of setting to 0 on put in server
new 		g_iArClass[MAXPLAYERS + 1];
new 		g_iArClassToChangeToOnDeath[MAXPLAYERS + 1];
new 		g_iArTeam[MAXPLAYERS + 1]; //important for survivor-survivor fighting
new 		g_iArTeamToChangeToOnDeath[MAXPLAYERS + 1];
new			g_iArCauseOfDeath[MAXPLAYERS + 1];
new			g_iArWorldDeathCauser[MAXPLAYERS + 1];
new			g_iArJockeyedBy[MAXPLAYERS + 1];
new			g_iArCarriedBy[MAXPLAYERS + 1];
//classes
new			g_iArTimesScratchedBySpitter[MAXPLAYERS + 1];
new Float:	g_fArTimeSinceLastDamaged[MAXPLAYERS + 1];		//currently only used by ninjas, but might be used for other things later
new Float:	g_fArTimeSmokerSlowdownEndsAt[MAXPLAYERS + 1];
//powerups
new Float:	g_fArTimeAdrenalineEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeIncendiaryAmmoEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeExplosiveAmmoEndsAt[MAXPLAYERS + 1];
new Float:	g_fArTimeShieldEndsAt[MAXPLAYERS + 1];
new 		g_iArDefibCount[MAXPLAYERS + 1];

/*
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
	version = "0.3",
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
	if (buttons & IN_ATTACK2 && L4D2Direct_GetNextShoveTime(client) <= GetGameTime())
	{
		switch (g_iArClass[client])
		{
			case CLASS_NINJA:
			{
				CreateTimer(SPECIAL_M2_NINJA_BURST_TIME, Timed_DelayedM2Delay, client);
			}
			default:
			{
				L4D2Direct_SetNextShoveTime(client, GetGameTime() + g_fArM2IntervalOfClass[g_iArClass[client]]);
			}			
/*			case CLASS_TANK:
			{
				//do nothing
			}*/
		}
	}
}

public Action:Timed_DelayedM2Delay(Handle:timer, any:client)
{
	L4D2Direct_SetNextShoveTime(client, GetGameTime() + g_fArM2IntervalOfClass[g_iArClass[client]]);
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
			
			switch (g_iArClass[client])
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
			
			SetEntityHealth(client, g_iArMaxHealthOfClass[g_iArClass[client]]);
		}
		case TEAM_INFECTED:
		{
			new WeaponIndex;
			while ((WeaponIndex = GetPlayerWeaponSlot(client, 0)) != -1)
			{
				RemovePlayerItem(client, WeaponIndex);
				RemoveEdict(WeaponIndex);
			}
			
			switch (g_iArClass[client])
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
	if (args < 1)
	{
		ShowTeamMenu(client);
	}
	else
	{
		decl String:team[32];
		GetCmdArg(1, team, 32);
		
		SetNextTeam(client, team);
		ShowClassMenu(client);
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
		
		SetNextClass(client, class);
	}
}

stock SetNextTeam(client, const String:team[])
{
	if (StrEqual(team, "survivor", false) || StrEqual(team, "2", false))
	{
		if (IsPlayerAlive(client))
		{
			g_iArTeamToChangeToOnDeath[client] = TEAM_SURVIVOR;
		}
		else
		{
			g_iArTeam[client] = TEAM_SURVIVOR;
			ChangeClientTeam(client, TEAM_SURVIVOR);
			
			decl Float:pos[3], Float:ang[3], Float:vec[3];
			GetClientAbsOrigin(client, pos);
			GetClientEyeAngles(client, ang);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
			TeleportEntity(client, pos, ang, vec);
		}
	}
	else if (StrEqual(team, "infected", false) || StrEqual(team, "3", false))
	{
		if (IsPlayerAlive(client))
		{
			g_iArTeamToChangeToOnDeath[client] = TEAM_INFECTED;
		}
		else
		{
			g_iArTeam[client] = TEAM_INFECTED;
			ChangeClientTeam(client, TEAM_INFECTED);
		}
	}	
}

stock SetNextClass(client, const String:class[])
{
	switch (g_iArTeamToChangeToOnDeath[client] == TEAM_NONE ? GetClientTeam(client) : g_iArTeamToChangeToOnDeath[client])
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_BOOMER;
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_CHARGER;
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_HUNTER;
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_JOCKEY;
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_SMOKER;
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_SPITTER;
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
					if (g_iArClass[client] == CLASS_NONE)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_TANK;
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
					if (g_iArClass[client] == 0)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_JUGGERNAUT;
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
					if (g_iArClass[client] == 0)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_NINJA;
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
					if (g_iArClass[client] == 0)
					{
						StartSpawnTimer(DURATION_RESPAWN, client);
					}
					g_iArClass[client] = CLASS_SHARPSHOOTER;
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
	
	g_iArClass[client] = CLASS_NONE;
	g_iArScore[client] = 0;
	
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
	g_iArTeam[client] = TEAM_SPECTATOR;
	CreateTimer(2.0, Timed_ShowTeamMenuOnConnect, client);
}

public Action:Timed_ShowTeamMenuOnConnect(Handle:timer, any:client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	
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
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		if (GetMenuItem(menu, param2, info, sizeof(info)))
		{
			SetNextTeam(param1, info);
			ShowClassMenu(param1);			
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
	switch (g_iArTeamToChangeToOnDeath[client] == TEAM_NONE ? GetClientTeam(client) : g_iArTeamToChangeToOnDeath[client])
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
			SetNextClass(param1, info);
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
	PrintToChatAll("%s",classname);
	
	if (StrEqual(classname, "spitter_projectile"))
	{
//		SDKHook(entity, SDKHook_StartTouch, OnSpitDirectHit);
//		SetEntPropFloat(GetEntPropEnt(entity, Prop_Send, "m_hThrower"), Prop_Send, "m_flVelocityModifier", 1.0);
	}
	else if (StrEqual(classname, "witch"))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:OnSpitDirectHit(projectile, target)
{
	if (target > 0 && target <= MaxClients)
	{
		new spitter = GetEntPropEnt(projectile, Prop_Data, "m_hThrower");
		SDKHooks_TakeDamage(target, spitter, spitter, GetDamageAfterPowerups(spitter, target, DAMAGE_DIRECT_SPITTER));
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
		
		if (g_iArClass[attacker] == CLASS_SHARPSHOOTER)
		{
			new buttons = GetClientButtons(attacker);
			if (buttons & IN_DUCK)
			{
				damage *= 1.10;
			}
			if (buttons & IN_ZOOM) // this doesnt work like this! stupid! have to track people switching between zoomed and not zoomed! also, make it so the bonus is given when players are NOT zoomed
			{
				PrintToChatAll("sharpshooter zoomed, increasing damage by 10%");
				damage *= 1.10;
			}
		}
		else if (g_iArClass[attacker] == CLASS_SPITTER && damagetype != 265216)
		{
			g_iArTimesScratchedBySpitter[victim]++;
			CreateTimer(DURATION_DEBUFF_SPITTER, Timed_TickDownSpitterDebuff, victim);
		}
		else if (g_iArClass[attacker] == CLASS_NINJA)
		{
			new Float:buffer = g_fArTimeSinceLastDamaged[attacker]/100.0;
			if (buffer > 0.15)
			{
				buffer = 0.15;
			}
			damage *= 1.0 + buffer;
			PrintToChatAll("ninja damage increased by %.2f", buffer);
		}
		
		damage *= Pow(DAMAGE_SPECIAL_SPITTER_MULT, float(g_iArTimesScratchedBySpitter[victim]));
		
		if (GetClientHealth(victim) - RoundToNearest(damage) < 1 && GetGameTime() < g_fArTimeAdrenalineEndsAt[victim])	//if player is under the effects of adrenaline and was about to die
		{
			g_fArTimeAdrenalineEndsAt[victim] = GetGameTime();	//remove adrenaline speed buff
			SetEntityHealth(victim, 1);
		}
		if (GetGameTime() < g_fArTimeAdrenalineEndsAt[victim] + DURATION_ADRENALINE_SPECIAL)	//and make him immortal for a tiny amount of time
		{
			return Plugin_Handled;
		}
		
		g_fArTimeSinceLastDamaged[victim] = GetGameTime();
		
		return Plugin_Changed;
	}	
	
	return Plugin_Continue;
}

public Action:Timed_TickDownSpitterDebuff(Handle:timer, any:victim)
{
	g_iArTimesScratchedBySpitter[victim]--;
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (IsValidEntity(inflictor))
	{
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
	}
	return Plugin_Continue;
}

public Action:Scores(client, args)
{
	decl topEight[8];
	GetTopEight(topEight);

	decl String:playername[64];
	for (new n = 0; n < 8; n++)
	{
		GetClientName(topEight[n], playername, 64);
		PrintToConsole(client, "#%d - %s with %d kills (%s).", n + 1, playername, g_iArScore[topEight[n]], GetClientTeam(topEight[n]) == TEAM_SURVIVOR ? "SURVIVOR" : GetClientTeam(topEight[n]) == TEAM_INFECTED ? "INFECTED" : "NOT IN A TEAM");
		if (n < 3 || topEight[n] == client)
		{
			PrintToChat(client, "#%d - %s with %d kills (%s).", n + 1, playername, g_iArScore[topEight[n]], GetClientTeam(topEight[n]) == TEAM_SURVIVOR ? "SURVIVOR" : GetClientTeam(topEight[n]) == TEAM_INFECTED ? "INFECTED" : "NOT IN A TEAM");
		}
	}
}

stock GetTopEight(topEight[8])
{
	topEight[0] = 0;
	g_iArScore[0] = -100;
	for (new n = 1; n <= MaxClients; n++)
	{
		if (IsClientInGame(n))
		{
			if (g_iArScore[n] > g_iArScore[topEight[0]])
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
			else if (g_iArScore[n] > g_iArScore[topEight[1]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = topEight[2];
				topEight[2] = topEight[1];
				topEight[1] = n;
			}
			else if (g_iArScore[n] > g_iArScore[topEight[2]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = topEight[2];
				topEight[2] = n;
			}
			else if (g_iArScore[n] > g_iArScore[topEight[3]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = topEight[3];
				topEight[3] = n;
			}
			else if (g_iArScore[n] > g_iArScore[topEight[4]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = topEight[4];
				topEight[4] = n;
			}
			else if (g_iArScore[n] > g_iArScore[topEight[5]])
			{
				topEight[7] = topEight[6];
				topEight[6] = topEight[5];
				topEight[5] = n;
			}
			else if (g_iArScore[n] > g_iArScore[topEight[6]])
			{
				topEight[7] = topEight[6];
				topEight[6] = n;
			}
			else if (g_iArScore[n] > g_iArScore[topEight[7]])
			{
				topEight[7] = n;
			}
		}
	}
}

public Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("%s", name);
	
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_iArJockeyedBy[victim] = jockey;
	CreateTimer(DURATION_SPECIAL_JOCKEY, Timed_JockeySelfDamage, victim, TIMER_REPEAT);
}

public Action:Timed_JockeySelfDamage(Handle:timer, any:victim)
{
	if (g_iArJockeyedBy[victim] == 0 || !IsPlayerAlive(victim) || !IsPlayerAlive(g_iArJockeyedBy[victim]))
	{
		return Plugin_Stop;
	}
	
	PrintToChatAll("jockey self-damaging");
	SDKHooks_TakeDamage(g_iArJockeyedBy[victim], g_iArJockeyedBy[victim], g_iArJockeyedBy[victim], GetDamageAfterPowerups(g_iArJockeyedBy[victim], g_iArJockeyedBy[victim], DAMAGE_SPECIAL_JOCKEY_SELF));
	return Plugin_Continue;
}

public Event_JockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("%s", name);
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_iArJockeyedBy[victim] = 0;
}

public Event_ChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	g_iArWorldDeathCauser[victim] = attacker;
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
	
	if (client == 0)
	{
		return;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == client)
	{
		PrintToChatAll("Kamikaze Kill");
		g_iArCauseOfDeath[client] = COD_KAMIKAZE;
	}
	else
	{
		if (attacker > 0 && attacker <= MaxClients)
		{
			if (GetClientTeam(client) == GetClientTeam(attacker))
			{
				PrintToChatAll("FF Kill");
				g_iArCauseOfDeath[client] = COD_FF;
			}
			else
			{
				PrintToChatAll("Normal Kill");
				g_iArCauseOfDeath[client] = COD_PWNT;
			}
		}
		else
		{	//gonna have to enforce COD_KAMIKAZE for death charges and shit
			if (g_iArWorldDeathCauser[client] != 0)
			{
				PrintToChatAll("Normal Kill (forced world death)");
				g_iArCauseOfDeath[client] = COD_PWNT;
				attacker = g_iArWorldDeathCauser[client];
			}
			else if (g_iArJockeyedBy[client] != 0)
			{
				PrintToChatAll("Normal Kill (death jockey)");				
				g_iArCauseOfDeath[client] = COD_PWNT;
				attacker = g_iArJockeyedBy[client];
			}
			else if (g_iArCarriedBy[client] != 0)
			{
				PrintToChatAll("Normal Kill (death charge)");
				g_iArCauseOfDeath[client] = COD_PWNT;
				attacker = g_iArCarriedBy[client];
			}
			else
			{
				PrintToChatAll("World Kill (accidental/suicide)");
				g_iArCauseOfDeath[client] = COD_WORLD;
			}			
		}
	}
	g_iArWorldDeathCauser[client] = 0;
	
	switch (g_iArCauseOfDeath[client])
	{
		case COD_FF:
		{
			g_iArScore[attacker]--;
		}
		case COD_PWNT:
		{
			g_iArScore[attacker]++;
		}
		case COD_WORLD:
		{
			g_iArScore[client]--;
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
	
	if (g_iArTeamToChangeToOnDeath[client] != TEAM_NONE)
	{
		new bool:isSurvivorTeam = (g_iArTeamToChangeToOnDeath[client] == TEAM_SURVIVOR);
		
		decl Float:pos[3], Float:ang[3], Float:vec[3];
		if (isSurvivorTeam)
		{
			GetClientAbsOrigin(client, pos);
			GetClientEyeAngles(client, ang);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
		}
		
		ChangeClientTeam(client, g_iArTeamToChangeToOnDeath[client]);
		g_iArTeam[client] = g_iArTeamToChangeToOnDeath[client];
		g_iArTeamToChangeToOnDeath[client] = TEAM_NONE;
		
		if (isSurvivorTeam)
		{
			TeleportEntity(client, pos, ang, vec);	//fix camera view getting weird on team change
		}
	}
	if (g_iArClassToChangeToOnDeath[client] != CLASS_NONE)
	{
		g_iArClass[client] = g_iArClassToChangeToOnDeath[client];
		g_iArClassToChangeToOnDeath[client] = CLASS_NONE;
	}
}

stock StartSpawnTimer(Float:duration, client)
{
	CreateTimer(duration, Timed_Respawn, client);
}

public Action:Timed_Respawn(Handle:timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) != TEAM_SPECTATOR && g_iArClass[client] != 0)
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
	DispatchKeyValue(respawnee, "glowrange", "1");
	DispatchKeyValue(respawnee, "glowrangemin", "128");
	SetEntProp(respawnee, Prop_Send, "m_iGlowType", 2);
	SetEntProp(respawnee, Prop_Send, "m_bFlashing", false);
	AcceptEntityInput(respawnee, "StopGlowing");
	TeleportEntity(respawnee, fArSpawnPosition, fArSpawnAngles, NULL_VECTOR);
	EmitSoundToClient(respawnee, "/ui/pickup_scifi37.wav"); //louder for SI than survivors for some reason
//	EmitSoundToClient(respawnee, "/ui/pickup_guitarriff10.wav");	//can't be precached for some reason
	
	KvRewind(kv);
	CloseHandle(kv);
	CloseHandle(hEnemyPositionArray);
	CloseHandle(hSpawnIndexArray);	
}

public Action:CreateArena(client, args)
{
	if (args >= 1)
	{
		new Handle:kv = CreateKeyValues("L4D2Arena");
		FileToKeyValues(kv, DIR_KV);
		
		decl String:mapname[64];
		GetCurrentMap(mapname, 64);

		decl String:arenaname[64];
		GetCmdArg(1, arenaname, 64);
		
		KvJumpToKey(kv, mapname, true);
		KvJumpToKey(kv, arenaname, true);
		
		KvRewind(kv);
		KeyValuesToFile(kv, DIR_KV);
		CloseHandle(kv);
	}
	return Plugin_Handled;		
}

public Action:ChooseArena(client, args)
{
	if (args >= 1)
	{
		new Handle:kv = CreateKeyValues("L4D2Arena");
		FileToKeyValues(kv, DIR_KV);
		
		decl String:mapname[64];
		GetCurrentMap(mapname, 64);
		
		decl String:arenaname[64];
		GetCmdArg(1, arenaname, 64);
		
		KvJumpToKey(kv, mapname, true);
		if (KvJumpToKey(kv, arenaname, false))
		{
			g_sCurrentArena = arenaname;
		}
		else
		{
			PrintToChat(client, "Invalid arena name: %s", arenaname);
		}
		
		KvRewind(kv);
		KeyValuesToFile(kv, DIR_KV);
		CloseHandle(kv);
	}
	return Plugin_Handled;
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
	if (!KvJumpToKey(kv, g_sCurrentArena, false))
	{
		PrintToChat(client, "Invalid arena name: %s", g_sCurrentArena);
	}
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
	if (!KvJumpToKey(kv, g_sCurrentArena, false))
	{
		PrintToChat(client, "Invalid arena name: %s", g_sCurrentArena);
	}	
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
	if (!KvJumpToKey(kv, g_sCurrentArena, false))
	{
		PrintToChat(client, "Invalid arena name: %s", g_sCurrentArena);
	}
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
	retVal = g_fArMaxSpeedOfClass[g_iArClass[client]];
	
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
	
	if (g_iArClass[victim] == CLASS_TANK) //make tanks m2able
	{
		new seq = GetEntProp(victim, Prop_Send, "m_nSequence");
		if (seq == SEQ_TANK_ROCK_OVERHAND || seq == SEQ_TANK_ROCK_OVERHEAD || seq == SEQ_TANK_ROCK_UNDERHAND)
		{
			SetEntPropFloat(victim, Prop_Send, "m_flCycle", 5.0);	//end rock sequence if m2d
		}
		
		L4D_StaggerPlayer(victim, attacker, NULL_VECTOR);
	}

	if (g_iArClass[attacker] == CLASS_JUGGERNAUT)	//special juggernaut abilities
	{
		if (g_iArClass[victim] == CLASS_CHARGER)	//can m2 chargers
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
		color = COLOR_GREEN;
	}
	else if (StrEqual(sBuffer, "adrenaline"))
	{
		fArSpawnAngles[2] = 60.0;
		color = COLOR_TEAL;
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
	
	EmitSoundToAll(SOUND_ITEMSPAWN, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_MAX);
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
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a first aid kit: +%d health.", ABSOLUTE_MEDKIT_BONUS_HEALTH);
			}
			else if (StrEqual(modelname, MODEL_DEFIB, false))
			{
				g_iArDefibCount[player]++;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a defibrillator: +1 instant respawn.");
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
				CreateTimer(DURATION_RESPAWN_POWERUP_QUICK, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a shot of adrenaline: +%.0f% speed for %.0f seconds.", PERCENTG_ADRENALINE_BONUS_SPEED*100, DURATION_ADRENALINE);
			}
			else if (StrEqual(modelname, MODEL_INCENDIARY, false))
			{
				g_fArTimeIncendiaryAmmoEndsAt[player] = GetGameTime() + DURATION_INCENDIARY;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up an incendiary ammo pack: +%.0f% damage for %.0f seconds.", PERCENTG_INCENDIARY_BONUS_DAMAGE*100, DURATION_INCENDIARY);
			}
			else if (StrEqual(modelname, MODEL_EXPLOSIVE, false))
			{
				g_fArTimeExplosiveAmmoEndsAt[player] = GetGameTime() + DURATION_EXPLOSIVE;
				CreateTimer(DURATION_RESPAWN_POWERUP_LONG, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up an explosive ammo pack: +%.0f% damage for %.0f seconds.", PERCENTG_EXPLOSIVE_BONUS_DAMAGE*100, DURATION_EXPLOSIVE);
			}
			else if (StrEqual(modelname, MODEL_SHIELD, false))
			{
				g_fArTimeShieldEndsAt[player] = GetGameTime() + DURATION_SHIELD;
				CreateTimer(DURATION_RESPAWN_POWERUP_MID, Timed_RespawnPowerup, index);
				PrintHintText(player, "You picked up a riot shield: +%.0f% damage protection for %.0f seconds.", PERCENTG_SHIELD_BONUS_PROTECTION*100, DURATION_SHIELD);
			}
			
			RemovePowerup(index);
			EmitSoundToAll(SOUND_ITEMGRAB, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_MAX);
		}
	}
}

stock HealPlayer(client, amount)
{
	new currentHealth = GetClientHealth(client);
	if (currentHealth + amount > g_iArMaxHealthOfClass[g_iArClass[client]])
	{
		SetEntityHealth(client, g_iArMaxHealthOfClass[g_iArClass[client]]);
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
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	HookEvent("jockey_killed", Event_JockeyRideEnd);
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
	SetConVarFloat(FindConVar("vs_tank_damage"), DAMAGE_TANK);
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
	SetConVarFloat(FindConVar("z_jockey_control_variance"), 0.1);
	SetConVarFloat(FindConVar("z_jockey_control_max"), 0.9);
	SetConVarFloat(FindConVar("z_jockey_control_min"), 0.9);
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
	SetConVarFloat(FindConVar("z_spit_latency"),  0.1);
	SetConVarFloat(FindConVar("z_spit_spread_delay"), 0.1);
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
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 3.0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_amt_penalty"), 0.0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_cooldown"), 0.0);
	SetConVarInt(FindConVar("z_gun_swing_vs_max_penalty"), 50);
	SetConVarInt(FindConVar("z_gun_swing_vs_min_penalty"), 0);
	SetConVarFloat(FindConVar("z_gun_swing_vs_restore_time"), 10.0);
	SetConVarInt(FindConVar("z_respawn_distance"), 20000);
	SetConVarInt(FindConVar("z_respawn_interval"), 20000);
	SetConVarInt(FindConVar("tank_fist_radius"), 25);
	
	SetConVarFlags(FindConVar("sv_tankpropfade"), GetConVarFlags(FindConVar("sv_tankpropfade")) & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar("sv_tankpropfade"), 0);	
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
	SetConVarFloat(FindConVar("z_jockey_control_variance"), 0.7);
	SetConVarFloat(FindConVar("z_jockey_control_max"), 0.8);
	SetConVarFloat(FindConVar("z_jockey_control_min"), 0.8);
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
	SetConVarFloat(FindConVar("z_spit_latency"),  0.3);
	SetConVarFloat(FindConVar("z_spit_spread_delay"), 0.2);
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
	SetConVarInt(FindConVar("tank_fist_radius"), 15);
	
	SetConVarFlags(FindConVar("sv_tankpropfade"), GetConVarFlags(FindConVar("sv_tankpropfade")) & FCVAR_CHEAT);
	SetConVarInt(FindConVar("sv_tankpropfade"), 1);
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
	RegConsoleCmd("sm_arena", ChooseArena);
	RegConsoleCmd("sm_createarena", CreateArena);
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
	
	


		  */

	//	  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  

		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  














