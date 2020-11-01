-- WoW Rambler Project - UI Mod Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local AddonName = ...

local mainFrame = CreateFrame("Frame", nil, UIParent)
mainFrame.events = {}
mainFrame:Hide()

SetCVar("showBattlefieldMinimap", "1")
SetCVar("autoLootDefault", "1")

-- Tutorials... Meh.
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_WORLD_MAP_FRAME, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_CLEAN_UP_BAGS, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_BAG_SETTINGS, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_GARRISON_ZONE_ABILITY, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_GARRISON_LANDING, true)
SetCVarBitfield("closedInfoFrames", SpellBookFrame_GetTutorialEnum(), true)

ZoneTextFrame:SetParent(mainFrame)
SubZoneTextFrame:SetParent(mainFrame)

function mainFrame:SetupEvents()
	self:SetScript("OnEvent", function(self, event, ...)
		self.events[event](self, ...)
	end)

	for k, v in pairs(self.events) do
		self:RegisterEvent(k)
	end
end

function mainFrame:SetupSettings()
	self.questTurnInDelay = 8
	self.questAcceptDelay = 5
	self.defaultChatTabText = " "
	self.chatFontSize = 12
end

function mainFrame:SetupChatFrame()
	for i = 1, NUM_CHAT_WINDOWS do
		-- Get rid of the ugly chat edit box.
		_G["ChatFrame"..i.."EditBoxLeft"]:Hide()
		_G["ChatFrame"..i.."EditBoxMid"]:Hide()
		_G["ChatFrame"..i.."EditBoxRight"]:Hide()

		-- And adjust font a little.
		local chatFrame = _G["ChatFrame"..i.."EditBox"]
		local name, size, style = chatFrame:GetFont()
		chatFrame:SetFont(name, self.chatFontSize, style)
		_G["ChatFrame"..i.."EditBoxHeader"]:SetFont(name, self.chatFontSize, style)

		-- Remove newcomers tip.
		_G["ChatFrame"..i.."EditBoxNewcomerHint"]:SetParent(mainFrame)
	end

	-- Chat needs to be loaded first. This timer gives enough time.
	C_Timer.After(0, function()
		local parent = _G["ChatFrame1"]
		parent:ClearAllPoints()
		parent:SetPoint('BOTTOMLEFT', UIParent, 0, 0)
		parent:SetSize(325, 156)
		local chatFrame = _G["ChatFrame3"];
		local chatTab = _G["ChatFrame3Tab"];

		chatFrame:Show();
		chatTab:Show();
		SetChatWindowShown(3, true);
		FCF_DockFrame(chatFrame, (#FCFDock_GetChatFrames(GENERAL_CHAT_DOCK)), true);
		FCF_SetWindowName(chatFrame, self.defaultChatTabText);

		if ChatFrame3Tab:IsVisible() then
			FCF_Tab_OnClick(ChatFrame3Tab)
		end
	end)
end

function mainFrame:SetupMinimap()
	for _, b in ipairs({Minimap:GetChildren()}) do
		if b ~= MinimapBackdrop then
			pcall(b.Hide, b)
		end
	end

	for _, b in ipairs({MinimapBackdrop:GetChildren()}) do
		pcall(b.Hide, b)
	end

	MiniMapMailFrame:SetParent(mainFrame)
	MinimapBorderTop:SetParent(mainFrame)
	MinimapZoneTextButton:SetParent(mainFrame)
end

function mainFrame:SetupBattlefieldMap()
	if not BattlefieldMapFrame then
		return
	end

	BattlefieldMapFrame.BorderFrame.CloseButton:Hide()
	BattlefieldMapFrame.BorderFrame.CloseButtonBorder:Hide()
	BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("player", 18)

	-- This is ugly. I just don't get how this frame works.
	local newHeight = 154
	local newWidth = 231 --newHeight * BattlefieldMapFrame:GetWidth() / BattlefieldMapFrame:GetHeight()

	BattlefieldMapFrame:SetSize(newWidth, newHeight);
	BattlefieldMapFrame:OnFrameSizeChanged()

	BattlefieldMapTab:SetPoint("BOTTOMRIGHT", -106, 160)

	BattlefieldMapOptions.opacity = 0
	BattlefieldMapOptions.locked = false
	BattlefieldMapFrame:RefreshAlpha()
	BattlefieldMapFrame:SetMovable(true)
	BattlefieldMapFrame:StartMoving()
	BattlefieldMapFrame:StopMovingOrSizing()

	BattlefieldMapFrame:OnEvent("ADDON_LOADED")

	-- There is a bug that leaves 1px on top and 1px on one of the sides that is transparent.
	-- Let's cover it.
	if not BattlefieldMapFrame.backgroundFix then
		BattlefieldMapFrame.backgroundFix = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		BattlefieldMapFrame.backgroundFix:SetFrameStrata("BACKGROUND")
		BattlefieldMapFrame.backgroundFix:SetBackdrop({
			bgFile = nil,
			edgeFile = "Interface/BUTTONS/WHITE8X8",
			edgeSize = 4,
			insets = { left = 1, right = 1, top = 1, bottom = 1 },
		})

		BattlefieldMapFrame.backgroundFix:SetPoint("BOTTOMRIGHT", 0, 0)
		BattlefieldMapFrame.backgroundFix:SetSize(newWidth + 3, newHeight + 4)
		BattlefieldMapFrame.backgroundFix:SetBackdropBorderColor(0, 0, 0, 1)
	end

	-- Move the tooltip a little to the top so it won't collide with the battlefield map.
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
		tooltip:SetOwner(parent, "ANCHOR_NONE");
		tooltip:SetPoint("BOTTOMRIGHT", TooltipAnchor, "BOTTOMRIGHT", 0, 175)
	end)
end

function mainFrame:OnQuest()
	if not QuestNpcNameFrame then
		return
	end

	local questIdText = QuestNpcNameFrame.questIdText

	if not questIdText then
		local name, size, style = QuestFrameNpcNameText:GetFont()

		QuestNpcNameFrame.questIdText = QuestNpcNameFrame:CreateFontString()
		questIdText = QuestNpcNameFrame.questIdText

		questIdText:SetFont(name, size, style)
		questIdText:SetPoint("TOP", 0, -size * 2.5)
		questIdText:SetTextColor(1, 1,1, .4)
	end

	local questId = GetQuestID()

	if questId ~= nil and questId ~= 0 then
		questIdText:SetFormattedText("Questa è la missione numero %d", questId)
	else
		questIdText:SetText("")
	end
end

local onHideAddress = WorldMapFrame:GetScript("OnHide")
local lockedWorldMap = false
WorldMapFrame:SetScript("OnHide", function(self)
	if lockedWorldMap then
		WorldMapFrame:OnEvent("WORLD_MAP_OPEN")
	end

	onHideAddress(WorldMapFrame)
end)

local function ShowMap(seconds)
	lockedWorldMap = true
	WorldMapFrame:OnEvent("WORLD_MAP_OPEN")

	C_Timer.After(seconds, function()
		lockedWorldMap = false
		WorldMapFrame:OnEvent("WORLD_MAP_CLOSE")
	end)
end

local function Dummy() end

local function BlockQuestFrames(seconds)
	GossipFrame:Hide()
	QuestFrame:Hide()

	local gossipHook = GossipFrame.Show
	GossipFrame.Show = Dummy

	local npcHook = QuestFrame.Show
	QuestFrame.Show = Dummy

	GossipFrame:Hide()
	QuestFrame:Hide()

	C_Timer.After(seconds, function()
		GossipFrame.Show = gossipHook
		QuestFrame.Show = npcHook
	end)
end

QuestFrameAcceptButton:HookScript("OnClick", function() BlockQuestFrames(mainFrame.questAcceptDelay) end)
QuestFrameCompleteQuestButton:HookScript("OnClick", function() BlockQuestFrames(mainFrame.questTurnInDelay) end)

function mainFrame.events:PLAYER_ENTERING_WORLD(...)
	self:SetupMinimap()
	self:SetupChatFrame()
	self:SetupBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED(...)
	-- Blizzard's UI has a problem with updating the battlefield map
	-- in places like Zuldazar - The Great Seal. Going outside does
	-- not change the map. Let's force it to do so.
	BattlefieldMapFrame:OnEvent("ZONE_CHANGED_NEW_AREA")
	self:SetupBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED_NEW_AREA(...)
	self:SetupBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED_INDOORS(...)
	BattlefieldMapFrame:OnEvent("ZONE_CHANGED_NEW_AREA")
	self:SetupBattlefieldMap()
end

function mainFrame.events:QUEST_ACCEPTED(questId)
	-- A naive "workaround" for starting auto-quest-accept zones.
	if IsShiftKeyDown() then
		return
	end

	if C_QuestLog.IsWorldQuest(questId) then
		return
	end

	if C_QuestLog.IsQuestTask(questId) then
		return
	end

	ShowMap(self.questAcceptDelay)
	ChatFrame3TabText:SetText(questId)
end

function mainFrame.events:QUEST_TURNED_IN(questId)
	ShowMap(self.questTurnInDelay)
	ChatFrame3TabText:SetText(self.defaultChatTabText)
end

function mainFrame.events:QUEST_REMOVED(questId)
	ChatFrame3TabText:SetText(self.defaultChatTabText)
end

function mainFrame.events:QUEST_DETAIL(...)
	self:OnQuest()
end

function mainFrame.events:QUEST_PROGRESS(...)
	self:OnQuest()
end

function mainFrame.events:QUEST_FINISHED(...)
	self:OnQuest()
end

function mainFrame.events:QUEST_COMPLETE(...)
	self:OnQuest()
end

function mainFrame.events:QUEST_GREETING(...)
	self:OnQuest()
end

function mainFrame.events:QUEST_ACCEPT_CONFIRM(...)
	self:OnQuest()
end

mainFrame:SetupSettings()
mainFrame:SetupEvents()
