new bool:g_bLockMenu;

public Action:Command_BindAction(iClient, const String:sCommand[], iArgs)
{
	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_CT) {
		return Plugin_Continue;
	}

	new String:sAction[64];

	if (StrEqual(sCommand, "buyammo1", false) && g_sBindActionBuyAmmo1[0] != '\0') {
		strcopy(sAction, sizeof(sAction), g_sBindActionBuyAmmo1);
	} else if (StrEqual(sCommand, "buyammo2", false) && g_sBindActionBuyAmmo2[0] != '\0') {
		strcopy(sAction, sizeof(sAction), g_sBindActionBuyAmmo2);
	} else if (StrEqual(sCommand, "+lookatweapon", false) && g_sBindActionLookAtWeapon[0] != '\0') {
		strcopy(sAction, sizeof(sAction), g_sBindActionLookAtWeapon);
	} else {
		return Plugin_Continue;
	}

	if (!TG_CheckModuleAccess(iClient, TG_MenuItem, sAction)) {
		return Plugin_Continue;
	}

	if (StrEqual(sAction, "Core_SwitchToRedTeam", false) || StrEqual(sAction, "Core_SwitchToBlueTeam", false) || StrEqual(sAction, "Core_SwitchToNoneTeam", false)) {
		new TG_Team:iTeam;

		if (StrContains(sAction[13], "red", false) == 0) {
			iTeam = TG_RedTeam;
		} else if (StrContains(sAction[13], "blue", false) == 0) {
			iTeam = TG_BlueTeam;
		} else if (StrContains(sAction[13], "none", false) == 0) {
			iTeam = TG_NoneTeam;
		}

		new iTarget = GetClientAimTarget(iClient);
		if (iTarget > 0) {
			SwitchToTeam(iClient, iTarget, iTeam);
		}
	} else if (StrEqual(sAction, "Core_SwitchAllToNoneTeam", false)) {
		ClearTeams(iClient);
	} else if (StrContains(sAction, "Core_SwitchAllToRedTeam", false) == 0) {
		SwitchAllToRedTeam(iClient);

		if (StrEqual(sAction, "Core_SwitchAllToRedTeamJumpToGames", false)) {
			GamesMenu(iClient, TG_RedOnly);
		}
	} else if (StrContains(sAction, "Core_SwitchAllFiftyFifty", false) == 0) {
		SwitchAllFiftyFifty(iClient);

		if (StrEqual(sAction, "Core_SwitchAllFiftyFiftyJumpToGames", false)) {
			GamesMenu(iClient, TG_TeamGame);
		}
	} else if ((StrEqual(sAction, "Core_SpawnRedMark", false) || StrEqual(sAction, "Core_SpawnBlueMark", false)) && g_PlayerData[iClient][AbleToMark]) {
		new Float:fAngles[3], Float:fOrigin[3];

		GetClientEyeAngles(iClient, fAngles);
		GetClientEyePosition(iClient, fOrigin);

		new Handle:hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, MarkTraceFilter);

		if (TR_DidHit(hTrace)) {
			new Float:fPos[3];
			new TG_Team:iTeam;

			TR_GetEndPosition(fPos, hTrace);

			if (StrContains(sAction[10], "red", false) == 0) {
				iTeam = TG_RedTeam;
			} else {
				iTeam = TG_BlueTeam;
			}

			SpawnMark(iClient, iTeam, fPos[0], fPos[1], fPos[2], _, _, _, false);
		}
	} else {
		if (Call_OnMenuSelect(TG_MenuItem, sAction, TG_None, iClient) != Plugin_Continue)
			return Plugin_Continue;

		Call_OnMenuSelected(TG_MenuItem, sAction, TG_None, iClient);

		if (StrContains(sAction, "Core_", false) == 0) {
			CoreMenuItemsActions(iClient, sAction);
		}
	}

	return Plugin_Continue;
}

public bool:MarkTraceFilter(iEntity, iContentsMask)
{
	if (Client_IsIngame(iEntity))
		return false;

	return true;
}

public Action:Command_SetTeam(iClient, iArgs)
{
	if (!Client_IsValid(iClient, true))
		return Plugin_Handled;

	if (GetCmdArgs() != 2) {
		ReplyToCommand(iClient, "[TeamGames] Usage: sm_tgteam <#userid|name> <team = 0|1|2>");
		return Plugin_Handled;
	}

	new String:sTarget[64];
	new String:sTeam[2];

	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sTeam, sizeof(sTeam));

	new iTarget = FindTarget(iClient, sTarget, true, true);
	if (iTarget == -1 || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) != CS_TEAM_T) {
		ReplyToCommand(iClient, "[TeamGames] Couldn't target this player !");
		return Plugin_Handled;
	}

	new TG_Team:iTeam = TG_GetTeamFromString(sTeam);
	if (iTeam == TG_ErrorTeam) {
		ReplyToCommand(iClient, "[TeamGames] Invalid team argument !");
		return Plugin_Handled;
	}

	SwitchToTeam(-1, iTarget, iTeam);

	return Plugin_Handled;
}

public Action:Command_Visible(iClient, iArgs)
{
	if (iArgs == 0) {
		Command_VisibleMainMenu(iClient);
		return Plugin_Handled;
	} else if (iArgs <= 3) {
		PrintToConsole(iClient, "Usage: sm_tgvisible <visibility = 0|1> <type = game|menu> <module id>");
		return Plugin_Handled;
	}

	decl String:sID[TG_MODULE_ID_LENGTH], String:sType[5];
	new bool:bVisibility = bool:GetCmdArgInt(1);
	new TG_ModuleType:iType;

	GetCmdArg(2, sType, sizeof(sType));
	GetCmdArg(3, sID, sizeof(sID));

	if (StrEqual(sType, "game"))
		iType = TG_Game;
	else if (StrEqual(sType, "menu"))
		iType = TG_MenuItem;

	TG_SetModuleVisibility(iType, sID, bVisibility);

	return Plugin_Handled;
}

Command_VisibleMainMenu(iClient)
{
	new Handle:hMenu = CreateMenu(VisibleMainMenu_Handler);

	SetMenuTitle(hMenu, "%T", "MenuVisibility-Title", iClient);

	AddMenuItemFormat(hMenu, "menuitems", _, "%T", "MenuVisibility-MenuItems", iClient);
	AddMenuItemFormat(hMenu, "games", _, "%T", "MenuVisibility-Games", iClient);

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public VisibleMainMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		decl String:sKey[24];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));

		if (StrEqual(sKey, "menuitems"))
			Command_VisibleSubMenu(iClient, TG_MenuItem);
		else if (StrEqual(sKey, "games", false))
			Command_VisibleSubMenu(iClient, TG_Game);
	} else if (iAction == MenuAction_End) {
		CloseHandle(hMenu);
	}
}

Command_VisibleSubMenu(iClient, TG_ModuleType:iType)
{
	new Handle:hMenu = CreateMenu(VisibleSubMenu_Handler);

	if (iType == TG_MenuItem) {
		SetMenuTitle(hMenu, "%T", "MenuVisibility-SubTitle", iClient);

		for (new i = 0; i < g_iMenuItemListEnd; i++) {
			if (!g_MenuItemList[i][Used])
				continue;

			new String:sName[TG_MODULE_NAME_LENGTH];
			Call_AskModuleName(g_MenuItemList[i][Id], TG_MenuItem, iClient, sName, sizeof(sName), _, g_MenuItemList[i][DefaultName]);

			AddMenuItemFormat(hMenu, g_MenuItemList[i][Id], _, "%s %s", (g_MenuItemList[i][Visible]) ? "[X]" : "[ ]", sName);
		}
	} else if (iType == TG_Game) {
		SetMenuTitle(hMenu, "%T", "MenuVisibility-SubTitle", iClient);

		for (new i = 0; i < g_iGameListEnd; i++) {
			if (!g_GameList[i][Used])
				continue;

			new String:sName[TG_MODULE_NAME_LENGTH];
			Call_AskModuleName(g_GameList[i][Id], TG_Game, iClient, sName, sizeof(sName), _, g_GameList[i][DefaultName]);

			AddMenuItemFormat(hMenu, g_GameList[i][Id], _, "%s %s", (g_GameList[i][Visible]) ? "[X]" : "[ ]", sName);
		}
	}

	PushMenuCell(hMenu, "Core_-TYPE-", _:iType);

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public VisibleSubMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	switch (iAction) {
		case MenuAction_Select: {
			decl String:sKey[128], String:sDisplay[128];
			new TG_ModuleType:iType = TG_ModuleType:GetMenuCell(hMenu, "Core_-TYPE-", -1);
			GetMenuItem(hMenu, iKey, sKey, sizeof(sKey), _, sDisplay, sizeof(sDisplay));

			if (StrContains(sDisplay, "[ ]") == 0)
				TG_SetModuleVisibility(iType, sKey, true);
			else if (StrContains(sDisplay, "[X]") == 0)
				TG_SetModuleVisibility(iType, sKey, false);
			else
				return;

			Command_VisibleSubMenu(iClient, iType);
		}
		case MenuAction_Cancel: {
			if (iKey == MenuCancel_ExitBack) {
				Command_VisibleMainMenu(iClient);
			}
		}
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
}

public Action:Command_Update(iClient, iArgs)
{
	new bool:bTriggered = Updater_ForceUpdate();
	new String:sMsg[256];

	if (bTriggered)
		strcopy(sMsg, sizeof(sMsg), "[TeamGames] Update was triggered.");
	else
		strcopy(sMsg, sizeof(sMsg), "[TeamGames] No available update.");

	ReplyToCommand(iClient, sMsg);

	return Plugin_Handled;
}

public Action:Command_ModulesList(iClient, iArgs)
{
	ListGames(iClient);
	ListMenuItems(iClient);

	return Plugin_Handled;
}

public Action:Command_GamesList(iClient, iArgs)
{
	DisplayGamesListMenu(iClient);
	return Plugin_Handled;
}

static DisplayGamesListMenu(iClient)
{
	if (Client_IsValid(iClient)) {
		new Handle:hMenu = CreateMenu(GamesListMenu_Handler);
		SetMenuTitle(hMenu, "%T", "MenuGamesList-Title", iClient);

		AddMenuItemFormat(hMenu, "TeamGame", _, "%T", "MenuGamesList-TeamGame", iClient);
		AddMenuItemFormat(hMenu, "RedOnly", _, "%T", "MenuGamesList-RedOnly", iClient);

		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, iClient, 30);
	}
}

public GamesListMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	switch (iAction) {
		case MenuAction_Select: {
			new String:sKey[12];
			GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));

			new Handle:hSubMenu = CreateMenu(GamesListSubMenu_Handler);

			if (StrEqual(sKey, "TeamGame")) {
				SetMenuTitle(hSubMenu, "%T", "MenuGamesList-Title-TeamGame", iClient);
				PushMenuCell(hSubMenu, "Core_-GameType-", _:TG_TeamGame);

				new String:sName[TG_MODULE_NAME_LENGTH];
				for (new i = 0; i < MAX_GAMES; i++) {
					if (g_GameList[i][Used] && g_GameList[i][Visible] && g_GameList[i][GameType] == TG_TeamGame) {
						Call_AskModuleName(g_GameList[i][Id], TG_Game, iClient, sName, sizeof(sName));

						AddMenuItem(hSubMenu, g_GameList[i][Id], sName);
					}
				}
			} else {
				SetMenuTitle(hSubMenu, "%T", "MenuGamesList-Title-RedOnly", iClient);
				PushMenuCell(hSubMenu, "Core_-GameType-", _:TG_RedOnly);

				new String:sName[TG_MODULE_NAME_LENGTH];
				for (new i = 0; i < MAX_GAMES; i++) {
					if (g_GameList[i][Used] && g_GameList[i][Visible] && g_GameList[i][GameType] == TG_RedOnly) {
						Call_AskModuleName(g_GameList[i][Id], TG_Game, iClient, sName, sizeof(sName));

						AddMenuItem(hSubMenu, g_GameList[i][Id], sName);
					}
				}
			}

			SetMenuExitBackButton(hSubMenu, true);
			DisplayMenu(hSubMenu, iClient, MENU_TIME_FOREVER);
		}
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
}

public GamesListSubMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	switch (iAction) {
		case MenuAction_Select: {
			new String:sGameID[TG_MODULE_ID_LENGTH], String:sGameName[TG_MODULE_NAME_LENGTH], String:sClientName[64];
			new TG_GameType:iType = TG_GameType:GetMenuCell(hMenu, "Core_-GameType-");
			GetMenuItem(hMenu, iKey, sGameID, sizeof(sGameID));
			GetClientName(iClient, sClientName, sizeof(sClientName));

			for (new iUser = 1; iUser <= MaxClients; iUser++) {
				if (!IsClientInGame(iUser)) {
					continue;
				}

				Call_AskModuleName(sGameID, TG_Game, iUser, sGameName, sizeof(sGameName));
				CPrintToChat(iUser, "%T", (iType == TG_TeamGame) ? "MenuGamesList-Chosen-TeamGame" : "MenuGamesList-Chosen-RedOnly", iUser, sClientName, sGameName);
			}
		}
		case MenuAction_Cancel: {
			if (iKey == MenuCancel_ExitBack) {
				DisplayGamesListMenu(iClient);
			}
		}
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
}

public Action:Command_StopTG(iClient, iArgs)
{
	if (GetClientTeam(iClient) != CS_TEAM_CT && !CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)) {
		CPrintToChat(iClient, "%t", "Menu-CTOnly");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient) && !CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)) {
		CPrintToChat(iClient, "%t", "Menu-AliveOnly");
		return Plugin_Handled;
	}

	StopGame(iClient);

	return Plugin_Handled;
}

public Action:Command_Rebel(iClient, iArgs)
{
	if (Client_IsValid(iClient)) {
		if (GetClientTeam(iClient) != CS_TEAM_T) {
			CPrintToChat(iClient, "%t", "Rebel-PrisonersOnly");
		} else if (!IsPlayerAlive(iClient)) {
			CPrintToChat(iClient, "%t", "Rebel-AliveOnly");
		} else if (!TG_IsPlayerRedOrBlue(iClient)) {
			CPrintToChat(iClient, "%t", "Rebel-InTeamOnly");
		} else {
			MakeRebel(iClient);
		}
	}

	return Plugin_Handled;
}

public Action:Command_MainMenu(iClient, iArgs)
{
	if (CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)) {
		g_PlayerData[iClient][MenuLock] = false;
		MainMenu(iClient);
		return Plugin_Handled;
	}

	if (GetClientTeam(iClient) == CS_TEAM_CT) {
		if (GetTime() < g_iMenuTimeLock) {
			CPrintToChat(iClient, "%t", "Menu-TimeLock", g_iMenuTimeLock - GetTime());
			return Plugin_Handled;
		}

		if (!IsPlayerAlive(iClient)) {
			CPrintToChat(iClient, "%t", "Menu-AliveOnly");
			return Plugin_Handled;
		}

		if (g_bLockMenu) {
			g_PlayerData[iClient][MenuLock] = false;
			new UnlockCount;

			for (new i = 1; i <= MaxClients; i++) {
				if (g_PlayerData[i][MenuLock] == false)
					UnlockCount++;
			}

			if (UnlockCount >= RoundToNearest(Team_GetClientCount(CS_TEAM_CT, CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE) * GetConVarFloat(g_hMenuPercent))) {
				if (g_bLockMenu)
					CPrintToChatAll("%t", "Menu-Unlocked");

				g_bLockMenu = false;
			} else {
				CPrintToChatAll("%t", "Menu-Locked", UnlockCount, RoundToNearest(Team_GetClientCount(CS_TEAM_CT, CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE) * GetConVarFloat(g_hMenuPercent)));
			}
		}

		if (!g_bLockMenu)
			MainMenu(iClient);
	} else {
		CPrintToChat(iClient, "%t", "Menu-CTOnly");
	}

	return Plugin_Handled;
}

MainMenu(iClient)
{
	if (g_iMenuItemListEnd < 1 || !Client_IsIngame(iClient))
		return;

	new Action:iResult = Plugin_Continue;
	Call_StartForward(Forward_OnMenuDisplay);
	Call_PushCell(iClient);
	Call_Finish(iResult);

	if (iResult != Plugin_Continue)
		return;

	Call_StartForward(Forward_OnMenuDisplayed);
	Call_PushCell(iClient);
	Call_Finish();

	new Handle:hMenu = CreateMenu(MainMenu_Handler);
	decl String:sMenuItemName[TG_MODULE_NAME_LENGTH];

	SetMenuTitle(hMenu, "%T", "Menu-Title", iClient);

	for (new i = 0; i < g_iMenuItemListEnd; i++) {
		if (!g_MenuItemList[i][Used] || !g_MenuItemList[i][Visible] || !TG_CheckModuleAccess(iClient, TG_MenuItem, g_MenuItemList[i][Id])) {
			continue;
		}

		if (StrEqual(g_MenuItemList[i][Id], "Core_TeamsMenu", false)) {
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);

			if (g_bTeamsLock == true || g_Game[GameProgress] == TG_InProgress || g_Game[GameProgress] == TG_InPreparation)
				AddMenuItemFormat(hMenu, "Core_TeamsMenu", ITEMDRAW_DISABLED, "%T", "Menu-Teams", iClient);
			else
				AddMenuItemFormat(hMenu, "Core_TeamsMenu", _, "%T", "Menu-Teams", iClient);

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_GamesMenu", false)) {
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);

			if (GetTime() < g_iGamesTimeLock) {
				AddMenuItemFormat(hMenu, "Core_GamesMenu", ITEMDRAW_DISABLED, "%T", "Menu-Games-TimeLock", iClient, g_iGamesTimeLock - GetTime());
			} else {
				if (g_Game[GameProgress] != TG_NoGame || GetCountAllGames() < 1 || g_iRoundLimit == 0 || (!IsGameTypeAvailable(TG_RedOnly) && !IsGameTypeAvailable(TG_TeamGame)))
					AddMenuItemFormat(hMenu, "Core_GamesMenu", ITEMDRAW_DISABLED, "%T", "Menu-Games", iClient);
				else
					AddMenuItemFormat(hMenu, "Core_GamesMenu", _, "%T", "Menu-Games", iClient);
			}


			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_GamesMenu-TeamGame", false)) {
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);

			if (GetTime() < g_iGamesTimeLock) {
				AddMenuItemFormat(hMenu, "Core_GamesMenu-TeamGame", ITEMDRAW_DISABLED, "%T", "Menu-Games-TimeLock", iClient, g_iGamesTimeLock - GetTime());
			} else {
				if (g_Game[GameProgress] != TG_NoGame || GetCountAllGames() < 1 || g_iRoundLimit == 0 || !IsGameTypeAvailable(TG_TeamGame))
					AddMenuItemFormat(hMenu, "Core_GamesMenu-TeamGame", ITEMDRAW_DISABLED, "%T", "Menu-Games-TeamGame", iClient);
				else
					AddMenuItemFormat(hMenu, "Core_GamesMenu-TeamGame", _, "%T", "Menu-Games-TeamGame", iClient);
			}

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_GamesMenu-RedOnly", false)) {
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);

			if (GetTime() < g_iGamesTimeLock) {
				AddMenuItemFormat(hMenu, "Core_GamesMenu-TeamGame", ITEMDRAW_DISABLED, "%T", "Menu-Games-TimeLock", iClient, g_iGamesTimeLock - GetTime());
			} else {
				if (g_Game[GameProgress] != TG_NoGame || GetCountAllGames() < 1 || g_iRoundLimit == 0 || !IsGameTypeAvailable(TG_RedOnly))
					AddMenuItemFormat(hMenu, "Core_GamesMenu-RedOnly", ITEMDRAW_DISABLED, "%T", "Menu-Games-RedOnly", iClient);
				else
					AddMenuItemFormat(hMenu, "Core_GamesMenu-RedOnly", _, "%T", "Menu-Games-RedOnly", iClient);
			}

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_FencesMenu", false)) {
			if (GetConVarInt(g_hFenceType) == 0 || !g_bFencesMenuMapVisibility) {
				continue;
			}

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);
			AddMenuItemFormat(hMenu, "Core_FencesMenu", _, "%T", "Menu-CreateFence", iClient);
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_StopGame", false)) {
			if (g_Game[GameProgress] != TG_NoGame) {
				AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);
				AddMenuItemFormat(hMenu, "Core_StopGame", _, "%T", "Menu-StopGame", iClient);
				AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
			}
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_GamesRoundLimitInfo", false)) {
			if (g_iRoundLimit > -1) {
				AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);

				if (g_iRoundLimit == 0)
					AddMenuItemFormat(hMenu, "Core_GamesRoundLimitInfo", ITEMDRAW_RAWLINE, "%T", "Menu-NoMoreGames", iClient);
				else if (g_iRoundLimit > 0)
					AddMenuItemFormat(hMenu, "Core_GamesRoundLimitInfo", ITEMDRAW_RAWLINE, "%T", "Menu-CountGamesInfo", iClient, g_iRoundLimit);

			}

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else if (StrEqual(g_MenuItemList[i][Id], "Core_Separator", false)) {
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);
			AddMenuItem(hMenu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER);
			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		} else {
			new TG_MenuItemStatus:iStatus = Call_AskModuleName(g_MenuItemList[i][Id], TG_MenuItem, iClient, sMenuItemName, sizeof(sMenuItemName), _ ,g_MenuItemList[i][DefaultName]);

			if (iStatus == TG_Disabled)
				continue;

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], -1);

			if (iStatus == TG_Active)
				AddMenuItem(hMenu, g_MenuItemList[i][Id], sMenuItemName);
			else if (iStatus == TG_Inactive)
				AddMenuItem(hMenu, g_MenuItemList[i][Id], sMenuItemName, ITEMDRAW_DISABLED);

			AddSeperatorToMenu(hMenu, g_MenuItemList[i][Separator], 1);
		}
	}

	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

stock AddSeperatorToMenu(Handle:hMenu, iSeparator, iPosition)
{
	if (iSeparator == -1 && iPosition == -1)
		AddMenuItem(hMenu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER);
	else if (iSeparator == 1 && iPosition == 1)
		AddMenuItem(hMenu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER);
	else if (iSeparator == 2)
		AddMenuItem(hMenu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER);
}

public MainMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	switch (iAction) {
		case MenuAction_Select: {
			decl String:sKey[TG_MODULE_ID_LENGTH], String:CustomItemName[TG_MODULE_NAME_LENGTH];
			GetMenuItem(hMenu, iKey, sKey, sizeof(sKey), _, CustomItemName, sizeof(CustomItemName));

			if (!IsPlayerAlive(iClient) && !CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)) {
				CPrintToChat(iClient, "%T", "Menu-AliveOnly", iClient);
				return;
			}

			if (Call_OnMenuSelect(TG_MenuItem, sKey, TG_None, iClient) != Plugin_Continue)
				return;

			Call_OnMenuSelected(TG_MenuItem, sKey, TG_None, iClient);

			CoreMenuItemsActions(iClient, sKey);
		}
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
}

CoreMenuItemsActions(iClient, String:sKey[])
{
	if (StrEqual(sKey, "Core_MainMenu")){
		MainMenu(iClient);
	} else if (StrEqual(sKey, "Core_TeamsMenu")){
		TeamsMenu(iClient);
	} else if (StrContains(sKey, "Core_GamesMenu", false) == 0) {
		new iPos = FindCharInString(sKey, '-' );

		if (iPos != -1) {
			GamesMenu(iClient, GetGameTypeByName(sKey[iPos + 1]));
		} else {
			GamesMenu(iClient);
		}
	} else if (StrEqual(sKey, "Core_FencesMenu")) {
		FencesMenu(iClient);
	} else if (StrEqual(sKey, "Core_StopGame")) {
		StopGame(iClient);
	}
}

StopGame(iClient)
{
	new Action:iResult = Plugin_Continue;
	Call_StartForward(Forward_OnPlayerStopGame);
	Call_PushCell(iClient);
	Call_PushString(g_Game[GameID]);
	Call_Finish(iResult);
	if (iResult != Plugin_Continue) {
		return;
	}

	Call_StartForward(Forward_OnPlayerStopGamePost);
	Call_PushCell(iClient);
	Call_PushString(g_Game[GameID]);
	Call_Finish();

	TG_StopGame(TG_NoneTeam);

	TG_LogRoundMessage("StopGame", "Player %L stopped the game (sID: \"%s\") !", iClient, g_Game[GameID]);
	decl String:sClientName[64];
	GetClientName(iClient, sClientName, sizeof(sClientName));
	CPrintToChatAll("%t", "GameStop", sClientName);
}