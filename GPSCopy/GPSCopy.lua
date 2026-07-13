-- GPSCopy - intercetta l'output di .gps e lo mostra in una finestra copiabile
-- Uso: scrivi .gps come al solito, la finestra si apre da sola

local frame = CreateFrame("Frame", "GPSCopyFrame", UIParent)
frame:SetSize(420, 120)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("DIALOG")
frame:Hide()

frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.title:SetPoint("TOP", frame, "TOP", 0, -16)
frame.title:SetText("GPSCopy - Ctrl+A poi Ctrl+C per copiare")

local editBoxBg = CreateFrame("Frame", nil, frame)
editBoxBg:SetSize(390, 26)
editBoxBg:SetPoint("TOP", frame, "TOP", 0, -45)
editBoxBg:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
editBoxBg:SetBackdropColor(0, 0, 0, 1)

local editBox = CreateFrame("EditBox", nil, editBoxBg)
editBox:SetSize(380, 20)
editBox:SetPoint("CENTER")
editBox:SetAutoFocus(true)
editBox:SetFontObject(ChatFontNormal)
editBox:SetJustifyH("CENTER")
editBox:SetScript("OnEscapePressed", function(self) frame:Hide() end)

frame.info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.info:SetPoint("TOP", editBoxBg, "BOTTOM", 0, -12)
frame.info:SetJustifyH("CENTER")
frame.info:SetWidth(400)

local lastMap = nil

local function ShowCoords(x, y, z, o)
    local text = string.format("%s %s %s %s", x, y, z, o)
    if lastMap then
        text = text .. " " .. lastMap
    end
    editBox:SetText(text)
    editBox:HighlightText()
    editBox:SetFocus()
    frame.info:SetText(lastMap and "Ordine: X Y Z Orientation Map" or "Ordine: X Y Z Orientation")
    frame:Show()
end

-- Aggancia AddMessage su tutte le finestre di chat, invece di un singolo evento:
-- cosi' catturiamo il testo di .gps indipendentemente da come il server lo invia.
for i = 1, NUM_CHAT_WINDOWS do
    local cf = _G["ChatFrame" .. i]
    if cf then
        hooksecurefunc(cf, "AddMessage", function(self, text, ...)
            if not text then return end

            local mapid = string.match(text, "[Mm]ap:?%s*(%d+)")
            if mapid then
                lastMap = mapid
            end

            local x, y, z, o = string.match(text,
                "[Xx]:%s*(-?%d+%.?%d*)%s+[Yy]:%s*(-?%d+%.?%d*)%s+[Zz]:%s*(-?%d+%.?%d*)%s+[Oo]rientation:%s*(-?%d+%.?%d*)")

            if x then
                ShowCoords(x, y, z, o)
            end
        end)
    end
end
