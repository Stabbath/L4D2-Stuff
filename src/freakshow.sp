#pragma semicolon 1

	//test hud_zombieteam_showself 

	//test m_flAnimTime during getup
	
	//test m_flFallVelocity for pukenuke
	
	//m_iShovePenalty for the 10-second cooldown
	
	//z_fog_spawn 1 with random environmental effects

//ask tab: how to tamper with event hordes? get script value?
	
	//maybe have wave timer be longer or shorter depending on damage survivors take during previous wave?
	
//test leap_attach distance for nom2 and z_max_hunter_pounce_stagger_duration, player_blocked 

//maybe give survivors extra health based on map custom distance points?

//what are threat areas?

//1 m2 every 10 seconds, very high force

//boomers or spitters? or both, only allowing one depending on the map/part of map
//if spitters: cause slowdown for survivors when in spit, decrease spit damage

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <float>
#include <l4d2weapons>
#include <l4d2util_weapons>
#include <left4downtown>

#define ZC_SMOKER	1
#define ZC_BOOMER	2
#define ZC_HUNTER	3
#define ZC_SPITTER	4
#define ZC_JOCKEY	5
#define ZC_CHARGER	6
#define ZC_WITCH	7
#define ZC_TANK		8

#define ZCA_CHARGER 0
#define ZCA_JOCKEY 1
#define ZCA_SMOKER 2
#define ZCA_SPITTER 3

//si spawns
new iDeathCount;
new iZCActivity[4];
new iNextZC[4];

//waves
new iWaveCounter; //keeps track of how many waves have passed
new iWaveTimer; //counts down to 0 to send waves

//throwable-giver seeds
new iThrowSeed = -1;
new iThrowSetup;

new Handle:hFreezeMobTimers = INVALID_HANDLE;
new Handle:hWaveTimer 		= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Freakshow: A Config For The Mentally Deranged",
	author = "Stabby",
	description = "I'm lazy so all the special stuff I want in this config will be in this unique plugin",
	version = "0.1",
	url = "no url"
}

public OnPluginStart()
{	//weapons
	new String:sWeapon[32] = "weapon_rifle_m60";
	L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_Damage, 30);
	L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_ClipSize, 100);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxSpread, 40.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadPerShot, 2.60);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadDecay, 7.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinDuckingSpread, 0.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinStandingSpread, 1.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinInAirSpread, 3.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxMovementSpread, 6.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_Range, 4096.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier, 0.91);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_CycleTime, 0.07);	
	sWeapon = "weapon_shotgun_spas";
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_Range, 2048.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier, 0.32);
	
	//hooks
	HookEvent("item_pickup",Event_ItemPickup);	//weapon_pickup doesnt fire ever
	HookEvent("weapon_drop",Event_WeaponDrop);
	HookEvent("weapon_fire", Event_WeaponFire);//weapon_fire_on_empty doesnt fire
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_bot_replace", Event_PlayerReplacedByBot);
	HookEvent("player_left_start_area", OnPlayerLeftStartArea);
}

public OnPluginEnd()
{
	new String:sWeapon[32] = "weapon_rifle_m60";
	L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_Damage, 50);
	L4D2_SetIntWeaponAttribute(sWeapon, L4D2IWA_ClipSize, 150);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxSpread, 35.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadPerShot, 1.60);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_SpreadDecay, 7.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinDuckingSpread, 0.50);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinStandingSpread, 1.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MinInAirSpread, 3.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxMovementSpread, 6.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_Range, 3000.00);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier, 0.97);
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_CycleTime, 0.10);	
	sWeapon = "weapon_shotgun_spas";
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_Range, 3000.00);	
	L4D2_SetFloatWeaponAttribute(sWeapon, L4D2FWA_RangeModifier, 0.69);
}

public OnMapStart()
{	//if i decide to choose between boomer and spitter depending on map, getcurrentmap here and set it
	
	new mapscore = L4D_GetVersusMaxCompletionScore();
	SetConVarInt(FindConVar("ammo_autoshotgun_max"), mapscore/2);
	SetConVarInt(FindConVar("ammo_m60_max"), mapscore + mapscore/2);

	//timer
	if (hFreezeMobTimers == INVALID_HANDLE)
	{
		hFreezeMobTimers = CreateTimer(0.1, Timed_FreezeMobs, TIMER_REPEAT);
	}
	
	//throwable-giver seed
	if (iThrowSeed == -1)
	{
		iThrowSeed = GetRandomInt(0,15);
	}
	
}

public OnMapEnd()
{
	iThrowSeed = -1;
}

public Action:OnPlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	iThrowSetup = iThrowSeed;
	
	if (hFreezeMobTimers != INVALID_HANDLE)
	{	//unfreeze mob timers
		CloseHandle(hFreezeMobTimers);
	}
	
	if (hWaveTimer == INVALID_HANDLE)
	{	//start wave timer
		hWaveTimer = CreateTimer(1.0, Timed_ControlWaves, TIMER_REPEAT);
	}
}

public Action:Timed_FreezeMobs(Handle:timer)
{
	L4D_ResetMobTimer();
}

public Action:Timed_ControlWaves(Handle:unused)
{
	switch (iWaveTimer)
	{
		case 0:
		{
			iWaveTimer = 16; //16 rather than 15 to simplify the decrement after this switch statement
			SetConVarInt(FindConVar("director_no_specials"), 0);
			
			//iWaveCounter-- in switch or if statements? does a switch perform the operation, store the result and then use that to check what value it is, or does it repeat the check?
		
			switch (iWaveCounter % 10)
			{
				case 0:
				{
					PrintCenterTextAll("Wave Number: %d - Tank!",iWaveCounter);
				}
				case 5:
				{
					PrintCenterTextAll("Wave Number: %d - Mega Mob!",iWaveCounter);
				}
				default:
				{
					PrintCenterTextAll("Wave Number: %d",iWaveCounter);
				}
			}
			
			L4D_ResetMobTimer();	//just in case, to keep things sychronised
									//does it affect mega mob timer though?
//			SendSISpawns();
		}
		case 1,2,3,5:
		{
			PrintCenterTextAll("Wave Timer: %d",iWaveTimer);
		}
		case 10:
		{
			SetConVarInt(FindConVar("director_no_specials"), 1);
		}
	}
	
	iWaveTimer--;
	return;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	//not yet hooked
	if (GetClientTeam(attacker) != 3) return Plugin_Continue;
}

OnEntityCreated(oldEntity, const String:classname[])
{
	if(StrContains(classname,"weapon")!=-1)
	{
		new Handle:newEntity;
		
		if(StrContains(classname,"pistol")!=-1 || StrContains(classname,"melee")!=-1)
		{
			newEntity = CreateEntityByName("weapon_rifle_m60_spawn");
		}
		else
		{
			newEntity = CreateEntityByName("weapon_shotgun_spas_spawn");
		}
		
		decl Float:vecData[3];
				
		DispatchKeyValue(newEntity, "Spawnflags", "14");
		GetClientAbsAngles(oldEntity, vecData);
		DispatchKeyValueVector(newEntity, "Angles", angles);
		GetClientAbsOrigin(oldEntity, vecData);
		DispatchKeyValueVector(newEntity, "Origin", origin);
			
		AcceptEntityInput(oldEntity, "Kill");
		DispatchSpawn(newEntity);
	}
}


public Action:L4D_OnGetRunTopSpeed(target, &Float:retVal)
{
	if (GetClientTeam(target) == 2)
	{
		if (GetEntProp(target, Prop_Send, "m_iHealth") <= 20)
		{
			retVal = 420.0;
		}
		else
		{
			retVal = 360.0;
		}
		
		SetEntPropFloat(target, Prop_Data, "m_flMaxspeed", retVal);
		return Plugin_Handled;
	}
	
	if (GetClientTeam(target) == 3)
	{
		if (GetEntProp(target, Prop_Send, "m_isGhost"))
		{
			retVal = 800.0;
		}
		
		SetEntPropFloat(target, Prop_Data, "m_flMaxspeed", retVal);			
		return Plugin_Handled;		
	}
	return Plugin_Continue;
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sWeapon[32];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));
	
	if (StrEqual(sWeapon,"rifle_m60") || StrEqual(sWeapon,"shotgun_spas"))
	{
		new pistol = GetPlayerWeaponSlot(client, 1);
		RemovePlayerItem(client, pistol);
	}
}

public Action:Event_WeaponDrop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sWeapon[32];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));
	
	PrintToChatAll("weapon drop");
	
	if (StrEqual(sWeapon,"rifle_m60") || StrEqual(sWeapon,"shotgun_spas"))
	{
		PrintToChatAll("giving magnum for test");
		GivePlayerItem(client, "weapon_pistol_magnum");
//		GetRandomInt(0,9)
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientAndInGame(client)) { return; }
	if (GetClientTeam(client) != 3) { return; }
	
	new iZC = GetEntProp(client, Prop_Send, "m_zombieClass");
	
	new iVomitjarNum;
	new iPipeBombNum;
	
	if (iZC == ZC_TANK)
	{	//tank routine
		for (new i=0; i<=3; i++)
		{	//let's give the survivors their throwables
			if ((1 << i) & iThrowSetup)
			{
				iVomitjarNum++;
			}
			else
			{
				iPipeBombNum++;
			}
		}	
		
		for (new i = 1; i <= MAXPLAYERS; i++)
		{
			if (GetClientTeam(i) == 2)
			{
				if (GetRandomInt(0,1))
				{
					if (iVomitjarNum)
					{
						GivePlayerItem(i, "weapon_vomitjar");
						continue;
					}
					if (iPipeBombNum)
					{
						GivePlayerItem(i, "weapon_pipe_bomb");
					}
				}
				else
				{
					if (iPipeBombNum)
					{
						GivePlayerItem(i, "weapon_pipe_bomb");
						continue;
					}
					if (iVomitjarNum)
					{
						GivePlayerItem(i, "weapon_vomitjar");
					}
				}					
			}
		}

		//and of course scramble the throwable selection for next wave
		iThrowSetup = (iThrowSetup << 1) ^ (iThrowSetup);		
	}
	else
	{	//si spawn attribution routine
		/*
		Charger:
		Carry start: 1 point
		Carry end: 1 point
		Bowl: 1 point
		Damage: 0.5*dmg points (every hit does 4 damage, regardless of type)
		Charge duration: 1.0*time points
		Avg life: 1 charge start, 1 charge end, 0 bowls, 1 pound, 1 punch, 2.0 duration = 8 points
		
		Jockey:
		Ride start: 2 points
		Ride damage: 0.3*dmg points (simple way of incorporating ride duration as well, due to 3.33 dps ride)
		Scratch damage: 0.33*dmg points (3 dmg scratches)
		Avg life: 1 ride, 6 seconds, 1 scratch = 9 points
		
		Smoker:
		Pull start: 2 point
		Drag duration: 1.5*time points (maybe) 
		Damage: 0.5*dmg points
		Avg life: 1 pull, 3 seconds, 6 damage = 9.5
		
		Spitter:
		Damage: 0.75*dmg points
		Avg life: 12 damage (adjust spitter damage to make sure of it)
		*/
		//get total amount 
		//remember to only add 3 spawns on tank waves
	}
}

public Action:Event_PlayerReplacedByBot(Handle:event, const String:name[], bool:dontBroadcast)
{	//fires when passing from player to player
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if (GetClientTeam(bot) == 3)
	{
		if (GetEntProp(bot, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			ForcePlayerSuicide(bot);
		}
	}
	return;
}

stock bool:IsClientAndInGame(index)
{
    if (index > 0 && index < MaxClients)
    {
        return IsClientInGame(index);
    }
    return false;
}