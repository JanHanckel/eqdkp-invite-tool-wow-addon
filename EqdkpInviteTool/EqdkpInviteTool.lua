-- EqdkpInviteTool = LibStub("AceAddon-3.0"):NewAddon("EqdkpInviteTool", "AceConsole-3.0", "AceEvent-3.0" );

-- locals
local MainFrame;
local ScrollingTable = LibStub("ScrollingTable");

local EIT_GUI_RaidsTableSelection = nil;
local EIT_GUI_RaidStatesTableSelection = nil;

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

			-- allows using left and right buttons to move through chat 'edit' box
			for i = 1, NUM_CHAT_WINDOWS do
				_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
			end;
	
			----------------------------------
			-- Register Slash Commands!
			----------------------------------

			SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
			SlashCmdList.FRAMESTK = function()
				LoadAddOn("Blizzard_DebugTools");
				FrameStackTooltip_Toggle();
			end;			
		
			SLASH_EIT1 = "/eit";		
			SlashCmdList.EIT = ToogleFrame;
	
			PrintText("Welcome back", UnitName("player").."!");
		end;
	end;
end;

function CreateMainFrame()
	MainFrame = CreateFrame("Frame", "EIT_Main", UIParent, "BasicFrameTemplateWithInset");
	MainFrame:SetWidth(1000)
	MainFrame:SetHeight(700)
	MainFrame:SetPoint("TOPLEFT", 20, -120)
	MainFrame:SetShown(false);

	MainFrame:SetMovable(true);
	MainFrame:EnableMouse(true);
	MainFrame:RegisterForDrag("LeftButton");
	MainFrame:IsShown(true);
	MainFrame:SetScript("OnDragStart", MainFrame.StartMoving);
	MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing);

	-- TITLE
	--MainFrame.title:ClearAllPoints();
	MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	--MainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE");
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
	EIT_GUI_RaidHealersTable = CreateScrollingTable(EIT_GUI_RaidHealersTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 200, -50, false);
	EIT_GUI_RaidTanksTable = CreateScrollingTable(EIT_GUI_RaidTanksTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 400, -50, false);	
	EIT_GUI_RaidRangesTable = CreateScrollingTable(EIT_GUI_RaidRangesTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 600, -50, false);
	EIT_GUI_RaidMeleesTable = CreateScrollingTable(EIT_GUI_RaidMeleesTableColDef, "TOPLEFT", MainFrame, "TOPLEFT", 800, -50, false);

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

function EIT_GUI_RaidHealersTableUpdate(raidnum, statenum)
    if (Raids == nil) then return; end
	
    local EIT_GUI_RaidHealersTableData = {};
	print("Attendees!!");

	if(statenum == nil) then
		print("No State!!");
		EIT_GUI_RaidHealersTable:SetData({}, true);
		return;
	end

    for i, v in ipairs(Raids[raidnum]["RaidStates"][statenum]["Roles"][1]["Players"]) do
        EIT_GUI_RaidHealersTableData[i] = {v["Name"]};
    end
    
    EIT_GUI_RaidHealersTable:ClearSelection();
    EIT_GUI_RaidHealersTable:SetData(EIT_GUI_RaidHealersTableData, true);    
end

-- event handler functions
function EIT_GUI_OnUpdateHandler()
    local raidnum = EIT_GUI_RaidsTable:GetSelection();
    
    if (raidnum ~= EIT_GUI_RaidsTableSelection) then
		print("Selected Raid: "..raidnum);
        EIT_GUI_RaidsTableSelection = raidnum;
        if (raidnum) then
            EIT_GUI_RaidStatesTableUpdate(raidnum);
        else
            EIT_GUI_RaidStatesTableUpdate(nil);
        end
    end
    
	local statenum = EIT_GUI_RaidStatesTable:GetSelection();
	if (statenum and statenum ~= EIT_GUI_RaidStatesTableSelection) then
		print("Selected State: "..statenum);	
	end
		
	
	if (statenum == nil or statenum ~= EIT_GUI_RaidStatesTableSelection) then
        EIT_GUI_RaidStatesTableSelection = statenum;
        if (statenum) then
            EIT_GUI_RaidHealersTableUpdate(raidnum, statenum);
        else
            EIT_GUI_RaidHealersTableUpdate(raidnum, nil);
        end
    end
end