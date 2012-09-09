//Puke nuke aka the boomer bomb
//Plugin to make rocketing boomers explode if hitting the ground above a certain velocity
//by Stabby

//To-do:
//Maybe add explosive blast, with the already existing cvar being adjusted by the plugin and then restored
//test diescraper skyscraper roofs to check terminal speed, if too high readjust trigger distance or timer interval
//maybe trigger it based on acceleration? i.e. explode if the velocity drops more than X in the timer's interval

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <timers>

#define	ZC_BOOMER	2
#define TEAM_INFECTED 3

new bool:bMustExplode=false;

new Float:fHighestDistance = 0.0; //to be used in HeightTrace

new Handle:hMinVelocity = INVALID_HANDLE;
//new Handle:hExtraPush = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Puke Nuke",
	author = "Stabby",
	description = "Causes high-speed boomers to explode on contact with the ground. Calling it the Boomer Bomb or the Bile Blast is acceptable, but Puke Nuke is preferred. The Vomit V2 and the Sick C4 are not so good.",
	version = "1.2.1",
	url = "no url"
}

public OnPluginStart()
{
	HookEvent("player_jump",Event_PlayerJump);
	//HookEvent("boomer_near",Event_BoomerNear);
		//boomer_near is detected in a vertical cylinder around survivors, rather than a sphere
		//userid and victim are the same for this event, for whatever reason
	
	hMinVelocity = CreateConVar("pukenuke_minvelocity", "700.0", "900.0 can easily be achieved with a rocket off of nm1-height roof", FCVAR_PLUGIN, true, 0.0, false);
//	hExtraPush 	 = CreateConVar("pukenuke_extrapush", "", "Force of puke nukes.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (!IsClientAndInGame(client))									{ return Plugin_Continue; }
	if (GetClientTeam(client) != TEAM_INFECTED)						{ return Plugin_Continue; }
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_BOOMER)	{ return Plugin_Continue; }
	
	CreateTimer(0.05,HeightTrace,client,TIMER_REPEAT); //tried 0.1 to lighten the load, but it was easy to jump from 50+ to 0 at high velocities, completely skipping detection
	fHighestDistance = 0.0; //just in case
	
	return Plugin_Continue;
}

public Action:HeightTrace(Handle:unused, any:client)
{	
	if (GetClientTeam(client) != TEAM_INFECTED || GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_BOOMER)	{ return Plugin_Stop; }	//just in case
	
	decl Float:fGroundPos[3];
	decl Float:fBoomerPos[3];
	GetClientAbsOrigin(client,fBoomerPos);
	
	new Float:fAngle[3] = { 90.0, 0.0, 0.0 };
	
	new Handle:hTrace = TR_TraceRayFilterEx(fBoomerPos, fAngle, MASK_SOLID, RayType_Infinite,FilterSelf,client);
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fGroundPos, hTrace);
		
		new Float:fDistance = GetVectorDistance(fBoomerPos,fGroundPos,false);
		
		if (fDistance > fHighestDistance) //records the tallest height achieved in flight
		{
			fHighestDistance = fDistance;
		}
		
		decl Float:fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		new Float:fVelNorm = GetVectorLength(fVelocity, false);
				
		new Float:fMinVelocity = GetConVarFloat(hMinVelocity);
		
		if (fVelNorm >= fMinVelocity)
		{
			bMustExplode = true;
		}
		else //safeguard against mid-flight slowdowns via collision with walls and whatnot
		{
			bMustExplode = false;		
		}

		if (fDistance <= 140.0 && fHighestDistance > 400.0) //has the boomer nearing the ground actually jumped off yet?
		{
			if (IsClientAndInGame(client) && IsPlayerAlive(client) && bMustExplode)
			{
				new Float:fETA = fDistance / fVelNorm; //ignoring gravity accel
				
				CreateTimer(fETA,Damage,client);
			}
			return Plugin_Stop;
		}
	}
	CloseHandle(hTrace);
	
	bMustExplode=false; //reset	
	
	return Plugin_Continue;
}

public Action:Damage(Handle:unused, any:target)
{
    new pointHurt = CreateEntityByName("point_hurt");            // Create point_hurt
    DispatchKeyValue(target, "targetname", "hurtme");                // mark boomer
    DispatchKeyValue(pointHurt, "Damage", "50");                    // damage enough to kill it
    DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");        // Target Assignment
    DispatchKeyValue(pointHurt, "DamageType", "65536");            // Type of damage
    DispatchSpawn(pointHurt);                                        // Spawn descriped point_hurt
    AcceptEntityInput(pointHurt, "Hurt");                         // Trigger point_hurt execute
    AcceptEntityInput(pointHurt, "Kill");                         // Remove point_hurt
    DispatchKeyValue(target, "targetname",    "cake");            // Clear target's mark
} 

public bool:FilterSelf(entity, mask, any:data)
{
	if (entity == data)
	{
		return false; //entity hit itself, ignore this hit
	}
	return true; //entity did not hit itself, target is valid
}

stock bool:IsClientAndInGame(index)
{
    if (index > 0 && index < MaxClients)
    {
        return IsClientInGame(index);
    }
    return false;
}