#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define TEAM_INFECTED 3

#define SI_COUNT	0
#define ZC_SMOKER	1
#define ZC_BOOMER	2
#define ZC_HUNTER	3
#define ZC_SPITTER	4
#define ZC_JOCKEY	5
#define ZC_CHARGER	6
#define	ARRAY_SIZE	7

/*
 * To-do:
 * - Calamity special sack system.
 * - maybe make it so that the initial X spawns are the same (X = sum of limits for all si), rather than it just being the first 4. Or does the game already do that?
 */

public Plugin:myinfo = 
{
	name = "Left 4 Dead 2 Standardised Spawns",
	author = "Stabby",
	description = "Makes it so sack order always does what you expect/want it to.",
	version = "0.1",
	url = "none"
}

new Handle:	hArrayZombieClasses = INVALID_HANDLE;
new Handle: hSDKCallSetClass = INVALID_HANDLE;
new Handle: hArCvar[ARRAY_SIZE] = INVALID_HANDLE;
new			iArSavedSpawns[ARRAY_SIZE] = 0;

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(LoadGameConfigFile("l4d2_random"), SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSDKCallSetClass = EndPrepSDKCall();
	
	hArrayZombieClasses = CreateArray();
}

public L4D_OnEnterGhostState(client)
{
	new curZc = GetEntProp(client, Prop_Send, "m_zombieClass");	
	
	if (iArSavedSpawns[curZc] < GetConVarInt(hArCvar[curZc]))	//UNSAVED? - if the count for this zc hasnt reached the max yet
	{
		PushArrayCell(hArrayZombieClasses, curZc);	//SAVE! - add the zc to the array and let him keep it
		iArSavedSpawns[curZc]++;	//keep track of how many spawns of this zc are stored
		iArSavedSpawns[SI_COUNT]++;	//and how many spawns total
	}
	else
	{
		if (GetSumOfZLimits() == iArSavedSpawns[SI_COUNT])	//ALL SAVED? - if all spawns have been added to array already
		{
			new newZc = GetArrayCell(hArrayZombieClasses, 0);	//SET SAVED! - fetch the next class from the array
			SDKCall(hSDKCallSetClass, client, newZc);	
			RemoveFromArray(hArrayZombieClasses, 0);	//remove it from array since it's being used
			iArSavedSpawns[newZc]--;	//and keep track of the removal
			iArSavedSpawns[SI_COUNT]--;	//
		}
		else
		{
			for (new n = 1; n <= ZC_CHARGER; n++)	//SET UNSAVED! - set to a class that hasnt been saved yet
			{
				if (iArSavedSpawns[n] < GetConVarInt(hArCvar[n]))
				{
					SDKCall(hSDKCallSetClass, client, n);
					break;
				}
			}
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= MaxClients)
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			new curZc = GetEntProp(client, Prop_Send, "m_zombieClass");	//add his zc to the array
			PushArrayCell(hArrayZombieClasses, curZc);
			iArSavedSpawns[curZc]++;	//increment the count of spawns of curZc that are stored
			iArSavedSpawns[SI_COUNT]++;	//and total amount of spawns
		}
	}
}

GetSumOfZLimits()
{
	new count = 0;
	for (new zc = 1; zc <= ZC_CHARGER; zc++)
	{
		count += GetConVarInt(hArCvar[zc]);
	}
	return count;
}

//
