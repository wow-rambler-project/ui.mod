-- WoW Rambler Project - Addon
--
-- mailto: wow.rambler.project@gmail.com
--

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

function mainFrame:SetupFont(font, fontObject, xOffset)
	font:SetFontObject(fontObject)
	font:SetPoint("TOPLEFT", xOffset, 0)
	font:SetJustifyH("LEFT")
end

function mainFrame:Setup()
	self:SetParent(MinimapCluster)
	self:SetPoint("TOPRIGHT", -10, -3)

	local fontObject = ObjectiveTrackerBlocksFrame.QuestHeader.Text:GetFontObject()

	self.positionXText = self:CreateFontString(nil, "OVERLAY")
	self.positionYText = self:CreateFontString(nil, "OVERLAY")
	self.zoneText = self:CreateFontString(nil, "OVERLAY")

	self:SetupFont(self.positionXText, fontObject, 0)

	-- Measure max width of a single coordinate.
	self.positionXText:SetText("100.0")
	self.maxPositionWidth = self.positionXText:GetStringWidth()

	self:SetupFont(self.positionYText, fontObject, self.maxPositionWidth)
	self:SetupFont(self.zoneText, fontObject, self.maxPositionWidth * 2)

	self:SetHeight(self.positionXText:GetLineHeight())

	self.mapCoordinatesCache = {}
	self.playerMapPosition = CreateVector2D(0,0)
	self.zeroVector = CreateVector2D(0, 0)
	self.oneVector = CreateVector2D(1, 1)

	-- Get rid of the ugly chat edit box.
	ChatFrame1EditBoxLeft:Hide()
	ChatFrame1EditBoxMid:Hide()
	ChatFrame1EditBoxRight:Hide()

	self:SetupEvents()
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
		-- This approach uses more memory.
		-- local mapPosObject = C_Map.GetPlayerMapPosition(mapID, "player")
		-- if mapPosObject then 
		--	return mapPosObject:GetXY()
		-- end 

		return self:GetPlayerMapPosition(mapID)
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

	MiniMapMailFrame:SetParent(hideFrame)
	MinimapBorderTop:SetParent(hideFrame)
	MinimapZoneTextButton:SetParent(hideFrame)
	ZoneTextFrame:SetParent(hideFrame)
	SubZoneTextFrame:SetParent(hideFrame)
end

function mainFrame:SetupBattlefieldMap()
	if not BattlefieldMapFrame then
		return
	end

	BattlefieldMapFrame:SetResizable(true)
	BattlefieldMapFrame.BorderFrame.CloseButton:Hide()
	BattlefieldMapFrame.BorderFrame.CloseButtonBorder:Hide()
	BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("player", 18)

	local newHeight = 154
	local newWidth = newHeight * BattlefieldMapFrame:GetWidth() / BattlefieldMapFrame:GetHeight()

	BattlefieldMapFrame:SetSize(newWidth, newHeight);
	BattlefieldMapFrame:OnFrameSizeChanged()

	local backgroundFix = CreateFrame("Frame", nil, UIParent)
	backgroundFix:SetPoint("BOTTOMRIGHT", 0, 0)
	backgroundFix:SetSize(newWidth + 3, newHeight + 4)
	
	local background = backgroundFix:CreateTexture()
	background:SetTexture("Interface/BUTTONS/WHITE8X8")
	background:SetColorTexture(0, 0, 0, 1)
	background:SetAllPoints(backgroundFix)
end

function mainFrame:OnUpdate(timeDelta)
	self.timeDelta = self.timeDelta + timeDelta

	if self.timeDelta < 0.1 then 
		return
	end 

	local x, y = self:GetPlayerZonePosition()
	x = x or 0
	y = y or 0

	self.positionXText:SetFormattedText("%.1f", x * 100)
	self.positionYText:SetFormattedText("%.1f", y * 100)

	self.timeDelta = 0
end

function mainFrame:OnZoneChange()
	self:UpdateZoneInfo()
	self:SetWidth(self.maxPositionWidth * 2 + self.zoneText:GetStringWidth())
end

local function OnQuest()
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

	questIdText:SetFormattedText("Questa è la missione numero %d", GetQuestID())
end

function mainFrame.events:PLAYER_ENTERING_WORLD(...)
	self:OnZoneChange()
	self:SetupMinimap()
	self:SetupBattlefieldMap()
end

function mainFrame.events:ZONE_CHANGED(...)
	self:OnZoneChange()
end

function mainFrame.events:ZONE_CHANGED_NEW_AREA(...)
	self:OnZoneChange()
end

function mainFrame.events:ZONE_CHANGED_INDOORS(...)
	self:OnZoneChange()
end

function mainFrame.events:QUEST_PROGRESS(...)
	OnQuest()
end

function mainFrame.events:QUEST_DETAIL(...)
	OnQuest()
end

mainFrame:Setup()
