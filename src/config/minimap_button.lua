local ADDON_NAME, ns = ...

ns.MinimapButton = ns.MinimapButton or {}

local ICON_PATH = "Interface\\AddOns\\" .. ADDON_NAME .. "\\assets\\tt_plus_icon"
local DISABLED_MARK = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
local RADIUS_PAD = 5

local function PositionButton(button)
    if not Minimap then
        return
    end
    local angle = math.rad(ns.GetMinimapAngle())
    local radius = (Minimap:GetWidth() / 2) + RADIUS_PAD
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function DragUpdate(button)
    if not Minimap then
        return
    end
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local px, py = GetCursorPosition()
    px, py = px / scale, py / scale
    ns.SetMinimapAngle(math.deg(math.atan2(py - my, px - mx)))
    PositionButton(button)
end

local function RefreshAddonUi()
    if ns.Menu.Refresh then
        ns.Menu.Refresh()
    end
end

local function ToggleAddonEnabled()
    ns.SetAddonEnabled(not ns.GetAddonEnabled())
    RefreshAddonUi()
end

local function HideMinimapIcon()
    ns.SetMinimapShown(false)
    RefreshAddonUi()
    print(ns.PREFIX .. " /tt+ to configure")
end

local function ShowMinimapMenu(owner)
    if GameTooltip then
        GameTooltip:Hide()
    end
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, root)
            root:CreateCheckbox("Tooltip+", function()
                return ns.GetAddonEnabled()
            end, ToggleAddonEnabled)
            root:CreateButton("Hide", HideMinimapIcon)
        end)
        return
    end
    local menu = ns.MinimapButton.menu
    if not menu then
        menu = CreateFrame("Frame", ADDON_NAME .. "MinimapMenu", UIParent, "UIDropDownMenuTemplate")
        ns.MinimapButton.menu = menu
    end
    UIDropDownMenu_Initialize(menu, function()
        local toggle = UIDropDownMenu_CreateInfo()
        toggle.text = "Tooltip+"
        toggle.checked = ns.GetAddonEnabled()
        toggle.isNotRadio = true
        toggle.keepShownOnClick = true
        toggle.func = ToggleAddonEnabled
        UIDropDownMenu_AddButton(toggle)

        local hide = UIDropDownMenu_CreateInfo()
        hide.text = "Hide"
        hide.notCheckable = true
        hide.func = HideMinimapIcon
        UIDropDownMenu_AddButton(hide)
    end, "MENU")
    ToggleDropDownMenu(1, nil, menu, owner, 0, 0)
end

function ns.MinimapButton.Refresh()
    local button = ns.MinimapButton.button
    if not button then
        return
    end
    if ns.GetMinimapShown() then
        PositionButton(button)
        button:Show()
        local enabled = ns.GetAddonEnabled()
        if button.icon then
            if enabled then
                button.icon:SetVertexColor(1, 1, 1)
            else
                button.icon:SetVertexColor(0.55, 0.55, 0.55)
            end
        end
        if button.disabledMark then
            button.disabledMark:SetShown(not enabled)
        end
    else
        button:Hide()
    end
end

function ns.MinimapButton.Create()
    if ns.MinimapButton.button then
        ns.MinimapButton.Refresh()
        return ns.MinimapButton.button
    end
    if not Minimap then
        return nil
    end

    local button = CreateFrame("Button", ADDON_NAME .. "MinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 6, -6)
    icon:SetTexture(ICON_PATH)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local disabledMark = button:CreateTexture(nil, "ARTWORK")
    disabledMark:SetSize(12, 12)
    disabledMark:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    disabledMark:SetTexture(DISABLED_MARK)
    disabledMark:Hide()
    button.disabledMark = disabledMark

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local title = ns.IS_DEV and "Tooltip+ (dev)" or "Tooltip+"
        if not ns.GetAddonEnabled() then
            title = ns.IS_DEV and "Tooltip+ (dev, disabled)" or "Tooltip+ (disabled)"
        end
        GameTooltip:SetText(title)
        GameTooltip:AddLine("Left-click: open options", 1, 1, 1)
        GameTooltip:AddLine("Right-click: menu", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around the minimap", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            DragUpdate(self)
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if self.isDragging then
            self.isDragging = false
            return
        end
        if mouseButton == "RightButton" then
            ShowMinimapMenu(self)
            return
        end
        ns.Menu.Toggle()
    end)

    ns.MinimapButton.button = button
    ns.MinimapButton.Refresh()
    return button
end
