#pragma semicolon 1

//Notes:
//damage drop functions were elaborated taking a single sniper into account
//drop may be inadequate for configs that have different types of snipers
//also: plugin is most likely completely unnecessary since damage drop is controlled by the RangeModifier property of weapons, but it was still fun to code

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define TEAM_INFECTED 3

//cvar handles
new Handle:hDistBrSh	= INVALID_HANDLE;
new Handle:hFactorBrA	= INVALID_HANDLE;
new Handle:hFactorBrB	= INVALID_HANDLE;
new Handle:hMinDamage	= INVALID_HANDLE;
new Handle:hTest		= INVALID_HANDLE;
//new Handle:hSmooth		= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "HR Nerf",
	author = "Stabby",
	description = "Adds damage drop in function of distance to snipers",
	version = "1.0",
	url = "no url"
}

public OnPluginStart()
{
	//Cvars
	//range at which the damage drop function shifts to the second branch. default 400.0, min 0.0, max 4000.0
	hDistBrSh		= CreateConVar("hrnerf_shift_dist",		"400.0", "nondescript", FCVAR_PLUGIN, true,  0.0, true, 4000.0);
	//factor for first branch. default 1.0, min -5.0, max 5.0
	hFactorBrA		= CreateConVar("hrnerf_factor_a",		"1.0",	 "nondescript", FCVAR_PLUGIN, true, -5.0, true, 5.0);	
	//factor for second branch. default 2.0, min -5.0, max 5.0
	hFactorBrB		= CreateConVar("hrnerf_factor_b",		"2.0",   "nondescript", FCVAR_PLUGIN, true, -5.0, true, 5.0);
	//damage will not be allowed to drop below this value. default 1, min 0
	hMinDamage		= CreateConVar("hrnerf_mindamage",		"1.0",   "nondescript", FCVAR_PLUGIN, true,  0.0, false);
	//if enabled, will print info on damage and distance, so the user can figure out what he wants to do with the other cvars
	hTest			= CreateConVar("hrnerf_test_enable",	"0.0",   "nondescript", FCVAR_PLUGIN, true,  0.0, true, 1.0);	
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!attacker || !victim) { return Plugin_Continue; }	
	if (!IsValidEdict(weapon) || !IsValidEdict(inflictor) || !IsValidEdict(victim)) { return Plugin_Continue; }
	
	decl String:sWepClass[48];
	GetEntityClassname(weapon, sWepClass, sizeof(sWepClass));	
	
	if (!IsSniper(sWepClass) || GetClientTeam(victim) != TEAM_INFECTED) { return Plugin_Continue; }
		
	decl Float:fClientPos[3];
	decl Float:fVictimPos[3];
	GetClientEyePosition(attacker,fClientPos);
	GetClientEyePosition(victim,fVictimPos);
	new Float:fDistance = GetVectorDistance(fClientPos,fVictimPos,false);
		
	new Float:fDistBrSh 	= GetConVarFloat(hDistBrSh);
	new Float:fFactorBrA 	= GetConVarFloat(hFactorBrA);
	new Float:fFactorBrB	= GetConVarFloat(hFactorBrB);
	new Float:fDistOffset 	= fDistance - fDistBrSh; //used in an earlier version to smooth transition between branches
	
	if (fDistance <= fDistBrSh)
	{	
		damage -= fFactorBrA * (0.004*fDistance + 0.00001*fDistance*fDistance);
	}
	else
	{	
		new Float:fDeduct = fFactorBrA * (0.004*fDistBrSh 	+ 0.00001*fDistBrSh*fDistBrSh);
		damage -= fDeduct + fFactorBrB * (0.02*fDistOffset 	- 0.0000025*fDistOffset*fDistOffset);
	}
	
	new Float:fMinDamage = GetConVarFloat(hMinDamage);
	if (damage < fMinDamage)
	{
		damage = fMinDamage;
	}
	
	if (GetConVarBool(hTest))
	{
		PrintToChatAll("%f damage at %f distance (dist offset from branch shift is %f)", damage,fDistance,fDistOffset);
	}
	
	return Plugin_Changed;
}

stock bool:IsSniper(const String:weapon[48])
{
	if (StrEqual(weapon,"weapon_hunting_rifle",false)) 		{ return true; }
	if (StrEqual(weapon,"weapon_sniper_military",false)) 	{ return true; }
	if (StrEqual(weapon,"weapon_sniper_scout",false)) 		{ return true; }
	if (StrEqual(weapon,"weapon_sniper_awp",false)) 		{ return true; }
	return false;
}

stock bool:IsClientAndInGame(index)
{
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

