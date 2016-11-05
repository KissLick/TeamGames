new Handle:g_hLogTime, bool:g_bLogCvar, String:g_sLogFile[PLATFORM_MAX_PATH];
new Handle:g_hAutoUpdate;
new Handle:g_hCTFriendlyFire;

new Handle:g_hModuleDefVisibility;

new Handle:g_hMenuPercent;
new Handle:g_hAllowMultiSwitch;
new Handle:g_hMenuTimeLock, g_iMenuTimeLock;

new Handle:g_hBindActionBuyAmmo1, String:g_sBindActionBuyAmmo1[64];
new Handle:g_hBindActionBuyAmmo2, String:g_sBindActionBuyAmmo2[64];
new Handle:g_hBindActionLookAtWeapon, String:g_sBindActionLookAtWeapon[64];

new Handle:g_hSelfDamage;

new Handle:g_hCheckTeams;
new Handle:g_hRoundLimit, g_iRoundLimit;
new Handle:g_hMoveSurvivors;
new Handle:g_hSaveWeapons;
new Handle:g_hRebelAttack;
new Handle:g_hKillFrags, Handle:g_hKillScore;
new Handle:g_hGamesTimeLock, g_iGamesTimeLock;

new Handle:g_hChangeTeamDelay;
new Handle:g_hTeamDiff;
new Handle:g_hTeamAttack;
new Handle:g_hNoneTeamAttack;
new Handle:g_hNotifyPlayerTeam, Handle:g_hNotifyTimer;

new Handle:g_hAllowMark;
new Handle:g_hMarkLife;
new Handle:g_hMarkLaser;
new Handle:g_hMarkLimit, g_iMarkLimitCounter;
new Handle:g_hMarkBlockDMG;
new Handle:g_hMarkSpawnDelay;
new Handle:g_hMarkInfinite;

new Handle:g_hImportantMsg;
new Handle:g_hAllowTeamPrefix;

new Handle:g_hFenceType;
new Handle:g_hFenceHeight;
new Handle:g_hFenceNotify;
new Handle:g_hFencePunishLength;
new Handle:g_hFenceFreeze;
new Handle:g_hFencePunishColorSettings;
new Handle:g_hFencePunishColor, g_iFencePunishColor[3];

new Handle:g_hForceAutoKick;
new Handle:g_hForceTKPunish;
new Handle:g_hFriendlyFire, g_iFriendlyFire;
new Handle:g_hFFReduction;

LoadConVars()
{
	g_iRoundLimit = GetConVarInt(g_hRoundLimit);

	GetConVarString(g_hBindActionBuyAmmo1, 		g_sBindActionBuyAmmo1, 		sizeof(g_sBindActionBuyAmmo1));
	TrimString(g_sBindActionBuyAmmo1);
	GetConVarString(g_hBindActionBuyAmmo2, 		g_sBindActionBuyAmmo2, 		sizeof(g_sBindActionBuyAmmo2));
	TrimString(g_sBindActionBuyAmmo2);
	GetConVarString(g_hBindActionLookAtWeapon, 	g_sBindActionLookAtWeapon, 	sizeof(g_sBindActionLookAtWeapon));
	TrimString(g_sBindActionLookAtWeapon);

	GetConVarColorToArray(g_hFencePunishColor, g_iFencePunishColor);

	if (GetConVarBool(g_hForceAutoKick))
		SetConVarIntSilent("mp_autokick", 0);

	if (GetConVarBool(g_hForceTKPunish))
		SetConVarIntSilent("mp_tkpunish", 0);

	g_iFriendlyFire = GetConVarInt(g_hFriendlyFire);
	if (g_iFriendlyFire == 1) {
		SetConVarIntSilent("mp_friendlyfire", 1);
	} else if (g_iFriendlyFire == 2) {
		SetConVarIntSilent("mp_friendlyfire", 0);
	}

	if (g_iEngineVersion == Engine_CSGO && GetConVarBool(g_hFFReduction)) {
		SetConVarIntSilent("ff_damage_reduction_bullets", 		1);
		SetConVarIntSilent("ff_damage_reduction_grenade", 		1);
		SetConVarIntSilent("ff_damage_reduction_grenade_self", 	1);
		SetConVarIntSilent("ff_damage_reduction_other", 		1);
	}
}

SetConVarIntSilent(const String:ConVarName[256], ConVarValue)
{
	new Handle:hHndl = FindConVar(ConVarName);

	if (hHndl != INVALID_HANDLE) {
		if (Convar_HasFlags(hHndl, FCVAR_NOTIFY))
			Convar_RemoveFlags(hHndl, FCVAR_NOTIFY);

		SetConVarInt(hHndl, ConVarValue, true);
	}
}

GetConVarColorToArray(Handle:cvar, color[3])
{
	new String:sValue[9], String:sRed[3], String:sGreen[3], String:sBlue[3];
	GetConVarString(cvar, sValue, sizeof(sValue));
	FormatEx(sRed, sizeof(sRed), "%c%c", sValue[0], sValue[1]);
	FormatEx(sGreen, sizeof(sGreen), "%c%c", sValue[2], sValue[3]);
	FormatEx(sBlue, sizeof(sBlue), "%c%c", sValue[4], sValue[5]);

	StringToIntEx(sRed, color[0], 16);
	StringToIntEx(sGreen, color[1], 16);
	StringToIntEx(sBlue, color[2], 16);
}

HookConVarsChange()
{
	HookConVarChange(g_hRoundLimit,        		Hook_ConVarChange);
	HookConVarChange(g_hBindActionBuyAmmo1, 	Hook_ConVarChange);
	HookConVarChange(g_hBindActionBuyAmmo2, 	Hook_ConVarChange);
	HookConVarChange(g_hBindActionLookAtWeapon,	Hook_ConVarChange);
	HookConVarChange(g_hFencePunishColor,  		Hook_ConVarChange);
	HookConVarChange(g_hForceAutoKick,     		Hook_ConVarChange);
	HookConVarChange(g_hForceTKPunish,     		Hook_ConVarChange);
	HookConVarChange(g_hFriendlyFire,      		Hook_ConVarChange);
	HookConVarChange(g_hFFReduction,       		Hook_ConVarChange);
}

public Hook_ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	LoadConVars();
}
