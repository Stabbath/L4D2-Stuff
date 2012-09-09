#pragma semicolon 1	

/* Randomised cvar stuff
 * Syntax:
 * random_cvar <proportion> <minvalue> <maxvalue> <Cvar1> <Cvar2> <Cvar3> <...>
 * Plugin will select a random number for Cvar1 between minvalue and maxvalue, and scale all the following Cvars. 
 * The % that Cvar1 is increased will be stored and multiplied by the proportion, and Cvar2, Cvar3, etc will be increased or decreased by this percentage of their default value.
 * For simple direct and inverse proportion, just use "1.0" and "-1.0".
 * If Cvar1 is already defined and it's the only cvar listed, it'll be re-randomised.
 * If Cvar1 is already defined and there's other cvars listed, it will skip the randomisation of Cvar1 and go straight to the scaling of the rest.
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
 * 0.4.1
 * - Changed announcement code so that console prints will no longer have the colour characters.
 * - Added a loop to get the data for the default attribute arrays from the server on plugin start instead of having them pre-defined. It's so much neater and shorter now.
 * - Made it so that cvars can be re-randomised now, by using only a single cvar argument for the already-randomised cvar. Using several will still scale them according to that cvar.
 */
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <float>
#include <l4d2weapons.inc>

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

//highest actual weapon id + 1
#define WP_NUM 37

#define NUMBER_LENGTH	16
#define WEAPON_LENGTH	32
#define BUFFER_LENGTH	48

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
	version = "0.4.1",
	url = "no url"
}

new Float:WepPrecision[WP_NUM];
new Float:WepRange[WP_NUM];

new DefaultDamage[WP_NUM];
new Float:DefaultSpreadPerShot[WP_NUM];
new Float:DefaultMaxSpread[WP_NUM];
new Float:DefaultSpreadDecay[WP_NUM];
new Float:DefaultMinDuckingSpread[WP_NUM];
new Float:DefaultMinStandingSpread[WP_NUM];
new Float:DefaultMinInAirSpread[WP_NUM];
new Float:DefaultMaxMovementSpread[WP_NUM];
new Float:DefaultRange[WP_NUM];
new Float:DefaultRangeModifier[WP_NUM];

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
	g_hAnnounceWeapons= CreateConVar(	"random_announce_weapons",	"1",		"Should the plugin be allowed to announce changes for all modified weapons?", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//hide clipsize/ammo info from announcement?
	g_hAnnounceAmmo	= CreateConVar(		"random_announce_ammo",		"1",		"If 0, will hide ammo and clipsize info for all weapons even if there have been changes to them.", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//should Cvar changes be announced?
	g_hAnnounceCvars	= CreateConVar(	"random_announce_cvars",	"1",		"Should the plugin be allowed to announce changes for all modified Cvars?", FCVAR_PLUGIN, true, 	0.0, true, 1.0);
	//should on-connect announcements be sent to chat? 0 sends to console
	g_hAnnounceToChat	= CreateConVar(	"random_announce_to_chat",	"1",		"Should the plugin send announcements to chat? If not, sends to console. Flags: 1 - send weapon stats to chat, 2 - send cvar stats to chat.", FCVAR_PLUGIN, true, 	0.0, true, 1.0);
	//should the stats be re-randomised every map?
//	hReRandom		= CreateConVar(		"random_mod_everymap",		"1",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//include melee attribute randomisation?
//	hModMelee		= CreateConVar(		"random_mod_melee",			"0",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//include m2 delay and penalty randomisation?
//	hModShove		= CreateConVar(		"random_mod_shove",			"0",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);
	//limits the maximum number of different modded weapons in the game to this number. 0 means no limit
//	hWepLimit		= CreateConVar(		"random_limit_weapons",		"0",		"nondescript", FCVAR_PLUGIN, true,  0.0, true, 10.0);
	
	for (new n = 1; n < WP_NUM; n++)
	{
		if (!IsItAnActualWeapon(n)) { continue; }
		
		decl String:sWeapon[WEAPON_LENGTH];
		sWeapon = GetWeapon(n);
		
		//Store default values for everything from current attributes (ClipSize and Bullets are still done through functions though)
		DefaultDamage[n]			=	L4D2_GetIntWeaponAttribute(sWeapon, L4D2IWA_Damage);
		DefaultMaxMovementSpread[n]	=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxMovementSpread	);
		DefaultMaxSpread[n]			=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxSpread			);
		DefaultMinDuckingSpread[n]	=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MinDuckingSpread	);
		DefaultMinInAirSpread[n]	=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MinInAirSpread	);
		DefaultMinStandingSpread[n]	=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MinStandingSpread	);
		DefaultRange[n]				=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_Range				);
		DefaultRangeModifier[n]		=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier		);
		DefaultSpreadDecay[n]		=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadDecay		);
		DefaultSpreadPerShot[n]		=	L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadPerShot		);
		
		//take care of precision and range arrays
		WepPrecision[n] = 1.0;
		WepRange[n] = 1.0;
	}
	
	g_hArrayModdedCvars	= CreateArray(BUFFER_LENGTH);
	g_hTrieModdedCvars	= CreateTrie();
	
	RegServerCmd ("random_setiwa",		SetIntAtts);
	RegServerCmd ("random_setfwa",		SetFloatAtts);
	RegServerCmd ("random_resetatts",	ResetAtts);
	RegServerCmd ("random_setcvar",		SetCvar);
	RegServerCmd ("random_resetcvars",	ResetCvars);
	RegConsoleCmd("random_showatts", 	ShowAtts);
	RegConsoleCmd("random_showcvars", 	ShowCvars);
	
	HookEvent("item_pickup",Event_ItemPickup);	//weapon_pickup doesnt fire ever
}

public Action:SetCvar(args)
{	
	if (args < 4)	{ return; }
	
	decl n;	//used in loops
	decl String:sArArgs[args + 1][BUFFER_LENGTH];
	for (n = 1; n <= args; n++)	{ GetCmdArg(n, sArArgs[n], BUFFER_LENGTH); }	
	
	new Float:	proportion= StringToFloat(sArArgs[1]);
	new Float:	minValue  = StringToFloat(sArArgs[2]);
	new Float:	maxValue  = StringToFloat(sArArgs[3]);
	new Float:	percentChange;
	
	new Handle:	hCvar = FindConVar(sArArgs[4]);
	if (hCvar == INVALID_HANDLE) { return; }
	
	GetConVarString(hCvar, sArArgs[0], BUFFER_LENGTH);	//index 0 is otherwise unused, save Cvar value as string here
	
	if (GetTrieValue(g_hTrieModdedCvars, sArArgs[0], percentChange))	//means this cvar's already been randomised, store its current variation into percentChange 
	{																	//to correct thew new percentChange based on the cvar's default, rather than the previous randomised value
		if (args == 4)	//only 1 cvar argument, let's re-randomise that cvar
		{
			if (StrContains(sArArgs[0], ".") == -1)
			{	//it's not a float Cvar
				new randValue	= GetRandomInt(RoundToNearest(minValue), RoundToNearest(maxValue));
				percentChange = (float(randValue) / (float(GetConVarInt(hCvar)) * (1.0 + percentChange)) - 1.0) * proportion;
				SetConVarInt(hCvar, randValue);
			}
			else
			{	//it is a float Cvar
				new Float:randValue	= GetRandomFloat(minValue, maxValue);
				percentChange = (randValue / (GetConVarFloat(hCvar) * (1.0 + percentChange))- 1.0) * proportion;
				SetConVarFloat(hCvar, randValue);
			}
			SetTrieValue(g_hTrieModdedCvars, sArArgs[4], percentChange / proportion, true);	//save offset percent to set new cvars according to this cvar's change
			PushArrayString(g_hArrayModdedCvars, sArArgs[4]);	//and store key in array so we don't lose it! used in the printcvarstats loop, possibly in other things later
		}
		else	//several cvar arguments, let's use the first one to scale the rest
		{
			percentChange *= proportion;
		}
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
	decl String:sWeapon[WEAPON_LENGTH];
	GetCmdArg(1, sWeapon, sizeof(sWeapon));
	decl String:stmpAttr[NUMBER_LENGTH];
	GetCmdArg(2, stmpAttr,sizeof(stmpAttr));	
	decl String:stmpMin[NUMBER_LENGTH];
	GetCmdArg(3, stmpMin, sizeof(stmpMin));	
	decl String:stmpMax[NUMBER_LENGTH];
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
	decl String:sWeapon[WEAPON_LENGTH];
	GetCmdArg(1, sWeapon, sizeof(sWeapon));
	decl String:stmpAttr[NUMBER_LENGTH];
	GetCmdArg(2, stmpAttr,sizeof(stmpAttr));	
	decl String:stmpMin[NUMBER_LENGTH];
	GetCmdArg(3, stmpMin, sizeof(stmpMin));	
	decl String:stmpMax[NUMBER_LENGTH];
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
	decl String:class[BUFFER_LENGTH];
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
	
	decl String:class[BUFFER_LENGTH];
	GetEdictClassname(weapon, class, sizeof(class));
	SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(class, L4D2IWA_ClipSize));
	
	return;
}

/*
 * Attribute and Cvar Reset
 */

public OnPluginEnd()
{
	ResetAtts(1);
	ResetCvars(1);
}

public Action:ResetCvars(args)
{	
	decl String:sCvarName[BUFFER_LENGTH], String:sCvarValue[BUFFER_LENGTH];
	decl Float: value;	//used to store the percentChange from the trie
	new  Handle: hCvar = INVALID_HANDLE;

	new size = GetArraySize(g_hArrayModdedCvars);
	for (new n = 0; n < size; n++)
	{
		GetArrayString(g_hArrayModdedCvars, n, sCvarName, BUFFER_LENGTH);
		GetTrieValue(g_hTrieModdedCvars, sCvarName, value);
		
		hCvar = FindConVar(sCvarName);
		if (hCvar == INVALID_HANDLE) { return; }	//invalid cvars won't be stored into the trie since this check is done while setting them, but you never know

		GetConVarString(hCvar, sCvarValue, BUFFER_LENGTH);	//index 0 is otherwise unused, save Cvar value as string here
		
		if (StrContains(sCvarValue, ".") == -1)
		{	//it's not a float Cvar
			SetConVarInt(hCvar, RoundToNearest(GetConVarInt(hCvar) / (1.0 + value)));
		}
		else
		{	//it is a float Cvar
			SetConVarFloat(hCvar, GetConVarFloat(hCvar) / (1.0 + value));
		}
	}
	ClearTrie(g_hTrieModdedCvars);
	ClearArray(g_hArrayModdedCvars);	
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
		decl String: cvarName[BUFFER_LENGTH];
		decl String: cvarValue[NUMBER_LENGTH];
		
		GetArrayString(g_hArrayModdedCvars, n, cvarName, BUFFER_LENGTH);
		GetConVarString(FindConVar(cvarName), cvarValue, NUMBER_LENGTH);
		
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
			
			decl String:weapon[WEAPON_LENGTH];
			weapon = GetWeapon(n);
			
			decl String:buffer[BUFFER_LENGTH];
			decl String:damageString[BUFFER_LENGTH];
			decl String:ammoString[BUFFER_LENGTH];
			decl String:spreadString[BUFFER_LENGTH];
			decl String:rangeString[BUFFER_LENGTH];
			
			new bullets		= L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Bullets);
			new damage		= L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Damage);
			new clipsize	= L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_ClipSize);
			new ammo 		= GetConVarInt(FindConVar(GetAmmoType(n)));
			new Float:percentageDifference;

			new bool:bDamageModded 	= (bullets != GetDefaultBullets(n) || damage != DefaultDamage[n]);
			new bool:bAmmoModded 	= (clipsize != GetDefaultClipSize(n) || ammo != GetDefaultAmmo(n)) && GetConVarBool(g_hAnnounceAmmo);
			new bool:bSpreadModded	= (L4D2_GetFloatWeaponAttribute(weapon, L4D2FWA_SpreadDecay) != DefaultSpreadDecay[n]);
			new bool:bRangeModded	= (L4D2_GetFloatWeaponAttribute(weapon, L4D2FWA_Range) != DefaultRange[n] || L4D2_GetFloatWeaponAttribute(weapon, L4D2FWA_RangeModifier) != DefaultRangeModifier[n]);			
			
			new bool:bToChat = bool:(GetConVarInt(g_hAnnounceToChat) & 1);
			
			//in case nothing besides ammo has been changed and ammo is hidden
			if (!bDamageModded && !bSpreadModded && !bRangeModded && !bAmmoModded)	{ continue; }
			
			//format announcement according to what's been changed
			if (bDamageModded)			
			{
				if (bToChat)	{ damageString = "\x01Dmg: \x03"; }
				else			{ damageString = "Dmg: "; }	
				
				if (StrContains(weapon, "shotgun") != -1)
				{
					IntToString(bullets, buffer, sizeof(buffer));
					StrCat(damageString, sizeof(damageString), buffer);
					StrCat(damageString, sizeof(damageString), "*");					
				}
				IntToString(damage, buffer, sizeof(buffer));
				StrCat(damageString, sizeof(damageString), buffer);
				
				if (bToChat)	{ StrCat(damageString, sizeof(damageString), "\x01(\x04"); }
				else			{ StrCat(damageString, sizeof(damageString), "("); }	
				
				percentageDifference = float(L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Bullets)*L4D2_GetIntWeaponAttribute(weapon, L4D2IWA_Damage))*100.0/float(DefaultDamage[n]);
				FloatToString(percentageDifference, buffer, 3);
				StrCat(damageString, sizeof(damageString), buffer);

				if (bToChat)	{ StrCat(damageString, sizeof(damageString), "%%\x01); "); }
				else			{ StrCat(damageString, sizeof(damageString), "%%); "); }
			}
			
			if (bAmmoModded)
			{
				if (bToChat)	{ ammoString = "Ammo: \x03"; }
				else			{ ammoString = "Ammo: "; }
				
				IntToString(clipsize, buffer, sizeof(buffer));
				StrCat(ammoString, sizeof(ammoString), buffer);
				StrCat(ammoString, sizeof(ammoString), "/");
				IntToString(ammo, buffer, sizeof(buffer));
				StrCat(ammoString, sizeof(ammoString), buffer);
				if (bToChat)	{ StrCat(ammoString, sizeof(ammoString), "\x01; "); }
				else			{ StrCat(ammoString, sizeof(ammoString), "; "); }
			}
			
			if (bSpreadModded)
			{
				if (bToChat)	{ spreadString = "Spread: \x04"; }
				else			{ spreadString = "Spread: "; }
				
				percentageDifference = WepPrecision[n]*100.0;
				FloatToString(percentageDifference, buffer, 3);
				StrCat(damageString, sizeof(damageString), buffer);
				
				if (bToChat)	{ StrCat(damageString, sizeof(damageString), "%%\x01; "); }
				else			{ StrCat(damageString, sizeof(damageString), "%%; "); }
			}

			if (bRangeModded)
			{
				if (bToChat) 	{ rangeString = "Range: \x04"; }
				else	 		{ rangeString = "Range: "; }
				
				percentageDifference = WepRange[n]*100.0;
				FloatToString(percentageDifference, buffer, 3);
				StrCat(rangeString, sizeof(rangeString), buffer);
				if (bToChat)	{ StrCat(rangeString, sizeof(rangeString), "%%\x01;"); }
				else			{ StrCat(rangeString, sizeof(rangeString), "%%;"); }				
			}
			//end announcement formatting
			
			
			if (bToChat)		//announce!
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
				PrintToConsole(i,"%s: %s%s%s%s",
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
		case WP_SMG, WP_SMG_SILENCED, WP_SMG_MP5: 						{ammo_type = "ammo_smg_max";}	
		case WP_PUMPSHOTGUN, WP_SHOTGUN_CHROME: 						{ammo_type = "ammo_shotgun_max";}	
		case WP_AUTOSHOTGUN, WP_SHOTGUN_SPAS:							{ammo_type = "ammo_autoshotgun_max";}
		case WP_HUNTING_RIFLE:											{ammo_type = "ammo_huntingrifle_max";}
		case WP_SNIPER_MILITARY, WP_SNIPER_AWP, WP_SNIPER_SCOUT:		{ammo_type = "ammo_sniperrifle_max";}
		case WP_RIFLE, WP_RIFLE_AK47, WP_RIFLE_DESERT, WP_RIFLE_SG552:	{ammo_type = "ammo_assaultrifle_max";}
	}
	return ammo_type;
}

stock GetDefaultAmmo(wp_index)
{
	new ammo = -1;
	switch (wp_index)
	{
		case WP_SMG, WP_SMG_SILENCED, WP_SMG_MP5: 						{ammo = 650;}	
		case WP_PUMPSHOTGUN, WP_SHOTGUN_CHROME:							{ammo = 80;}	
		case WP_AUTOSHOTGUN, WP_SHOTGUN_SPAS:							{ammo = 90;}
		case WP_HUNTING_RIFLE:											{ammo = 150;}
		case WP_SNIPER_MILITARY, WP_SNIPER_AWP, WP_SNIPER_SCOUT:		{ammo = 180;}
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

stock bool:IsItAnActualWeapon(id)
{
	if ((id >= 1 && id <= 11) || (id == 19) || (id == 26) || (id >= 32 && id <= 36))	{ return true; }
	return false;	
}


