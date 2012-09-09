#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:	bIsBridge;			//for parish bridge cars
new bool:	bIgnoreOverkill		[MAXPLAYERS + 1];	//for hittable hits

//cvars
new Handle: hBridgeCarDamage			= INVALID_HANDLE;
new Handle: hLogStandingDamage			= INVALID_HANDLE;
new Handle: hCarStandingDamage			= INVALID_HANDLE;
new Handle: hBumperCarStandingDamage	= INVALID_HANDLE;
new Handle: hHandtruckStandingDamage	= INVALID_HANDLE;
new Handle: hForkliftStandingDamage		= INVALID_HANDLE;
new Handle: hBHLogStandingDamage		= INVALID_HANDLE;
new Handle: hDumpsterStandingDamage		= INVALID_HANDLE;
new Handle: hHaybaleStandingDamage		= INVALID_HANDLE;
new Handle: hBaggageStandingDamage		= INVALID_HANDLE;
new Handle: hStandardIncapDamage		= INVALID_HANDLE;
new Handle: hTankSelfDamage				= INVALID_HANDLE;
new Handle: hDisallowOverHit			= INVALID_HANDLE;

//use tries with model names (and damage values)?

public Plugin:myinfo = 
{
    name = "L4D2 Hittable Control",
    author = "Stabby",
    version = "0.2.2",
    description = "Allows for customisation of hittable damage values."
};

public OnPluginStart()
{
	hBridgeCarDamage		= CreateConVar( "hc_bridge_car_damage",			"25.0",
											"Damage of cars in the parish bridge finale. Overrides standard incap damage on incapacitated players.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hLogStandingDamage		= CreateConVar( "hc_sflog_standing_damage",		"48.0",
											"Damage of hittable swamp fever logs to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hBHLogStandingDamage	= CreateConVar( "hc_bhlog_standing_damage",		"100.0",
											"Damage of hittable blood harvest logs to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hCarStandingDamage		= CreateConVar( "hc_car_standing_damage",		"100.0",
											"Damage of hittable non-parish-bridge cars to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hBumperCarStandingDamage= CreateConVar( "hc_bumpercar_standing_damage",	"100.0",
											"Damage of hittable bumper cars to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hHandtruckStandingDamage= CreateConVar( "hc_handtruck_standing_damage",	"8.0",
											"Damage of hittable handtrucks (aka dollies) to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hForkliftStandingDamage= CreateConVar(  "hc_forklift_standing_damage",	"100.0",
											"Damage of hittable forklifts to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hDumpsterStandingDamage	= CreateConVar( "hc_dumpster_standing_damage",	"100.0",
											"Damage of hittable dumpsters to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hHaybaleStandingDamage	= CreateConVar( "hc_haybale_standing_damage",	"48.0",
											"Damage of hittable haybales to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hBaggageStandingDamage	= CreateConVar( "hc_baggage_standing_damage",	"48.0",
											"Damage of hittable baggage carts to non-incapped survivors.",
											FCVAR_PLUGIN, true, 0.0, true, 300.0 );
	hStandardIncapDamage	= CreateConVar( "hc_incap_standard_damage",		"100.0",
											"Damage of all hittables to incapped players. -1 will have incap damage default to valve's standard incoherent damages. -2 will have incap damage default to each hittable's corresponding standing damage.",
											FCVAR_PLUGIN, true, -2.0, true, 300.0 );
	hTankSelfDamage			= CreateConVar( "hc_disable_self_damage",		"0",
											"If set, tank will not damage itself with hittables.",
											FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	hDisallowOverHit		= CreateConVar( "hc_disable_overhit",			"1",
											"If set, hittables will not be allowed to incap and do further damage in a single hit.",
											FCVAR_PLUGIN, true, 0.0, true, 1.0 );
}

public OnMapStart()
{
	decl String:buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if (StrContains(buffer, "c5m5") != -1)
	{
		bIsBridge = true;
	}
	else
	{
		bIsBridge = false;	//in case of map changes or something
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage( victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3] )
{
	if (!IsValidEdict(attacker) || !IsValidEdict(victim) || !IsValidEdict(inflictor))	{ return Plugin_Continue; }
	
	decl String:sClass[64];
	GetEdictClassname(inflictor, sClass, sizeof(sClass));
	
	if (StrEqual(sClass,"prop_physics"))
	{
		if (bIgnoreOverkill[victim]) { return Plugin_Handled; }
				
		if (victim == attacker && GetConVarBool(hTankSelfDamage))	{ return Plugin_Handled; }
		if (GetClientTeam(victim) != 2)	{ return Plugin_Continue; }	
		
		decl String:sModelName[128];
		GetEntPropString(inflictor, Prop_Data, "m_ModelName", sModelName, 128);
		
		if (bIsBridge)
		{
			damage = 4.0*GetConVarFloat(hBridgeCarDamage);
			inflictor = 0;	//because valve is silly and damage on incapped players would be ignored otherwise
		}
		else
		{	//incapacitated? 
			if (GetEntProp(victim, Prop_Send, "m_isIncapacitated"))
			{
				new Float:val = GetConVarFloat(hStandardIncapDamage);
				if (val >= 0.0)
				{
					damage = val;
				}
				else if (val == -1) { return Plugin_Continue; }
			}
			else 
			{
				if (StrEqual(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl"))
				{
					damage = GetConVarFloat(hBaggageStandingDamage);
				}
				else if (StrEqual(sModelName, "models/props_unique/haybails_single.mdl"))
				{
					damage = GetConVarFloat(hHaybaleStandingDamage);
				}
				else if (StrEqual(sModelName, "models/props_foliage/Swamp_FallenTree01_bare.mdl"))
				{
					damage = GetConVarFloat(hLogStandingDamage);
				}
				else if (StrEqual(sModelName, "models/props_foliage/tree_trunk_fallen.mdl"))
				{
					damage = GetConVarFloat(hBHLogStandingDamage);
				}
				else if (StrEqual(sModelName, "models/props_fairgrounds/bumpercar.mdl"))
				{
					damage = GetConVarFloat(hBumperCarStandingDamage);
				}
				else if (StrEqual(sModelName, "models/props/cs_assault/handtruck.mdl"))
				{
					damage = GetConVarFloat(hHandtruckStandingDamage);
				}
				else if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl"))
				{
					damage = GetConVarFloat(hForkliftStandingDamage);
				}
				else if (StrContains(sModelName, "dumpster") != -1)
				{
					damage = GetConVarFloat(hDumpsterStandingDamage);
				}
				else if (StrContains(sModelName, "cara_") != -1 || StrContains(sModelName, "taxi_") != -1 || StrContains(sModelName, "police_car") != -1)
				{
					damage = GetConVarFloat(hCarStandingDamage);
				}
			}
		}			
		
		bIgnoreOverkill[victim] = true;	//standardise them bitchin over-hits
		if (GetConVarBool(hDisallowOverHit)) { CreateTimer(1.2, Timed_ClearInvulnerability, victim); }
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:Timed_ClearInvulnerability(Handle:thisTimer, any:victim)
{
	bIgnoreOverkill[victim] = false;
}


