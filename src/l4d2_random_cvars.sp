#pragma semicolon 1	

/* random_setcvars <proportion> <minvalue> <maxvalue> <cvar1> <cvar2> <cvar3> <...>
 * Plugin will select a random number for Cvar1 between minvalue and maxvalue, and scale all the following Cvars.
 * The % that Cvar1 is increased will be stored and multiplied by the proportion, and Cvar2, Cvar3, etc will be increased or decreased by this percentage of their default value.
 * For simple direct and inverse proportion, just use "1.0" and "-1.0".
 * If Cvar1 is already defined and it's the only cvar listed, it'll be re-randomised.
 * If Cvar1 is already defined and there's other cvars listed, it will skip the randomisation of Cvar1 and go straight to the scaling of the rest.
 * By default, all cvars are treated as floats.
 * If you want to treat a cvar as an integer instead, type it in as, for example, "int:z_common_limit".
 * For the sake of tidiness and OCD you can use "float:<cvar name>" as well: this will have no effect, meaning they'll still be treated as floats by default.
 * 
 * random_resetcvars <cvar1> <cvar2> <cvar3> <...>
 * Resets specified cvars to engine defaults.
 * If none are specified, all are randomised.
 * 
 * random_undocvars <cvar1> <cvar2> <cvar3> <...>
 * Plugin will save the value of a randomised cvar when it's re-randomised the first time.
 * Undoing a cvar will return it to that first randomised value.
 * To store a new random value as the non-engine default, reset the cvar to engine default first with random_resetcvars.
 * Remember to use "int:" and "float:", otherwise values are fetched as floats by default.
 * 
 * random_showcvars
 * Will simply show details on changed cvars to the client who requests it.
 * 
 * To-do:
 * - maybe add client command to print to console regardless of to-chat Cvar, and make the existing one always print to chat
 */
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <float>

#define DEBUG 0

#define NUMBER_LENGTH	16
#define BUFFER_LENGTH	48

//#define BIT_ATTR 1
#define BIT_CVAR 2

public Plugin:myinfo = 
{
	name = "Randomised Cvars",
	author = "Stabby",
	description = "Allows for randomisation of cvars and the optional announcement of changes to players.",
	version = "0.5.3",
	url = "no url"
}

//Cvar handles
new Handle:	g_hAnnounceCvars	= INVALID_HANDLE;
new Handle:	g_hAnnounceToChat	= INVALID_HANDLE;

//cvar-randomisation-related structures and things
new Handle: g_hTriePercentChanges				= INVALID_HANDLE;	//stores the difference between the current and default values as a percentage, for proportioning and scaling
new Handle: g_hTrieFirstRandomisationValues		= INVALID_HANDLE;	//stores values attributed to cvars on their first randomisation, to allow them to be returned to a default randomised status instead of having to either reset to source default or re-randomising
new Handle: g_hArrayCvarList					= INVALID_HANDLE;	//to store randomised cvars' names

public OnPluginStart()
{	//Cvars
	//should Cvar changes be announced?
	g_hAnnounceCvars	= CreateConVar(	"random_announce_cvars",         "1", "Should the plugin be allowed to announce changes for all modified Cvars?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//should on-connect announcements be sent to chat? 0 sends to console
	g_hAnnounceToChat	= CreateConVar(	"random_announce_to_chat_flags", "1", "Should the plugin send announcements to chat? If not, sends to console. Flags: 1 - send weapon stats to chat, 2 - send cvar stats to chat.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	g_hArrayCvarList		= CreateArray(BUFFER_LENGTH);
	g_hTriePercentChanges	= CreateTrie();
	g_hTrieFirstRandomisationValues = CreateTrie();
	
	RegServerCmd ("random_setcvars",	SetCvars);		//extensive explanation in comment at the beginning of this file
	RegServerCmd ("random_undocvars",	UndoCvars);		//toggles a re-randomised cvar back to its first randomised value
	RegServerCmd ("random_resetcvars",	ResetCvars);	//resets cvars to default values and clears tries and array
	RegConsoleCmd("random_showcvars", 	ShowCvars);		//displays cvar changes to players
}

public Action:SetCvars(args)
{	
	if (args < 4)	{ DebugPrintToServer("[random] Error: Less than 4 arguments in SetCvar call."); return; }
	
	decl n;	//used in loops
	decl String:sArStrings[args + 1][BUFFER_LENGTH];
	for (n = 1; n <= args; n++)	{ GetCmdArg(n, sArStrings[n], BUFFER_LENGTH); }
	
	new bool:isInteger = IsForcingIntegerDataType(sArStrings[4]);
	
	new Handle:	hCvar = FindConVar(sArStrings[4]);
	if (hCvar == INVALID_HANDLE) { DebugPrintToServer("[random] Error: Could not find first cvar in SetCvar call: %s.",sArStrings[4]); return; }
	new Float:	proportion= StringToFloat(sArStrings[1]);
//	if (proportion == 0.0) { DebugPrintToServer("Do not use 0 as proportion, you silly person!"); return; }
	
	new Float:	minValue  = StringToFloat(sArStrings[2]);
	new Float:	maxValue  = StringToFloat(sArStrings[3]);
	new Float:	randValue = GetRandomFloat(minValue, maxValue);
	new Float:	percentChange = randValue / GetConVarFloat(hCvar) - 1.0;
	
	if (GetTrieValue(g_hTriePercentChanges, sArStrings[4], percentChange))	//means this cvar's already been randomised
	{
		if (args == 4)	//only 1 cvar argument, let's re-randomise it
		{	
			SetTrieValue(g_hTrieFirstRandomisationValues, sArStrings[4], GetConVarFloat(hCvar), true);
			ResetConVar(FindConVar(sArStrings[4]));
			
			percentChange = randValue / GetConVarFloat(hCvar) - 1.0;
			SetConVarValue(hCvar, randValue, isInteger);
			
			SetTrieValue(g_hTriePercentChanges, sArStrings[4], percentChange, true);	//save offset percent to set new cvars according to this cvar's change
			
			DebugPrintToServer("[random] Re-randomised %s, new value: %f; percent offset from default: %f", sArStrings[4], randValue, percentChange);
		}	//if there's several cvar arguments, we'll use the first one to scale/re-scale the rest, without re-randomising the first
	}
	else	//first time randomising
	{
		PushArrayString(g_hArrayCvarList, sArStrings[4]);
		
		percentChange = randValue / GetConVarFloat(hCvar) - 1.0;
		SetConVarValue(hCvar, randValue, isInteger);
		
		DebugPrintToServer("[random] Randomised %s, new value: %f, percent change: %f", sArStrings[4], randValue, percentChange);
		
		SetTrieValue(g_hTriePercentChanges, sArStrings[4], percentChange, true);
	}
	
	percentChange *= proportion;	//take specified proportion into account
	
	decl Float: newPercentChange, Float: newValue;	//because they're reused every loop
	for (n = 5; n <= args; n++)
	{
		isInteger = IsForcingIntegerDataType(sArStrings[n]);
		
		hCvar = FindConVar(sArStrings[n]);
		if (hCvar == INVALID_HANDLE) { DebugPrintToServer("[random] Warning: Could not find %s. Will skip to next listed cvar if one exists.", sArStrings[n]); continue; }
		
		if (GetTrieValue(g_hTriePercentChanges, sArStrings[n], newPercentChange))	//storing into newPercentChange just because it has to be stored somewhere
		{	//it's being re-randomised
			SetTrieValue(g_hTrieFirstRandomisationValues, sArStrings[n], GetConVarFloat(hCvar), true);
			ResetConVar(FindConVar(sArStrings[n]));
		}
		else
		{	//it's the first time it's being randomised
			PushArrayString(g_hArrayCvarList, sArStrings[n]);
		}
		
		newValue = GetConVarFloat(hCvar) * (1.0 + percentChange);
		newPercentChange = newValue / GetConVarFloat(hCvar) - 1.0;
		SetConVarValue(hCvar, newValue, isInteger);
		
		SetTrieValue(g_hTriePercentChanges, sArStrings[n], newPercentChange, true);	//save offset percent to set new cvars according to this cvar's change
		
		DebugPrintToServer("[random] Scaled %s according to %s, new value: %f; percent offset from default: %f", sArStrings[n], sArStrings[4], newValue, newPercentChange);
	}
}

public Action:UndoCvars(args)
{
	decl String:sCvarName[BUFFER_LENGTH];
	new Float:  oldValue;
	new Float:  newValue;
	new Float:  defaultValue;
	new Float:  percentChange;
	new Handle:	hCvar;
	new bool:	isInteger;
	
	for (new n = 1; n <= args; n++)
	{
		GetCmdArg(n, sCvarName, BUFFER_LENGTH);
		
		isInteger = IsForcingIntegerDataType(sCvarName);
		
		hCvar = FindConVar(sCvarName);
		if (hCvar == INVALID_HANDLE) { DebugPrintToServer("[random] Warning: Failed to undo %s: cvar not found!", sCvarName); continue; }
		
		if (GetTrieValue(g_hTrieFirstRandomisationValues, sCvarName, newValue))	//means this cvar's been RE-randomised
		{
			GetTrieValue(g_hTriePercentChanges, sCvarName, percentChange);
			
			oldValue = GetConVarFloat(hCvar);
			SetConVarValue(hCvar, newValue, isInteger);
			defaultValue = oldValue / (1.0 + percentChange);
			percentChange = newValue / defaultValue - 1.0;
			SetTrieValue(g_hTriePercentChanges, sCvarName, percentChange, true);
			RemoveFromTrie(g_hTrieFirstRandomisationValues, sCvarName);
			
			DebugPrintToServer("[random] Undid %s: %f to %f. Percent offset from default %f.", sCvarName, oldValue, newValue, percentChange);
		}
		else
		{
			DebugPrintToServer("[random] Warning: Failed to undo %s: cvar not in a re-randomised condition!", sCvarName);
		}
	}
}

public Action:ResetCvars(args)
{
	decl String:sCvarName[BUFFER_LENGTH];
	decl String:buffer[BUFFER_LENGTH];
	
	if (args == 0)
	{
		new size = GetArraySize(g_hArrayCvarList);
		for (new n = 0; n < size; n++)
		{
			GetArrayString(g_hArrayCvarList, n, sCvarName, BUFFER_LENGTH);
			ResetConVar(FindConVar(sCvarName));
		}
		
		ClearTrie(g_hTriePercentChanges);
		ClearTrie(g_hTrieFirstRandomisationValues);
		ClearArray(g_hArrayCvarList);
		
		DebugPrintToServer("[random] Successfully reset all cvars.");
	}
	else
	{
		for (new n = 1; n <= args; n++)
		{
			GetCmdArg(n, sCvarName, BUFFER_LENGTH);	

			RemoveFromTrie(g_hTriePercentChanges, sCvarName);
			RemoveFromTrie(g_hTrieFirstRandomisationValues, sCvarName);
			
			new size = GetArraySize(g_hArrayCvarList);
			for (new k = 0; k < size; k++)
			{
				GetArrayString(g_hArrayCvarList, n, buffer, BUFFER_LENGTH);
				if (StrEqual(sCvarName, buffer))
				{
					RemoveFromArray(g_hArrayCvarList, k);
					break;
				}
			}
			
			DebugPrintToServer("[random] Successfully reset %s.",sCvarName);
			ResetConVar(FindConVar(sCvarName));
		}
	}
}	

public OnPluginEnd()
{
	ResetCvars(1);
}

public OnClientPutInServer(client)
{
	ShowCvars(client, 1);
}

public Action:ShowCvars(i, args)
{
	if (GetConVarBool(g_hAnnounceCvars))
	{
		new size = GetArraySize(g_hArrayCvarList);
		if (size >= 1)
		{
			if (GetConVarInt(g_hAnnounceToChat) & BIT_CVAR)	{ PrintToConsole(i, "* *Randomised Cvar Values: * *"); }
			else											{ PrintToChat(i, "* *Randomised Cvar Values: * *"); }
			
			for (new n = 0; n < size; n++)
			{
				decl String: cvarName[BUFFER_LENGTH];
				decl String: cvarValue[NUMBER_LENGTH];
				
				GetArrayString(g_hArrayCvarList, n, cvarName, BUFFER_LENGTH);
				GetConVarString(FindConVar(cvarName), cvarValue, NUMBER_LENGTH);
				
				if (GetConVarInt(g_hAnnounceToChat) & BIT_CVAR)	{ PrintToConsole(i, "%s: %s", cvarName, cvarValue); }
				else											{ PrintToChat(i, "%s: %s", cvarName, cvarValue); }
			}
		}
	}
}

//Sets cvar to float or int depending on the datatype that is enforced by the user
stock SetConVarValue(Handle:hCvar, Float:randValue, bool:isInteger)
{
	if (isInteger)	{ SetConVarInt	(hCvar, RoundToNearest(randValue)); }	//simply rounding to nearest here for the sake of simplicity
	else 			{ SetConVarFloat(hCvar, randValue); }					//even though probability of extremes is probably somewhat tampered with
}

// Checks if user wishes cvar to be treated as an integer, 
// and formats the cvar argument to contain only the cvar name
stock bool:IsForcingIntegerDataType(&String:cvar[])
{
	decl String:buffers[2][BUFFER_LENGTH];
	
	ExplodeString(cvar, ":", buffers, 2, BUFFER_LENGTH, false);
	cvar = buffers[1];
	
	if (StrEqual(buffers[0],"int")) { return true; }
	return false;
}

stock DebugPrintToServer(const String:message[], any:...)
{
	#if DEBUG
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), message, 2);
	PrintToServer(buffer);
    #endif
}

