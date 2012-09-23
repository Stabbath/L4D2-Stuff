#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2weapons.inc>

#define ZC_JOCKEY  5
#define ZC_CHARGER 6
#define ZC_TANK    8

public Plugin:myinfo = 
{
	name = "Melee Control",
	author = "Stabby",
	description = "Allows for control of melee damage to chargers, jockeys, tanks and smokers/hunters/spitters/boomers. Couldn't be bothered to find a way to add control for witches and commons.",
	version = "0.1",
	url = "no url"
}

//Cvar handles
new Handle: hBaseMeleeDamageToCharger = INVALID_HANDLE;
new Handle: hBaseMeleeDamageToJockey  = INVALID_HANDLE;
new Handle: hBaseMeleeDamageToOthers  = INVALID_HANDLE;
new Handle: hBaseMeleeDamageToTank    = INVALID_HANDLE;

//and a little something to stop making every trace register
new Float:  fTimeUntilNextAllowedMeleeDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];	//from [attacker] to [victim]

public OnPluginStart()
{
	hBaseMeleeDamageToCharger = CreateConVar("mc_damage_charger", "150.0",		"Self-explanatory.", FCVAR_PLUGIN, true,  0.0, false);
	hBaseMeleeDamageToJockey  = CreateConVar("mc_damage_jockey",  "81.25",		"Self-explanatory.", FCVAR_PLUGIN, true,  0.0, false);
	hBaseMeleeDamageToOthers  = CreateConVar("mc_damage_others",  "62.50",		"Self-explanatory.", FCVAR_PLUGIN, true,  0.0, false);
	hBaseMeleeDamageToTank    = CreateConVar("mc_damage_tank",    "150.0",		"Self-explanatory.", FCVAR_PLUGIN, true,  0.0, false);	
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

//interestingly, you could use this to make it so that a melee attack does damage according to the hitgroup with the highest multiplier that was hit
//rather than it being based on the first hit registered for each individual victim. Would make leveling sooo much easier
public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{	
	decl String:classname[48];
	GetEdictClassname(inflictor, classname, 48);
	
	if (StrEqual(classname, "weapon_melee"))
	{
		if (fTimeUntilNextAllowedMeleeDamage[attacker][victim] > GetEngineTime()) { return Plugin_Handled; }
				
		if (GetClientTeam(victim) == 3)
		{
			new zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			
			switch (zombieClass)
			{
				case 5: { damage = GetConVarFloat(hBaseMeleeDamageToJockey); }
				case 6: { damage = GetConVarFloat(hBaseMeleeDamageToCharger); }
				case 8: { damage = GetConVarFloat(hBaseMeleeDamageToTank); }
				default: { damage = GetConVarFloat(hBaseMeleeDamageToOthers); }
			}
			fTimeUntilNextAllowedMeleeDamage[attacker][victim] = GetEngineTime() + 0.4;
			return Plugin_Changed;
		}		
	}
	return Plugin_Continue;
}


