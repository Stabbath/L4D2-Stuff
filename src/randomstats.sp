#pragma semicolon 1	

/*
 * Endless arrays
 */

 //T1 | weapons and their ids
#define WP_SMG 2
#define WP_PUMPSHOTGUN 3
#define WP_SMG_SILENCED 7
#define WP_SHOTGUN_CHROME 8
//secondary
#define WP_PISTOL 1
#define WP_PISTOL_MAGNUM 32
#define WP_MELEE 19
//snipers
#define WP_HUNTING_RIFLE 6
#define WP_SNIPER_MILITARY 10
//T2 
#define WP_RIFLE 5
#define WP_RIFLE_DESERT 9
#define WP_AUTOSHOTGUN 4
#define WP_SHOTGUN_SPAS 11
#define WP_RIFLE_AK47 26
//css
#define WP_SMG_MP5 33
#define WP_RIFLE_SG552 34
#define WP_SNIPER_AWP 35
#define WP_SNIPER_SCOUT 36
//throwables
#define WP_MOLOTOV 13
#define WP_PIPE_BOMB 14
#define WP_VOMITJAR 25
//heals and other shit
#define WP_FIRST_AID_KIT 12
#define WP_PAIN_PILLS 15
#define WP_ADRENALINE 23
#define WP_MACHINEGUN 45

//highest USABLE weapon id + 1
#define WP_NUM 37

//weapons
new Float:WepPrecision[WP_NUM] =
{
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,	//5
	1.0,	
	1.0,
	1.0,
	1.0,	
	1.0,	//10
	1.0,
	1.0,
	1.0,
	1.0,	
	1.0,	//15
	1.0,
	1.0,
	1.0,	
	1.0,
	1.0,	//20
	1.0,
	1.0,
	1.0,	
	1.0,	
	1.0,	//25
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,	//30
	1.0,
	1.0,	
	1.0,	
	1.0,	
	1.0,	//35
	1.0,	
	1.0,	
};

new Float:WepRange[WP_NUM] =
{
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,	//5
	1.0,	
	1.0,
	1.0,
	1.0,	
	1.0,	//10
	1.0,
	1.0,
	1.0,
	1.0,	
	1.0,	//15
	1.0,
	1.0,
	1.0,	
	1.0,
	1.0,	//20
	1.0,
	1.0,
	1.0,	
	1.0,	
	1.0,	//25
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,	//30
	1.0,
	1.0,	
	1.0,	
	1.0,	
	1.0,	//35
	1.0,	
	1.0,	
};

static DefaultDamage[WP_NUM] =
{
	-1,	//no weapon - 0
	1, 	//pistol 
	20,	//smg
	25,//pump
	23,//autosg
	33,	//rifle - 5
	90,	//hr
	25,	//silenced smg
	31,//chrome
	44,	//scar
	90,	//sniper - 10
	28,//spas
	-1,	//medkit
	-1,	//molotov
	-1,	//pipebomb
	-1,	//pills - 15
	-1,	//no weapon
	-1,	//no weapon
	-1,	//no weapon
	1,	//melee
	-1,	//no weapon - 20
	-1,	//no weapon
	-1,	//no weapon
	-1,	//adren
	-1,	//no weapon
	-1,	//no weapon - 25
	58,	//ak47
	-1,	//no weapon
	-1,	//no weapon
	-1,	//no weapon
	-1,	//no weapon - 30
	-1,	//no weapon
	1,	//deagle
	24,	//mp5
	33,	//sg552
	115,//awp - 35
	90,	//scout
};

static Float:DefaultSpreadPerShot[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	0.31,	//smg
	1.00,	//pump
	20.00,	//autosg
	0.75,	//rifle - 5
	1.00,	//hr
	0.40,	//silenced smg
	1.00,	//chrome
	0.60,	//scar
	1.00,	//sniper - 10
	22.00,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	1.60,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	0.35,	//mp5
	0.75,	//sg552
	1.00,	//awp - 35
	1.00,	//scout
};

static Float:DefaultMaxSpread[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	30.00,	//smg
	5.00,	//pump
	5.00,	//autosg
	30.00,	//rifle - 5
	15.00,	//hr
	30.00,	//silenced smg
	5.00,	//chrome
	25.00,	//scar
	15.00,	//sniper - 10
	5.00,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	35.00,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	30.00,	//mp5
	30.00,	//sg552
	15.00,	//awp - 35
	15.00,	//scout
};

static Float:DefaultSpreadDecay[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	5.00,	//smg
	5.00,	//pump
	5.00,	//autosg
	5.00,	//rifle - 5
	8.00,	//hr
	5.00,	//silenced smg
	5.00,	//chrome
	4.00,	//scar
	8.00,	//sniper - 10
	6.00,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	7.00,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	5.00,	//mp5
	5.00,	//sg552
	8.00,	//awp - 35
	8.00,	//scout
};

static Float:DefaultMinDuckingSpread[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	0.69,	//smg
	0.00,	//pump
	0.00,	//autosg
	0.05,	//rifle - 5
	0.00,	//hr
	0.85,	//silenced smg
	0.00,	//chrome
	0.05,	//scar
	0.05,	//sniper - 10
	0.00,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	0.50,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	0.75,	//mp5
	0.05,	//sg552
	0.00,	//awp - 35
	0.00,	//scout
};

static Float:DefaultMinStandingSpread[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	1.00,	//smg
	0.80,	//pump
	0.80,	//autosg
	0.40,	//rifle - 5
	0.10,	//hr
	1.20,	//silenced smg
	0.80,	//chrome
	0.34,	//scar
	0.50,	//sniper - 10
	0.75,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	1.00,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	1.10,	//mp5
	0.40,	//sg552
	0.10,	//awp - 35
	0.10,	//scout
};

static Float:DefaultMinInAirSpread[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	1.70,	//smg
	2.50,	//pump
	2.50,	//autosg
	1.50,	//rifle - 5
	1.50,	//hr
	1.70,	//silenced smg
	2.50,	//chrome
	1.25,	//scar
	1.50,	//sniper - 10
	2.50,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	3.00,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	1.70,	//mp5
	1.50,	//sg552
	1.50,	//awp - 35
	1.50,	//scout
};

static Float:DefaultMaxMovementSpread[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	3.00,	//smg
	1.50,	//pump
	1.50,	//autosg
	5.00,	//rifle - 5
	3.00,	//hr
	3.00,	//silenced smg
	1.50,	//chrome
	4.00,	//scar
	5.00,	//sniper - 10
	1.50,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	6.00,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	3.00,	//mp5
	5.00,	//sg552
	3.00,	//awp - 35
	3.00,	//scout
};

static Float:DefaultRange[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	2500.0,	//smg
	3000.0,	//pump
	3000.0,	//autosg
	3000.0,	//rifle - 5
	8192.0,	//hr
	2200.0,	//silenced smg
	3000.0,	//chrome
	3000.0,	//scar
	8192.0,	//sniper - 10
	3000.0,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	3000.0,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	2500.0,	//mp5
	3000.0,	//sg552
	8192.0,	//awp - 35
	8192.0,	//scout	
};

static Float:DefaultRangeModifier[WP_NUM] =
{
	-1.0,	//no weapon - 0
	1.0, 	//pistol 
	0.83,	//smg
	0.69,	//pump
	0.69,	//autosg
	0.97,	//rifle - 5
	1.00,	//hr
	0.83,	//silenced smg
	0.69,	//chrome
	0.97,	//scar
	1.00,	//sniper - 10
	0.69,	//spas
	-1.0,	//medkit
	-1.0,	//molotov
	-1.0,	//pipebomb
	-1.0,	//pills - 15
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	1.0,	//melee
	-1.0,	//no weapon - 20
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//adren
	-1.0,	//no weapon
	-1.0,	//no weapon - 25
	0.97,	//ak47
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon
	-1.0,	//no weapon - 30
	-1.0,	//no weapon
	1.0,	//deagle
	0.84,	//mp5
	0.97,	//sg552
	1.0,	//awp - 35
	1.0,	//scout	
};

/* Randomised cvar stuff
 * Syntax:
 * rwa_cvar <proportion> <minvalue> <maxvalue> <Cvar1> <Cvar2> <Cvar3> <...>
 * Plugin will select a random number for Cvar1 between minvalue and maxvalue, and scale all the following Cvars. 
 * The % that Cvar1 is increased will be stored and multiplied by the proportion, and Cvar2, Cvar3, etc will be increased or decreased by this percentage of their default value.
 * For simple direct and inverse proportion, just use "1.0" and "-1.0".
 * 
 * To-do:
 * - make it so that if Cvar1 has already been randomised, all the following Cvars will be scaled according to its variation and to proportion. Use tries for this, key is Cvar name, value is difference from default! So easy.
 * - maybe add melee randomisation
 * - maybe add client command to print to console regardless of to-chat Cvar, and make the existing one always print to chat
 * - maybe look into pistols again to find out what exactly was wrong with them
 */

/* Gonna start keeping a version history
 * pre-0.3.1:
 * - Fully working randomised weapon attributes for IWA's, and collectively for range/rangemodifier and all spread-related FWAs.
 * - No cycle time because ugly, no penetration because pointless.
 * - Included ammo as randomisable as a fake IWA.
 * - Weapon attributes can be reset by the server, and are automatically reset on plugin end.
 * 0.3.1:
 * - Added customisable unlimited cvar randomisation.
 * - Cleaned some code up.
 * - Merged ResetFloatAtts and ResetIntAtts into one, because being separated was needless.
 * - Revamped announcement system:
 *   - added cvar to control if things are announced or not and to allow clip/ammo info to be hidden no matter what
 *   - made it so that only stats that have been changed are displayed.
 * 0.4:
 * - Removed "ammo" as a possible argument for int atts, since this can be done with rwa_Cvar now. Plugin will only print ammo in weapon announcement if there were other changes to the weapon.
 * - Added "range" safeguard in case RangeModifier > 1.0 caused issues or made damage increase with distance.
 * - More announcement revamping:
 *   - Changed announcement cvars to separate weapons from cvars.
 *   - Cvar changes can now be announced, added client command for that.
 *   - Added flag cvar to choose between printing weapon and cvar stats to chat or to console.
 * - Added functionality to random cvars: if Cvar1 has already been randomised, all the following Cvars will be scaled according to its variation and to proportion.
 * - Added CSS weapon attributes.
 */
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <float>
#include <l4d2weapons.inc>

#define WEAPON_LENGTH 32

//for retrieval of ammo values.
#define AMMO_INDEX_SMG 0
#define AMMO_INDEX_SHOTGUN 1
#define AMMO_INDEX_RIFLE 2
#define AMMO_INDEX_AUTOSHOTGUN 3
#define AMMO_INDEX_HR 4
#define AMMO_INDEX_SNIPER 5

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define CLIPSIZE_BASIC	50
#define CLIPSIZE_T1SG	8
#define CLIPSIZE_T2SG	10
#define CLIPSIZE_HR		15
#define CLIPSIZE_SNIPER	30
#define CLIPSIZE_AK		40
#define CLIPSIZE_SCAR	60
#define CLIPSIZE_AWP	20

#define PELLETS_CRM	8
#define PELLETS_PMP	10
#define PELLETS_AS	11
#define PELLETS_SPA	9

public Plugin:myinfo = 
{
	name = "Randomised Stats - Weapon Attributes and Cvars",
	author = "Stabby",
	description = "Allows for randomisation of weapon attributes and cvars and the announcement of changes to players.",
	version = "0.4",
	url = "no url"
}

new bool:g_bIsWeaponModded[WP_NUM];

//Cvar handles
new Handle:	g_hAnnounceWeapons	= INVALID_HANDLE;
new Handle:	g_hAnnounceAmmo		= INVALID_HANDLE;
new Handle:	g_hAnnounceCvars	= INVALID_HANDLE;
new Handle:	g_hAnnounceToChat	= INVALID_HANDLE;

//cvar-randomisation-related structures and things
new Handle: g_hTrieModdedCvars	= INVALID_HANDLE;
new Handle: g_hArrayModdedCvars	= INVALID_HANDLE;

public OnPluginStart()
{
	//Cvars
	//announce weapon stats to players?
	g_hAnnounceWeapons= CreateConVar(	"rwa_announce_weapons",	"1",		"Should the plugin be allowed to announce changes for all modified weapons?", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//hide clipsize/ammo info from announcement?
	g_hAnnounceAmmo	= CreateConVar(		"rwa_announce_ammo",	"1",		"If 0, will hide ammo and clipsize info for all weapons even if there have been changes to them.", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//should Cvar changes be announced?
	g_hAnnounceCvars	= CreateConVar(	"rwa_announce_cvars",	"1",		"Should the plugin be allowed to announce changes for all modified Cvars?", FCVAR_PLUGIN, true, 	0.0, true, 1.0);
	//should on-connect announcements be sent to chat? 0 sends to console
	g_hAnnounceToChat	= CreateConVar(	"rwa_announce_to_chat",	"1",		"Should the plugin send announcements to chat? If not, sends to console. Flags: 1 - send weapon stats to chat, 2 - send cvar stats to chat.", FCVAR_PLUGIN, true, 	0.0, true, 1.0);
	//should the stats be re-randomised every map?
//	hReRandom		= CreateConVar(		"rwa_mod_everymap",		"1",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//include melee attribute randomisation?
//	hModMelee		= CreateConVar(		"rwa_mod_melee",		"0",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//include m2 delay and penalty randomisation?
//	hModShove		= CreateConVar(		"rwa_mod_shove",		"0",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//limits the maximum number of different modded weapons in the game to this number. 0 means no limit
//	hWepLimit		= CreateConVar(		"rwa_limit_weapons",	"0",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 10.0);
	
	g_hArrayModdedCvars	= CreateArray(48);
	g_hTrieModdedCvars	= CreateTrie();
	
	RegServerCmd ("rwa_int",		SetIntAtts);
	RegServerCmd ("rwa_float",		SetFloatAtts);
	RegServerCmd ("rwa_reset",		ResetAtts);
	RegConsoleCmd("rwa_showatts", 	ShowAtts);
	RegConsoleCmd("rwa_showcvars", 	ShowCvars);
	RegServerCmd ("rwa_cvar",		SetCvar);
	
	HookEvent("item_pickup",Event_ItemPickup);	//weapon_pickup doesnt fire ever
}

public Action:SetCvar(args)
{	
	decl n;	//used in loops
	decl String:sArArgs[args + 1][48];
	for (n = 1; n <= args; n++)	{ GetCmdArg(n, sArArgs[n], 48); }	
	
	new Float:	proportion= StringToFloat(sArArgs[1]);
	new Float:	minValue  = StringToFloat(sArArgs[2]);
	new Float:	maxValue  = StringToFloat(sArArgs[3]);
	new Float:	percentChange;
	
	new Handle:	hCvar = FindConVar(sArArgs[4]);
	if (hCvar == INVALID_HANDLE) { return; }
	
	GetConVarString(hCvar, sArArgs[0], 48);	//index 0 is otherwise unused, save Cvar value as string here
	
	if (GetTrieValue(g_hTrieModdedCvars, sArArgs[0], percentChange))	//means this cvar's already been randomised
	{
		percentChange *= proportion;
	}
	else
	{
		if (StrContains(sArArgs[0], ".") == -1)
		{	//it's not a float Cvar
			new randValue	= GetRandomInt(RoundToNearest(minValue), RoundToNearest(maxValue));
			percentChange = (float(randValue) / float(GetConVarInt(hCvar)) - 1.0) * proportion;
			SetConVarInt(hCvar, randValue);
		}
		else
		{	//it is a float Cvar
			new Float:randValue	= GetRandomFloat(minValue, maxValue);
			percentChange = (randValue / GetConVarFloat(hCvar) - 1.0) * proportion;
			SetConVarFloat(hCvar, randValue);
		}
		SetTrieValue(g_hTrieModdedCvars, sArArgs[4], percentChange / proportion, true);	//save offset percent to set new cvars according to this cvar's change
		PushArrayString(g_hArrayModdedCvars, sArArgs[4]);	//and store key in array so we don't lose it! used in the printcvarstats loop, possibly in other things later
	}
	
	
	for (n = 5; n <= args; n++)
	{
		hCvar = FindConVar(sArArgs[n]);
		if (hCvar == INVALID_HANDLE) { continue; }
		
		if (StrContains(sArArgs[0], ".") == -1)	
		{
			new buffer = RoundToNearest(float(GetConVarInt(hCvar)) * (1.0 + percentChange));
			SetConVarInt(hCvar, buffer);
		}
		else 
		{
			new Float:buffer = GetConVarFloat(hCvar) * (1.0 + percentChange);
			SetConVarFloat(hCvar, buffer);
		}
		SetTrieValue(g_hTrieModdedCvars, sArArgs[n], percentChange, true);	//save offset percent to set new cvars according to this cvar's change
		PushArrayString(g_hArrayModdedCvars, sArArgs[n]);	//and store key in array so we don't lose it! and then it takes forever to find and you just know the keys are in the last place you'd think of
	}
}	

public Action:SetIntAtts(args)
{
	decl String:sWeapon[64];
	GetCmdArg(1, sWeapon, sizeof(sWeapon));
	decl String:stmpAttr[64];
	GetCmdArg(2, stmpAttr,sizeof(stmpAttr));	
	decl String:stmpMin[64];
	GetCmdArg(3, stmpMin, sizeof(stmpMin));	
	decl String:stmpMax[64];
	GetCmdArg(4, stmpMax, sizeof(stmpMax));
	
	new minvalue = StringToInt(stmpMin);
	new maxvalue = StringToInt(stmpMax);
	
	new randval = GetRandomInt(minvalue,maxvalue);
	
	g_bIsWeaponModded[GetInt(sWeapon)] = true;
	
	new L4D2IntWeaponAttributes:attr = GetIntAttributeFromString(stmpAttr);	//could check for validity first, but nahh	
	L4D2_SetIntWeaponAttribute(sWeapon, attr, randval);
}

public Action:SetFloatAtts(args)
{
	decl String:sWeapon[64];
	GetCmdArg(1, sWeapon, sizeof(sWeapon));
	decl String:stmpAttr[64];
	GetCmdArg(2, stmpAttr,sizeof(stmpAttr));	
	decl String:stmpMin[64];
	GetCmdArg(3, stmpMin, sizeof(stmpMin));	
	decl String:stmpMax[64];
	GetCmdArg(4, stmpMax, sizeof(stmpMax));
	
	new Float:minvalue = StringToFloat(stmpMin);
	new Float:maxvalue = StringToFloat(stmpMax);
	
	new Float:randval = GetRandomFloat(minvalue,maxvalue);

	new wepid = GetInt(sWeapon);
	g_bIsWeaponModded[wepid] = true;
	
	if (StrEqual(stmpAttr, "spread"))
	{
		WepPrecision[wepid] = randval;
		
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadPerShot, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadPerShot));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxSpread, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxSpread));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadDecay, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadDecay));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinDuckingSpread, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MinDuckingSpread));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinStandingSpread, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MinStandingSpread));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinInAirSpread, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MinInAirSpread));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxMovementSpread, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxMovementSpread));
	}
	else if (StrEqual(stmpAttr, "range"))
	{
		WepRange[wepid] = randval;
		
		new Float:buffer = randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier);
		if (buffer > 1.0)	{ buffer = 1.0; }	//in case > 1.0 was possible, since that would probably make damage increase with distance and that's silly
		
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_Range, randval*L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_Range));
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier, buffer);
	}
	
	return;
}

/*
 * Announcements
 */

public Action:ShowAtts(client, args)
{
	if (GetConVarBool(g_hAnnounceWeapons)){ PrintWeaponStats(client); }
}

public Action:ShowCvars(client, args)
{
	if (GetConVarBool(g_hAnnounceCvars))	{ PrintCvarStats(client); }
}

public OnClientPutInServer(client)
{
	ShowAtts(client, 1);
	ShowCvars(client, 1);
	CreateTimer(5.0,PrintText,client);
}

public Action:PrintText(Handle:unused, any:i)
{
	ShowAtts(i, 1);
	ShowCvars(i, 1);
}

/*
 * Non-standard ClipSize Reload Glitch Semi-fix 
 */

public Action:OnReload(weapon)
{
	decl String:class[56];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (GetEntProp(weapon, Prop_Send, "m_iClip1") == L4D2_GetIntWeaponAttribute(class, L4D2IWA_ClipSize))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sWeapon[WEAPON_LENGTH];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));
	
	if (StrContains(sWeapon,"pistol") ==-1 && StrContains(sWeapon,"melee") ==-1)	
	{
		CreateTimer(0.001,WeaponClipFix,client);
	}
}

public Action:WeaponClipFix(Handle:unused, any:client)
{	
	new weapon = GetPlayerWeaponSlot(client, 0);	
	if (weapon == INVALID_ENT_REFERENCE) return;

	SDKHook(weapon,SDKHook_Reload,OnReload);	//Hook for reload animation glitch semi-fix
	//unhook on weapon drop?
	
	decl String:class[56];
	GetEdictClassname(weapon, class, sizeof(class));
	SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(class, L4D2IWA_ClipSize));
	
	return;
}

/*
 * Attribute Reset
 */

public OnPluginEnd()
{
	ResetAtts(1);
}
 
public Action:ResetAtts(args)
{
	for (new id=0; id<=WP_NUM; id++)
	{
		if (!g_bIsWeaponModded[id]) { continue; }
		
		decl String:sWeapon[WEAPON_LENGTH];
		sWeapon = GetWeapon(id);
		
		L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_Damage, DefaultDamage[id]);
		L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_Damage, GetDefaultBullets(id));
		L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_Damage, GetDefaultClipSize(id));
		
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_Range, DefaultRange[id]);	
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier, DefaultRangeModifier[id]);			
		
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadPerShot, 	 DefaultSpreadPerShot[id]);
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxSpread, 		 DefaultMaxSpread[id]);
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadDecay, 		 DefaultSpreadDecay[id]);
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinDuckingSpread,  DefaultMinDuckingSpread[id]);
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinStandingSpread, DefaultMinStandingSpread[id]);
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinInAirSpread, 	 DefaultMinInAirSpread[id]);
		L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxMovementSpread, DefaultMaxMovementSpread[id]);
	}
}

/*
 * Stocks
 */

 stock PrintCvarStats(i)	
{	
	new size = GetArraySize(g_hArrayModdedCvars);
	if (size >= 1)
	{
		if (GetConVarInt(g_hAnnounceToChat) & 2)	{ PrintToConsole(i, "* *Randomised Cvar Values: * *"); }
		else										{ PrintToChat(i, "* *Randomised Cvar Values: * *"); }
	}
	
	for (new n = 0; n < size; n++)
	{
		decl String: cvarName[64];
		decl String: cvarValue[64];
		
		GetArrayString(g_hArrayModdedCvars, n, cvarName, 64);
		GetConVarString(FindConVar(cvarName), cvarValue, 64);
		
		if (GetConVarInt(g_hAnnounceToChat) & 2)	{ PrintToConsole(i, "%s: %s", cvarName, cvarValue); }
		else										{ PrintToChat(i, "%s: %s", cvarName, cvarValue); }
	}
}
 
stock PrintWeaponStats(i)	
{	
	for (new n = 0; n < WP_NUM; n++)
	{
		static bool:anyModded = false;
		
		if (g_bIsWeaponModded[n])
		{
			if (!anyModded)	//if nothing's been modded, no point even printing the header
			{
				anyModded = true;
				if (GetConVarInt(g_hAnnounceToChat) % 1)	{ PrintToChat(i,"\x05Survivor Weapon Stats:"); }
				else 										{ PrintToConsole(i,"\x05Survivor Weapon Stats:"); }
			}
			
			decl String:weapon[33];
			weapon = GetWeapon(n);
			
			decl String:buffer[48];
			decl String:damageString[48];
			decl String:ammoString[48];
			decl String:spreadString[48];
			decl String:rangeString[48];
			
			new bullets		= L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Bullets);
			new damage		= L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Damage);
			new clipsize	= L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_ClipSize);
			new ammo 		= GetConVarInt(FindConVar(GetAmmoType(n)));
			new Float:percentageDifference;
			new bool:bDamageModded 	= (bullets != GetDefaultBullets(n) || damage != DefaultDamage[n]);
			new bool:bAmmoModded 	= (clipsize != GetDefaultClipSize(n) || ammo != GetDefaultAmmo(n)) && GetConVarBool(g_hAnnounceAmmo);
			new bool:bSpreadModded	= (L4D2_GetFloatWeaponAttribute(weapon, L4D2FWA_SpreadDecay) != DefaultSpreadDecay[n]);
			new bool:bRangeModded	= (L4D2_GetFloatWeaponAttribute(weapon, L4D2FWA_Range) != DefaultRange[n] || L4D2_GetFloatWeaponAttribute(weapon, L4D2FWA_RangeModifier) != DefaultRangeModifier[n]);			
			
			//in case nothing besides ammo has been changed and ammo is hidden
			if (!bDamageModded && !bSpreadModded && !bRangeModded && !bAmmoModded)	{ continue; }
			
			//format announcement according to what's been changed
			if (bDamageModded)			
			{
				damageString = "\x01Dmg: \x03";
				if (StrContains(weapon, "shotgun") != -1)
				{
					IntToString(bullets, buffer, sizeof(buffer));
					StrCat(damageString, sizeof(damageString), buffer);
					StrCat(damageString, sizeof(damageString), "*");					
				}
				IntToString(damage, buffer, sizeof(buffer));
				StrCat(damageString, sizeof(damageString), buffer);
				
				percentageDifference = float(L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Bullets)*L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Damage))*100.0/float(DefaultDamage[n]);
				FloatToString(percentageDifference, buffer, 3);
				StrCat(damageString, sizeof(damageString), "\x01(\x04");
				StrCat(damageString, sizeof(damageString), buffer);
				StrCat(damageString, sizeof(damageString), "%%\x01); ");				
			}
			
			if (bAmmoModded)
			{
				ammoString = "Ammo: \x03";
				IntToString(clipsize, buffer, sizeof(buffer));
				StrCat(ammoString, sizeof(ammoString), buffer);
				StrCat(ammoString, sizeof(ammoString), "/");
				IntToString(ammo, buffer, sizeof(buffer));
				StrCat(ammoString, sizeof(ammoString), buffer);
				StrCat(ammoString, sizeof(ammoString), "\x01; ");
			}
			
			if (bSpreadModded)
			{
				spreadString = "Spread: \x04";
				
				percentageDifference = WepPrecision[n]*100.0;
				FloatToString(percentageDifference, buffer, 3);
				StrCat(damageString, sizeof(damageString), buffer);
				StrCat(damageString, sizeof(damageString), "%%\x01; ");
			}

			if (bRangeModded)
			{
				rangeString = "Range: \x04";
				
				percentageDifference = WepRange[n]*100.0;
				FloatToString(percentageDifference, buffer, 3);
				StrCat(rangeString, sizeof(rangeString), buffer);
				StrCat(rangeString, sizeof(rangeString), "%%\x01;");
			}
			//end announcement formatting
			
			
			if (GetConVarInt(g_hAnnounceToChat) & 1)		//announce!
			{
				PrintToChat(i,"\x05%s: %s%s%s%s",
					GetShortName(weapon),
					bDamageModded	? damageString	: "",
					bAmmoModded		? ammoString	: "",
					bSpreadModded	? spreadString	: "",
					bRangeModded	? rangeString	: "");
			}
			else
			{
				PrintToConsole(i,"\x05%s: %s%s%s%s",
					GetShortName(weapon),
					bDamageModded	? damageString	: "",
					bAmmoModded		? ammoString	: "",
					bSpreadModded	? spreadString	: "",
					bRangeModded	? rangeString	: "");				
			}			
		}
	}
	return;
 }
 
stock L4D2IntWeaponAttributes:GetIntAttributeFromString(const String:buffer[])
{
	if(StrEqual(buffer,"damage")) 	{return L4D2IWA_Damage;}
	if(StrEqual(buffer,"clipsize"))	{return L4D2IWA_ClipSize;}
	return L4D2IWA_Bullets;
}

//associates a weapon index with its respective ammo Cvar, for chat printing
stock String:GetAmmoType(wp_index)
{
	decl String:ammo_type[22];
	switch (wp_index)
	{
		case WP_SMG, WP_SMG_SILENCED, WP_SMG_MP5: 			{ammo_type = "ammo_smg_max";}	
		case WP_PUMPSHOTGUN, WP_SHOTGUN_CHROME: 			{ammo_type = "ammo_shotgun_max";}	
		case WP_AUTOSHOTGUN, WP_SHOTGUN_SPAS:				{ammo_type = "ammo_autoshotgun_max";}
		case WP_HUNTING_RIFLE:						{ammo_type = "ammo_huntingrifle_max";}
		case WP_SNIPER_MILITARY, WP_SNIPER_AWP, WP_SNIPER_SCOUT:	{ammo_type = "ammo_sniperrifle_max";}
		case WP_RIFLE, WP_RIFLE_AK47, WP_RIFLE_DESERT, WP_RIFLE_SG552:	{ammo_type = "ammo_assaultrifle_max";}
	}
	return ammo_type;
}

stock GetDefaultAmmo(wp_index)
{
	new ammo = -1;
	switch (wp_index)
	{
		case WP_SMG, WP_SMG_SILENCED, WP_SMG_MP5: 			{ammo = 650;}	
		case WP_PUMPSHOTGUN, WP_SHOTGUN_CHROME:				{ammo = 80;}	
		case WP_AUTOSHOTGUN, WP_SHOTGUN_SPAS:				{ammo = 90;}
		case WP_HUNTING_RIFLE:						{ammo = 150;}
		case WP_SNIPER_MILITARY, WP_SNIPER_AWP, WP_SNIPER_SCOUT:	{ammo = 180;}
		case WP_RIFLE, WP_RIFLE_AK47, WP_RIFLE_DESERT, WP_RIFLE_SG552:	{ammo = 360;}
	}
	return ammo;
}

//returns an integer id associated with a particular weapon; for use with arrays and whatnot
stock GetInt(const String:weapon[])
{
	if (StrEqual(weapon,"weapon_smg",false)) 				{return WP_SMG;}
	if (StrEqual(weapon,"weapon_smg_silenced",false)) 		{return WP_SMG_SILENCED;}
	if (StrEqual(weapon,"weapon_smg_mp5",false)) 			{return WP_SMG_MP5;}	
	if (StrEqual(weapon,"weapon_pistol",false)) 			{return WP_PISTOL;}
	if (StrEqual(weapon,"weapon_pitstol_magnum",false)) 	{return WP_PISTOL_MAGNUM;}
	if (StrEqual(weapon,"weapon_pumpshotgun",false)) 		{return WP_PUMPSHOTGUN;}
	if (StrEqual(weapon,"weapon_shotgun_chrome",false)) 	{return WP_SHOTGUN_CHROME;}
	if (StrEqual(weapon,"weapon_autoshotgun",false)) 		{return WP_AUTOSHOTGUN;}
	if (StrEqual(weapon,"weapon_shotgun_spas",false)) 		{return WP_SHOTGUN_SPAS;}	
	if (StrEqual(weapon,"weapon_hunting_rifle",false)) 		{return WP_HUNTING_RIFLE;}
	if (StrEqual(weapon,"weapon_sniper_military",false)) 	{return WP_SNIPER_MILITARY;}
	if (StrEqual(weapon,"weapon_sniper_awp",false)) 		{return WP_SNIPER_AWP;}
	if (StrEqual(weapon,"weapon_sniper_scout",false)) 		{return WP_SNIPER_SCOUT;}	
	if (StrEqual(weapon,"weapon_melee",false)) 				{return WP_MELEE;}
	if (StrEqual(weapon,"weapon_rifle",false)) 				{return WP_RIFLE;}
	if (StrEqual(weapon,"weapon_rifle_ak47",false)) 		{return WP_RIFLE_AK47;}
	if (StrEqual(weapon,"weapon_rifle_desert",false)) 		{return WP_RIFLE_DESERT;}
	if (StrEqual(weapon,"weapon_rifle_sg552",false)) 		{return WP_RIFLE_SG552;}
	return 0; // if none of the above, data has no meaning
}

//inverse function of GetInt
stock String:GetWeapon(int)
{
	new String:buffer[WEAPON_LENGTH] = "no_weapon";
	switch (int)
	{
		case WP_SMG: 				{buffer = "weapon_smg";}	
		case WP_SMG_SILENCED: 		{buffer = "weapon_smg_silenced";}
		case WP_PISTOL: 			{buffer = "weapon_pistol";}	
		case WP_PISTOL_MAGNUM: 		{buffer = "weapon_pistol_magnum";}	
		case WP_PUMPSHOTGUN: 		{buffer = "weapon_pumpshotgun";}	
		case WP_SHOTGUN_CHROME: 	{buffer = "weapon_shotgun_chrome";}
		case WP_AUTOSHOTGUN:		{buffer = "weapon_autoshotgun";}
		case WP_SHOTGUN_SPAS:		{buffer = "weapon_shotgun_spas";}
		case WP_HUNTING_RIFLE:		{buffer = "weapon_hunting_rifle";}
		case WP_SNIPER_MILITARY:	{buffer = "weapon_sniper_military";}
		case WP_SNIPER_AWP:			{buffer = "weapon_sniper_awp";}
		case WP_SNIPER_SCOUT:		{buffer = "weapon_sniper_scout";}
		case WP_MELEE:				{buffer = "weapon_melee";}
		case WP_RIFLE:				{buffer = "weapon_rifle";}
		case WP_RIFLE_AK47:			{buffer = "weapon_rifle_ak47";}
		case WP_RIFLE_DESERT:		{buffer = "weapon_rifle_desert";}
		case WP_RIFLE_SG552:		{buffer = "weapon_rifle_sg552";}
	}
	return buffer;
}

//to save space and make it look nicer
stock String:GetShortName(const String:weapon[])
{
	new String:buff[7] = "waffle";
	if (StrEqual(weapon,"weapon_smg",false)) 				{buff = "SMG";}
	if (StrEqual(weapon,"weapon_smg_silenced",false)) 		{buff = "Si.SMG";}
	if (StrEqual(weapon,"weapon_smg_mp5",false)) 			{buff = "MP5";}	
	if (StrEqual(weapon,"weapon_pistol",false)) 			{buff = "Pistol";}
	if (StrEqual(weapon,"weapon_pitstol_magnum",false)) 	{buff = "Magnum";}
	if (StrEqual(weapon,"weapon_pumpshotgun",false)) 		{buff = "Pump";}
	if (StrEqual(weapon,"weapon_shotgun_chrome",false)) 	{buff = "Chrome";}
	if (StrEqual(weapon,"weapon_autoshotgun",false)) 		{buff = "AutoSG";}
	if (StrEqual(weapon,"weapon_shotgun_spas",false)) 		{buff = "SPAS";}	
	if (StrEqual(weapon,"weapon_hunting_rifle",false)) 		{buff = "HR";}
	if (StrEqual(weapon,"weapon_sniper_military",false)) 	{buff = "Sniper";}
	if (StrEqual(weapon,"weapon_sniper_awp",false)) 		{buff = "AWP";}
	if (StrEqual(weapon,"weapon_sniper_scout",false)) 		{buff = "Scout";}	
	if (StrEqual(weapon,"weapon_melee",false)) 				{buff = "Melee";}
	if (StrEqual(weapon,"weapon_rifle",false)) 				{buff = "M16";}
	if (StrEqual(weapon,"weapon_rifle_ak47",false)) 		{buff = "AK47";}
	if (StrEqual(weapon,"weapon_rifle_desert",false)) 		{buff = "SCAR";}
	if (StrEqual(weapon,"weapon_rifle_sg552",false)) 		{buff = "SG552";}	
	return buff;
}

//for resetting
stock GetDefaultBullets(id)
{
	new buffer = 1;
	switch (id)
	{
		case WP_PUMPSHOTGUN:	{buffer = PELLETS_PMP;}
		case WP_SHOTGUN_CHROME:	{buffer = PELLETS_CRM;}
		case WP_AUTOSHOTGUN:	{buffer = PELLETS_AS; }
		case WP_SHOTGUN_SPAS:	{buffer = PELLETS_SPA;}
	}
	return buffer;
}

//for resetting
stock GetDefaultClipSize(id)
{
	new buffer = CLIPSIZE_BASIC;
	switch (id)
	{
		case WP_PUMPSHOTGUN, WP_SHOTGUN_CHROME:	{buffer = CLIPSIZE_T1SG;}
		case WP_AUTOSHOTGUN, WP_SHOTGUN_SPAS:	{buffer = CLIPSIZE_T2SG;}
		case WP_RIFLE_AK47:						{buffer = CLIPSIZE_AK;}
		case WP_RIFLE_DESERT:					{buffer = CLIPSIZE_SCAR;}
		case WP_HUNTING_RIFLE, WP_SNIPER_SCOUT:	{buffer = CLIPSIZE_HR;}
		case WP_SNIPER_MILITARY:				{buffer = CLIPSIZE_SNIPER;}
		case WP_SNIPER_AWP:						{buffer = CLIPSIZE_AWP;}
	}
	return buffer;
}



