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

/* To-do:
 * Add difficulty rating to maps based on crox's logger data gathering
 * Add control over the minimum/maximum difficulty of maps as well as the entire match
 *			or rather, create a few presets: "easy", "normal" "hard" that have maps of corresponding difficulty
 * Maybe show scores in already played maps with maplist cause why the hell not?
 */

/*
Other possible future additions:

cmt_veto_style: (in addition to enforcing ordered vetoing, rather than relying on common courtesy)
	0: means 1-2-...-2-1 vetoing (team 1 gets 1 veto, team 2 gets 2, team 1 gets 2, ...)
	1: means 1-1-...-1-1 vetoing
cmt_veto_time:
	0: unlimited veto time
	>0: each team has this long for each of their vetoes. If this time elapses before they make a choice, they lose that veto.


don't forget about this: map pool has 5 maps, each team vetoes 1, which leaves 3, whether the map gets announced right away or only when it's about to be played is cvar'd
*/

#define DIR_CFGS "cfg/cmt/"
#define BUF_SZ	64
#define TAG_SZ	32

new Handle:	g_hCvarPoolsize;
new Handle:	g_hCvarMinPoolsize;
new Handle:	g_hCvarVetoCount;

new Handle:	g_hTrieGroups;	//handle to a trie that stores a (dyn. array of tries) by name of map group
new Handle:	g_hArrayGroupPlayOrder;
new Handle:	g_hArrayMapPools;
new			g_iPoolBeingVetoed;
new			g_iVetoesUsed[2];
new			g_bMaplistFinalized;
new			g_iMapsPlayed;

public OnPluginStart() {
	ResetScores();
    SetRandomSeed(seed:GetEngineTime());

	hTrieGroups = CreateTrie();

	//Pre-match commands
	RegServerCmd(	"sm_addmap",	AddMap,
					"Adds a map to a map group under the specified tags. Use without params for syntax.");
	RegServerCmd(	"sm_tagrank",	TagRank,
					"Sets a tag's rank in the group. Use without params for syntax.");
	//Match start commands
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


	g_hTrieGroups = CreateTrie();
	g_hArrayGroupPlayOrder = CreateArray();
	g_hArrayMapPools = CreateArray();
}

stock Handle:GetMapPool(String:tag[], poolsize) {
	new Handle:hArraySelectedMaps;
	new Handle:hArrayAvailableMaps;
	if (!GetTrieValue(g_hTrieTags, tag, &hArrayMaps)) return 0;
	
	if (GetArraySize(hArrayMaps) <= poolsize) {	//if there's no room for randomness, just get straight to it
		return hArrayAvailableMaps;
	} else { //otherwise, get random maps
		decl String:map[BUF_SZ];
		for (new i = 0; i < poolsize; i++) {
			GetArrayString(hArrayAvailableMaps, GetRandomInt(0, GetArraySize(hArrayMaps)), map, BUF_SZ);

			if (HasMapBeenSelected(map)) //no repetitions
				i--;
			else
				PushArrayString(hArraySelectedMaps, map);
		}
		return hArraySelectedMaps;
	}
}

public Action:MapSet(client, args) {
	if (args < 1) {
		ReplyToCommand("Syntax: sm_mapset <groupname>");
		ReplyToCommand("Prepares the map pools for the specified group.");
	}
	
	decl String:group[BUF_SZ];
	GetCmdArg(1, group, BUF_SZ);
	
	ServerCommand("exec DIR_CFGS%s", group);
	
	CreateTimer(2.0, Timed_PostMapsetLoad, group);
}

public Action:Timed_PostMapsetLoad(Handle:timer, any:group) {
	new Handle:hTrieTags;
	if (!GetTrieValue(g_hTrieGroups, group, &hTrieTags)) return Plugin_Stop;	//this will only happen if there is no such config
	
	new poolsize = GetConVarInt(g_hCvarPoolsize);
	new mapnum = GetArraySize(g_hArrayGroupPlayOrder);
	
	decl String:tag[TAG_SZ];
	for (new i = 0; i < mapnum; i++) {
		GetArrayString(g_hArrayGroupPlayOrder, i, tag, TAG_SZ);
		PushArrayCell(g_hArrayMapPools, GetMapPool(hTrieTags, tag, poolsize));
	}
}

stock Handle:GetPoolThatContainsMap(String:map[]) {
	for (new i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		new hArrayPool = GetArrayCell(g_hArrayMapPools, i);
		if (FindStringInArray(hArrayPool, map) > 0) {
			return hArrayPool;
		}
	}
	return INVALID_HANDLE;
}

stock bool:HasMapBeenSelected(String:map[]) {	//could use a trie instead, but meh
	for (new i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		if (FindStringInArray(GetArrayCell(g_hArrayMapPools, i), map) > 0) {
			return 1;
		}
	}
	return 0;
}

public Action:Veto(client, args) {
	new team = GetClientTeam(client) - 2;
	if (team < 0) {
		ReplyToCommand(client, "You're a spectator, no veto for you.");
		return Plugin_Handled;
	}
	
	if (g_bMaplistFinalized) {
		ReplyToCommand(client, "This is not the time to be vetoing!");
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
		ReplyToCommand(client, "Invalid map.");
		return Plugin_Handled;
	}

	if (GetArraySize(hArrayPool) <= GetConVarInt(g_hCvarMinPoolsize)) {
		ReplyToCommand(client, "Sorry! There are too few maps in the pool the specified map belongs to: no more can be removed.");
	} else {
		RemoveFromArray(hArrayPool, index);
		PrintToChatAll("Map %s has been removed from its pool.", map);
		++g_iVetoesUsed[team];
	}
	
	if (g_iVetoesUsed[0] == GetConVarInt(g_hCvarVetoCount) && g_iVetoesUsed[1] == GetConVarInt(g_hCvarVetoCount)) {
		VetoingIsOver();
		CreateTimer(1.0, Timed_TickTock, TIMER_REPEAT);
	}
	
	return Plugin_Handled;
}

stock VetoingIsOver() {
	g_bMaplistFinalized = true;

	new i, size;

	//Select 1 random map from each pool
	for (i = 0; i < GetArraySize(g_hArrayMapPools); i++) {
		new Handle:hArrayPool = GetArrayCell(g_hArrayMapPools, i);
		while ((size = GetArraySize(hArrayPool)) > 1) {
			RemoveFromArray(hArrayPool, GetRandomInt(0, size - 1));
		}
	}
	
	//Show final maplist to everyone
	PrintToChatAll("Map list has been settled!");
	for (i = 1; i <= MaxClients; i++) {
		Maplist(client);
	}
}

public Action:Timed_TickTock(Handle:timer) {
	static Float:fTimeRemaining = 5.0;
	
	if (fTimeRemaining > 0.0) {
		fTimeRemaining -= 1.0;
		PrintToChatAll("Game will start in %f seconds.", fTimeRemaining);
		return Plugin_Continue;
	}
	
	ResetScores();
	GotoNextMap();
}

public Action:Maplist(client, args) {
	PrintToChat(client, "Maplist: ");
	decl String:buffer[MAXLENGTH];
	for (new i = 0; i <= GetArraySize(hArrayMaps); i++) {
		GetArrayString(GetArrayCell(g_hArrayMapPools, i), 0, buffer, BUF_SZ);
		PrintToChat(client, "\t%d - %s", i + 1, RefineMapName(buffer));
	}
	return Plugin_Handled;
}

public L4D2_OnRealRoundEnd(roundNumber) {
    if (roundNumber) {
		g_iMapsPlayed++;
		
		//force-end the game since only finales would usually really end it
		if (g_iMapsPlayed == GetArraySize(g_hArrayMapPools)) ServerCommand("sm_resetmatch");
		
		GotoNextMap();
    }
}

stock GotoNextMap() {
	decl String:buffer[BUF_SZ];
	GetArrayString(GetArrayCell(g_hArrayMapPools, g_iMapsPlayed), 0, buffer, BUF_SZ);
	ForceChangeLevel(buffer, "Custom map transition.");
}

stock ResetScores() {
	GameRules_SetProp("m_iSurvivorScore", 0, _, 0); //reset scores
	GameRules_SetProp("m_iSurvivorScore", 0, _, 1); //    
}

public Action:TagRank(args) {
	if (args < 2) {
		ReplyToCommand("Syntax: sm_tagrank <tag> <map number>");
		ReplyToCommand("Sets tag <tag> as the tag to be used to fetch maps for map <map number> in the map list.");
		ReplyToCommand("Rank 0 is map 1, rank 1 is map 2, etc.");
	} else {
		decl String:buffer[TAG_SZ];
		GetCmdArg(2, buffer, TAG_SZ);
		new index = StringToInt(buffer);
		
		GetCmdArg(1, buffer, TAG_SZ);
		
		if (index >= GetArraySize(g_hArrayGroupPlayOrder)) {
			ResizeArray(g_hArrayGroupPlayOrder, index + 1);
		}
		
		SetArrayString(g_hArrayGroupPlayOrder, index, buffer);
	}
	
	return Plugin_Handled;
}

public Action:AddMap(args) {
	if (args < 3) {
		ReplyToCommand("Syntax: sm_addmap <groupname> <mapname> <tag1> <tag2> <...>");
		ReplyToCommand("Adds <mapname> to <groupname> and tags it with every mentioned tag.");
	} else {
		decl String:group[BUF_SZ];
		GetCmdArg(1, group, BUF_SZ);
		decl String:map[BUF_SZ];
		GetCmdArg(2, map, BUF_SZ);
		
		//get the trie of all tags for this group from the trie of all groups
		new Handle:hTrieTags;
		if (!GetTrieValue(g_hTrieGroups, group, &hTrieTags)) SetTrieValue(g_hTrieGroups, group, hTrieTags); 
		
		//add all tags to the trie, and push the mapname onto each corresponding array
		for (new i = 3; i <= args; i++) {
			GetCmdArg(i, tag, TAG_SZ);
			new Handle:hArrayMaps;
			if (!GetTrieValue(hTrieTags, tag, &hArrayMaps)) SetTrieValue(h_TrieTags, tag, hArrayMaps);
			PushArrayString(hArrayMaps, map);
		}
	}
	
	return Plugin_Handled;
}

//TODO-MAYBE get user-friendly names, that aren't "c10m1_blablabla"
stock String:RefineMapName(String:map[]) {
	return map;
}
