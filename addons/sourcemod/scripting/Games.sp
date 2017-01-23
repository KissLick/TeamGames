new String:g_sGamePrepare[6][PLATFORM_MAX_PATH];
new String:g_sGameEnd[3][PLATFORM_MAX_PATH];
new String:g_sGameStart[PLATFORM_MAX_PATH];

GamesMenu(iClient, TG_GameType:iTypeSpecific = TG_None)
{
	if (iTypeSpecific != TG_None && IsGameTypeAvailable(iTypeSpecific) && GetCountAllGames() > 0) {
		new Handle:hMenu = CreateMenu(GamesMenu_Handler);
		new String:sName[TG_MODULE_NAME_LENGTH];

		if (iTypeSpecific == TG_TeamGame) {
			SetMenuTitle(hMenu, "%T", "Menu-Games-TeamGame", iClient);
		} else if (iTypeSpecific == TG_RedOnly) {
			SetMenuTitle(hMenu, "%T", "Menu-Games-RedOnly", iClient);
		}

		PushMenuCell(hMenu, "__Core_GameType__", _:iTypeSpecific);

		for (new i = 0; i < g_iGameListEnd; i++) {
			if (!g_GameList[i][Used] || !g_GameList[i][Visible])
				continue;

			if (!(g_GameList[i][TGType] & iTypeSpecific))
				continue;

			if (!TG_CheckModuleAccess(iClient, TG_Game, g_GameList[i][Id]))
				continue;

			new TG_MenuItemStatus:iStatus = Call_AskModuleName(g_GameList[i][Id], TG_Game, iClient, sName, sizeof(sName), TG_Active, g_GameList[i][DefaultName]);

			if (iStatus == TG_Disabled)
				continue;

			AddSeperatorToMenu(hMenu, g_GameList[i][Separator], -1);

			if (iStatus == TG_Active) {
				AddMenuItem(hMenu, g_GameList[i][Id], sName);
			} else {
				AddMenuItem(hMenu, g_GameList[i][Id], sName, ITEMDRAW_DISABLED);
			}

			AddSeperatorToMenu(hMenu, g_GameList[i][Separator], 1);
		}

		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, iClient, 30);
	}
}

public GamesMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		new String:sKey[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));

		new TG_GameType:iGameType = TG_GameType:GetMenuCell(hMenu, "__Core_GameType__");

		#if defined DEBUG
		LogMessage("[TG DEBUG] Player %L selected game (id = '%s').", iClient, sKey);
		#endif

		if (Call_OnMenuSelect(TG_Game, sKey, iGameType, iClient) != Plugin_Continue)
			return;

		Call_OnMenuSelected(TG_Game, sKey, iGameType, iClient);
	} else if (iAction == MenuAction_Cancel && iKey == MenuCancel_ExitBack) {
		MainMenu(iClient);
	}
}

TG_GameType:GetGameTypeByName(String:sTypeStr[])
{
	if (StrEqual(sTypeStr, "TeamGame", false))
		return TG_TeamGame;
	else if (StrEqual(sTypeStr, "RedOnly", false))
		return TG_RedOnly;
	else
		return TG_None;
}

public TG_OnTeamEmpty(const String:sID[], TG_GameType:iGameType, iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (g_Game[GameProgress] != TG_NoGame && g_Game[EndOnTeamEmpty]) {
		if (g_Game[TGType] == TG_TeamGame) {
			TG_StopGame(TG_GetOppositeTeam(iTeam));
		} else if (g_Game[TGType] == TG_RedOnly && iTeam == TG_RedTeam) {
			TG_StopGame(TG_RedTeam);
		}
	}
}

public TG_OnPlayerLeaveGame(const String:sID[], TG_GameType:iGameType, iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (g_Game[RemoveDrops]) {
		SDKUnhook(iClient, SDKHook_WeaponDrop, Hook_WeaponDrop);
	}

	if (g_Game[TGType] == TG_RedOnly && g_Game[EndOnTeamEmpty] && iTeam == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:hWinner = CreateArray();
		for (new i = 0; i < MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(hWinner, i);
				break;
			}
		}

		TG_StopGame(TG_RedTeam, hWinner);
	}
}
