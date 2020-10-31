-- WoW Rambler Project - Addon
--
-- mailto: wow.rambler.project@gmail.com
--

SetCVar("showBattlefieldMinimap", "1")

-- Tutorials... Meh.
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_WORLD_MAP_FRAME, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_CLEAN_UP_BAGS, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_BAG_SETTINGS, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_GARRISON_ZONE_ABILITY, true)
SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_GARRISON_LANDING, true)
SetCVarBitfield("closedInfoFrames", SpellBookFrame_GetTutorialEnum(), true)

local hideFrame = CreateFrame("Frame")
hideFrame:Hide()

local mainFrame = CreateFrame("Frame", nil, UIParent)
mainFrame.events = {}

function mainFrame:SetupEvents()
	self:SetScript("OnEvent", function(self, event, ...)
		self.events[event](self, ...)
	end)

	for k, v in pairs(self.events) do
		self:RegisterEvent(k)
	end

	self.timeDelta = 0
	self:SetScript("OnUpdate", self.OnUpdate)
end

function mainFrame:SetupSettings()
	WoWRamblerProjectQuestLog = WoWRamblerProjectQuestLog or {}
	WoWRamblerProjectQuestMap = WoWRamblerProjectQuestMap or {}
	WoWRamblerProjectQuestsDone = WoWRamblerProjectQuestsDone or {}

	self.version, self.build = GetBuildInfo()
	self.questTurnInDelay = 8
	self.questAcceptDelay = 5
	self.defaultChatTabText = " "
	self.chatFontSize = 12
end

function mainFrame:SetupCoordinatesFrame()
	self.positionX = nil
	self.positionY = nil

	local function SetupFont(font, fontObject, xOffset)
		font:SetFontObject(fontObject)
		font:SetPoint("TOPLEFT", xOffset, 0)
		font:SetJustifyH("LEFT")
	end

	self:SetPoint("TOPRIGHT", -10, -3)

	local fontObject = ObjectiveTrackerBlocksFrame.QuestHeader.Text:GetFontObject()

	self.positionXText = self:CreateFontString(nil, "OVERLAY")
	self.positionYText = self:CreateFontString(nil, "OVERLAY")
	self.zoneText = self:CreateFontString(nil, "OVERLAY")

	SetupFont(self.positionXText, fontObject, 0)

	-- Measure max width of a single coordinate.
	self.positionXText:SetText("100.0")
	self.maxPositionWidth = self.positionXText:GetStringWidth()
	self.positionXText:SetText("")

	SetupFont(self.positionYText, fontObject, self.maxPositionWidth)
	SetupFont(self.zoneText, fontObject, self.maxPositionWidth * 2)

	self:SetHeight(self.positionXText:GetLineHeight())

	self.mapCoordinatesCache = {}
	self.playerMapPosition = CreateVector2D(0,0)
	self.zeroVector = CreateVector2D(0, 0)
	self.oneVector = CreateVector2D(1, 1)

	-- Hide default frames.
	ZoneTextFrame:SetParent(hideFrame)
	SubZoneTextFrame:SetParent(hideFrame)
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
		_G["ChatFrame"..i.."EditBoxNewcomerHint"]:SetParent(hideFrame)
	end

	-- Chat needs to be loaded first. This timer gives enough time.
	C_Timer.After(0, function()
		local parent = _G["ChatFrame1"]
		parent:ClearAllPoints()
		parent:SetPoint('BOTTOMLEFT', UIParent, 0, 0)
		parent:SetSize(320, 156)
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

function mainFrame:UpdateZoneInfo()
	local zone = GetRealZoneText()
	local subZone = GetSubZoneText()

	if (subZone == "") then
		self.zoneText:SetText(zone)
	else
		self.zoneText:SetFormattedText("%s - %s", zone, subZone)
	end
end

function mainFrame:GetPlayerMapPosition(mapId)
	local worldPosition = self.mapCoordinatesCache[mapId]

	if not worldPosition then
		worldPosition = {}
		local _
		_, worldPosition[1] = C_Map.GetWorldPosFromMapPos(mapId, self.zeroVector)
		_, worldPosition[2] = C_Map.GetWorldPosFromMapPos(mapId, self.oneVector)

		-- Exile's Reach - North Sea: returns nil
		if (not worldPosition[1]) or (not worldPosition[2]) then
			return 0, 0
		end

		worldPosition[2]:Subtract(worldPosition[1])
		self.mapCoordinatesCache[mapId] = worldPosition
	end

	self.playerMapPosition.x, self.playerMapPosition.y = UnitPosition('Player')
	self.playerMapPosition:Subtract(worldPosition[1])

	return (1 / worldPosition[2].y) * self.playerMapPosition.y, (1 / worldPosition[2].x) * self.playerMapPosition.x
end

function mainFrame:GetPlayerZonePosition()
	local mapID = C_Map.GetBestMapForUnit("player")

	if mapID then
		local x, y = self:GetPlayerMapPosition(mapID)
		
		-- This approach uses more memory.
		-- local mapPosObject = C_Map.GetPlayerMapPosition(mapID, "player")
		-- if mapPosObject then 
		-- 	x, y = mapPosObject:GetXY()
		-- end

		-- x = x or 0
		-- y = y or 0

		return math.floor(x * 1000), math.floor(y * 1000)
	end

	return 0, 0
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

	MiniMapMailFrame:SetParent(hideFrame)
	MinimapBorderTop:SetParent(hideFrame)
	MinimapZoneTextButton:SetParent(hideFrame)
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

function mainFrame:OnUpdate(timeDelta)
	self.timeDelta = self.timeDelta + timeDelta

	if self.timeDelta < (1 / 60) then
		return
	end
	
	self.timeDelta = 0

	if self.isInInstace then
		return
	end

	local x, y = self:GetPlayerZonePosition()

	if x ~= self.positionX then
		if x ~= 0 then
			self.positionXText:SetFormattedText("%.1f", x / 10)
		else
			self.positionXText:SetText("")
		end
		
		self.positionX = x
	end

	if y ~= self.positionY then
		if y ~= 0 then
			self.positionYText:SetFormattedText("%.1f", y / 10)
		else
			self.positionYText:SetText("")
		end

		self.positionY = y
	end
end

function mainFrame:OnZoneChange()
	self:UpdateZoneInfo()
	self:SetWidth(self.maxPositionWidth * 2 + self.zoneText:GetStringWidth())
	self:SetupBattlefieldMap()
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

local function ArrayDifference(minuend, subtrahend)
	local tempArray = {}

	for k, v in pairs(minuend) do
		tempArray[v] = true
	end

	for k, v in pairs(subtrahend) do
		tempArray[v] = nil
	end

	local difference = {}
	local n = 0

	for k, v in pairs(minuend) do
		if tempArray[v] then
			n = n + 1
			difference[n] = v
		end
	end

	return difference
end

function mainFrame:RegisterTurnedInQuest(questId)
	local serverQuests = C_QuestLog.GetAllCompletedQuestIDs()
	local diff = ArrayDifference(serverQuests, WoWRamblerProjectQuestsDone)

	if next(diff) ~= nil then
		WoWRamblerProjectQuestMap[questId] = {}
		for k, v in pairs(diff) do
			table.insert(WoWRamblerProjectQuestMap[questId], v)
		end
	end

	WoWRamblerProjectQuestsDone = serverQuests
	table.insert(WoWRamblerProjectQuestsDone, questId)
	WoWRamblerProjectQuestLog[questId] = WoWRamblerProjectQuestLog[questId] or {}
	local entry = WoWRamblerProjectQuestLog[questId]

	table.insert(entry, GetServerTime())
	table.insert(entry, string.format("%s @ %s (%s)", date(), self.version, self.build))
	table.insert(entry, C_QuestLog.GetTitleForQuestID(questId))
end

function mainFrame.events:PLAYER_ENTERING_WORLD(...)
	self.isInInstace = IsInInstance()
	self:OnZoneChange()
	self:SetupMinimap()
	self:SetupBattlefieldMap()

	if self.isInInstace then
		self.positionXText:SetText("")
		self.positionYText:SetText("")
	end
end

function mainFrame.events:ZONE_CHANGED(...)
	-- Blizzard's UI has a problem with updating the battlefield map
	-- in places like Zuldazar - The Great Seal. Going outside does
	-- not change the map. Let's force it to do so.
	BattlefieldMapFrame:OnEvent("ZONE_CHANGED_NEW_AREA")
	self:OnZoneChange()
end

function mainFrame.events:ZONE_CHANGED_NEW_AREA(...)
	self:OnZoneChange()
end

function mainFrame.events:ZONE_CHANGED_INDOORS(...)
	BattlefieldMapFrame:OnEvent("ZONE_CHANGED_NEW_AREA")
	self:OnZoneChange()
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
	self:RegisterTurnedInQuest(questId)
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
mainFrame:SetupCoordinatesFrame()
mainFrame:SetupChatFrame()
mainFrame:SetupEvents()
