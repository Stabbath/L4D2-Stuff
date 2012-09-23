#pragma semicolon 1

#include <sourcemod>
#include <left4downtown>

public Plugin:myinfo = 
{
    name = "Only Boomer Commons",
    author = "Stabby",
    version = "0.2.1",
    description = "Toggles z_common_limit between 30 when a boomer horde spawns and 0 when 7 seconds have elapsed since the horde spawn. Also increases boomer horde size by 20%."
};

new bool: bTimerRunning = false;

public OnPluginStart() 
{
	SetConVarInt(FindConVar("z_common_limit"), 0);
}

public Action:L4D_OnSpawnITMob(&amount)
{
	SetConVarInt(FindConVar("z_common_limit"), 30);
	amount = amount * 5 / 4;
	
	if (!bTimerRunning)
	{
		CreateTimer(7.0, Timed_ResetCommonLimit);
		bTimerRunning = true;
	}
}

public Action:Timed_ResetCommonLimit(Handle:unused)
{
	SetConVarInt(FindConVar("z_common_limit"), 0);
	bTimerRunning = false;
}


