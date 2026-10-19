local ADDON_NAME, ns = ...

ns.EditMode = ns.EditMode or {}

local function ApplyBackdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
        frame:SetBackdropBorderColor(0.83, 0.66, 0.35, 1)
    end
end

local function ScopeLabel(scope)
    if scope == "global" then
        return "Global"
    end
    return ns.TYPE_LABELS[scope] or scope
end

function ns.EditMode.IsActive()
    return ns.EditMode.frame and ns.EditMode.frame:IsShown()
end

function ns.EditMode.Commit(handle, opts)
    opts = opts or {}
    if not handle then
        return
    end
    local scope = ns.EditMode.scope or "global"
    local x = handle:GetLeft() or 0
    local y = handle:GetBottom() or 0
    ns.SetPositionField(scope, "mode", "point")
    ns.SetPositionField(scope, "pointX", math.floor(x + 0.5))
    ns.SetPositionField(scope, "pointY", math.floor(y + 0.5))
    ns.EditMode.dirty = false
    if not opts.silent and ns.Menu.Refresh then
        ns.Menu.Refresh()
    end
end

function ns.EditMode.CurrentMode()
    local scope = ns.EditMode.scope or "global"
    local position = ns.GetPositionSource(scope ~= "global" and scope or nil)
    return position.mode or "cursor"
end

function ns.EditMode.Cancel()
    ns.EditMode.dirty = false
    if ns.EditMode.frame then
        ns.EditMode.frame:Hide()
    end
    ns.EditMode.active = false
    ns.EditMode.RestoreMenu()
end

function ns.EditMode.Create()
    if ns.EditMode.frame then
        return ns.EditMode.frame
    end

    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local overlay = CreateFrame("Frame", ADDON_NAME .. "EditMode", UIParent)
    overlay:SetAllPoints()
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetFrameLevel(1)
    overlay:EnableMouse(false)
    overlay:Hide()

    local help = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    help:SetPoint("TOP", 0, -40)
    overlay.help = help

    local handle = CreateFrame("Frame", ADDON_NAME .. "EditHandle", overlay, template)
    handle:SetSize(240, 96)
    handle:SetPoint("CENTER")
    handle:EnableMouse(true)
    handle:SetMovable(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function(self)
        ns.EditMode.dirty = true
        self:StartMoving()
    end)
    handle:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        ns.EditMode.Commit(self)
    end)
    ApplyBackdrop(handle)

    local title = handle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -14)
    handle.title = title

    local detail = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail:SetPoint("TOP", title, "BOTTOM", 0, -8)
    handle.detail = detail

    local done = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
    done:SetSize(120, 24)
    done:SetPoint("BOTTOM", 0, 48)
    done:SetText("Done")
    done:SetScript("OnClick", function()
        ns.EditMode.Stop()
    end)

    overlay.handle = handle
    ns.EditMode.frame = overlay
    tinsert(UISpecialFrames, overlay:GetName())
    overlay:SetScript("OnHide", function()
        ns.EditMode.active = false
    end)
    return overlay
end

function ns.EditMode.PlaceHandle()
    local frame = ns.EditMode.frame
    if not frame then
        return
    end
    local handle = frame.handle
    local scope = ns.EditMode.scope or "global"
    local position = ns.GetPositionSource(scope ~= "global" and scope or nil)
    handle:ClearAllPoints()
    if position.mode == "point" then
        handle:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", position.pointX or 400, position.pointY or 300)
    elseif position.mode == "corner" then
        local corner = ns.CORNERS[position.corner] and position.corner or "BOTTOMRIGHT"
        handle:SetPoint(corner, UIParent, corner, position.offsetX or 0, position.offsetY or 0)
    else
        handle:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function ns.EditMode.Refresh()
    local frame = ns.EditMode.Create()
    local scope = ns.EditMode.scope or "global"
    local position = ns.GetPositionSource(scope ~= "global" and scope or nil)
    local label = ScopeLabel(scope)

    frame.help:SetText(label .. ": Set X, Y")
    frame.handle:Show()
    frame.handle:EnableMouse(true)
    frame.handle.title:SetText(label)
    frame.handle.detail:SetText(("Drag to place.\nX %d   Y %d"):format(position.pointX or 0, position.pointY or 0))
    ns.EditMode.PlaceHandle()
end

function ns.EditMode.RaiseMenu()
    if not ns.Menu.frame then
        return
    end
    ns.Menu.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    ns.Menu.frame:SetFrameLevel(50)
end

function ns.EditMode.RestoreMenu()
    if not ns.Menu.frame then
        return
    end
    ns.Menu.frame:SetFrameStrata("DIALOG")
    ns.Menu.frame:SetFrameLevel(1)
end

function ns.EditMode.Start(scope)
    ns.EditMode.scope = scope or ns.Menu.scope or "global"
    ns.EditMode.dirty = false
    local frame = ns.EditMode.Create()
    ns.EditMode.RaiseMenu()
    ns.EditMode.Refresh()
    frame:Show()
    ns.EditMode.active = true
end

function ns.EditMode.Stop()
    if ns.EditMode.dirty and ns.EditMode.frame and ns.EditMode.CurrentMode() == "point" then
        ns.EditMode.Commit(ns.EditMode.frame.handle, { silent = true })
    end
    if ns.EditMode.frame then
        ns.EditMode.frame:Hide()
    end
    ns.EditMode.active = false
    ns.EditMode.dirty = false
    ns.EditMode.RestoreMenu()
    if ns.Menu.Refresh then
        ns.Menu.Refresh()
    end
end
