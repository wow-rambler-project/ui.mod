-- WoW Rambler Project - Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local hideFrame = CreateFrame("Frame")
hideFrame:Hide()

local mainFrame, events = CreateFrame("Frame", nil, UIParent), {}

mainFrame.fontSize = 20
mainFrame.timeDelta = 0

mainFrame:SetPoint("TOP", 0, -0.6180339887 * mainFrame.fontSize)

local tR, tG, tB = 246/255, 227/255, 186/255

local function UpdateZoneInfo()
	local zone = GetRealZoneText()
	local subZone = GetSubZoneText()

	if (subZone == "") then
		mainFrame.zoneText:SetText(zone)
	else
		mainFrame.zoneText:SetFormattedText("%s - %s", zone, subZone)
	end
end

local mapCoordinatesCache = {}
local playerMapPosition = CreateVector2D(0,0)
local zeroVector = CreateVector2D(0, 0)
local oneVector = CreateVector2D(1, 1)

local function GetPlayerMapPosition(mapId)
	local worldPosition = mapCoordinatesCache[mapId]

	if not worldPosition then
		worldPosition = {}
		local _
		_, worldPosition[1] = C_Map.GetWorldPosFromMapPos(mapId, zeroVector)
		_, worldPosition[2] = C_Map.GetWorldPosFromMapPos(mapId, oneVector)

		worldPosition[2]:Subtract(worldPosition[1])
		mapCoordinatesCache[mapId] = worldPosition
	end

	playerMapPosition.x, playerMapPosition.y = UnitPosition('Player')
	playerMapPosition:Subtract(worldPosition[1])

	return (1 / worldPosition[2].y) * playerMapPosition.y, (1 / worldPosition[2].x) * playerMapPosition.x
end

local function GetPlayerZonePosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		-- This approach uses more memory.
		-- local mapPosObject = C_Map.GetPlayerMapPosition(mapID, "player")
		-- if mapPosObject then 
		--	return mapPosObject:GetXY()
		-- end 

		return GetPlayerMapPosition(mapID)
	end
end

local function SetupMinimap()
	for _, b in ipairs({Minimap:GetChildren()}) do
		pcall(b.Hide, b)
	end

	MiniMapMailFrame:SetParent(hideFrame)
	GameTimeFrame:SetParent(hideFrame)

	Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
	Minimap:SetWidth(166 + 13)
	Minimap:SetHeight(166)
	Minimap:SetPoint("TOPRIGHT", -13, -13)

	MinimapBorderTop:SetParent(hideFrame)
	MinimapZoneTextButton:SetParent(hideFrame)
end

local function SetupBattlefieldMap()
	if not BattlefieldMapFrame then
		return
	end

	BattlefieldMapFrame.BorderFrame:SetAlpha(0)
	BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("player", 18)

	BattlefieldMapFrame:ClearAllPoints()
	BattlefieldMapFrame:SetPoint("BOTTOMRIGHT", 2, -3)
	BattlefieldMapFrame:SetAlpha(1)
end

local function SetupUnitFrames()
	local actionBarWidth = 160
	local playerFrameX = (1920 / 2) - (actionBarWidth / 2) - PlayerFrame:GetWidth()
	local targetFrameX = (1920 / 2) + (actionBarWidth / 2)

	PlayerFrame:ClearAllPoints()
	PlayerFrame:SetPoint("TOPLEFT", playerFrameX, -880)

	TargetFrame:ClearAllPoints()
	TargetFrame:SetPoint("TOPLEFT", targetFrameX, -880)
end

local function SetupRemainingUI()
	GossipFrame:SetScale(1.25)
	QuestFrame:SetScale(1.25)
	ZoneTextFrame:SetParent(hideFrame)
	SubZoneTextFrame:SetParent(hideFrame)
end

mainFrame.maxPositionWidthText = mainFrame:CreateFontString()
mainFrame.positionXText = mainFrame:CreateFontString(nil, "OVERLAY")
mainFrame.positionYText = mainFrame:CreateFontString(nil, "OVERLAY")
mainFrame.zoneText = mainFrame:CreateFontString(nil, "OVERLAY")

mainFrame.maxPositionWidthText:SetFont("Fonts\\MORPHEUS.TTF", mainFrame.fontSize, "OUTLINE")
mainFrame.positionXText:SetFont("Fonts\\MORPHEUS.TTF", mainFrame.fontSize, "OUTLINE")
mainFrame.positionYText:SetFont("Fonts\\MORPHEUS.TTF", mainFrame.fontSize, "OUTLINE")
mainFrame.zoneText:SetFont("Fonts\\MORPHEUS.TTF", mainFrame.fontSize, "OUTLINE")

mainFrame.maxPositionWidthText:SetText("100.0")
mainFrame.maxPositionWidth = mainFrame.maxPositionWidthText:GetStringWidth()

mainFrame.positionXText:SetPoint("TOPLEFT", 0, 0)
mainFrame.positionYText:SetPoint("TOPLEFT", mainFrame.maxPositionWidth, 0)
mainFrame.zoneText:SetPoint("TOPLEFT", mainFrame.maxPositionWidth * 2, 0)

mainFrame.positionXText:SetJustifyH("LEFT")
mainFrame.positionYText:SetJustifyH("LEFT")
mainFrame.zoneText:SetJustifyH("LEFT")

mainFrame.positionXText:SetTextColor(tR, tG, tB, 1)
mainFrame.positionYText:SetTextColor(tR, tG, tB, 1)
mainFrame.zoneText:SetTextColor(tR, tG, tB, 1)

mainFrame:SetHeight(mainFrame.maxPositionWidthText:GetStringHeight())

local function OnUpdate(self, timeDelta)
	self.timeDelta = self.timeDelta + timeDelta
	if self.timeDelta < 0.1 then 
		return
	end 

	local x, y = GetPlayerZonePosition()
	x = x or 0
	y = y or 0

	self.positionXText:SetFormattedText("%.1f", x * 100)
	self.positionYText:SetFormattedText("%.1f", y * 100)

	self.timeDelta = 0
end

local function OnZoneChange()
	UpdateZoneInfo()
	mainFrame:SetWidth((mainFrame.maxPositionWidth * 2) + mainFrame.zoneText:GetStringWidth())
end

local function OnQuest()
	local questIdText = QuestNpcNameFrame.questIdText

	if not questIdText then
		local name, size, style = QuestFrameNpcNameText:GetFont()

		QuestNpcNameFrame.questIdText = QuestNpcNameFrame:CreateFontString()
		questIdText = QuestNpcNameFrame.questIdText

		questIdText:SetFont(name, size, style)
		questIdText:SetPoint("TOP", 0, -size * 2.5)
		questIdText:SetTextColor(1,1,1,.4)
	end

	questIdText:SetFormattedText("This is quest number %d.", GetQuestID())
end

function events:PLAYER_ENTERING_WORLD(...)
	OnZoneChange()
	SetupMinimap()
	SetupBattlefieldMap()
	SetupUnitFrames()
	SetupRemainingUI()
end

function events:ZONE_CHANGED(...)
	OnZoneChange()
end

function events:ZONE_CHANGED_NEW_AREA(...)
	OnZoneChange()
end

function events:ZONE_CHANGED_INDOORS(...)
	OnZoneChange()
end

function events:QUEST_PROGRESS(...)
	OnQuest()
end

function events:QUEST_DETAIL(...)
	OnQuest()
end

mainFrame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...)
end)

for k, v in pairs(events) do
	mainFrame:RegisterEvent(k)
end

mainFrame:SetScript("OnUpdate", OnUpdate)
