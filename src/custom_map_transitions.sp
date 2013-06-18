#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2util_rounds>
#include <left4downtown>

//things to test maybe
//	L4D_RestartScenarioFromVote(const String:map[]); 
//	L4D_GetTeamScore(logical_team, campaign_score=false);
//	L4D_GetCampaignScores(&scoreA, &scoreB);


/*
1: Collect underpants
2a: Fetch all maps from each preset pool into a plugin pool
	- if a map is tagged for 2+ pools in the preset, load it only into one of them
2b: Remove until there's only cmt_poolsize maps or less in each plugin pool
2c: Store the pool order, ie pool 1 is used for map 1, pool 2 for map 2, pool 1 for map 3, pool 3 for map 4, etc
2d: Go through vetoing process
2e: Select the final maplist from the remaining maps according to the pool order
3: Profit
*/

public Plugin:myinfo =
{
	name = "Custom Map Transitions",
	author = "Stabby",
	description = "Makes games more fun and varied! Yay!",
	version = "3",
	url = "https://github.com/Stabbath/L4D2-Stuff"
};

/* TODO:
 * - test !forcemapset
 * - make it so everything in the plugin is reset after the last map in the mapset
 * - maybe add a safeguard in case, for example, there's 9 maps and 3 vetoes per team, all maps belong to the same pool, and 4 is the min poolsize. the 6th veto will not be usable, so players would be stuck in the vetoing process (unless void is allowed)
 * - re-test using mapend instead of onroundend; possibly put level change on a timer after round end
 * - maybe add cvar for unbalanced vetoes: -1 keeps balanced, 0 means survivors get an extra veto, 1 means infected get an extra veto
 * - possibly replace cmt_minimum_poolsize on a per-tag basis, since you might want to have 3 min pool for a tag but 1 min pool for another one, if the first is used by 3 ranks and the 2nd by only 1 or any other scenario
 * - Maybe show scores in already played maps with maplist cause why the hell not?
 */

#define DIR_CFGS "cmt/"
#define BUF_SZ	64
#define TIME_MAPCHANGE_DELAY	10.0	//5 worked perfectly, but maybe higher values are better?

new Handle:	g_hCvarPoolsize;
new Handle:	g_hCvarMinPoolsize;
new Handle:	g_hCvarVetoCount;
new Handle:	g_hCvarAllowVoid;

new Handle:	g_hArrayTags;				//stores tags for indexing g_hTriePools
new Handle:	g_hTriePools;				//stores pool array handles by tag name
new Handle:	g_hArrayTagOrder;			//stores tags by rank
new Handle:	g_hArrayMapOrder;			//stores finalised map list in order
new			g_iVetoesUsed[2];
new	bool:	g_bMaplistFinalized;
new			g_iMapsPlayed;
new bool:	g_bMapsetInitialized;
new			g_iMapCount;

public OnPluginStart() {
	SetRandomSeed(seed:GetEngineTime());

	//Pre-match commands
	RegConsoleCmd(	"sm_forcemapset",	ForceMapSet,
					"Starts a mapset according to the maps specified in the params.");
	RegConsoleCmd(	"sm_mapset",		MapSet,
					"Loads the mapset for the specified group. Use without params for syntax.");
	RegServerCmd(	"sm_addmap",		AddMap,
					"Adds a map to a map group under the specified tags. Use without params for syntax.");
	RegServerCmd(	"sm_tagrank",		TagRank,
					"Sets a tag's rank in the group. Use without params for syntax.");
	RegServerCmd(	"sm_mapsetlock",	Lock,
					"Locks and finalizes a mapset, allowing the plugin to start processing it.");
	//Match commands
	RegConsoleCmd(	"sm_maplist",		Maplist,
					"Shows a player cmt's selected map list.");
	RegConsoleCmd(	"sm_veto",			Veto,
					"Lets players veto a map. Uses per team per game cvar'd.");

	
	g_hCvarPoolsize = CreateConVar(		"cmt_poolsize", "1000",
										"How many maps will be initially pooled for each tag.",
										FCVAR_PLUGIN, true, 1.0, false);
	g_hCvarMinPoolsize = CreateConVar(	"cmt_minimum_poolsize", "1",
										"How many maps must remain in each pool after vetoing.",
										FCVAR_PLUGIN, true, 1.0, false);
	g_hCvarVetoCount = CreateConVar(	"cmt_veto_count", "0",
										"How many vetoes each team gets.",
										FCVAR_PLUGIN, true, 0.0, false);
	g_hCvarAllowVoid = CreateConVar(	"cmt_allow_void", "1",
										"Are teams allowed to veto @void, therefore discarding a veto?",
										FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_hArrayTags = CreateArray(BUF_SZ/4);	//1 block = 4 characters => X characters = X/4 blocks
	g_hTriePools = CreateTrie();
	g_hArrayTagOrder = CreateArray(BUF_SZ/4);
	g_hArrayMapOrder = CreateArray(BUF_SZ/4);
}

public OnMapStart() {
	SetNextMap("#game_nextmap");
}

public OnPluginEnd() {
	SetNextMap("#game_nextmap");
}

//console cmd: loads a specified set of maps
public Action:ForceMapSet(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "Syntax: sm_mapset <map1> <map2> <map3> <...>");
		ReplyToCommand(client, "Launches a mapset as specified.");
	}
	
	if (g_bMapsetInitialized) {
		ReplyToCommand(client, "Sorry, a map preset is already loaded. To select a different one you have to resetmatch and then load the config again before selecting a different mapset.");
		return Plugin_Handled;
	}
	
	//so things don't break and so the game starts right away
	ResetConVar(g_hCvarPoolsize);
	ResetConVar(g_hCvarMinPoolsize);
	ResetConVar(g_hCvarVetoCount);

	decl String:map[BUF_SZ];
	for (new i = 1; i <= args; i++) {
		GetCmdArg(i, map, BUF_SZ);
		ServerCommand("sm_addmap %s %d", map, i);
		ServerCommand("sm_tagrank %d %d", i, i-1);
	}
	ServerCommand("sm_mapsetlock");

	return Plugin_Handled;
}

//console cmd: loads a cmt cfg
public Action:MapSet(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "Syntax: sm_mapset <groupname>");
		ReplyToCommand(client, "Prepares the map pools for the specified group.");
	}

	if (g_bMapsetInitialized) {
		ReplyToCommand(client, "Sorry, a map preset is already loaded. To select a different one you have to resetmatch and then load the config again before selecting a different mapset.");
		return Plugin_Handled;
	}
	
	decl String:group[BUF_SZ];
	GetCmdArg(1, group, BUF_SZ);
	
	ServerCommand("exec %s%s.cfg", DIR_CFGS, group);
	PrintToChatAll("Loading %s preset...", group);
	g_bMapsetInitialized = true;

	return Plugin_Handled;
}

//creates the initial map list after a map set has been loaded
public Action:Lock(args) {
	if (g_bMaplistFinalized) {
		ReplyToCommand(0, "The map list is already finalized, what are you trying to lock?");
		return Plugin_Handled;
	}

	new mapnum = GetArraySize(g_hArrayTagOrder);
	new triesize = GetTrieSize(g_hTriePools);
	
	if (mapnum == 0) {
		g_bMapsetInitialized = false;	//failed to load it on the exec
		PrintToChatAll("Failed to load preset.");
		return Plugin_Handled;
	}

	if (g_iMapCount < triesize) {
		g_bMapsetInitialized = false;	//bad preset format
		PrintToChatAll("Preset has improper tagranks: the number of maps to be played does not match the highest rank. Should have N+1 tagranks for highest rank N.");
		return Plugin_Handled;
	}
	
	//all this to cut each pool down to cmt_poolsize maps
	decl String:buffer[BUF_SZ];
	decl Handle:hArrayMapPool;
	new poolsize = GetConVarInt(g_hCvarPoolsize);
	new tagnum = GetArraySize(g_hArrayTags);
	decl sizepool;
	for (new i = 0; i < tagnum; i++) {
		GetArrayString(g_hArrayTags, i, buffer, BUF_SZ);
		GetTrieValue(g_hTriePools, buffer, hArrayMapPool);
		while ((sizepool = GetArraySize(hArrayMapPool)) >= poolsize) {
			RemoveFromArray(hArrayMapPool, GetRandomInt(0, sizepool - 1));
		}
	}

	PrintToChatAll("Map set has been loaded!");

	//if no vetoes are allowed, just go straight to vetoingisover
	if (GetConVarInt(g_hCvarVetoCount) == 0) {
		VetoingIsOver();
	} else {
		PrintToChatAll("You may now veto maps from the map list.");
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i))
				FakeClientCommand(i, "sm_maplist");
		}
	}

	return Plugin_Handled;
}

//returns a handle to the first array which is found to contain the specified mapname (should be the first and only one)
stock Handle:GetPoolThatContainsMap(String:map[], &index) {
	decl String:buffer[BUF_SZ];
	decl Handle:hArrayMapPool;

	for (new i = 0; i < GetArraySize(g_hArrayTags); i++) {
		GetArrayString(g_hArrayTags, i, buffer, BUF_SZ);
		GetTrieValue(g_hTriePools, buffer, hArrayMapPool);
		if ((index = FindStringInArray(hArrayMapPool, map)) >= 0) {
			return hArrayMapPool;
		}
	}
	return INVALID_HANDLE;
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
	
	if (StrEqual(map, "@void", false)) {
		if (GetConVarBool(g_hCvarAllowVoid)) {
			PrintToChatAll("Veto discarded.");
			++g_iVetoesUsed[team];
		} else {
			ReplyToCommand(client, "Sorry, @void vetoes are disabled.");
		}
	} else {
	
		decl index;
		new Handle:hArrayPool = GetPoolThatContainsMap(map, index);
		if (hArrayPool == INVALID_HANDLE) {
			ReplyToCommand(client, "Invalid map, no pool contains it.");
			return Plugin_Handled;
		}

		if (GetArraySize(hArrayPool) <= GetConVarInt(g_hCvarMinPoolsize)) {
			ReplyToCommand(client, "Sorry! There are too few maps in the pool the specified map belongs to: no more can be removed.");
			return Plugin_Handled;
		}
	
		RemoveFromArray(hArrayPool, index);
		PrintToChatAll("Map %s has been removed from its pool.", map);
		++g_iVetoesUsed[team];

	}

	if (g_iVetoesUsed[0] == GetConVarInt(g_hCvarVetoCount) && g_iVetoesUsed[1] == GetConVarInt(g_hCvarVetoCount)) {
		PrintToChatAll("Vetoing is over.");
		VetoingIsOver();
	}
	
	return Plugin_Handled;
}

//called after the last veto has been used
stock VetoingIsOver() {
	g_bMaplistFinalized = true;
	
	decl i, mapIndex;
	decl Handle:hArrayPool;
	decl String:tag[BUF_SZ];
	decl String:map[BUF_SZ];

	//Select 1 random map for each rank out of the remaining ones
	for (i = 0; i < GetArraySize(g_hArrayTagOrder); i++) {
		GetArrayString(g_hArrayTagOrder, i, tag, BUF_SZ);
		GetTrieValue(g_hTriePools, tag, hArrayPool);
		mapIndex = GetRandomInt(0, GetArraySize(hArrayPool) - 1);	

		GetArrayString(hArrayPool, mapIndex, map, BUF_SZ);
		RemoveFromArray(hArrayPool, mapIndex);
		PushArrayString(g_hArrayMapOrder, map);
	}

	//clear things because we only need the finalised map order in memory
	for (i = 0; i < GetArraySize(g_hArrayTagOrder); i++) {
		GetArrayString(g_hArrayTagOrder, i, tag, BUF_SZ);
		GetTrieValue(g_hTriePools, tag, hArrayPool);
		ClearArray(hArrayPool);
	}
	ClearTrie(g_hTriePools);
	ClearArray(g_hArrayTagOrder);

	//Show final maplist to everyone
	PrintToChatAll("Map list has been settled!");
	for (i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i))
			FakeClientCommand(i, "sm_maplist");
	}

	PrintToChatAll("Game will start in 8 seconds.");
	CreateTimer(8.0, Timed_GiveThemTimeToReadTheMapList);
}

public Action:Timed_GiveThemTimeToReadTheMapList(Handle:timer) {
	ResetScores();	//scores wouldn't cross over because of forced map change before 2nd round end, but doesnt hurt
	GotoNextMap(true);
}

//client cmd: displays map list
public Action:Maplist(client, args) {
	PrintToChat(client, "Maplist: ");
	decl String:buffer[BUF_SZ];

	if (g_bMaplistFinalized) {
		for (new i = 0; i < GetArraySize(g_hArrayMapOrder); i++) {
			GetArrayString(g_hArrayMapOrder, i, buffer, BUF_SZ);
			PrintToChat(client, "%2d - %s", i + 1, buffer);
		}
	} else {
		PrintToChat(client, "should be printing maplist, unless there's segfaults");
		decl Handle:hArrayMapPool;
		decl String:tag[BUF_SZ];
		for (new i = 0; i < GetArraySize(g_hArrayTagOrder); i++) {
			GetArrayString(g_hArrayTagOrder, i, tag, BUF_SZ);
			GetTrieValue(g_hTriePools, tag, hArrayMapPool);
			PrintToChat(client, "%2d - %s", i + 1, tag);
			for (new j = 0; j < GetArraySize(hArrayMapPool); j++) {
				GetArrayString(hArrayMapPool, j, buffer, BUF_SZ);
				PrintToChat(client, "\t%s", buffer);
			}
		}
	}
	return Plugin_Handled;
}

//change map a bit after round end, because onmapend was too late
/*public OnRoundEnd() {
	if (InSecondHalfOfRound()) {
		g_iMapsPlayed++;

		//if it's over, just let the game do whatever it wants. Maybe force-end it later
//		if (g_iMapsPlayed < g_iMapCount) GotoNextMap(L4D_IsMissionFinalMap());
	}
}*/

//changes map
GotoNextMap(bool:force=false) {
	decl String:buffer[BUF_SZ];
	GetArrayString(g_hArrayMapOrder, g_iMapsPlayed, buffer, BUF_SZ);

	if (force) {
//		L4D_RestartScenarioFromVote(buffer);	<- this doesnt seem to work, it sends people to the main menu ( left4downtown)
		ForceChangeLevel(buffer, "Custom map transition.");
	} else {
		SetNextMap(buffer);
	}
}

//stop scores from being reset on finales 
//they'd be kinda reset on normal maps too if those weren't handled with SetNextMap()
//public Action:L4D_OnClearTeamScores(bool:newCampaign) {
//	if (newCampaign) return Plugin_Handled;
//	return Plugin_Continue;	
//}

//Action:L4D_OnSetCampaignScores(&scoreA, &scoreB); <- maybe use this to track map scores?

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
		decl String:buffer[BUF_SZ];
		GetCmdArg(2, buffer, BUF_SZ);
		new index = StringToInt(buffer);
		
		GetCmdArg(1, buffer, BUF_SZ);
		
		if (index >= GetArraySize(g_hArrayTagOrder)) {
			ResizeArray(g_hArrayTagOrder, index + 1);
		}
		
		g_iMapCount++;
		SetArrayString(g_hArrayTagOrder, index, buffer);
		PushArrayString(g_hArrayTags, buffer);
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
		
		decl String:tag[BUF_SZ];
		
		//add the map under only one of the tags
		//TODO - maybe we should add it under all tags, since it might be removed from 1+ or even all of them anyway
		//also, if that ends up being implemented, remember to remove vetoed maps from ALL the pools it belongs to
		if (args == 2) {
			GetCmdArg(2, tag, BUF_SZ);
		} else {
			GetCmdArg(GetRandomInt(2, args), tag, BUF_SZ);
		}

		decl Handle:hArrayMapPool;
		if (!GetTrieValue(g_hTriePools, tag, hArrayMapPool))
			SetTrieValue(g_hTriePools, tag, (hArrayMapPool = CreateArray(BUF_SZ/4)));

		PushArrayString(hArrayMapPool, map);
	}
	
	return Plugin_Handled;
}


public Action:L4D_OnSetCampaignScores(&scoreA, &scoreB) {
	PrintToChatAll("OnSetCampScores: Setting campaign scores! A: %d B: %d", scoreA, scoreB);
	LogMessage("OnSetCampScores: Setting campaign scores! A: %d B: %d", scoreA, scoreB);

	PrintToChatAll("OnSetCampScores: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	LogMessage("OnSetCampScores: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	PrintToChatAll("OnSetCampScores: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));
	LogMessage("OnSetCampScores: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));

	CreateTimer(1.0, Timed_postset);
}
public Action:Timed_postset(Handle:timer) {
	PrintToChatAll("POST setcamp: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	LogMessage("POST setcamp: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	PrintToChatAll("POST setcamp: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
	LogMessage("POST setcamp: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
}


public Action:L4D_OnClearTeamScores(bool:newCampaign) {
	PrintToChatAll("OnClearTeamScores");
	LogMessage("OnClearTeamScores");

	PrintToChatAll("OnClearTeamScores: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	LogMessage("OnClearTeamScores: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	PrintToChatAll("OnClearTeamScores: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
	LogMessage("OnClearTeamScores: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	

	CreateTimer(1.0, Timed_postclear);
}
public Action:Timed_postclear(Handle:timer) {
	PrintToChatAll("POST OnClearTeamScores: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	LogMessage("POST OnClearTeamScores: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	PrintToChatAll("POST ClearTeamScores: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
	LogMessage("POST ClearTeamScores: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
	
	g_iMapsPlayed++;

	if (g_iMapsPlayed < g_iMapCount) GotoNextMap(L4D_IsMissionFinalMap());
}


public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors) {
	PrintToChatAll("OnEndVersusModeRound");
	LogMessage("OnEndVersusModeRound");

	PrintToChatAll("OnEndVsRnd: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	LogMessage("OnEndVsRnd: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	PrintToChatAll("OnEndVsRnd: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));
	LogMessage("OnEndVsRnd: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));

	CreateTimer(1.0, Timed_postendvs);
}
public Action:Timed_postendvs(Handle:timer) {
	PrintToChatAll("post vs rnd: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	LogMessage("post vs rnd: GetCampScores! A: %d B: %d", L4D_GetTeamScore(0, true),  L4D_GetTeamScore(1, true));
	PrintToChatAll("post vs rnd: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
	LogMessage("post vs rnd: GetTeamScore! A: %d B: %d",  L4D_GetTeamScore(0),  L4D_GetTeamScore(1));	
}

