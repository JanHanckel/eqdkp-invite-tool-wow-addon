-- locals
local MainFrame;
local ScrollingTable = LibStub("ScrollingTable");
local TimerFactory = LibStub("AceTimer-3.0");

local EIT_GUI_RaidsTableSelection = nil;
local EIT_GUI_RaidStatesTableSelection = nil;

local AttendeesTable = {};
local UnitsToInvite = {};

local TimerInfos = {};

-- table definitions
local EIT_RaidsTableColDef = { 
    {["name"] = "#", ["width"] = 30, ["defaultsort"] = "dsc"}, 
    {["name"] = "Datum", ["width"] = 120}
};

local EIT_RaidStatesTableColDef = {     
    {["name"] = "Status", ["width"] = 150}
};

local EIT_GUI_RaidHealersTableColDef = {
	{["name"] = Raids[1]["RaidStates"][1]["Roles"][1]["Name"] or "Healer", ["width"] = 120}
}

local EIT_GUI_RaidTanksTableColDef = {
	{["name"] = Raids[1]["RaidStates"][1]["Roles"][2]["Name"] or "Tank", ["width"] = 120}
}

local EIT_GUI_RaidRangesTableColDef = {
	{["name"] = Raids[1]["RaidStates"][1]["Roles"][3]["Name"] or "Ranges", ["width"] = 120}
}

local EIT_GUI_RaidMeleesTableColDef = {
	{["name"] = Raids[1]["RaidStates"][1]["Roles"][4]["Name"] or "Melees", ["width"] = 120}
}

function EIT_MainFrame_OnLoad(frame)
    frame:RegisterEvent("ADDON_LOADED");    
end;

function EIT_MainFrame_OnEvent(frame, event, ...)
    if (event == "ADDON_LOADED") then
        local addonName = ...;
		if (addonName == "EqdkpInviteTool") then
            
			frame:UnregisterEvent("ADDON_LOADED");		
		
			SLASH_EIT1 = "/eit";		
			SlashCmdList.EIT = ToogleFrame;
	
			PrintText("Welcome back", UnitName("player").."!");
		end;
	end;
end;

function CreateMainFrame()
	MainFrame = CreateFrame("Frame", "EIT_Main", UIParent, "BasicFrameTemplateWithInset");
	MainFrame:SetWidth(870)
	MainFrame:SetHeight(500)
	MainFrame:SetPoint("TOPLEFT", 20, -120)
	MainFrame:SetShown(false);

	MainFrame:SetMovable(true);
	MainFrame:EnableMouse(true);
	MainFrame:RegisterForDrag("LeftButton");
	MainFrame:IsShown(true);
	MainFrame:SetScript("OnDragStart", MainFrame.StartMoving);
	MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing);

	-- TITLE
	MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	MainFrame.title:SetPoint("CENTER", MainFrame.TitleBg, "CENTER", 5, 0);
	MainFrame.title:SetText("Eqdkp Invite Tool");

	-- BUTTON
	--MainFrame.testButton = CreateButton("CENTER", MainFrame, "TOP", 0, -70, "TEST");

	-- TABLES
	-- Raids
	EIT_GUI_RaidsTable = ScrollingTable:CreateST(EIT_RaidsTableColDef, 12, nil, nil, MainFrame);
    EIT_GUI_RaidsTable.frame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 10, -50);
    EIT_GUI_RaidsTable:EnableSelection(true);
	--EIT_GUI_RaidsTable:RegisterEvents({["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
	--		print("click function");
	--		EIT_GUI_RaidHealersTable:setData(nil, false);
	--		return false;
	--	end
	--});

	-- RaidStates
	EIT_GUI_RaidStatesTable = ScrollingTable:CreateST(EIT_RaidStatesTableColDef, 12, nil, nil, MainFrame);
    EIT_GUI_RaidStatesTable.frame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 10, -270);
    EIT_GUI_RaidStatesTable:EnableSelection(true);

	-- RaidAttendees
	-- Healers
	AttendeesTable = {
		[1] = CreateScrollingTable(EIT_GUI_RaidHealersTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 220, -50, false),
		[2] = CreateScrollingTable(EIT_GUI_RaidTanksTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 380, -50, false),
		[3] = CreateScrollingTable(EIT_GUI_RaidRangesTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 540, -50, false),
		[4] = CreateScrollingTable(EIT_GUI_RaidMeleesTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 700, -50, false)
	}

	-- BUTTON
	MainFrame.inviteButton = CreateButton("RIGHT", MainFrame, "RIGHT", -20, -20, "Invite to Raid");
	MainFrame.inviteButton:SetScript("OnClick", 
		function() 
			RaidInvite() 
		end
	);

	return MainFrame;
end

function ToogleFrame ()
	local mainFrame = MainFrame or CreateMainFrame();
	mainFrame:SetShown(not mainFrame:IsShown());

	mainFrame:SetScript("OnUpdate", function() EIT_GUI_OnUpdateHandler(); end);
	EIT_GUI_RaidsTableUpdate();
end

-- # BEGIN GUI HELPERS #
function CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
	local btn = CreateFrame("Button", nil, relativeFrame, "GameMenuButtonTemplate");
	btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
	btn:SetSize(140, 40);
	btn:SetText(text);
	btn:SetNormalFontObject("GameFontNormalLarge");
	btn:SetHighlightFontObject("GameFontHighlightLarge");

	return btn;
end

function CreateScrollingTable(tableDef, point, relativeFrame, relativePoint, xOffset, yOffset, enableSelection)
	local table = ScrollingTable:CreateST(tableDef, 12, nil, nil, relativeFrame);
    table.frame:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
    table:EnableSelection(enableSelection);
	
	table:RegisterEvents({["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)			
			player = data[row][1];
			printText("Inviting ", player);
			InviteUnit(player);
			return false;
		end
	});

	return table;
end

-- # END GUI HELPERS #

function PrintText(...)
    local hex = "00ccff";
    local prefix = string.format("|cff%s%s|r", hex:upper(), "Eqdkp Invite Tool: ");	
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

-- data updates
function EIT_GUI_RaidsTableUpdate()
    if (Raids == nil) then return; end
    local EIT_GUI_RaidsTableData = {};
    
    for i, v in ipairs(Raids) do
        EIT_GUI_RaidsTableData[i] = {i, v["Date"]};
    end
    
    EIT_GUI_RaidsTable:ClearSelection();
    EIT_GUI_RaidsTable:SetData(EIT_GUI_RaidsTableData, true);    
end

function EIT_GUI_RaidStatesTableUpdate(raidnum)		
    if (Raids == nil) then return; end
	
    local EIT_GUI_RaidStatesTableData = {};
    
    for i, v in ipairs(Raids[raidnum]["RaidStates"]) do
        EIT_GUI_RaidStatesTableData[i] = {v["Name"]};
    end
    
    EIT_GUI_RaidStatesTable:ClearSelection();
	EIT_GUI_RaidStatesTableSelection = nil;
    EIT_GUI_RaidStatesTable:SetData(EIT_GUI_RaidStatesTableData, true);    
end

function EIT_GUI_AttendeesUpdate(table, raidnum, statenum, rolenum)
    if (Raids == nil) then return; end
	
    local data = {};

	if(statenum == nil) then		
		table:SetData({}, true);
		return;
	end

    for i, v in ipairs(Raids[raidnum]["RaidStates"][statenum]["Roles"][rolenum]["Players"]) do
        data[i] = {v["Name"]};
    end
    
    table:ClearSelection();
    table:SetData(data, true);    
end

-- event handler functions
function EIT_GUI_OnUpdateHandler()
    local raidnum = EIT_GUI_RaidsTable:GetSelection();
    
    if (raidnum ~= EIT_GUI_RaidsTableSelection) then		
        EIT_GUI_RaidsTableSelection = raidnum;
        if (raidnum) then
            EIT_GUI_RaidStatesTableUpdate(raidnum);
        else
            EIT_GUI_RaidStatesTableUpdate(nil);
        end
    end
    
	local statenum = EIT_GUI_RaidStatesTable:GetSelection();
	
	if (statenum == nil or statenum ~= EIT_GUI_RaidStatesTableSelection) then
        EIT_GUI_RaidStatesTableSelection = statenum;
        if (statenum) then
			for i, v in ipairs(Raids[raidnum]["RaidStates"][statenum]["Roles"]) do
				EIT_GUI_AttendeesUpdate(AttendeesTable[i], raidnum, statenum, i);				
			end
        else
			for i, v in ipairs(AttendeesTable) do
				EIT_GUI_AttendeesUpdate(AttendeesTable[i], raidnum, nil, i);
			end
        end
    end
end


function RaidInvite()
	UnitsToInvite = GetUnitsToInvite();
	
	if (table.getn(UnitsToInvite) <= 0) then return; end

	TimerInfos["playerName"] = UnitName("player")
	TimerInfos["timerCount"] = 0
	TimerInfos["groupMems"] = 0
	TimerInfos["tableSize"] = table.getn(UnitsToInvite)
	TimerInfos["tableIter"] = 1
	TimerInfos["timer"] = TimerFactory:ScheduleRepeatingTimer(InviteTime, .5)
end

function InviteTime()	
	local currentPlayer = UnitsToInvite[TimerInfos["tableIter"]]
	if not (UnitInParty(currentPlayer) or UnitInRaid(currentPlayer)) then
		if currentPlayer ~= UnitName("player") then			
			printText("Inviting ", currentPlayer)
			InviteUnit(currentPlayer)
		end
	end
	if not IsInRaid(player) then
		ConvertToRaid()
	end
	TimerInfos["tableIter"] = TimerInfos["tableIter"] + 1
	if TimerInfos["tableIter"] > TimerInfos["tableSize"]  then
		printText("End of invites.")
		MainFrame:CancelTimer(TimerInfos["timer"])
	end
end

function GetUnitsToInvite()
	local raidnum = EIT_GUI_RaidsTable:GetSelection();    
	local statenum = EIT_GUI_RaidStatesTable:GetSelection();	
	local units = {};
	
	if(raidnum ~= nil and statenum ~= nil) then
		for i, v in ipairs(Raids[raidnum]["RaidStates"][statenum]["Roles"]) do		
			for j, w in ipairs(v["Players"]) do
				table.insert(units, w["Name"]);
			end		
		end
	else
		printText("EIT: No players selected!")
	end
	
	return units;
end