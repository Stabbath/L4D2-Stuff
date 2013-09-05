#pragma semicolon 1

#include <sourcemod>

new         iDefaultCommonLimit;
new Handle: hCvarCommonLimit;
new Handle: hCvarStarterCommonLimit;
new bool:   bGameStarted;
new bool:   bInRound;

public Plugin:myinfo = {
	name = "L4D2 Starter Common",
	author = "Stabby, original by Blade",
	description = "Decreases amount of common before leaving the saferoom to a cvar'd value, and then increases it to the normal value upon leaving saferoom.",
	version = "3",
	url = "nope"
}

public OnPluginStart() {
	hCvarCommonLimit = FindConVar("z_common_limit");
	hCvarStarterCommonLimit = CreateConVar("z_starting_common_limit", "0", "Common limit to have in place before survivors leave saferoom.", FCVAR_PLUGIN, true, 0.0, false);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
}

public OnPluginEnd() {
	SetConVarInt(hCvarCommonLimit, iDefaultCommonLimit);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	bInRound = false;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!bGameStarted) {
        	bGameStarted = true;
	        iDefaultCommonLimit = GetConVarInt(hCvarCommonLimit);
	}

	if (!bInRound) CreateTimer(1.0, Timed_PostRoundStart, _, TIMER_FLAG_NO_MAPCHANGE);

	bInRound = true;
}

public Action:Timed_PostRoundStart(Handle:timer) {
    SetConVarInt(hCvarCommonLimit, GetConVarInt(hCvarStarterCommonLimit));
}

public Action:Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid"))) == 2)
            SetConVarInt(hCvarCommonLimit, iDefaultCommonLimit);
}

// vim: ts=4 sw=4 et
