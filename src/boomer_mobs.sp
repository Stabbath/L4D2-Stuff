#pragma semicolon 1

#include <sourcemod>
#include <left4downtown>

public Plugin:myinfo = 
{
    name = "Boomer Mobs",
    author = "Stabby",
    version = "0.1",
    description = "Toggles z_common_limit between 30 when a boomer horde spawns and 0 when 7 seconds have elapsed since the horde spawn. Also allows for customisation of boomer horde size."
};

new bool: bTimerRunning = false;
new Handle: hMult = INVALID_HANDLE;
new Handle: hBool = INVALID_HANDLE;

public OnPluginStart()
{
	SetConVarInt(FindConVar("z_common_limit"), 0);
	hMult = CreateConVar("boomer_mobs_amount_mult", "1.0", "Commons added to spawn queue on boomer mob spawn will be multiplied by this.", FCVAR_PLUGIN, true, 0.0);
	hBool = CreateConVar("boomer_mobs_only", "1", "Commons outside of boomer hordes will be ignored. Note that some maps are glitchy and will still have a tiny amount of commons at the beginning of events, such as Dead Air 4.", FCVAR_PLUGIN, true, 0.0);
}

public OnMapStart()
{
	if (!GetConVarBool(hBool))
	{
		SetConVarInt(FindConVar("z_common_limit"), 30);
	}
}

public Action:L4D_OnSpawnITMob(&amount)
{
	SetConVarInt(FindConVar("z_common_limit"), 30);
	
	amount = RoundToNearest(float(amount) * GetConVarFloat(hMult));
	
	if (!bTimerRunning && GetConVarBool(hBool))
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


