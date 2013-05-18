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
#define	ARRAY_SIZE	7

stock String:getzcname(z) {
	switch (z) {
		case 1:	{ return "smoker"; }
		case 2:	{ return "boomer"; }
		case 3:	{ return "hunter"; }
		case 4:	{ return "spitter"; }
		case 5:	{ return "jockey"; }
		case 6:	{ return "charger"; }
	}
	return "wtf";
}

/*
 * To-do:
 * - Tenacity special sack system.
 */

public Plugin:myinfo = 
{
	name = "Left 4 Dead 2 Standardised Spawns",
	author = "Stabby",
	description = "Makes it so sack order always does what you expect/want it to.",
	version = "0.2",
	url = "none"
}

new Handle:	hQueueZCs = INVALID_HANDLE;	//FIFO list implemented via adt_array or whatever
new Handle:	hQueueCrossroundBuffer = INVALID_HANDLE;	//FIFO list to which the starting spawn attributions are loaded, to keep them the same for both teams
new Handle:	hSDKCallSetClass = INVALID_HANDLE;		//sdkcall for changing si class
new Handle:	hArCvar[ARRAY_SIZE] = INVALID_HANDLE;	//cvar array for z_versus_<class>_limit's 

new Handle: hTHISISACVARLOL;

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(LoadGameConfigFile("l4d2_random"), SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSDKCallSetClass = EndPrepSDKCall();
	
	hQueueZCs = CreateArray();
	hQueueCrossroundBuffer = CreateArray();
	
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
	if (!GetConVarBool(hTHISISACVARLOL)) PrintToChat(client, "You've entered ghost state: you should be a %s.", getzcname(GetArrayCell(hQueueZCs, 0)));
	SDKCall(hSDKCallSetClass, client, GetArrayCell(hQueueZCs, 0));
	RemoveFromArray(hQueueZCs, 0);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)	//pushes the zc of the dying player
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= MaxClients)
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			PushArrayCell(hQueueZCs, GetEntProp(client, Prop_Send, "m_zombieClass"));
		}
	}
}

public OnRoundStart() {
	ClearArray(hQueueZCs);
	new size = GetArraySize(hQueueCrossroundBuffer);
	for (new i = 0; i < size; i++) {
		PushArrayCell(hQueueZCs, GetArrayCell(hQueueCrossroundBuffer, i));
	}
}

public OnMapStart() {	//pushes all instances of all classes to the list in a random order
	ClearArray(hQueueZCs);
	ClearArray(hQueueCrossroundBuffer);

	new Handle:hArray = CreateArray();	//copy of hArCvar
	new i;
	
	for (i = 1; i < ARRAYSIZE; i++) {
		if (GetConVarInt(hArCvar[i]) > 0) PushArrayCell(hArray, hArCvar[i]);
	}
	
	new Handle:hZCIndexes = CreateArray();
	for (i = 0; i < ARRAYSIZE; i++) PushArrayCell(hZCIndexes, i);
	
	new spawnsAdded[ARRAYSIZE];
	new size;
	while ((size = GetArraySize(hArray)) > 0) {
		i = GetRandomInt(0, size - 1);
		if (spawnsAdded[i] < GetConVarInt(hArCvar[i])) {
			PushArrayCell(hQueueCrossroundBuffer, hZCIndexes[i]);
			spawnsAdded[i]++;
		} else {
			new index = FindValueInArray(hArray, hArCvar[i]);
			RemoveFromArray(hArray, index);
			RemoveFromArray(hZCIndexes, index);
		}
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
