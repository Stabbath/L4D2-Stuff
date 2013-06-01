#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new iTickCount;
new iDefaultCommonLimit;
new iSixthOfDefaultCommonLimit;
new Handle: hCvarCommonLimit = INVALID_HANDLE;
new Handle: hTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "L4D2 Starter Common",
    author = "Stabby, original by Blade",
    description = "Decreases amount of common before leaving the saferoom to a sixth, and then increases it every 5 seconds to a quarter, half and finally to the full cfg-defined value.",
    version = "2.1",
    url = "nope"
}

public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
}

public OnConfigsExecuted()
{
    hCvarCommonLimit = FindConVar("z_common_limit");
    iDefaultCommonLimit = GetConVarInt(hCvarCommonLimit);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    SetConVarInt(hCvarCommonLimit, iDefaultCommonLimit / 6);

    if (hTimer != INVALID_HANDLE)
    { //in case of early double/tri cap (on round start instead of end in case of map changes)
        KillTimer(hTimer);
    }
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    SetConVarInt(hCvarCommonLimit, iDefaultCommonLimit / 6);
}

public Action:L4D_OnFirstSurvivorLeftSafeArea(client)
{
    iTickCount = 3;
    hTimer = CreateTimer(5.0, Timed_CommonLimitChange, _, TIMER_REPEAT);
}

public Action:Timed_CommonLimitChange(Handle:timer)
{
    new buffer = iDefaultCommonLimit / (1 << --iTickCount);
    SetConVarInt(hCvarCommonLimit, buffer);
    
    if (iTickCount == 0)
    {
        hTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}
