#pragma semicolon 1

//Super sexy plugin to report info on every hit to its hitter
//including damage and hitgroup and all that jazz
//by Stabby

//Note:
//Plugin should be used solo with sb_stop 1, for the sake of simplicity
//Warning: Commented-out code related to firerate and hitrate was written while very sleep-deprived.

//To-do:
//*maybe* get reach of different melee weapons 
//check how many times weapon_fire is fired with shotgun blasts: once for all pellets or once per pellet? cause i cant remember

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2weapons>

//number of pellets from T1 shotties
#define	PMP_PELLETS	7
#define	CRM_PELLETS	9

//max length of weapon name plus one
#define WEAPON_LENGTH 33

// highest weapon id plus one (for index 0)
#define WEAPON_NUM 46
 
//T1 | weapons and their ids
#define WP_SMG 2
#define WP_PUMPSHOTGUN 3
#define WP_SMG_SILENCED 7
#define WP_SHOTGUN_CHROME 8
//secondary
#define WP_PISTOL 1
#define WP_PISTOL_MAGNUM 32
#define WP_MELEE 19
//snipers
#define WP_HUNTING_RIFLE 6
#define WP_SNIPER_MILITARY 10
//T2 
#define WP_RIFLE 5
#define WP_RIFLE_DESERT 9
#define WP_AUTOSHOTGUN 4
#define WP_SHOTGUN_SPAS 11
#define WP_RIFLE_AK47 26
//css
#define WP_SMG_MP5 33
#define WP_RIFLE_SG552 34
#define WP_SNIPER_AWP 35
#define WP_SNIPER_SCOUT 36
//throwables
#define WP_MOLOTOV 13
#define WP_PIPE_BOMB 14
#define WP_VOMITJAR 25
//heals and other shit
#define WP_FIRST_AID_KIT 12
#define WP_PAIN_PILLS 15
#define WP_ADRENALINE 23
#define WP_MACHINEGUN 45

new Float:fTime[2];
new Float:fTotalTime[WEAPON_NUM];
	
new iShots[WEAPON_NUM];
new iHits[WEAPON_NUM];
new fHitrate[WEAPON_NUM];
new fFirerate[WEAPON_NUM];

new Float:fWepAttributes[15][WEAPON_NUM];

public Plugin:myinfo = 
{
	name = "Report Hits",
	author = "Stabby",
	description = "Reports damage and hitgroup of all hits to their respective actor",
	version = "1.0",
	url = "no url"
}

public OnPluginStart()
{
	HookEvent("player_hurt",Event_PlayerHurt);
	//HookEvent("weapon_fire",Event_WeaponFire);
	/*
	// creates log of attribute values for all weapons, if first time running
	if (!FileExists("attributelog",false))
	{
		new Handle:attlog = OpenFile("attributelog","a");
	
		new String:sWeapon[33];
		
		// cycles through all weapons
		for (new w=0; w <= 5 ; w++)
		{	
			sWeapon = GetWeapon(w);
			
			/*DEBUG* /PrintToChatAll("%s",sWeapon);
			
			if (L4D2_IsValidWeapon(sWeapon))
			{
				// cycles through all float attributes and logs them (int attributes dont really matter)
				for (new i=0; i <= 14; i++)
				{
				fWepAttributes[i][w] = L4D2_GetFloatWeaponAttribute(sWeapon, L4D2FWA_MaxPlayerSpeed);
				LogToOpenFile(attlog,"%s - %s - %f",sWeapon,GetAttribute(i),fWepAttributes[i][w]);
				} 
				//
			}
		}
		CloseHandle(attlog);
		//
	}
	//*/
}

/*
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sWeapon[WEAPON_LENGTH];
	GetEventString(event,"weapon",sWeapon,sizeof(sWeapon));	

	iShots[GetInt(sWeapon)]++; //increments total shots for this particular weapon
	
	fTime[1]=fTime[0];
	fTime[0]=GetEngineTime();
	
	new Float:fTimeElapsed=fTime[0]-fTime[1]; // time since last shot was fired
	
	GetFirerate(sWeapon,fTimeElapsed);
	
	return Plugin_Continue;
}
*/

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient		= GetClientOfUserId(GetEventInt(event,"attacker"));
	new iVictim		= GetClientOfUserId(GetEventInt(event,"userid"));
	new iHitgroup 	= GetEventInt(event,"hitgroup");
	new iDamage 	= GetEventInt(event,"dmg_health");
	decl String:sWeapon[WEAPON_LENGTH];
	decl String:sVictim[65];

	if (!IsClientAndInGame(iClient) || !IsClientAndInGame(iVictim))	{ return Plugin_Continue; }
	
	decl Float:fClientPos[3];
	decl Float:fVictimPos[3];
	decl Float:fDistance;
	
	GetEventString(event,"weapon",sWeapon,sizeof(sWeapon));
	GetClientName(iVictim, sVictim, sizeof(sVictim));
	
	//get distance between attacker and victim
	GetClientEyePosition(iClient,fClientPos);
	GetClientEyePosition(iVictim,fVictimPos);
	fDistance = GetVectorDistance(fClientPos,fVictimPos,false);
	//
	
	/*
	// increment hits for this weapon
	iHits[GetInt(sWeapon)]++; //increment total hits for this weapon, including separate pellet hits
	//
	*/

	//keep the client informed
	//PrintToChat(iClient,"%d damage to %s (%s|%s) at %f units (%f secs)",iDamage,sVictim,hitGroupName(iHitgroup),sWeapon,fDistance,fTime[0]-fTime[1]);
	//
	
	//currently on hold, needs careful progressive testing and development
	/*
	new i = GetInt(sWeapon);
	fHitrate[i] = float(iHits[i]) / float(iShots[i]);
	if (StrEqual(sWeapon,"pumpshotgun",false)) { fHitrate[i] = fHitrate[i] / float(PMP_PELLETS); }
	if (StrEqual(sWeapon,"shotgun_chrome",false)) { fHitrate[i] = fHitrate[i] / float(CRM_PELLETS); }
	*/

	// log collected data with a separate file for each weapon
	new String:sFile[60] = "_reporthitslogs/";
	StrCat(sFile, 60, sWeapon);
	StrCat(sFile, 60, "_log.txt");
	LogToFile(sFile,"%f distance, %d damage, %f multiplier\\n",fDistance,iDamage,hitGroupMult(iHitgroup));
	//
	
	return Plugin_Continue;
}

/*
//calculates firerate for a given weapon; fTimeElapsed is global and doesnt need to be passed as a parameter

//not perfect in terms of what is considered a long break, but good enough for my tests
stock GetFirerate(const String:sWeapon[], Float:fTime)
{	
	new i = GetInt(sWeapon);
	new bool:bShotgun = (StrEqual(sWeapon,"pumpshotgun",false) || StrEqual(sWeapon,"shotgun_chrome",false));
	new bool:bSmg = (StrEqual(sWeapon,"smg",false) || StrEqual(sWeapon,"smg_silenced",false));
	
	// ignore long breaks between shotgun blasts and the different pellet hits from the same blast
	if (bShotgun && (fTime>1.0 || fTime<0.5)) { return; }
	// ignore long breaks between other weapons
	if (!bShotgun && fTime>0.4) { return; }
	if (bSmg && fTime>0.1) { return; }
	
	fTotalTime[i] = fTotalTime[i] + fTime;
	
	PrintToChatAll("%f total time with %s",fTotalTime[i],sWeapon);
	
	fFirerate[i] = float(iShots[i]) / fTotalTime[i];
	
	PrintToChatAll("%f firerate with %s",fFirerate[i],sWeapon);
	
	return;
}
*/

//associates the different float attributes with an integer, to simplify data-gathering loops
//using the enum from l4d2weapons.inc
stock L4D2FloatWeaponAttributes:GetAttribute(num)
{
	new L4D2FloatWeaponAttributes:attribute;
	switch (num)
	{
		case 0: {attribute = L4D2FWA_MaxPlayerSpeed;}
		case 1: {attribute = L4D2FWA_SpreadPerShot;}
		case 2: {attribute = L4D2FWA_MaxSpread;}
		case 3: {attribute = L4D2FWA_SpreadDecay;}
		case 4: {attribute = L4D2FWA_MinDuckingSpread;}
		case 5: {attribute = L4D2FWA_MinStandingSpread;}
		case 6: {attribute = L4D2FWA_MinInAirSpread;}
		case 7: {attribute = L4D2FWA_MaxMovementSpread;}
		case 8: {attribute = L4D2FWA_PenetrationNumLayers;}
		case 9: {attribute = L4D2FWA_PenetrationPower;}
		case 10:{attribute = L4D2FWA_PenetrationMaxDist;}
		case 11:{attribute = L4D2FWA_CharPenetrationMaxDist;}
		case 12:{attribute = L4D2FWA_Range;}
		case 13:{attribute = L4D2FWA_RangeModifier;}
		case 14:{attribute = L4D2FWA_CycleTime;}
	}
	return attribute;
}


//returns an integer id associated with a particular weapon
stock GetInt(const String:weapon[])
{
	if (StrEqual(weapon,"smg",false)) 				{return WP_SMG;}
	if (StrEqual(weapon,"smg_silenced",false)) 		{return WP_SMG_SILENCED;}
	if (StrEqual(weapon,"smg_mp5",false)) 			{return WP_SMG_MP5;}	
	if (StrEqual(weapon,"pistol",false)) 			{return WP_PISTOL;}
	if (StrEqual(weapon,"pistol_magnum",false)) 	{return WP_PISTOL_MAGNUM;}
	if (StrEqual(weapon,"pumpshotgun",false)) 		{return WP_PUMPSHOTGUN;}
	if (StrEqual(weapon,"shotgun_chrome",false)) 	{return WP_SHOTGUN_CHROME;}
	if (StrEqual(weapon,"autoshotgun",false)) 		{return WP_AUTOSHOTGUN;}
	if (StrEqual(weapon,"shotgun_spas",false)) 		{return WP_SHOTGUN_SPAS;}	
	if (StrEqual(weapon,"hunting_rifle",false)) 	{return WP_HUNTING_RIFLE;}
	if (StrEqual(weapon,"sniper_military",false)) 	{return WP_SNIPER_MILITARY;}
	if (StrEqual(weapon,"sniper_awp",false)) 		{return WP_SNIPER_AWP;}
	if (StrEqual(weapon,"sniper_scout",false)) 		{return WP_SNIPER_SCOUT;}	
	if (StrEqual(weapon,"melee",false)) 			{return WP_MELEE;}
	if (StrEqual(weapon,"rifle",false)) 			{return WP_RIFLE;}
	if (StrEqual(weapon,"rifle_ak47",false)) 		{return WP_RIFLE_AK47;}
	if (StrEqual(weapon,"rifle_desert",false)) 		{return WP_RIFLE_DESERT;}
	if (StrEqual(weapon,"rifle_sg552",false)) 		{return WP_RIFLE_SG552;}
	return 0; // if none of the above, data has no meaning
}

//inverse function of GetInt
stock String:GetWeapon(int)
{
	new String:buffer[WEAPON_LENGTH] = "no_weapon";
	switch (int)
	{
		case WP_SMG: 				{buffer = "smg";}	
		case WP_SMG_SILENCED: 		{buffer = "smg_silenced";}
		case WP_PISTOL: 			{buffer = "pistol";}	
		case WP_PISTOL_MAGNUM: 		{buffer = "pistol_magnum";}	
		case WP_PUMPSHOTGUN: 		{buffer = "pumpshotgun";}	
		case WP_SHOTGUN_CHROME: 	{buffer = "shotgun_chrome";}
		case WP_AUTOSHOTGUN:		{buffer = "autoshotgun";}
		case WP_SHOTGUN_SPAS:		{buffer = "shotgun_spas";}
		case WP_HUNTING_RIFLE:		{buffer = "hunting_rifle";}
		case WP_SNIPER_MILITARY:	{buffer = "sniper_military";}
		case WP_SNIPER_AWP:			{buffer = "sniper_awp";}
		case WP_SNIPER_SCOUT:		{buffer = "sniper_scout";}
		case WP_MELEE:				{buffer = "melee";}
		case WP_RIFLE:				{buffer = "rifle";}
		case WP_RIFLE_AK47:			{buffer = "rifle_ak47";}
		case WP_RIFLE_DESERT:		{buffer = "rifle_desert";}
		case WP_RIFLE_SG552:		{buffer = "rifle_sg552";}
	}
	return buffer;
}

// returns the name of a hitgroup using its integer id
stock String:hitGroupName(hitgroup)
{
    new String:tmpString[15] = "";
    switch (hitgroup)
    {
        case 0: { tmpString = "generic"; }		//1.0x
        case 1: { tmpString = "head"; }			//4.0x (1.25x for shotguns)
        case 2: { tmpString = "chest"; }		//1.0x
        case 3: { tmpString = "stomach"; }		//1.25x
        case 4: { tmpString = "arm (left)"; }	//1.0x
        case 5: { tmpString = "arm (right"; }
        case 6: { tmpString = "leg (left)"; }	//0.75x
        case 7: { tmpString = "leg (right)"; }
        case 10: { tmpString = "gear"; }		//????
    }
    return tmpString;
}

// how many times higher than generic was the damage dealt?
stock Float:hitGroupMult(hitgroup)
{
	new Float:buffer;
	switch (hitgroup)
	{
		case 0: {buffer = 1.0;}		// generic
		case 1: {buffer = 4.0;}		// head
		case 2: {buffer = 1.0;}		//chest
		case 3: {buffer = 1.25;}	// stomach
		case 4: {buffer = 1.0;}		//arms
		case 5: {buffer = 1.0;}
		case 6: {buffer = 0.75;}	//legs
		case 7: {buffer = 0.75;}
		case 10:{buffer = 0.0;}		// what the hell is "gear" in l4d2?
	}
	return buffer;
}

/*notes and conclusions: 
-jockeys dont have legs! (or do they? doesnt look like it, but then again they just wont stand still)
-hitgroup multiplier is clearly applied before damage drop with distance, although this info has no real use
weapon stats:
-smg:  20 dmg (1 ff)  0.04 seconds  between shots
-sil:  25 dmg (1 ff)  
-crm:7x31 dmg (1 ff)  0.9-1 second between shots (0.75 with shove)
-pmp:9x25 dmg (1 ff) 
-pis:  36 dmg (1 ff)
-mgn:  80 dmg (2 ff)
-melee:5% on Tank (2 ff)
       25% on Witch
	   65% on Charger
	   100% on SI and CI*/ 