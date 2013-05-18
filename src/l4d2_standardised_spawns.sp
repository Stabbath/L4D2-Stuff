#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2util_rounds>

#define TEAM_INFECTED 3

#define SI_COUNT	0
#define ZC_SMOKER	1
#define ZC_BOOMER	2
#define ZC_HUNTER	3
#define ZC_SPITTER	4
#define ZC_JOCKEY	5
#define ZC_CHARGER	6
#define	ARRAYSIZE	7

/*
 * To-do:
 * - Tenacity special sack system.
 */

public Plugin:myinfo = 
{
	name = "Left 4 Dead 2 Standardised Spawns",
	author = "Stabby",
	description = "Makes it so sack order always does what you expect/want it to.",
	version = "0.2.1",
	url = "none"
}

new Handle:	hArrayZCs = INVALID_HANDLE;	//FIFO list implemented via adt_array or whatever
new Handle:	hArrayCrossroundBuffer = INVALID_HANDLE;	//FIFO list to which the starting spawn attributions are loaded, to keep them the same for both teams

new Handle:	hSDKCallSetClass = INVALID_HANDLE;		//sdkcall for changing si class
new Handle:	hArCvar[ARRAYSIZE] = INVALID_HANDLE;	//cvar array for z_versus_<class>_limit's 

new Handle: hTHISISACVARLOL;

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(LoadGameConfigFile("l4d2_random"), SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSDKCallSetClass = EndPrepSDKCall();
	
	hArrayZCs = CreateArray();
	hArrayCrossroundBuffer = CreateArray();
	
	hTHISISACVARLOL = CreateConVar("bitch_turn_off_that_debug", "0");
	
	hArCvar[ZC_BOOMER] = FindConVar("z_versus_boomer_limit");
	hArCvar[ZC_SMOKER] = FindConVar("z_versus_smoker_limit");
	hArCvar[ZC_CHARGER] = FindConVar("z_versus_charger_limit");
	hArCvar[ZC_SPITTER] = FindConVar("z_versus_spitter_limit");
	hArCvar[ZC_HUNTER] = FindConVar("z_versus_hunter_limit");
	hArCvar[ZC_JOCKEY] = FindConVar("z_versus_jockey_limit");
}

public L4D_OnEnterGhostState(client)	//replaces class of player with the bottom of the list, and removes it from the list
{
	new buf = GetArrayCell(hArrayZCs, 0);
	if (!GetConVarBool(hTHISISACVARLOL)) PrintToChat(client, "You've entered ghost state: you should be a %s.", buf == 1 ? "smoker" : buf == 2 ? "boomer" : buf == 3 ? "hunter" : buf == 4 ? "spitter" : buf == 5 ? "jockey" : buf == 6 ? "charger" : "wtf");
	SDKCall(hSDKCallSetClass, client, GetArrayCell(hArrayZCs, 0));
	RemoveFromArray(hArrayZCs, 0);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= MaxClients)
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			PushArrayCell(hArrayZCs, GetEntProp(client, Prop_Send, "m_zombieClass"));
		}
	}
}

public OnRoundStart() {
	ClearArray(hArrayZCs);
	new size = GetArraySize(hArrayCrossroundBuffer);
	for (new i = 0; i < size; i++) {
		PushArrayCell(hArrayZCs, GetArrayCell(hArrayCrossroundBuffer, i));
	}
}

public OnMapStart() {
	ClearArray(hArrayZCs);
	ClearArray(hArrayCrossroundBuffer);

	//add all instances of usable ZCs to this array
	//e.g. if there's a limit of 2 to every ZC, add each ZC twice
	new Handle:hArrayZCInstances = CreateArray();	//buffer array pre-randomisation
	for (new i = 1; i < ARRAYSIZE; i++) {
		for (new j = 0; j < GetConVarInt(hArCvar[i]); j++) {
			PushArrayCell(hArrayZCInstances, i);
		}
	}
	
	new size, i;
	while ((size = GetArraySize(hArrayZCInstances)) > 0) {
		i = GetRandomInt(0, size - 1);
		PushArrayCell(hArrayZCs, i);
		PushArrayCell(hArrayCrossroundBuffer, i);
		RemoveFromArray(hArrayZCInstances, i);
	}
}

stock GetSumOfZLimits()
{
	new count = 0;
	for (new zc = 1; zc <= ZC_CHARGER; zc++)
	{
		count += GetConVarInt(hArCvar[zc]);
	}
	return count;
}
