#pragma semicolon 1

/*
 * Currently very, very broken, I'll look into it later.
 */

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new g_iDefaultCommonLimit;
new Handle:g_hCvarCommonLimit = INVALID_HANDLE;

new Handle:hTimer 	= INVALID_HANDLE;
new bool:bFirstRoundOfGame = true;
new bool:bGameStart = false;
new iTickCount 		= 3;
new iInfectedNum 	= 0;
new iStartCommonMax	= 0;

public Plugin:myinfo =
{
	name = "L4D2 Starter Common",
	author = "Blade, Stabby",
	description = "Decreases amount of common before leaving the saferoom.",
	version = "1.1.2",
	url = "nope"
}

public OnEntityCreated(entity, const String:classname[])
{	
	if (!bGameStart && StrEqual(classname, "infected"))
	{
		PrintToChatAll("new common; %d/%d",iInfectedNum + 1, iStartCommonMax);
		if (++iInfectedNum > iStartCommonMax) { 
			PrintToChatAll("Infected killed.");
			AcceptEntityInput(entity, "Kill"); }
	}
	return;
}

public OnPluginStart()
{
	g_hCvarCommonLimit = FindConVar("z_common_limit");	

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_left_start_area", PlayerLeftStartArea);	
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bGameStart = false;
	
	if (bFirstRoundOfGame)
	{
		g_iDefaultCommonLimit = GetConVarInt(g_hCvarCommonLimit);
		bFirstRoundOfGame = false;
	}
	
	PrintToChatAll("default common limit: %d",g_iDefaultCommonLimit);	
	
	new buffer = g_iDefaultCommonLimit / 6;
	SetConVarInt(g_hCvarCommonLimit, buffer);
	iStartCommonMax = buffer;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hTimer != INVALID_HANDLE) { PrintToChatAll("timer killed because of early wipe"); KillTimer(hTimer); }	//in case of early double/tri cap
	iTickCount 		= 3;
	iInfectedNum 	= 0;
}

public Action:PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	bGameStart = true;	
	PrintToChatAll("game started, starting timer");
	hTimer = CreateTimer(5.0, CommonLimitDelay, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:CommonLimitDelay(Handle:timer)
{	
	SetConVarInt(g_hCvarCommonLimit, g_iDefaultCommonLimit / (1 << --iTickCount));
	
	PrintToChatAll("%d tick count, common limit: %d",iTickCount,g_iDefaultCommonLimit);
	
	if (!iTickCount)	{ PrintToChatAll("timer stopped"); return Plugin_Stop; }

	return Plugin_Continue;
}