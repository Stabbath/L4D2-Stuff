#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new 		iDefaultCommonLimit;
new			iSixthOfDefaultCommonLimit;
new			iTickCount = 3;
new bool:	bTimerHasNotBeenUsedYet = true;
new Handle:	hCvarCommonLimit = INVALID_HANDLE;
new Handle:	hTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "L4D2 Starter Common",
	author = "Stabby, original by Blade",
	description = "Decreases amount of common before leaving the saferoom to a sixth, and then increases it every 5 seconds to a quarter, half and finally to the full cfg-defined value.",
	version = "2.0.2",
	url = "nope"
}

public OnPluginStart()
{
	hCvarCommonLimit = FindConVar("z_common_limit");
	iDefaultCommonLimit = GetConVarInt(hCvarCommonLimit);	//will be adjusted if the .cfg's change it to non-default
	HookConVarChange(hCvarCommonLimit, CommonLimitChanged);
	
	HookEvent("round_start",	Event_RoundStart);
	HookEvent("round_end",		Event_RoundEnd);
	HookEvent("player_left_start_area",	PlayerLeftStartArea);
}

public CommonLimitChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(oldVal) == iSixthOfDefaultCommonLimit && StringToInt(newVal) == iDefaultCommonLimit) 
	{
		SetConVarInt(cvar, iSixthOfDefaultCommonLimit);
		return;
	} //to prevent map changes from messing things up

	if (bTimerHasNotBeenUsedYet && StringToInt(newVal) != iSixthOfDefaultCommonLimit)	//second condition to avoid recursion when cvar is preemptively set before round start
	{
		iDefaultCommonLimit = StringToInt(newVal);
		
		new buffer = iDefaultCommonLimit / 6;	//set it the first time since round_start is too late
		SetConVarInt(cvar, buffer);
		iSixthOfDefaultCommonLimit = buffer;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new buffer = iDefaultCommonLimit / 6;
	SetConVarInt(hCvarCommonLimit, buffer);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hTimer != INVALID_HANDLE)
	{	//in case of early double/tri cap
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
	
	new buffer = iDefaultCommonLimit / 6;
	SetConVarInt(hCvarCommonLimit, buffer);
	iTickCount 		= 3;
}

public Action:PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	hTimer = CreateTimer(5.0, CommonLimitDelay, INVALID_HANDLE, TIMER_REPEAT);
	bTimerHasNotBeenUsedYet = false;
}

public Action:CommonLimitDelay(Handle:timer)
{	
	SetConVarInt(hCvarCommonLimit, iDefaultCommonLimit / (1 << --iTickCount));
	
	if (!iTickCount)
	{
		hTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}