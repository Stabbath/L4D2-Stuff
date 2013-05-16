#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2util>

public Plugin:myinfo =
{
	name = "Custom Map Transitions",
	author = "Stabby",
	description = "Makes games more fun and varied! Yay!",
	version = "1.0",
	url = "no url"
};

/* TODO:
 * - Maybe show scores in already played maps with maplist cause why the hell not?
 */

/*
Other possible future additions:

cmt_veto_style: (in addition to enforcing ordered vetoing, rather than relying on common courtesy)
	0: means free vetoing
	1: means 1-1-...-1-1 vetoing
	2: means 1-2-...-2-1 vetoing (team 1 gets 1 veto, team 2 gets 2, team 1 gets 2, ...)
cmt_veto_time:
	0: unlimited veto time
	>0: each team has this long for each of their vetoes. If this time elapses before they make a choice, they lose that veto.


don't forget about this: map pool has 5 maps, each team vetoes 1, which leaves 3, whether the map gets announced right away or only when it's about to be played is cvar'd
*/

#define DIR_CFGS "cmt/"
#define BUF_SZ	64
#define TAG_SZ	32

new Handle:	g_hCvarPoolsize;
new Handle:	g_hCvarMinPoolsize;
new Handle:	g_hCvarVetoCount;

new Handle:	g_hTrieTags;
new Handle:	g_hArrayGroupPlayOrder;
new Handle:	g_hArrayMapPools;
new			g_iVetoesUsed[2];
new			g_bMaplistFinalized;
new			g_iMapsPlayed;
new bool:	g_bMapsetInitialized;

/*
	logic:
	- maps are added with sm_addmap
		maps are added to an array that is stored by tag name in g_hTrieTags
	- maps are ranked with sm_tagrank
		tags are added in order of rank to g_hArrayGroupPlayOrder
	
	a map pool of up to cmt_poolsize is selected for each rank by removing maps from the
	arrays in g_hTrieTags until there's only cmt_poolsize left
	
	players are allowed to veto maps until their team has used all their vetoes, with vetoing
	removing the vetoed map from its pool.
	
	after all vetoes are done, remaining maps for each pool are removed until there's only 
	1 per pool, and that will be the final map list
*/





public OnPluginStart() {
	ResetScores();
	SetRandomSeed(seed:GetEngineTime());

	//Pre-match commands
	RegServerCmd(	"sm_addmap",	AddMap,
					"Adds a map to a map group under the specified tags. Use without params for syntax.");
	RegServerCmd(	"sm_tagrank",	TagRank,
					"Sets a tag's rank in the group. Use without params for syntax.");
	RegServerCmd(	"sm_mapset",	MapSet,
					"Loads the mapset for the specified group. Use without params for syntax.");
	//Match commands
	RegConsoleCmd(	"sm_maplist",	Maplist,
					"Shows a player cmt's selected map list.");
	RegConsoleCmd(	"sm_veto",		Veto,
					"Lets players veto a map. Uses per team per game cvar'd.");
	
	
	
	
	g_hCvarPoolsize = CreateConVar(		"cmt_poolsize", "1",
										"How many maps will be initially pooled for each rank.",
										FCVAR_PLUGIN, true, 1.0, false);
	g_hCvarMinPoolsize = CreateConVar(	"cmt_minimum_poolsize", "1",
										"How many maps must remain in each pool after vetoing.",
										FCVAR_PLUGIN, true, 1.0, false);
	g_hCvarVetoCount = CreateConVar(	"cmt_veto_count", "0",
										"How many vetoes each team gets.",
										FCVAR_PLUGIN, true, 0.0, false);
/*	g_hCvarRepetitions = CreateConVar(	"cmt_repetitions", "1",				//TODO: add this, maybe
										"How many times can a map be chosen (for different pools).",
										FCVAR_PLUGIN, true, 1.0, false);*/

	g_hTrieTags = CreateTrie();
	g_hArrayGroupPlayOrder = CreateArray();
	g_hArrayMapPools = CreateArray();
}

stock Handle:GetMapPool(String:tag[], poolsize) {
	decl Handle:hArrayAvailableMaps;
	if (!GetTrieValue(g_hTrieTags, tag, hArrayAvailableMaps)) return INVALID_HANDLE;
	
	if (GetArraySize(hArrayAvailableMaps) <= poolsize) {	//if there's no room for randomness, just get straight to it
		return hArrayAvailableMaps;
	} else { //otherwise, get random maps
		new Handle:hArraySelectedMaps = CreateArray();
		decl String:map[BUF_SZ];
		for (new i = 0; i < poolsize; i++) {
			GetArrayString(hArrayAvailableMaps, GetRandomInt(0, GetArraySize(hArrayAvailableMaps)), map, BUF_SZ);

			if (HasMapBeenSelected(map)) //no repetitions
				i--;
			else
				PushArrayString(hArraySelectedMaps, map);
		}
		return hArraySelectedMaps;
	}
}


//server cmd: loads a cmt cfg
public Action:MapSet(args) {
	if (args < 1) {
		ReplyToCommand(0, "Syntax: sm_mapset <groupname>");
		ReplyToCommand(0, "Prepares the map pools for the specified group.");
	}

	if (g_bMapsetInitialized) {
		ReplyToCommand(0, "Sorry, a map preset is already loaded. To select a different one you have to resetmatch and then load the config again before selecting a different mapset.");
	}
	
	decl String:group[BUF_SZ];
	GetCmdArg(1, group, BUF_SZ);
	
	ServerCommand("exec %s%s.cfg", DIR_CFGS, group);
	ReplyToCommand(0, "Loading %s preset...", group);
	g_bMapsetInitialized = true;

	new Handle:tmpstack = CreateStack(BUF_SZ);
	PushStackString(tmpstack, group);
	CreateTimer(1.0, Timed_PostMapsetLoad, tmpstack);

	return Plugin_Handled;
}

//creates the initial map list after a map set has been loaded
public Action:Timed_PostMapsetLoad(Handle:timer, any:tmpstack) {
	decl String:group[BUF_SZ];
	PopStackString(tmpstack, group, BUF_SZ);
	
	new poolsize = GetConVarInt(g_hCvarPoolsize);
	new mapnum = GetArraySize(g_hArrayGroupPlayOrder);
	
	if (mapnum == 0 || GetArraySize(g_hArrayMapPools) == 0) {
		g_bMapsetInitialized = false;	//failed to load it on the exec
		PrintToChatAll("Failed to load preset.");
	}
	
	decl String:tag[TAG_SZ];
	for (new i = 0; i < mapnum; i++) {
		GetArrayString(g_hArrayGroupPlayOrder, i, tag, TAG_SZ);
		PushArrayCell(g_hArrayMapPools, GetMapPool(tag, poolsize));
		PrintToChatAll("Map tag for map %d is \"%s\".", i, tag);
	}
	
	PrintToChatAll("Map set has been loaded!");

	//if no vetoes are allowed, just go straight to vetoingisover
	if (GetConVarInt(g_hCvarVetoCount) == 0) {
		VetoingIsOver();
	} else {
		PrintToChatAll("You may now veto maps from the map list.");
	}
}

//returns a handle to the first array which is found to contain the specified mapname
stock Handle:GetPoolThatContainsMap(String:map[]) {
	for (new i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		new Handle:hArrayPool = GetArrayCell(g_hArrayMapPools, i);
		if (FindStringInArray(hArrayPool, map) > 0) {
			return hArrayPool;
		}
	}
	return INVALID_HANDLE;
}

//returns whether or not a map has already been selected
stock bool:HasMapBeenSelected(String:map[]) {	//could use a trie instead, but meh
	for (new i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		if (FindStringInArray(GetArrayCell(g_hArrayMapPools, i), map) > 0) {
			return true;
		}
	}
	return false;
}

//client cmd: vetoes a map off the list
public Action:Veto(client, args) {
	new team = GetClientTeam(client) - 2;
	if (team < 0) {
		ReplyToCommand(client, "You're a spectator, no veto for you.");
		return Plugin_Handled;
	}
	
	if (g_bMaplistFinalized) {
		ReplyToCommand(client, "The time for vetoes is already over!");
		return Plugin_Handled;
	}
	
	if (g_iVetoesUsed[team] == GetConVarInt(g_hCvarVetoCount)) {
		ReplyToCommand(client, "Your team has used all of its vetoes!");
		return Plugin_Handled;
	}

	if (args < 1) {
		ReplyToCommand(client, "Please specify a map.");
		return Plugin_Handled;
	}
	
	decl String:map[BUF_SZ];
	GetCmdArg(1, map, BUF_SZ);
	
	new Handle:hArrayPool = GetPoolThatContainsMap(map);
	if (hArrayPool == INVALID_HANDLE) {
		ReplyToCommand(client, "Invalid map, no pool contains it.");
		return Plugin_Handled;
	}

	if (GetArraySize(hArrayPool) <= GetConVarInt(g_hCvarMinPoolsize)) {
		ReplyToCommand(client, "Sorry! There are too few maps in the pool the specified map belongs to: no more can be removed.");
		return Plugin_Handled;
	}
	
	RemoveFromArray(hArrayPool, FindStringInArray(hArrayPool, map));
	PrintToChatAll("Map %s has been removed from its pool.", map);
	++g_iVetoesUsed[team];
	
	if (g_iVetoesUsed[0] == GetConVarInt(g_hCvarVetoCount) && g_iVetoesUsed[1] == GetConVarInt(g_hCvarVetoCount)) {
		VetoingIsOver();
	}
	
	return Plugin_Handled;
}

//called after the last veto has been used
stock VetoingIsOver() {
	g_bMaplistFinalized = true;
	
	new i, size;
	new Handle:hArrayPool;
	
	//Select 1 random map from each pool
	for (i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		hArrayPool = GetArrayCell(g_hArrayMapPools, i);
		while ((size = GetArraySize(hArrayPool)) > 1) {
			RemoveFromArray(hArrayPool, GetRandomInt(0, size - 1));
		}
	}
	
	//Show final maplist to everyone
	PrintToChatAll("Map list has been settled!");
	for (i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i))
			FakeClientCommand(i, "sm_maplist");
	}

	CreateTimer(2.0, Timed_TickTock, TIMER_REPEAT);
}

//called after vetoing is over
public Action:Timed_TickTock(Handle:timer) {
	static Float:fTimeRemaining = 5.0;
	
	if (fTimeRemaining > 0.0) {
		PrintToChatAll("Game will start in %.0f seconds.", fTimeRemaining);
		fTimeRemaining -= 1.0;
		return Plugin_Continue;
	}
	
	ResetScores();
	GotoNextMap();
	return Plugin_Stop;
}

//client cmd: displays map list
public Action:Maplist(client, args) {
	PrintToChat(client, "Maplist: ");
	decl String:buffer[BUF_SZ];
	decl Handle:hArrayMaps;
	for (new i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		hArrayMaps = GetArrayCell(g_hArrayMapPools, i);
		for (new j = 0; j < GetArraySize(hArrayMaps); j++) {
			GetArrayString(hArrayMaps, 0, buffer, BUF_SZ);
			PrintToChat(client, "\t%d - %s", i + 1, RefineMapName(buffer));
		}
	}
	return Plugin_Handled;
}

//forces map transitions
public L4D2_OnRealRoundEnd(roundNumber) {
    if (roundNumber) {
		g_iMapsPlayed++;
		
		//force-end the game since only finales would usually really end it
		if (g_iMapsPlayed == GetArraySize(g_hArrayMapPools)) ServerCommand("sm_resetmatch");
		
		GotoNextMap();
    }
}

//changes map
stock GotoNextMap() {
	decl String:buffer[BUF_SZ];
	GetArrayString(GetArrayCell(g_hArrayMapPools, g_iMapsPlayed), 0, buffer, BUF_SZ);
	ForceChangeLevel(buffer, "Custom map transition.");
}

//sets teams' scores to 0
stock ResetScores() {
	GameRules_SetProp("m_iSurvivorScore", 0, _, 0); //reset scores
	GameRules_SetProp("m_iSurvivorScore", 0, _, 1); //    
}

//server cmd: specifies a rank for a given tag
public Action:TagRank(args) {
	if (args < 2) {
		ReplyToCommand(0, "Syntax: sm_tagrank <tag> <map number>");
		ReplyToCommand(0, "Sets tag <tag> as the tag to be used to fetch maps for map <map number> in the map list.");
		ReplyToCommand(0, "Rank 0 is map 1, rank 1 is map 2, etc.");
	} else {
		decl String:buffer[TAG_SZ];
		GetCmdArg(2, buffer, TAG_SZ);
		new index = StringToInt(buffer);
		
		GetCmdArg(1, buffer, TAG_SZ);
		
		if (index >= GetArraySize(g_hArrayGroupPlayOrder)) {
			ResizeArray(g_hArrayGroupPlayOrder, index + 1);
		}
		
		SetArrayString(g_hArrayGroupPlayOrder, index, buffer);
		
		PrintToChatAll("Added tag %d
	}
	
	return Plugin_Handled;
}

//server cmd: adds a map to the maplist under specified tags
public Action:AddMap(args) {
	if (args < 2) {
		ReplyToCommand(0, "Syntax: sm_addmap <mapname> <tag1> <tag2> <...>");
		ReplyToCommand(0, "Adds <mapname> to the map selection and tags it with every mentioned tag.");
	} else {
		decl String:map[BUF_SZ];
		GetCmdArg(1, map, BUF_SZ);
		
		decl String:tag[TAG_SZ];
		
		//add all tags to the trie, and push the mapname onto each corresponding array
		for (new i = 2; i <= args; i++) {
			GetCmdArg(i, tag, TAG_SZ);
			new Handle:hArrayMaps;
			if (!GetTrieValue(g_hTrieTags, tag, hArrayMaps)) SetTrieValue(g_hTrieTags, tag, (hArrayMaps = CreateArray()));
			PushArrayString(hArrayMaps, map);
		}
	}
	
	return Plugin_Handled;
}

//returns a user-friendly name for a give map, that isn't "c10m1_blablabla" TODO 
stock String:RefineMapName(String:map[]) {
	return map;
}
