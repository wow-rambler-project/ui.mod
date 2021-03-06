-- WoW Rambler Project - UI Mod Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local AddonName = ...

local mainFrame = CreateFrame("Frame", nil, UIParent)
mainFrame.events = {}
mainFrame.questTurnInDelay = 8
mainFrame.questAcceptDelay = 5
mainFrame.defaultChatTabText = " "

-- Tutorials... Meh.
for i = 1, NUM_LE_FRAME_TUTORIALS do
	C_CVar.SetCVarBitfield("closedInfoFrames", i, true)
end

for i = 1, NUM_LE_FRAME_TUTORIAL_ACCCOUNTS do
	C_CVar.SetCVarBitfield("closedInfoFramesAccountWide", i, true)
end

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
	GarrisonLandingPageMinimapButton:SetParent(mainFrame)
end

function mainFrame:UpdateBattlefieldMap()
	BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("player", 18)

	BattlefieldMapTab:ClearAllPoints();
	--BattlefieldMapTab:SetPoint("BOTTOMRIGHT", -106, 160)
--	BattlefieldMapTab:SetPoint("BOTTOMRIGHT", -147, 160)
	BattlefieldMapTab:SetPoint("BOTTOMRIGHT", -149, 160)
	BattlefieldMapTab:SetUserPlaced(true);

	local newHeight = 154
	local newWidth = newHeight * BattlefieldMapFrame:GetWidth() / BattlefieldMapFrame:GetHeight() -- 231

	BattlefieldMapOptions.opacity = 0
	BattlefieldMapFrame:SetSize(newWidth, newHeight);
	BattlefieldMapFrame:RefreshAlpha();
	BattlefieldMapFrame:UpdateUnitsVisibility();

	BattlefieldMapFrame.BorderFrame.CloseButton:Hide()
	BattlefieldMapFrame.BorderFrame.CloseButtonBorder:Hide()
end

function mainFrame:SetupBattlefieldMap()
	if not BattlefieldMapFrame then
		return
	end

	self:UpdateBattlefieldMap()

	-- There is a bug that leaves 1px on top and 1px on one of the sides that is transparent.
	-- Let's cover it.
	if not BattlefieldMapFrame.backgroundFix then
		BattlefieldMapFrame.backgroundFix = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		BattlefieldMapFrame.backgroundFix:SetFrameStrata("BACKGROUND")
		BattlefieldMapFrame.backgroundFix:SetBackdrop({
			bgFile = nil,
			edgeFile = "Interface/BUTTONS/WHITE8X8",
			edgeSize = 5,
			insets = { left = 1, right = 1, top = 1, bottom = 1 },
		})

		BattlefieldMapFrame.backgroundFix:SetPoint("BOTTOMRIGHT", 0, 0)
		-- BattlefieldMapFrame.backgroundFix:SetSize(BattlefieldMapFrame:GetWidth() + 3, BattlefieldMapFrame:GetHeight() + 4)
		BattlefieldMapFrame.backgroundFix:SetSize(BattlefieldMapFrame:GetWidth() + 4, BattlefieldMapFrame:GetHeight() + 5)
		BattlefieldMapFrame.backgroundFix:SetBackdropBorderColor(0, 0, 0, 1)
	end

	-- Move the tooltip a little to the top so it won't collide with the battlefield map.
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
		tooltip:SetOwner(parent, "ANCHOR_NONE")
		tooltip:SetPoint("BOTTOMRIGHT", TooltipAnchor, "BOTTOMRIGHT", 0, 175)
	end)
end

function mainFrame:OnQuest()
	if not QuestFrame:IsVisible() then
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
		-- questIdText:SetFormattedText("Questa è la missione numero %d", questId)
		questIdText:SetFormattedText("This is quest number %d", questId)
	else
		questIdText:SetText("")
	end
end

local lockedWorldMap = false

WorldMapFrame:HookScript("OnHide", function()
	if lockedWorldMap then
		OpenWorldMap()
	end
end)

local WorldMapSetPointHook = WorldMapFrame.SetPoint

WorldMapFrame.SetPoint = function(this, point, relativeFrame, relativePoint, ofsx, ofsy)
	WorldMapSetPointHook(this, "TOPLEFT", UIParent, "TOPLEFT", 16, -46)
end

local QuestFrameSetPointHook = QuestFrame.SetPoint

QuestFrame.SetPoint = function(this, point, relativeFrame, relativePoint, ofsx, ofsy)
	QuestFrameSetPointHook(this, "TOPLEFT", UIParent, "TOPLEFT", 16, -84)
end

local GossipFrameSetPointHook = GossipFrame.SetPoint

GossipFrame.SetPoint = function(this, point, relativeFrame, relativePoint, ofsx, ofsy)
	GossipFrameSetPointHook(this, "TOPLEFT", UIParent, "TOPLEFT", 16, -84)
end

local function ShowMap(seconds)
	lockedWorldMap = true

	OpenWorldMap()

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

QuestFrameAcceptButton:HookScript("OnClick", function()
	BlockQuestFrames(mainFrame.questAcceptDelay)
end)

QuestFrameAcceptButton:HookScript("OnShow", function()
	QuestFrameAcceptButton:Disable()

	C_Timer.After(5, function()
		QuestFrameAcceptButton:Enable()
	end)
end)

QuestFrameCompleteQuestButton:HookScript("OnClick", function()
	BlockQuestFrames(mainFrame.questTurnInDelay)
end)

QuestFrameCompleteQuestButton:HookScript("OnShow", function()
	QuestFrameCompleteQuestButton:Disable()

	C_Timer.After(5, function()
		QuestFrameCompleteQuestButton:Enable()
	end)
end)

QuestFrameCompleteButton:HookScript("OnShow", function()
	local enableHook = QuestFrameCompleteButton.Enable

	QuestFrameCompleteButton.Enable = Dummy
	
	QuestFrameCompleteButton:Disable()

	C_Timer.After(5, function()
		QuestFrameCompleteButton.Enable = enableHook
		QuestFrameCompleteButton:Enable()
	end)
end)

function mainFrame.events:PLAYER_ENTERING_WORLD(...)
	SetCVar("showBattlefieldMinimap", "1")
	SetCVar("autoLootDefault", "1")
	-- SetCVar("cameraYawMoveSpeed", "30")
	-- SetCVar("cameraPitchMovespeed", "17")
	SetCVar("cameraYawMoveSpeed", "23")
	SetCVar("cameraPitchMovespeed", "13")

	self:Hide()
	self:SetupMinimap()
	self:SetupBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED(...)
	-- Blizzard's UI has a problem with updating the battlefield map
	-- in places like Zuldazar - The Great Seal. Going outside does
	-- not change the map. Let's force it to do so.
	BattlefieldMapFrame:OnEvent("ZONE_CHANGED_NEW_AREA")
	self:UpdateBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED_NEW_AREA(...)
	self:UpdateBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED_INDOORS(...)
	BattlefieldMapFrame:OnEvent("ZONE_CHANGED_NEW_AREA")
	self:UpdateBattlefieldMap()
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

function mainFrame.events:UPDATE_FLOATING_CHAT_WINDOWS(...)
	local parent = _G["ChatFrame1"]
	parent:ClearAllPoints()
	parent:SetPoint('BOTTOMLEFT', UIParent, 5, 6)
	-- parent:SetSize(329, 156)
	parent:SetSize(375, 151)
end

function mainFrame.events:UPDATE_CHAT_WINDOWS(...)
	for i = 1, NUM_CHAT_WINDOWS do
		-- Get rid of the ugly chat edit box.
		_G["ChatFrame"..i.."EditBoxLeft"]:Hide()
		_G["ChatFrame"..i.."EditBoxMid"]:Hide()
		_G["ChatFrame"..i.."EditBoxRight"]:Hide()

		-- And adjust font a little.
		-- local name, size, style = _G["ChatFrame"..i]:GetFont()
		-- _G["ChatFrame"..i]:SetFont(name, self.chatFontSize, style)

		-- Remove newcomers tip.
		_G["ChatFrame"..i.."EditBoxNewcomerHint"]:SetParent(mainFrame)
	end

	FCF_DockFrame(ChatFrame3, (#FCFDock_GetChatFrames(GENERAL_CHAT_DOCK)), true);
	FCF_SetWindowName(ChatFrame3, self.defaultChatTabText);

	if ChatFrame3Tab:IsVisible() then
		FCF_Tab_OnClick(ChatFrame3Tab)
	end

	local parent = _G["ChatFrame1"]
	parent:ClearAllPoints()
	parent:SetPoint('BOTTOMLEFT', UIParent, 5, 6)
	-- parent:SetSize(329, 156)
	parent:SetSize(375, 151)
end

mainFrame:SetupEvents()
