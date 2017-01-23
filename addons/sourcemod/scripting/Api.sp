//------------------------------------------------------------------------------------------------
// Natives
public Native_GetPlayerTeam(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_T)
		return _:TG_ErrorTeam;

	return _:g_PlayerData[iClient][Team];
}

public Native_SetPlayerTeam(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iTarget = GetNativeCell(2);
	new TG_Team:iTeam = TG_Team:GetNativeCell(3);

	if (SwitchToTeam(iClient, iTarget, iTeam) != 1)
		return false;

	return true;
}

public Native_LoadPlayerWeapons(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) == CS_TEAM_CT)
		return false;

	PlayerEquipmentLoad(iClient);

	return true;
}

public Native_AttachPlayerHealthBar(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iMaxHealth = GetNativeCell(2);
	new bool:bDestroyOnLeaveGame = bool:GetNativeCell(3);

	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient) || iMaxHealth < 1)
		return;

	g_iPlayerHPBar[iClient][MaxHealth] = iMaxHealth;
	g_iPlayerHPBar[iClient][AutomaticDestroy] = bDestroyOnLeaveGame;

	UpdateHealthBar(iClient, false);
}

public Native_UpdatePlayerHealthBar(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	UpdateHealthBar(iClient);
}

public Native_DestroyPlayerHealthBar(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	RemoveHealthBar(iClient);
	g_iPlayerHPBar[iClient][MaxHealth] = 0;
	g_iPlayerHPBar[iClient][AutomaticDestroy] = true;
}

public Native_IsGameTypeAvailable(Handle:hPlugin, iNumParams)
{
	new TG_GameType:iGameType = TG_GameType:GetNativeCell(1);
	return IsGameTypeAvailable(iGameType);
}

public Native_FenceCreate(Handle:hPlugin, iNumParams)
{
	new Float:fA[3], Float:fC[3];

	GetNativeArray(1, fA, 3);
	GetNativeArray(2, fC, 3);

	CreateFence(fA, fC);
}

public Native_FenceDestroy(Handle:hPlugin, iNumParams)
{
	DestroyFence();
}

public Native_FencePlayerCross(Handle:hPlugin, iNumParams)
{
	new bool:bCallForward = bool:GetNativeCell(2);
	new iClient = GetNativeCell(2);
	FencePunishPlayer(iClient, bCallForward);
}

public Native_SpawnMark(Handle:hPlugin, iNumParams)
{
	new Float:fPos[3];

	new iClient = GetNativeCell(1);
	new TG_Team:iTeam = TG_Team:GetNativeCell(2);
	GetNativeArray(3, fPos, 3);
	new Float:fTime = GetNativeCell(4);
	new bool:bFireEvent = GetNativeCell(5);
	new bool:bCount = GetNativeCell(6);
	new bool:bBlockDMG = GetNativeCell(7);

	return _:SpawnMark(iClient, iTeam, fPos[0], fPos[1], fPos[2], fTime, bCount, bFireEvent, bBlockDMG);
}

public Native_DestroyMark(Handle:hPlugin, iNumParams)
{
	TriggerTimer(Handle:GetNativeCell(1));
}

public Native_GetTeamCount(Handle:hPlugin, iNumParams)
{
	new TG_Team:iTeam = TG_Team:GetNativeCell(1);
	return GetCountPlayersInTeam(iTeam);
}

public Native_ClearTeam(Handle:hPlugin, iNumParams)
{
	new TG_Team:iTeam = TG_Team:GetNativeCell(1);
	ClearTeam(iTeam);
}

public Native_SetTeamsLock(Handle:hPlugin, iNumParams)
{
	g_bTeamsLock = GetNativeCell(1);
}

public Native_GetTeamsLock(Handle:hPlugin, iNumParams)
{
	return g_bTeamsLock;
}

public Native_RegGame(Handle:hPlugin, iNumParams)
{
	if (!ExistMenuItemsConfigFile()) {
		return ThrowNativeError(10, "Game registration Failed! Config file (ConVar \"tg_modules_config\") must exist! (Error - \"TG_RegGame #10\")");
	}

	if (g_iGameListEnd > MAX_GAMES - 1) {
		return ThrowNativeError(9, "Game registration Failed! Reached maximum count of games! (Error - \"TG_RegGame #9\")");
	}

	decl String:sName[TG_MODULE_NAME_LENGTH], String:sID[TG_MODULE_ID_LENGTH];

	if (GetNativeString(1, sID, sizeof(sID)) != SP_ERROR_NONE) {
		return ThrowNativeError(1, "Game registration Failed! Couldn't get Arg1 (Game ID)! (Error - \"TG_RegGame #1\")");
	}

	if (IsModuleDisabled(TG_Game, sID))
		return 5;

	if (StrContains(sID, "Core_", false) == 0) {
		return ThrowNativeError(4, "Game registration Failed! Game ID can't start with \"Core_\" - it's reserved for core! (Error - \"TG_RegGame #4\")");
	}

	if (ExistGame(sID)) {
		return ThrowNativeError(3, "Game registration Failed! Game ID (\"%s\") must be unique! (Error - \"TG_RegGame #3\")", sID);
	}

	Call_AskModuleName(sID, TG_Game, LANG_SERVER, sName, sizeof(sName));

	new TG_GameType:iType = TG_GameType:GetNativeCell(2);
	new bool:bHealthBar = bool:GetNativeCell(3);
	new iIndex = GetGameIndex(sID, false);

	if (iIndex == -1) {
		iIndex = g_iGameListEnd;
		g_iGameListEnd++;

		strcopy(g_GameList[iIndex][Id], TG_MODULE_ID_LENGTH, sID);
		SaveGameToConfig(sID, sName, iType, bHealthBar);

		g_GameList[iIndex][Visible] = GetConVarBool(g_hModuleDefVisibility);
		g_GameList[iIndex][HealthBarVisibility] = bHealthBar;
	}

	g_GameList[iIndex][Used] = true;
	g_GameList[iIndex][TGType] = iType;
	strcopy(g_GameList[iIndex][DefaultName], TG_MODULE_NAME_LENGTH, sName);

	#if defined DEBUG
	LogMessage("[TG DEBUG] Registred game index = '%d', id = '%s', defaultname = '%s, type = '%d'. (g_iGameListEnd = '%d')", iIndex, g_GameList[iIndex][Id], g_GameList[iIndex][DefaultName], g_GameList[iIndex][TGType], g_iGameListEnd);
	#endif

	return 0;
}

public Native_RemoveGame(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];

	if (GetNativeString(1, sID, sizeof(sID)) != SP_ERROR_NONE) {
		return ThrowNativeError(1, "Game unregistration Failed! Couldn't get Arg2 (Game ID)! (Error - \"TG_RemoveGame #1\")");
	}

	// if (!ExistGame(sID)) {
		// return ThrowNativeError(2, "Game unregistration Failed! No game with \"GAME_ID\" = \"%s\" found! (Error - \"TG_RemoveGame #2\")", sID);
	// }

	if (ExistGame(sID)) {
		g_GameList[GetGameIndex(sID)][Used] = false;
	}

	return 0;
}

public Native_ShowPlayerSelectMenu(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
	new Function:fCallBack = GetNativeFunction(2);
#else
	new Function:fCallBack = Function:GetNativeCell(2);
#endif
	new bool:bRedTeam = bool:GetNativeCell(3);
	new bool:bBlueTeam = bool:GetNativeCell(4);
	new bool:bRandom = bool:GetNativeCell(5);
	new iData = GetNativeCell(6);

	decl String:CustomTitle[64];
	FormatNativeString(0, 7, 8, sizeof(CustomTitle), _, CustomTitle);

	if (!bRedTeam && !bBlueTeam)
		ThrowNativeError(0, "No team to choose player from!");

	new iCount = 0;

	if (bRedTeam)
		iCount += TG_GetTeamCount(TG_RedTeam);

	if (bBlueTeam)
		iCount += TG_GetTeamCount(TG_BlueTeam);

	if (iCount > 1) {
		new Handle:hMenu = CreateMenu(PlayerSelectMenu_Handler);
		decl String:sUserId[32];

		if (CustomTitle[0] == '\0')
			SetMenuTitle(hMenu, "%T", "MenuPlayerSelect-Title", iClient);
		else
			SetMenuTitle(hMenu, CustomTitle);

		if (bRandom)
			AddMenuItemFormat(hMenu, "--RANDOM--", _, "%T", "MenuPlayerSelect-Random", iClient);

		for (new i = 1; i <= MaxClients; i++) {
			if ((bRedTeam && TG_GetPlayerTeam(i) == TG_RedTeam) || (bBlueTeam && TG_GetPlayerTeam(i) == TG_BlueTeam)) {
				FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
				AddMenuItemFormat(hMenu, sUserId, _, "%N", i);
			}
		}

		PushMenuCell(hMenu, "--RED--", _:bRedTeam);
		PushMenuCell(hMenu, "--BLUE--", _:bBlueTeam);
		PushMenuCell(hMenu, "--DATA--", _:iData);
		PushMenuCell(hMenu, "--PLUGIN--", _:hPlugin);
		PushMenuCell(hMenu, "--FUNCTION--", _:fCallBack);

		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, iClient, 30);
	} else if (iCount == 1) {
		new iUser = 0;

		for (new i = 1; i <= MaxClients; i++) {
			if ((bRedTeam && TG_GetPlayerTeam(i) == TG_RedTeam) || (bBlueTeam && TG_GetPlayerTeam(i) == TG_BlueTeam)) {
				iUser = i;
				break;
			}
		}

		Call_StartFunction(hPlugin, fCallBack);
		Call_PushCell(iClient);
		Call_PushCell(iUser);
		Call_PushCell(false);
		Call_PushCell(iData);
		Call_Finish();
	} else {
		return false;
	}

	return true;
}

public PlayerSelectMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		new iUser;
		new bool:bRandom = false;
		new bool:bRedTeam = bool:GetMenuCell(hMenu, "--RED--");
		new bool:bBlueTeam = bool:GetMenuCell(hMenu, "--BLUE--");
		new iData = GetMenuCell(hMenu, "--DATA--");
		new Handle:hPlugin = Handle:GetMenuCell(hMenu, "--PLUGIN--");
		new Function:fCallBack = Function:GetMenuCell(hMenu, "--FUNCTION--");
		decl String:sUserId[32];
		GetMenuItem(hMenu, iKey, sUserId, sizeof(sUserId));

		if (StrEqual("--RANDOM--", sUserId)) {
			if (bRedTeam) {
				iUser = TG_GetRandomClient(TG_RedTeam);
			}

			if (bBlueTeam) {
				if (bRedTeam) {
					if (GetRandomInt(0, 1) == 0) {
						iUser = TG_GetRandomClient(TG_BlueTeam);
					}
				} else {
					iUser = TG_GetRandomClient(TG_BlueTeam);
				}
			}

			bRandom = true;
		} else {
			iUser = GetClientOfUserId(StringToInt(sUserId));
		}

		Call_StartFunction(hPlugin, fCallBack);
		Call_PushCell(iClient);
		Call_PushCell(iUser);
		Call_PushCell(bRandom);
		Call_PushCell(iData);
		Call_Finish();
	}
	// else if (iAction == MenuAction_Cancel && iKey == MenuCancel_ExitBack)
	// {
		// MainMenu(iClient);
	// }
}

public Native_FakeSelect(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new TG_ModuleType:iType = GetNativeCell(2);
	new TG_GameType:iGameType = GetNativeCell(4);
	decl String:sID[TG_MODULE_ID_LENGTH];

	if (GetNativeString(3, sID, sizeof(sID)) != SP_ERROR_NONE) {
		return ThrowNativeError(1, "Fake select failed! Couldn't get Arg3 (Module ID)!");
	}

	if (Call_OnMenuSelect(iType, sID, iGameType, iClient) != Plugin_Continue)
		return 0;

	Call_OnMenuSelected(iType, sID, iGameType, iClient);

	if (iType == TG_MenuItem && StrContains(sID, "Core_", false) == 0) {
		CoreMenuItemsActions(iClient, sID);
	}

	return 0;
}

public Native_RegMenuItem(Handle:hPlugin, iNumParams)
{
	if (!ExistMenuItemsConfigFile()) {
		return ThrowNativeError(6, "Main menu item registration Failed! Config file (ConVar \"tg_modules_config\") must exist! (Error - \"TG_RegMenuItem #6\")");
	}

	if (g_iMenuItemListEnd > MAX_MENU_ITEMS - 1) {
		return ThrowNativeError(5, "Main menu item registration Failed! Reached maximum count of main hMenu items! (Error - \"TG_RegMenuItem #5\")");
	}

	decl String:sItemName[TG_MODULE_NAME_LENGTH], String:sItemID[TG_MODULE_ID_LENGTH];

	if (GetNativeString(1, sItemID, sizeof(sItemID)) != SP_ERROR_NONE) {
		return ThrowNativeError(2, "Main menu item registration Failed! Couldn't get Arg1 (Item ID)! (Error - \"TG_RegMenuItem #2\")");
	}

	if (IsModuleDisabled(TG_MenuItem, sItemID))
		return 7;

	if (StrContains(sItemID, "Core_", false) == 0) {
		return ThrowNativeError(4, "Main menu item registration Failed! Item ID can't start with \"Core_\" - it's reserved for core items! (Error - \"TG_RegMenuItem #4\")");
	}

	if (ExistMenuItem(sItemID)) {
		return ThrowNativeError(3, "Main menu item registration Failed! Item ID (\"%s\") must be unique! (Error - \"TG_RegMenuItem #3\")", sItemID);
	}

	Call_AskModuleName(sItemID, TG_MenuItem, LANG_SERVER, sItemName, sizeof(sItemName));
	new iItemIndex = GetMenuItemIndex(sItemID, false);

	if (iItemIndex == -1) {
		iItemIndex = g_iMenuItemListEnd;
		g_iMenuItemListEnd++;

		strcopy(g_MenuItemList[iItemIndex][Id], TG_MODULE_ID_LENGTH, sItemID);
		SaveMenuItemToConfig(sItemID, sItemName);

		g_MenuItemList[iItemIndex][Visible] = GetConVarBool(g_hModuleDefVisibility);
	}

	g_MenuItemList[iItemIndex][Used] = true;
	strcopy(g_MenuItemList[iItemIndex][DefaultName], TG_MODULE_NAME_LENGTH, sItemName);

	#if defined DEBUG
	LogMessage("[TG DEBUG] Registred item ID = '%s', Name = '%s'.", sItemID, sItemName);
	#endif

	return 0;
}

public Native_RemoveMenuItem(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];

	if (GetNativeString(1, sID, sizeof(sID)) != SP_ERROR_NONE) {
		return ThrowNativeError(1, "Main menu item unregistration Failed! Couldn't get Arg1 (Item ID)! (Error - \"TG_RemoveMenuItem #1\")");
	}

	// if (!ExistMenuItem(sID)) {
		// return ThrowNativeError(2, "Main menu item unregistration Failed! No menu item with \"ITEM_ID\" = \"%s\" found! (Error - \"TG_RemoveMenuItem #2\")", sID);
	// }

	if (ExistMenuItem(sID)) {
		g_MenuItemList[GetMenuItemIndex(sID)][Used] = false;
	}

	return 0;
}

public Native_IsModuleReged(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];
	new TG_ModuleType:iType = GetNativeCell(1);

	if (GetNativeString(2, sID, sizeof(sID)) != SP_ERROR_NONE)
		return false;

	if (iType == TG_Game) {
		return ExistGame(sID);
	} else if (iType == TG_MenuItem) {
		return ExistMenuItem(sID);
	}

	return false;
}

public Native_GetRegedModules(Handle:hPlugin, iNumParams)
{
	new TG_ModuleType:iType = GetNativeCell(1);
	new Handle:hModules = CreateArray(TG_MODULE_ID_LENGTH);

	if (iType == TG_Game) {
		for (new i = 0; i < g_iGameListEnd; i++) {
			if (g_GameList[i][Used])
				PushArrayString(hModules, g_GameList[i][Id]);
		}

		return _:hModules;
	} else if (iType == TG_MenuItem) {
		for (new i = 0; i < g_iMenuItemListEnd; i++) {
			if (g_MenuItemList[i][Used])
				PushArrayString(hModules, g_MenuItemList[i][Id]);
		}

		return _:hModules;
	}

	return _:INVALID_HANDLE;
}

public Native_GetModuleName(Handle:hPlugin, iNumParams)
{
	new String:sID[TG_MODULE_ID_LENGTH], String:sName[TG_MODULE_ID_LENGTH];
	new TG_ModuleType:iType = GetNativeCell(1);
	new iClient = GetNativeCell(3);
	new iSize = GetNativeCell(5);

	if (GetNativeString(2, sID, sizeof(sID)) != SP_ERROR_NONE)
		ThrowNativeError(1, "Bad module ID");

	Call_AskModuleName(sID, iType, iClient, sName, iSize);
	SetNativeString(4, sName, TG_MODULE_NAME_LENGTH);
}

public Native_StartGame(Handle:hPlugin, iNumParams)
{
	new iClient, Handle:hDataPack;
	iClient = GetNativeCell(1);

	new String:sID[TG_MODULE_ID_LENGTH], String:sName[TG_MODULE_NAME_LENGTH], String:sSettings[TG_MODULE_NAME_LENGTH];
	GetNativeString(2, sID, sizeof(sID));
	new TG_GameType:iGameType = TG_GameType:GetNativeCell(3);
	GetNativeString(4, sSettings, sizeof(sSettings));
	Call_AskModuleName(sID, TG_Game, iClient, sName, sizeof(sName));

	hDataPack = Handle:GetNativeCell(5);
	new bool:bRemoveDropppedWeapons = GetNativeCell(6);
	new bool:bEndOnTeamEmpty = GetNativeCell(7);

	if (iGameType != TG_TeamGame && iGameType != TG_RedOnly) {
		return ThrowNativeError(1, "TGType arg. in TG_StartGame must be equal to \"TG_TeamGame\" or \"TG_RedTeam\" !");
	}

	if (iClient == 0) {
		TG_StartGamePreparation(iClient, sID, iGameType, sSettings, hDataPack, bRemoveDropppedWeapons, bEndOnTeamEmpty);
		return 0;
	}

	new Handle:hMenu = CreateMenu(GameStartMenu_Handler);
	SetMenuTitle(hMenu, "%T", "MenuGames-Start-Title", iClient, sName);
	AddMenuItemFormat(hMenu, "START_GAME",_ , "%T", "MenuGames-Start", iClient);
	PushMenuCell(hMenu, "-CLIENT-", iClient);
	PushMenuString(hMenu, "-GAMEID-", sID);
	PushMenuCell(hMenu, "-GAMETYPE-", _:iGameType);
	PushMenuString(hMenu, "-GAMESETTINGS-", sSettings);
	PushMenuCell(hMenu, "-DATAPACK-", _:hDataPack);
	PushMenuCell(hMenu, "-REMOVEDROPS-", _:bRemoveDropppedWeapons);
	PushMenuCell(hMenu, "-ENDONTEAMEMPTY-", _:bEndOnTeamEmpty);
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);

	return 0;
}

public Native_GetCurrentGameID(Handle:hPlugin, iNumParams)
{
	new iLength = GetNativeCell(2);

	if (iLength < TG_MODULE_ID_LENGTH)
		return false;

	if (!StrEqual(g_Game[GameID], "Core_NoGame")) {
		new String:sID[TG_MODULE_ID_LENGTH];

		strcopy(sID, TG_MODULE_ID_LENGTH, g_Game[GameID]);

		SetNativeString(1, sID, TG_MODULE_ID_LENGTH);
	} else {
		SetNativeString(1, "Core_NoGame", TG_MODULE_ID_LENGTH);
	}

	return true;
}

public Native_IsCurrentGameID(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];
	GetNativeString(1, sID, sizeof(sID));

	if (StrEqual(g_Game[GameID], sID))
		return true;
	else
		return false;
}

public Native_GetCurrentDataPack(Handle:hPlugin, iNumParams)
{
	return _:g_Game[GameDataPack];
}

public Native_GetCurrentStarter(Handle:hPlugin, iNumParams)
{
	return g_Game[GameStarter];
}

public Native_GetCurrentGameSettings(Handle:hPlugin, iNumParams)
{
	new iLength = GetNativeCell(2);

	if (iLength < TG_MODULE_NAME_LENGTH)
		return false;

	if (g_Game[GameProgress] != TG_NoGame) {
		SetNativeString(1, g_Game[GameSettings], TG_MODULE_NAME_LENGTH);
	} else {
		SetNativeString(1, "Core_NoGame", TG_MODULE_NAME_LENGTH);
	}

	return true;
}

public Native_GetCurrentGameType(Handle:hPlugin, iNumParams)
{
	return _:g_Game[TGType];
}

public Native_GetGameType(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];

	if (GetNativeString(1, sID, sizeof(sID)) != SP_ERROR_NONE)
		return 1;

	if (!ExistGame(sID))
		return 2;

	return _:g_GameList[GetGameIndex(sID)][TGType];
}

public Native_StopGame(Handle:hPlugin, iNumParams)
{
	if (g_Game[GameProgress] != TG_InProgress && g_Game[GameProgress] != TG_InPreparation)
		return 1;

	g_Game[GameProgress] = TG_NoGame;

	if (g_Game[RemoveDrops]) {
		for (new i = 1; i <= MaxClients; i++)
		{
			if (Client_IsIngame(i))
				SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
		}
	}

	if (g_hTimer_CountDownGamePrepare != INVALID_HANDLE) {
		KillTimer(g_hTimer_CountDownGamePrepare);
		g_hTimer_CountDownGamePrepare = INVALID_HANDLE;
	}

	new TG_Team:iTeam = TG_Team:GetNativeCell(1);
	new Handle:hWinners = Handle:GetNativeCellRef(2);
	new bool:bClear = bool:GetNativeCell(3);
	new bool:bWeapons = bool:GetNativeCell(4);

	if (GetConVarInt(g_hSaveWeapons) == 1) {
		bWeapons = true;
	} else if (GetConVarInt(g_hSaveWeapons) == 2 && bWeapons) {
		bWeapons = true;
	}

	new iWinners[MAXPLAYERS + 1];
	new iWinnersCount = 0;

	if (hWinners != INVALID_HANDLE) {
		if (GetArraySize(hWinners) > 0) {
			iWinnersCount = GetArraySize(hWinners);

			for (new i = 0; i < iWinnersCount; i++) {
				iWinners[i] = GetArrayCell(hWinners, i);
			}
		}

		CloseHandle(hWinners);
		SetNativeCellRef(2, INVALID_HANDLE);
	} else {
		if (g_Game[TGType] == TG_TeamGame && TG_IsTeamRedOrBlue(iTeam)) {
			for (new i = 0; i < MAXPLAYERS + 1; i++) {
				if ((iTeam == TG_RedTeam && g_Game[RedTeam][i] == 0) || (iTeam == TG_BlueTeam && g_Game[BlueTeam][i] == 0)) {
					break;
				}

				new iUser;

				if (iTeam == TG_RedTeam) {
					iUser = GetClientOfUserId(g_Game[RedTeam][i]);
				} else if (iTeam == TG_BlueTeam) {
					iUser = GetClientOfUserId(g_Game[BlueTeam][i]);
				}

				if (iUser == 0) {
					continue;
				}

				iWinners[i] = iUser;
				iWinnersCount++;
			}
		} else if (g_Game[TGType] == TG_RedOnly && (iTeam == TG_RedTeam || iTeam == TG_BlueTeam)) {
			for (new i = 0; i < MAXPLAYERS + 1; i++) {
				if (g_Game[RedTeam][i] == 0) {
					break;
				}

				new iUser = GetClientOfUserId(g_Game[RedTeam][i]);

				if (iUser == 0 || !IsPlayerAlive(iUser)) {
					continue;
				}

				iWinners[i] = iUser;
				iWinnersCount++;
			}
		}
	}

	new String:sWinners[1024];
	for (new i = 0; i < iWinnersCount; i++) {
		Format(sWinners, sizeof(sWinners), "%s, %N", sWinners, iWinners[i]);
	}
	strcopy(sWinners, sizeof(sWinners), sWinners[2]);

	if (g_bLogCvar) {
		new String:sTeam1[4096], String:sTeam2[4096];
		new iCount1, iCount2;

		for (new i = 1; i <= MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				Format(sTeam1, sizeof(sTeam1), "%s%L, ", sTeam1, i);
				iCount1++;
			}

			if (g_Game[TGType] == TG_TeamGame && TG_GetPlayerTeam(i) == TG_BlueTeam) {
				Format(sTeam2, sizeof(sTeam2), "%s%L, ", sTeam2, i);
				iCount2++;
			}
		}

		if (strlen(sTeam1) > 2)
			sTeam1[strlen(sTeam1) - 2] = '\0';
		else
			strcopy(sTeam1, sizeof(sTeam1), "");

		if (strlen(sTeam2) > 2)
			sTeam2[strlen(sTeam2) - 2] = '\0';
		else
			strcopy(sTeam2, sizeof(sTeam2), "");

		TG_LogRoundMessage(   "GameEnd", "(ID: \"%s\")", g_Game[GameID]);
		TG_LogRoundMessage(_, "{");
		if (g_Game[TGType] == TG_TeamGame) {
			TG_LogRoundMessage(_, "\tWinner team: \"%s\"", (iTeam == TG_RedTeam) ? "RedTeam" : (iTeam == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
			TG_LogRoundMessage(_, "");
			TG_LogRoundMessage(_, "\tSurvivors RedTeam (%d):  \"%s\"", iCount1, sTeam1);
			TG_LogRoundMessage(_, "\tSurvivors BlueTeam (%d): \"%s\"", iCount2, sTeam2);
		} else if (g_Game[TGType] == TG_RedOnly) {
			TG_LogRoundMessage(_, "\tSurvivors (%d):  \"%s\"", iCount1, sTeam1);
			TG_LogRoundMessage(_, "\tWinners (%d):  \"%s\"", iWinnersCount, sWinners);
		}
		TG_LogRoundMessage(_, "}");
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		SetEntityMoveType(i, MoveType:MOVETYPE_ISOMETRIC);

		if (bWeapons)
			PlayerEquipmentLoad(i);
	}

	if (g_iFriendlyFire == 2)
		SetConVarIntSilent("mp_friendlyfire", 0);

	Call_StartForward(Forward_OnGameEnd);
	Call_PushString(g_Game[GameID]);
	Call_PushCell(g_Game[TGType]);
	Call_PushCell(iTeam);
	Call_PushArray(iWinners, MAXPLAYERS + 1);
	Call_PushCell(iWinnersCount);
	Call_PushCell(g_Game[GameDataPack]);
	Call_Finish();

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			Call_OnPlayerLeaveGame(g_Game[GameID], g_Game[TGType], i, g_PlayerData[i][Team], TG_GameEnd);
		}
	}


	if (GetConVarInt(g_hMoveSurvivors) == 1) {
		ClearTeams();
	} else if (GetConVarInt(g_hMoveSurvivors) == 2 && bClear) {
		ClearTeams();
	}

	if (g_Game[TGType] == TG_TeamGame) {
		for (new iUser = 1; iUser <= MaxClients; iUser++) {
			if (!IsClientInGame(iUser)) {
				continue;
			}

			for (new i = 0; i <= _:GetConVarBool(g_hImportantMsg); i++) {
				CPrintToChat(iUser, "%T", (iTeam == TG_RedTeam) ? "TeamWins-RedTeam" : (iTeam == TG_BlueTeam) ? "TeamWins-BlueTeam" : "TeamWins-Tie", iUser);
			}
		}
	} else if (g_Game[TGType] == TG_RedOnly) {
		new String:sGameName[TG_MODULE_NAME_LENGTH];

		if (iWinnersCount > 0) {
			new bool:bOnlyOneWinner = (iWinnersCount == 1);

			for (new iUser = 1; iUser <= MaxClients; iUser++) {
				if (!IsClientInGame(iUser)) {
					continue;
				}

				Call_AskModuleName(g_Game[GameID], TG_Game, iUser, sGameName, sizeof(sGameName));

				for (new i = 0; i <= _:GetConVarBool(g_hImportantMsg); i++) {
					CPrintToChat(iUser, "%T", (bOnlyOneWinner) ? "TeamWins-Winner" : "TeamWins-Winners", iUser, sWinners, sGameName);
				}
			}
		} else {
			for (new iUser = 1; iUser <= MaxClients; iUser++) {
				if (!IsClientInGame(iUser)) {
					continue;
				}

				Call_AskModuleName(g_Game[GameID], TG_Game, iUser, sGameName, sizeof(sGameName));

				for (new i = 0; i <= _:GetConVarBool(g_hImportantMsg); i++) {
					CPrintToChat(iUser, "%T", "GameEnd", iUser, sGameName);
				}
			}
		}
	}

	g_bTeamsLock = false;
	ClearGameStatusInfo();

	if (IsSoundPrecached(g_sGameEnd[iTeam]))
		EmitSoundToAllAny(g_sGameEnd[iTeam]);

	return 0;
}

public Native_SetModuleVisibility(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];
	new TG_ModuleType:iType = TG_ModuleType:GetNativeCell(1);
	new bool:bVisibility = bool:GetNativeCell(3);

	if (GetNativeString(2, sID, sizeof(sID)) != SP_ERROR_NONE)
		return false;

	new iIndex;
	new bool:bChanged = false;

	if (iType == TG_Game) {
		iIndex = GetGameIndex(sID);

		if (iIndex == -1)
			return false;

		if (g_GameList[iIndex][Visible] && !bVisibility) {
			g_GameList[iIndex][Visible] = false;
			bChanged = true;
		} else if (!g_GameList[iIndex][Visible] && bVisibility) {
			g_GameList[iIndex][Visible] = true;
			bChanged = true;
		}

		if (bChanged)
			TG_LogMessage("ModuleVisibility", "Changed game (ID = '%s') visibility to %d", sID, _:bVisibility);
	}
	else if (iType == TG_MenuItem)
	{
		iIndex = GetMenuItemIndex(sID);

		if (iIndex == -1)
			return false;

		if (g_MenuItemList[iIndex][Visible] && !bVisibility) {
			g_MenuItemList[iIndex][Visible] = false;
			bChanged = true;

		} else if (!g_MenuItemList[iIndex][Visible] && bVisibility) {
			g_MenuItemList[iIndex][Visible] = true;
			bChanged = true;
		}

		if (bChanged)
			TG_LogMessage("ModuleVisibility", "Changed hMenu item (ID = '%s') visibility to %d", sID, _:bVisibility);
	}

	return true;
}

public Native_GetModuleVisibility(Handle:hPlugin, iNumParams)
{
	decl String:sID[TG_MODULE_ID_LENGTH];
	new TG_ModuleType:iType = GetNativeCell(1);

	if (GetNativeString(2, sID, sizeof(sID)) != SP_ERROR_NONE)
		return false;

	new iIndex;

	if (iType == TG_Game) {
		iIndex = GetGameIndex(sID);

		if (iIndex != -1)
			return g_GameList[iIndex][Visible];
	} else if (iType == TG_MenuItem) {
		iIndex = GetMenuItemIndex(sID);

		if (iIndex != -1)
			return g_MenuItemList[iIndex][Visible];
	}

	return false;
}

public Native_GetGameStatus(Handle:hPlugin, iNumParams)
{
	return _:g_Game[GameProgress];
}

public Native_IsGameStatus(Handle:hPlugin, iNumParams)
{
	if (g_Game[GameProgress] == TG_GameProgress:GetNativeCell(1))
		return true;
	else
		return false;
}

public Native_LogMessage(Handle:hPlugin, iNumParams)
{
	if (!g_bLogCvar)
		return;

	decl String:sPrefix[64], String:sMsg[512];
	new String:sOutput[512];
	new iWritten;

	GetNativeString(1, sPrefix, sizeof(sPrefix));
	FormatNativeString(0, 2, 3, sizeof(sMsg), iWritten, sMsg);

	if (strlen(sPrefix) > 0)
		Format(sOutput, sizeof(sOutput), "[%s]", sPrefix);

	if (strlen(sPrefix) > 0 && strlen(sMsg) > 0)
		StrCat(sOutput, sizeof(sOutput), " ");

	StrCat(sOutput, sizeof(sOutput), sMsg);

	LogToFileEx(g_sLogFile, sOutput);
}

public Native_LogRoundMessage(Handle:hPlugin, iNumParams)
{
	if (!g_bLogCvar)
		return;

	decl String:sPrefix[64], String:sMsg[512];
	new String:sOutput[512];
	new iWritten;

	GetNativeString(1, sPrefix, sizeof(sPrefix));
	FormatNativeString(0, 2, 3, sizeof(sMsg), iWritten, sMsg);

	if (strlen(sPrefix) > 0)
		Format(sOutput, sizeof(sOutput), "[%s]", sPrefix);

	if (strlen(sPrefix) > 0 && strlen(sMsg) > 0)
		StrCat(sOutput, sizeof(sOutput), " ");

	StrCat(sOutput, sizeof(sOutput), sMsg);

	Format(sOutput, sizeof(sOutput), "\t%s", sOutput);

	LogToFileEx(g_sLogFile, sOutput);
}

public Native_LogGameMessage(Handle:hPlugin, iNumParams)
{
	if (!g_bLogCvar)
		return;

	decl String:sGameId[TG_MODULE_ID_LENGTH], String:sPrefix[64], String:sMsg[512];
	new String:sOutput[512];
	new iWritten;

	if (GetNativeString(1, sGameId, sizeof(sGameId)) != SP_ERROR_NONE)
		return;

	GetNativeString(2, sPrefix, sizeof(sPrefix));
	FormatNativeString(0, 3, 4, sizeof(sMsg), iWritten, sMsg);

	Format(sOutput, sizeof(sOutput), "[%s]", sGameId);

	if (strlen(sPrefix) > 0)
		Format(sOutput, sizeof(sOutput), "%s[%s]", sOutput, sPrefix);

	if (strlen(sMsg) > 0)
		Format(sOutput, sizeof(sOutput), "%s %s", sOutput, sMsg);

	Format(sOutput, sizeof(sOutput), "\t%s", sOutput);

	if (g_Game[GameProgress] != TG_NoGame)
		Format(sOutput, sizeof(sOutput), "\t%s", sOutput);

	LogToFileEx(g_sLogFile, sOutput);
}

//------------------------------------------------------------------------------------------------
// AskPluginLoad2

public APLRes:AskPluginLoad2(Handle:hMySelf, bool:bLate, String:sError[], iErrMax)
{
	CreateNative("TG_GetPlayerTeam", Native_GetPlayerTeam);
	CreateNative("TG_SetPlayerTeam", Native_SetPlayerTeam);

	CreateNative("TG_LoadPlayerWeapons", Native_LoadPlayerWeapons);

	CreateNative("TG_AttachPlayerHealthBar", Native_AttachPlayerHealthBar);
	CreateNative("TG_UpdatePlayerHealthBar", Native_UpdatePlayerHealthBar);
	CreateNative("TG_DestroyPlayerHealthBar", Native_DestroyPlayerHealthBar);

	CreateNative("TG_FenceCreate", Native_FenceCreate);
	CreateNative("TG_FenceDestroy", Native_FenceDestroy);
	CreateNative("TG_FencePlayerCross", Native_FencePlayerCross);

	CreateNative("TG_SpawnMark", Native_SpawnMark);
	CreateNative("TG_DestroyMark", Native_DestroyMark);

	CreateNative("TG_GetTeamCount", Native_GetTeamCount);
	CreateNative("TG_ClearTeam", Native_ClearTeam);
	CreateNative("TG_SetTeamsLock", Native_SetTeamsLock);
	CreateNative("TG_GetTeamsLock", Native_GetTeamsLock);

	CreateNative("TG_IsModuleReged", Native_IsModuleReged);
	CreateNative("TG_GetRegedModules", Native_GetRegedModules);
	CreateNative("TG_GetModuleName", Native_GetModuleName);
	CreateNative("TG_FakeSelect", Native_FakeSelect);
	CreateNative("TG_SetModuleVisibility", Native_SetModuleVisibility);
	CreateNative("TG_GetModuleVisibility", Native_GetModuleVisibility);

	CreateNative("TG_RegMenuItem", Native_RegMenuItem);
	CreateNative("TG_RemoveMenuItem", Native_RemoveMenuItem);

	CreateNative("TG_RegGame", Native_RegGame);
	CreateNative("TG_RemoveGame", Native_RemoveGame);
	CreateNative("TG_StartGame", Native_StartGame);
	CreateNative("TG_GetCurrentGameID", Native_GetCurrentGameID);
	CreateNative("TG_IsCurrentGameID", Native_IsCurrentGameID);
	CreateNative("TG_GetCurrentDataPack", Native_GetCurrentDataPack);
	CreateNative("TG_GetCurrentStarter", Native_GetCurrentStarter);
	CreateNative("TG_GetCurrentGameSettings", Native_GetCurrentGameSettings);
	CreateNative("TG_GetCurrentGameType", Native_GetCurrentGameType);
	CreateNative("TG_GetGameType", Native_GetGameType);
	CreateNative("TG_StopGame", Native_StopGame);
	CreateNative("TG_GetGameStatus", Native_GetGameStatus);
	CreateNative("TG_IsGameStatus", Native_IsGameStatus);
	CreateNative("TG_IsGameTypeAvailable", Native_IsGameTypeAvailable);

	CreateNative("TG_ShowPlayerSelectMenu", Native_ShowPlayerSelectMenu);

	CreateNative("TG_LogMessage", Native_LogMessage);
	CreateNative("TG_LogRoundMessage", Native_LogRoundMessage);
	CreateNative("TG_LogGameMessage", Native_LogGameMessage);

	Forward_OnTraceAttack = 	 		CreateGlobalForward("TG_OnTraceAttack", 				ET_Hook, 	Param_Cell, 		Param_Cell, 		Param_CellByRef, 	Param_CellByRef, 	Param_FloatByRef, 	Param_CellByRef, 	Param_CellByRef, 	Param_Cell,   Param_Cell);
	Forward_OnPlayerDamage = 	 		CreateGlobalForward("TG_OnPlayerDamage", 				ET_Hook, 	Param_Cell, 		Param_Cell, 		Param_CellByRef, 	Param_CellByRef, 	Param_FloatByRef, 	Param_CellByRef, 	Param_CellByRef, 	Param_Cell,   Param_Cell);
	Forward_OnPlayerDeath = 	 		CreateGlobalForward("TG_OnPlayerDeath", 				ET_Ignore, 	Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_String, 		Param_Cell, 		Param_String, Param_Cell);
	Forward_OnPlayerTeam = 	 			CreateGlobalForward("TG_OnPlayerTeam", 					ET_Event, 	Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell);
	Forward_OnPlayerTeamPost = 	 		CreateGlobalForward("TG_OnPlayerTeamPost", 				ET_Ignore, 	Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell);
	Forward_OnPlayerRebel = 	 		CreateGlobalForward("TG_OnPlayerRebel", 				ET_Event, 	Param_Cell, 		Param_Cell);
	Forward_OnPlayerRebelPost = 	 	CreateGlobalForward("TG_OnPlayerRebelPost", 			ET_Ignore, 	Param_Cell, 		Param_Cell);
	Forward_OnPlayerLeaveGame = 	 	CreateGlobalForward("TG_OnPlayerLeaveGame", 			ET_Event, 	Param_String, 		Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell);
	Forward_OnPlayerStopGame = 	 		CreateGlobalForward("TG_OnPlayerStopGame", 				ET_Event, 	Param_Cell, 		Param_String);
	Forward_OnPlayerStopGamePost = 	 	CreateGlobalForward("TG_OnPlayerStopGamePost", 			ET_Ignore, 	Param_Cell, 		Param_String);
	Forward_OnLaserFenceCreate = 		CreateGlobalForward("TG_OnLaserFenceCreate", 			ET_Event, 	Param_Cell,			Param_Array, 		Param_Array);
	Forward_OnLaserFenceCreated = 		CreateGlobalForward("TG_OnLaserFenceCreated", 			ET_Ignore, 	Param_Cell,			Param_Array, 		Param_Array);
	Forward_OnLaserFenceCross = 		CreateGlobalForward("TG_OnLaserFenceCross", 			ET_Event, 	Param_Cell, 		Param_FloatByRef);
	Forward_OnLaserFenceCrossed = 		CreateGlobalForward("TG_OnLaserFenceCrossed", 			ET_Ignore, 	Param_Cell, 		Param_FloatByRef);
	Forward_OnLaserFenceDestroyed = 	CreateGlobalForward("TG_OnLaserFenceDestroyed", 		ET_Ignore, 	Param_Array, 		Param_Array);
	Forward_OnMarkSpawn = 				CreateGlobalForward("TG_OnMarkSpawn", 					ET_Event, 	Param_Cell,			Param_Cell, 		Param_Array, 		Param_Float);
	Forward_OnMarkSpawned = 			CreateGlobalForward("TG_OnMarkSpawned", 				ET_Ignore, 	Param_Cell,			Param_Cell, 		Param_Array, 		Param_Float, 		Param_Cell, 		Param_Cell);
	Forward_OnMarkDestroyed = 			CreateGlobalForward("TG_OnMarkDestroyed", 				ET_Ignore, 	Param_Cell,			Param_Cell, 		Param_Array, 		Param_Float, 		Param_Cell, 		Param_Cell, 		Param_Cell);
	Forward_OnGameStartMenu =  			CreateGlobalForward("TG_OnGameStartMenu",				ET_Event, 	Param_String,		Param_Cell,			Param_Cell, 		Param_String, 		Param_Cell);
	Forward_OnGamePreparePre =  		CreateGlobalForward("TG_OnGamePreparePre",				ET_Event, 	Param_String,		Param_Cell,			Param_Cell, 		Param_String, 		Param_Cell);
	Forward_OnGamePrepare =  			CreateGlobalForward("TG_OnGamePrepare",					ET_Ignore, 	Param_String,		Param_Cell,			Param_Cell, 		Param_String, 		Param_Cell);
	Forward_OnGameStart = 	 			CreateGlobalForward("TG_OnGameStart", 					ET_Ignore, 	Param_String,		Param_Cell,			Param_Cell, 		Param_String, 		Param_Cell);
	Forward_OnGameStartError = 			CreateGlobalForward("TG_OnGameStartError",				ET_Ignore, 	Param_String,		Param_Cell,			Param_Cell, 		Param_Cell, 		Param_String);
	Forward_OnTeamEmpty = 	 			CreateGlobalForward("TG_OnTeamEmpty", 					ET_Ignore, 	Param_String,		Param_Cell,			Param_Cell,			Param_Cell,			Param_Cell);
	Forward_OnGameEnd = 	 			CreateGlobalForward("TG_OnGameEnd", 					ET_Ignore, 	Param_String,		Param_Cell,			Param_Cell, 		Param_Array, 		Param_Cell, 		Param_Cell);
	Forward_OnMenuDisplay =  			CreateGlobalForward("TG_OnMenuDisplay",					ET_Event, 	Param_Cell);
	Forward_OnMenuDisplayed =  			CreateGlobalForward("TG_OnMenuDisplayed",				ET_Ignore, 	Param_Cell);
	Forward_OnMenuSelect = 				CreateGlobalForward("TG_OnMenuSelect", 					ET_Event, 	Param_Cell, 		Param_String,		Param_Cell,		Param_Cell);
	Forward_OnMenuSelected = 			CreateGlobalForward("TG_OnMenuSelected", 				ET_Ignore, 	Param_Cell, 		Param_String,		Param_Cell,		Param_Cell);
	Forward_OnDownloadsStart =			CreateGlobalForward("TG_OnDownloadsStart", 				ET_Ignore);
	Forward_OnDownloadFile =			CreateGlobalForward("TG_OnDownloadFile", 				ET_Ignore, 	Param_String,		Param_String,		Param_Cell, 		Param_CellByRef);
	Forward_OnDownloadsEnd =			CreateGlobalForward("TG_OnDownloadsEnd", 				ET_Ignore);
	Forward_AskModuleName =				CreateGlobalForward("TG_AskModuleName", 				ET_Ignore, 	Param_Cell,			Param_String,		Param_Cell, 		Param_String, 		Param_Cell, 		Param_CellByRef);

	CreateModulesConfigFileIfNotExist();

	RemoveAllTGMenuItems();
	RemoveAllGames();

	LoadMenuItemsConfig();
	LoadGamesMenuConfig();

	g_iEngineVersion = GetEngineVersion();
	if (g_iEngineVersion != Engine_CSS && g_iEngineVersion != Engine_CSGO) {
		LogError("Unsupported engine version detected!");
	}

	RegPluginLibrary("TeamGames");

	return APLRes_Success;
}

public GameStartMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Cancel) {
		if (Handle:GetMenuCell(hMenu, "-DATAPACK-") != INVALID_HANDLE) {
			CloseHandle(Handle:GetMenuCell(hMenu, "-DATAPACK-"));
		}

		MainMenu(iClient);
	} else if (iAction == MenuAction_Select) {
		decl String:sKey[64];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));

		if (StrEqual(sKey, "START_GAME")) {
			decl String:sSettings[TG_GAME_SETTINGS_LENGTH];
			decl String:sGameID[TG_MODULE_ID_LENGTH];
			new iStarter = GetMenuCell(hMenu, "-CLIENT-");
			new TG_GameType:iGameType = TG_GameType:GetMenuCell(hMenu, "-GAMETYPE-");
			new Handle:hDataPack = Handle:GetMenuCell(hMenu, "-DATAPACK-");
			new bool:bRemoveDrops = bool:GetMenuCell(hMenu, "-REMOVEDROPS-");
			new bool:bEndOnTeamEmpty = bool:GetMenuCell(hMenu, "-ENDONTEAMEMPTY-");

			GetMenuString(hMenu, "-GAMEID-", sGameID, sizeof(sGameID));
			GetMenuString(hMenu, "-GAMESETTINGS-", sSettings, sizeof(sSettings));

			new Action:iResult = Plugin_Continue;
			Call_StartForward(Forward_OnGameStartMenu);
			Call_PushString(sGameID);
			Call_PushCell(iGameType);
			Call_PushCell(iStarter);
			Call_PushString(sSettings);
			Call_PushCell(hDataPack);
			Call_Finish(iResult);
			if (iResult != Plugin_Continue) {
				if (hDataPack != INVALID_HANDLE) {
					CloseHandle(hDataPack);
				}
				return;
			}

			TG_StartGamePreparation(iStarter, sGameID, iGameType, sSettings, hDataPack, bRemoveDrops, bEndOnTeamEmpty);
		}
	}
}

TG_StartGamePreparation(iClient, String:sID[TG_MODULE_ID_LENGTH], TG_GameType:iGameType, String:sSettings[TG_GAME_SETTINGS_LENGTH], Handle:hGameCustomDataPack, bool:bRemoveDropppedWeapons, bool:bEndOnTeamEmpty)
{
	new Action:iResult = Plugin_Continue;
	Call_StartForward(Forward_OnGamePreparePre);
	Call_PushString(sID);
	Call_PushCell(iGameType);
	Call_PushCell(iClient);
	Call_PushString(sSettings);
	Call_PushCell(hGameCustomDataPack);
	Call_Finish(iResult);

	if (iResult != Plugin_Continue) {
		if (hGameCustomDataPack != INVALID_HANDLE) {
			CloseHandle(hGameCustomDataPack);
		}
		return 0;
	}

	new String:sName[TG_MODULE_NAME_LENGTH], String:sTeam1[4096], String:sTeam2[4096];
	new iGameIndex = GetGameIndex(sID);
	new iCount1, iCount2;

	decl String:sErrorDescription[512];
	new iErrorCode = 0;

	strcopy(sName, TG_MODULE_NAME_LENGTH, g_GameList[iGameIndex][DefaultName]);

	if (g_Game[GameProgress] == TG_InProgress || g_Game[GameProgress] == TG_InPreparation) {
		CPrintToChat(iClient, "%t", "StartGame-AnotherGameInProgress");
		Format(sErrorDescription, sizeof(sErrorDescription), "[ERROR - TG_StartGame #%d] \"%L\" tried to start preparation for game (sName: \"%s\") (sID: \"%s\") (sError: \"Another game in progress\")", 1, iClient, sName, sID);

		iErrorCode = 1;
	}

	if (!IsGameTypeAvailable(iGameType)) {
		CPrintToChat(iClient, "%t", "StartGame-BadTeamRatio");
		Format(sErrorDescription, sizeof(sErrorDescription), "[ERROR - TG_StartGame #%d] \"%L\" tried to start preparation for game (sName: \"%s\") (sID: \"%s\") (sError: \"Bad teams ratio\")", 2, iClient, sName, sID);

		iErrorCode = 2;
	}

	if (!IsPlayerAlive(iClient) && !CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)) {
		CPrintToChat(iClient, "%t", "StartGame-AliveOnly");
		Format(sErrorDescription, sizeof(sErrorDescription), "[ERROR - TG_StartGame #%d] \"%L\" tried to start preparation for game (sName: \"%s\") (sID: \"%s\") (sError: \"iActivator is dead and doesn't have required admin sFlag\")", 4, iClient, sName, sID);

		iErrorCode = 4;
	}

	if (iErrorCode != 0) {
		TG_LogRoundMessage("GamePrepare", sErrorDescription);

		Call_StartForward(Forward_OnGameStartError);
		Call_PushString(sID);
		Call_PushCell(iGameType);
		Call_PushCell(iClient);
		Call_PushCell(iErrorCode);
		Call_PushString(sErrorDescription);
		Call_Finish();

		if (hGameCustomDataPack != INVALID_HANDLE) {
			CloseHandle(hGameCustomDataPack);
			hGameCustomDataPack = INVALID_HANDLE;
		}

		// ThrowError(sErrorDescription);
		return iErrorCode;
	}

	g_Game[GameProgress] = TG_InPreparation;

	g_Game[GameDataPack] = hGameCustomDataPack;
	strcopy(g_Game[GameSettings], TG_GAME_SETTINGS_LENGTH, sSettings);
	g_Game[GameStarter] = iClient;
	g_Game[TGType] = iGameType;
	g_Game[RemoveDrops] = bRemoveDropppedWeapons;
	g_Game[EndOnTeamEmpty] = bEndOnTeamEmpty;
	g_Game[HealthBarVisibility] = g_GameList[iGameIndex][HealthBarVisibility];

	g_bTeamsLock = true;

	strcopy(g_Game[GameID], TG_MODULE_ID_LENGTH, sID);
	strcopy(g_Game[DefaultName], TG_MODULE_ID_LENGTH, g_GameList[iGameIndex][DefaultName]);

	if (g_iRoundLimit > 0)
		g_iRoundLimit--;

	for (new iUser = 1; iUser <= MaxClients; iUser++) {
		if (!IsClientInGame(iUser)) {
			continue;
		}

		if (GetClientTeam(iUser) == CS_TEAM_CT) {
			CPrintToChat(iUser, "%T", "StopGameInfo", iUser, "Menu-StopGame");
		}

		new String:sGameName[TG_MODULE_NAME_LENGTH];
		Call_AskModuleName(sID, TG_Game, iUser, sGameName, sizeof(sGameName));

		for (new i = 0; i <= _:GetConVarBool(g_hImportantMsg); i++) {
			if (sSettings[0] == '\0') {
				CPrintToChat(iUser, "%T", "GamePreparation", iUser, sGameName);
			} else {
				CPrintToChat(iUser, "%T", "GamePreparation-Settings", iUser, sGameName, sSettings);
			}
		}
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			SetEntityMoveType(i, MoveType:MOVETYPE_NONE);

			SavePlayerEquipment(i);
			Client_RemoveAllWeapons(i, "", true);

			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				g_Game[RedTeam][iCount1] = GetClientUserId(i);
				iCount1++;
				g_Game[RedTeam][iCount1] = 0;

				if (g_bLogCvar) {
					Format(sTeam1, sizeof(sTeam1), "%s%L, ", sTeam1, i);
				}
			}

			if (TG_GetPlayerTeam(i) == TG_BlueTeam) {
				g_Game[BlueTeam][iCount2] = GetClientUserId(i);
				iCount2++;
				g_Game[BlueTeam][iCount2] = 0;

				if (g_bLogCvar) {
					Format(sTeam2, sizeof(sTeam2), "%s%L, ", sTeam2, i);
				}
			}

			if (bRemoveDropppedWeapons) {
				SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
			}
		}

		if (IsClientConnected(i) && IsClientInGame(i))
			PrintToConsole(i, "\n// ----------\n\t[TeamGames] %N started preparation for game \"%s\"\n// ----------\n", iClient, sName);
	}

	Call_StartForward(Forward_OnGamePrepare);
	Call_PushString(g_Game[GameID]);
	Call_PushCell(g_Game[TGType]);
	Call_PushCell(g_Game[GameStarter]);
	Call_PushString(g_Game[GameSettings]);
	Call_PushCell(g_Game[GameDataPack]);
	Call_Finish();

	if (g_bLogCvar) {
		if (strlen(sTeam1) > 1)
			sTeam1[strlen(sTeam1) - 2] = '\0';

		if (strlen(sTeam2) > 1)
			sTeam2[strlen(sTeam2) - 2] = '\0';

		TG_LogRoundMessage(   "GamePrepare", "(ID: \"%s\")", g_Game[GameID]);
		TG_LogRoundMessage(_, "{");
		TG_LogRoundMessage(_, "\tSettings: \"%s\"", g_Game[GameSettings]);
		TG_LogRoundMessage(_, "\tActivator: \"%L\"", g_Game[GameStarter]);
		TG_LogRoundMessage(_, "");
		TG_LogRoundMessage(_, "\tRedTeam (%d): \"%s\"", iCount1, sTeam1);
		TG_LogRoundMessage(_, "\tBlueTeam (%d): \"%s\"", iCount2, sTeam2);
		TG_LogRoundMessage(_, "}");
	}

	if (IsSoundPrecached(g_sGamePrepare[5]))
		EmitSoundToAllAny(g_sGamePrepare[5]);

	g_iTimer_CountDownGamePrepare_counter = 4;
	g_hTimer_CountDownGamePrepare = CreateTimer(1.0, Timer_CountDownGamePrepare, _, TIMER_REPEAT);

	return 0;
}

public Action:Hook_WeaponDrop(iClient, weapon)
{
	if (!g_Game[RemoveDrops] || g_Game[GameProgress] == TG_NoGame)
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(iClient) && IsValidEdict(weapon)) {
		AcceptEntityInput(weapon, "Kill");
	}

	return Plugin_Continue;
}

public Action:Timer_CountDownGamePrepare(Handle:hTimer)
{
	if (g_iTimer_CountDownGamePrepare_counter > 0) {
		if (IsSoundPrecached(g_sGamePrepare[g_iTimer_CountDownGamePrepare_counter]))
			EmitSoundToAllAny(g_sGamePrepare[g_iTimer_CountDownGamePrepare_counter]);

		#if defined DEBUG
		LogMessage("[TG DEBUG] Played file '%s'.", g_sGamePrepare[g_iTimer_CountDownGamePrepare_counter]);
		#endif

		g_iTimer_CountDownGamePrepare_counter--;
	} else {
		if (IsSoundPrecached(g_sGameStart))
			EmitSoundToAllAny(g_sGameStart);

		if (g_hTimer_CountDownGamePrepare != INVALID_HANDLE) {
			KillTimer(g_hTimer_CountDownGamePrepare);
			g_hTimer_CountDownGamePrepare = INVALID_HANDLE;
		}

		g_iTimer_CountDownGamePrepare_counter = 4;

		g_Game[GameProgress] = TG_InProgress;

		for (new i = 1; i <= MaxClients; i++) {
			if (TG_IsTeamRedOrBlue(g_PlayerData[i][Team]))
				SetEntityMoveType(i, MoveType:MOVETYPE_ISOMETRIC);
		}

		for (new iUser = 1; iUser <= MaxClients; iUser++) {
			if (!IsClientInGame(iUser)) {
				continue;
			}

			new String:sGameName[TG_MODULE_NAME_LENGTH];
			Call_AskModuleName(g_Game[GameID], TG_Game, iUser, sGameName, sizeof(sGameName));

			for (new i = 0; i <= _:GetConVarBool(g_hImportantMsg); i++) {
				if (g_Game[GameSettings][0] == '\0') {
					CPrintToChat(iUser, "%T", "GameStart", iUser, sGameName);
				} else {
					CPrintToChat(iUser, "%T", "GameStart-Settings", iUser, sGameName, g_Game[GameSettings]);
				}
			}
		}

		if (g_iFriendlyFire == 2)
			SetConVarIntSilent("mp_friendlyfire", 1);

		Call_StartForward(Forward_OnGameStart);
		Call_PushString(g_Game[GameID]);
		Call_PushCell(g_Game[TGType]);
		Call_PushCell(g_Game[GameStarter]);
		Call_PushString(g_Game[GameSettings]);
		Call_PushCell(g_Game[GameDataPack]);
		Call_Finish();

		TG_LogRoundMessage("GameStart", "(ID: \"%s\")", g_Game[GameID]);
	}

	return Plugin_Continue;
}

TG_MenuItemStatus:Call_AskModuleName(const String:sID[], TG_ModuleType:iType, iClient, String:sName[], iNameSize, TG_MenuItemStatus:iStatus = TG_Active, const String:sDefaultName[] = "")
{
	if (sDefaultName[0] != '\0') {
		strcopy(sName, iNameSize, sDefaultName);
	} else {
		strcopy(sName, iNameSize, sID);
	}
	new TG_MenuItemStatus:m_iStatus = iStatus;

	Call_StartForward(Forward_AskModuleName);
	Call_PushCell(iType);
	Call_PushString(sID);
	Call_PushCell(iClient);
	Call_PushStringEx(sName, iNameSize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(iNameSize);
	Call_PushCellRef(m_iStatus);
	Call_Finish();

	return m_iStatus;
}

bool:Call_OnDownloadFile(String:sFile[], String:sPrefix[], Handle:hArgs, bool:bKnown)
{
	new bool:m_bKnown = bKnown;

	Call_StartForward(Forward_OnDownloadFile);
	Call_PushString(sFile);
	Call_PushString(sPrefix);
	Call_PushCell(hArgs);
	Call_PushCellRef(m_bKnown);
	Call_Finish();

	return m_bKnown;
}

Call_OnMenuSelected(TG_ModuleType:iType, const String:sID[], TG_GameType:iGameType, iClient)
{
	Call_StartForward(Forward_OnMenuSelected);
	Call_PushCell(iType);
	Call_PushString(sID);
	Call_PushCell(iGameType);
	Call_PushCell(iClient);
	Call_Finish();
}

Action:Call_OnMenuSelect(TG_ModuleType:iType, const String:sID[], TG_GameType:iGameType, iClient)
{
	new Action:iResult = Plugin_Continue;
	Call_StartForward(Forward_OnMenuSelect);
	Call_PushCell(iType);
	Call_PushString(sID);
	Call_PushCell(iGameType);
	Call_PushCell(iClient);
	Call_Finish(iResult);
	return iResult;
}

Call_OnPlayerLeaveGame(const String:sID[], TG_GameType:iGameType, iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	Call_StartForward(Forward_OnPlayerLeaveGame);
	Call_PushString(sID);
	Call_PushCell(iGameType);
	Call_PushCell(iClient);
	Call_PushCell(iTeam);
	Call_PushCell(iTrigger);
	Call_Finish();

	if (g_iPlayerHPBar[iClient][AutomaticDestroy]) {
		RemoveHealthBar(iClient);
	}
}

Call_OnTeamEmpty(const String:sID[], TG_GameType:iGameType, iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	Call_StartForward(Forward_OnTeamEmpty);
	Call_PushString(sID);
	Call_PushCell(iGameType);
	Call_PushCell(iClient);
	Call_PushCell(iTeam);
	Call_PushCell(iTrigger);
	Call_Finish();
}
