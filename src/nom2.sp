#pragma semicolon 1

/*
 * Probably some things that are redundant or pointless, but I got tired of looking at this plugin and didnt bother looking it over a final time.
 * A simpler way to do all this, for every class, would be to shorten the duration of the m2. At low values (but not too low), the trace lines are incompletely drawn and result in a fairly significant inability to m2.
 * While still being able to shove things that are standing, deadstopping becomes close to impossible, if not truly impossible.
 */

#include <sourcemod>
#include <left4downtown>
#include <sdktools>
#include <sdkhooks>
#include <float>

#define ZC_SMOKER	1
#define ZC_BOOMER	2
#define ZC_HUNTER	3
#define ZC_SPITTER	4
#define ZC_JOCKEY	5
#define ZC_CHARGER	6
#define ZC_TANK		8

#define FL_HUNTER	(1 << 0)
#define FL_JOCKEY	(1 << 1)
#define FL_CHARGER	(1 << 2)
#define FL_SMOKER	(1 << 3)
#define FL_BOOMER	(1 << 4)
#define FL_SPITTER	(1 << 5)
#define FL_TANK		(1 << 6)

#define TEAM_SURVIVORS	2
#define TEAM_INFECTED	3

public Plugin:myinfo = 
{
	name = "No m2; Stop Deadstopping!",
	author = "Stabby",
	description = "Allows customisable control of what can be shoved and what can't",
	version = "1.1.1",
	url = "no url"
}

//index always refers to jockey, rather than his victim
new bool:	bIsRiding	[MAXPLAYERS + 1]	;
new Float:	fVictimPos	[MAXPLAYERS + 1][3]	;
new 		iVictim		[MAXPLAYERS + 1]	;

//cvar handles: flags
new Handle:	hZCBlockShove		=	INVALID_HANDLE;
new Handle: hZCAllowShoveOff	=	INVALID_HANDLE;

new Handle:	hStunDuration		=	INVALID_HANDLE;
new Handle:	hJockeyFov			=	INVALID_HANDLE;
new Handle:	hHunterFov			=	INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("jockey_ride",Event_JockeyRide);
	HookEvent("player_shoved",Event_PlayerShoved);
	
	hStunDuration 	= FindConVar("z_gun_stun_duration");
	SetConVarInt(hStunDuration, 0);
	HookConVarChange(hStunDuration, ConVarReset);
	hJockeyFov 		= FindConVar("versus_shove_jockey_fov_leaping");
	SetConVarInt(hJockeyFov, 0);
	HookConVarChange(hJockeyFov, ConVarReset);
	hHunterFov		= FindConVar("versus_shove_hunter_fov_pouncing");
	SetConVarInt(hHunterFov, 0);
	HookConVarChange(hHunterFov, ConVarReset);
	
	hZCBlockShove 		= CreateConVar(	"nom2_block_flags",
										"127",
										"Which ZCs will be immune to staggering. If not included, chargers and tanks will be m2-able. 1 - Hunter; 2 - Jockey; 4 - Charger; 8 - Smoker; 16 - Boomer; 32 - Spitter; 64 - Tank.",
										FCVAR_PLUGIN,
										true,
										0.0,
										true,
										127.0 );
	hZCAllowShoveOff	= CreateConVar(	"nom2_allow_pinned_flags",
										"15",
										"Which ZCs will survivors be able to push off of teammates? Overrides nom2_block_flags for this scenario. 1 - Hunter; 2 - Jockey; 4 - Charger; 8 - Smoker.",
										FCVAR_PLUGIN,
										true,
										0.0,
										true,
										15.0 );
}

public ConVarReset(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal)) { SetConVarInt(cvar, 0); }
}

//add m2 to tanks and chargers
public Action:Event_PlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	//start charger
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_CHARGER)
	{			
		if (GetConVarInt(hZCBlockShove) & FL_CHARGER)
		{	//is charger pinning someone?
			if (IsClientAndInGame(GetEntPropEnt(client, Prop_Send, "m_pummelVictim"))
			&& (GetConVarInt(hZCAllowShoveOff) & FL_CHARGER))
			{				
				L4D_StaggerPlayer(client, GetClientOfUserId(GetEventInt(event,"attacker")), NULL_VECTOR);
			}
		}
		else
		{
			L4D_StaggerPlayer(client, GetClientOfUserId(GetEventInt(event,"attacker")), NULL_VECTOR);
		}
		return;
	}
	//end charger
	
	//start tank
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK
	&& !(GetConVarInt(hZCBlockShove) & FL_TANK))
	{
		L4D_StaggerPlayer(client, GetClientOfUserId(GetEventInt(event,"attacker")), NULL_VECTOR);
	}
	//end tank
	
	return;
}

//block m2 on others
public Action:L4D_OnShovedBySurvivor(attacker, client, const Float:vector[3])
{
	if (!IsClientAndInGame(client) || !IsClientAndInGame(attacker))	{ return Plugin_Continue; }
	if (GetClientTeam(client) != TEAM_INFECTED)						{ return Plugin_Continue; }
	
	PrintToChat(attacker, "You landed a m2!");
	PrintToChat(client, "You got m2'd!");
	
	//start hunter
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_HUNTER
	&& (GetConVarInt(hZCBlockShove) & FL_HUNTER))
	{
		if (IsClientAndInGame(GetEntPropEnt(client, Prop_Send, "m_pounceVictim"))
		&& (GetConVarInt(hZCAllowShoveOff) & FL_HUNTER))
		{
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}
	//end hunter
	
	//start jockey
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_JOCKEY
	&& (GetConVarInt(hZCBlockShove) & FL_JOCKEY))
	{
		new jockeyVictim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
		
		if (IsClientAndInGame(jockeyVictim)
		&& (GetConVarInt(hZCAllowShoveOff) & FL_JOCKEY))
		{
			return Plugin_Continue;
		}
		
		if (jockeyVictim == attacker)
		{
			return Plugin_Handled;
		}
		
		new ability = MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility"));
		//if the jockey is on the ground (and not riding) just block instantly; also block teleporting when ability is on cooldown
		if (!(GetEntityFlags(client) & FL_ONGROUND) && GetEntPropFloat(ability, Prop_Send, "m_timestamp") + GetEntPropFloat(ability, Prop_Send, "m_duration") < GetGameTime())
		{
			PrintToChat(attacker, "M2 on the jockey was blocked!");
			PrintToChat(client, "You got m2'd but it was blocked!");


			if (bIsRiding[client] == true)	//fix self-clears
			{
				decl Float:fJockeyPos[3];
				GetClientEyePosition(client, fJockeyPos);
				decl Float:fAngle[3];
				GetClientAbsAngles(client, fAngle);
				new apparentTarget = FindTargetThroughTraceray(fJockeyPos,fAngle,attacker);
				if (IsClientAndInGame(apparentTarget) && GetClientTeam(apparentTarget) == 2)
				{
					iVictim[client] = apparentTarget;
				}
				else
				{
					iVictim[client] = attacker;
					return Plugin_Handled;
				}
				
				for (new Float:o = -50.0; o <= 10.0; o += 0.35)
				{
					if (o >= 9.5) { o = -50.0; }
					
					GetClientEyePosition(iVictim[client], fVictimPos[client]);
					
					fVictimPos[client][2] += o;
					//test saving angle, velocity and position here and restoring them with a very short timer
					TeleportEntity(client,fVictimPos[client],NULL_VECTOR,NULL_VECTOR);
					
					if (IsClientAndInGame(GetEntPropEnt(client, Prop_Send, "m_jockeyVictim")))
					{
						bIsRiding[client] = false;	//to prevent running this several times in a row
						break;
					}
				}
			}
		}
		return Plugin_Handled;		
	}
	//end jockey
		
	//start smoker
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_SMOKER
	&& (GetConVarInt(hZCBlockShove) & FL_SMOKER))
	{
		if (IsClientAndInGame(GetEntPropEnt(client, Prop_Send, "m_tongueVictim"))
		&& (GetConVarInt(hZCAllowShoveOff) & FL_SMOKER))
		{
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}	
	//end smoker
	
	//start boomer
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_BOOMER
	&& (GetConVarInt(hZCBlockShove) & FL_BOOMER))
	{
		return Plugin_Handled;
	}	
	//end boomer
	
	//start spitter
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_SPITTER
	&& (GetConVarInt(hZCBlockShove) & FL_SPITTER))
	{
		return Plugin_Handled;
	}	
	//end spitter
		
	return Plugin_Continue;
}

//detect jockey rides to prevent self-clears when lag causes the shove to come after the jockey lands
public Action:Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	bIsRiding[GetClientOfUserId(GetEventInt(event,"userid"))] = true;
}

FindTargetThroughTraceray(Float:fJockeyPos[3],Float:fAngle[3],attacker)
{
	new iEntHit = 0;

	decl Float:n;
	decl Handle:hTrace;
	for (new Float:i=-60.0; i<=30.0; i+=1.0)
	{
		fAngle[0] += i;
		
		if (fAngle[0] > 90.0 || fAngle[0] < -90.0) { continue; }
		
		for (n=-10.0; i<=10.0; i+=0.5)
		{
			fAngle[1] += n;
			
			if (fAngle[1] > 180.0 || fAngle[1] < -180.0) { continue; }
			
			hTrace = TR_TraceRayFilterEx(fJockeyPos,fAngle,MASK_ALL,RayType_Infinite,Filter_FindAttacker,attacker);
			if (TR_DidHit(hTrace))
			{
				new ent = TR_GetEntityIndex(hTrace);
				if (IsClientAndInGame(ent)) { iEntHit = ent; }
			}
			CloseHandle(hTrace);			
		}
	}
	return iEntHit;
}

public bool:Filter_FindAttacker(entity, mask, any:data)
{
	if (entity == data && IsClientAndInGame(entity))
	{
		return true; //intended target, allow hit
	}
	return false; //tr did not hit intended target, ignore
}

stock bool:IsClientAndInGame(index)
{
    if (index > 0 && index < MaxClients)
    {
        return IsClientInGame(index);
    }
    return false;
}
