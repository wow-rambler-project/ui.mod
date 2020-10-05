-- WoW Rambler Project - Addon
--
-- mailto: wow.rambler.project@gmail.com
--

local mainFrame, events = CreateFrame("Frame", nil, UIParent), {}

mainFrame.fontSize = 20
mainFrame.timeDelta = 0

mainFrame:SetPoint("TOP", 0, -mainFrame.fontSize/2)

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

local hideFrame = CreateFrame("Frame")
hideFrame:Hide()

if _G["MiniMapMailFrame"] then
	_G["MiniMapMailFrame"]:SetParent(hideFrame)
end

if _G["GameTimeFrame"] then
	_G["GameTimeFrame"]:SetParent(hideFrame)
end

ZoneTextFrame:SetParent(hideFrame)
SubZoneTextFrame:SetParent(hideFrame)

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

-- local function onMouseDown(self, buttonName)	
-- 	if (buttonName == "LeftButton") then
-- 		mainFrame:StartMoving()
-- 	end
-- end

-- local function onMouseUp(self, buttonName)
-- 	mainFrame:StopMovingOrSizing()
-- end

-- mainFrame:RegisterForDrag("LeftButton")
-- mainFrame:SetClampedToScreen(true)
-- mainFrame:SetMovable(true)
-- mainFrame:EnableMouse(true)

local function OnUpdate(self, timeDelta)
	self.timeDelta = self.timeDelta + timeDelta
	if self.timeDelta < .05 then 
		return
	end 

	local x, y = GetPlayerZonePosition()
	x = x or 0
	y = y or 0

	self.positionXText:SetFormattedText("%.1f", x * 100)
	self.positionYText:SetFormattedText("%.1f", y * 100)

	self:SetWidth((self.maxPositionWidth * 2) + self.zoneText:GetStringWidth())

	self.timeDelta = 0
end

function events:PLAYER_ENTERING_WORLD(...)
	UpdateZoneInfo()
end

function events:ZONE_CHANGED(...)
	UpdateZoneInfo()
end

function events:ZONE_CHANGED_NEW_AREA(...)
	UpdateZoneInfo()
end

function events:ZONE_CHANGED_INDOORS(...)
	UpdateZoneInfo()
end

function events:QUEST_DETAIL(...)
	local questIdText = QuestNpcNameFrame.questIdText

	if not questIdText then
		local name, size, style = QuestFrameNpcNameText:GetFont()

		QuestNpcNameFrame.questIdText = QuestNpcNameFrame:CreateFontString()
		questIdText = QuestNpcNameFrame.questIdText

		questIdText:SetFont(name, size, style)
		questIdText:SetPoint("TOP", 0, -size * 2.5)
		questIdText:SetTextColor(1,1,1,.4)
	end

	questIdText:SetFormattedText("This quest's number is %d.", GetQuestID())
end

mainFrame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...)
end)

for k, v in pairs(events) do
	mainFrame:RegisterEvent(k)
end

mainFrame:SetScript("OnUpdate", OnUpdate)
--mainFrame:SetScript("OnMouseDown", onMouseDown)
--mainFrame:SetScript("OnMouseUp", onMouseUp)
