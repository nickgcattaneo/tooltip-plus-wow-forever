local ADDON_NAME, ns = ...

ns.Menu = ns.Menu or {}
ns.Menu.scope = "global"
ns.Menu.tab = "settings"

local function ApplyBackdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    end
end

local function ApplySectionBackdrop(frame)
    if not frame.SetBackdrop then
        return
    end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
end

local function PaintSection(frame, active)
    if not frame or not frame.SetBackdropColor then
        return
    end
    if active then
        frame:SetBackdropColor(0.07, 0.06, 0.04, 0.42)
        frame:SetBackdropBorderColor(0.83, 0.66, 0.35, 0.75)
    else
        frame:SetBackdropColor(0.04, 0.04, 0.04, 0.18)
        frame:SetBackdropBorderColor(0.45, 0.38, 0.25, 0.35)
    end
end

local function LayoutSection(frame, parent, top, height, active, inset)
    if not frame then
        return
    end
    inset = inset or 0
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, top)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, top)
    frame:SetHeight(height)
    if active == "outer" then
        if frame.SetBackdropColor then
            frame:SetBackdropColor(0.03, 0.03, 0.03, 0.22)
            frame:SetBackdropBorderColor(0.55, 0.45, 0.28, 0.55)
        end
    else
        PaintSection(frame, active)
    end
    frame:Show()
end

local function CreateSectionBox(parent, levelAdd)
    local frame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    ApplySectionBackdrop(frame)
    if frame.SetFrameLevel and parent.GetFrameLevel then
        frame:SetFrameLevel(parent:GetFrameLevel() + (levelAdd or 0))
    end
    PaintSection(frame, false)
    return frame
end

local function AddCheck(parent, label)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    local text = box.Text or box.text
    if text then
        text:SetText(label)
    end
    return box
end

local function AddBareCheck(parent)
    local box = AddCheck(parent, "")
    local text = box.Text or box.text
    if text then
        text:Hide()
    end
    box:SetSize(22, 22)
    if box.SetHitRectInsets then
        box:SetHitRectInsets(0, 0, 0, 0)
    end
    if box.SetFrameLevel and parent.GetFrameLevel then
        box:SetFrameLevel(parent:GetFrameLevel() + 4)
    end
    return box
end

local function BindCheck(box, getter, setter)
    box.getter = getter
    box.setter = setter
    box:SetScript("OnClick", function(self)
        self.setter(self:GetChecked())
        ns.Menu.Refresh()
    end)
end

local function RoundOffset(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function CommitOffsetBox(box, key)
    local value = tonumber(box:GetText())
    if value == nil then
        ns.Menu.Refresh()
        return
    end
    ns.SetPositionField(ns.Menu.scope, key, RoundOffset(value))
    ns.Menu.Refresh()
end

local function CreateOffsetBox(parent, name, key)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetSize(56, 22)
    box:SetAutoFocus(false)
    box:SetMaxLetters(6)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        self.revert = true
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        if self.revert then
            self.revert = nil
            ns.Menu.Refresh()
            return
        end
        CommitOffsetBox(self, key)
    end)
    return box
end

local function NudgePosition(key, delta)
    local typeId = ns.Menu.scope ~= "global" and ns.Menu.scope or nil
    local position = ns.GetPositionSource(typeId)
    local value = tonumber(position[key]) or 0
    ns.SetPositionField(ns.Menu.scope, key, RoundOffset(value + delta))
    ns.Menu.Refresh()
end

local function CreateStepper(parent, label)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(22, 22)
    button:SetText(label)
    return button
end

local function AttachSteppers(box, key)
    local parent = box:GetParent()
    local minus = CreateStepper(parent, "-")
    minus:SetPoint("RIGHT", box, "LEFT", -2, 0)
    minus:SetScript("OnClick", function()
        NudgePosition(key, -1)
    end)
    local plus = CreateStepper(parent, "+")
    plus:SetPoint("LEFT", box, "RIGHT", 2, 0)
    plus:SetScript("OnClick", function()
        NudgePosition(key, 1)
    end)
    box.minus = minus
    box.plus = plus
    return minus, plus
end

local function SetOffsetGroupShown(box, shown)
    box:SetShown(shown)
    if box.minus then
        box.minus:SetShown(shown)
    end
    if box.plus then
        box.plus:SetShown(shown)
    end
end

local function RefreshOffsetBox(box, value)
    if box.HasFocus and box:HasFocus() then
        return
    end
    box:SetText(tostring(value or 0))
end

local function CommitFadeBox(box)
    local value = tonumber(box:GetText())
    if value == nil then
        ns.Menu.Refresh()
        return
    end
    ns.SetFade(ns.Menu.scope, value)
    ns.Menu.Refresh()
end

local function CreateFadeBox(parent, name)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetSize(56, 22)
    box:SetAutoFocus(false)
    box:SetMaxLetters(4)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        self.revert = true
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        if self.revert then
            self.revert = nil
            ns.Menu.Refresh()
            return
        end
        CommitFadeBox(self)
    end)
    return box
end

local function NudgeFade(delta)
    local typeId = ns.Menu.scope ~= "global" and ns.Menu.scope or nil
    local source = ns.GetFadeSource(typeId)
    local value = tonumber(source.fade) or ns.DEFAULT_FADE
    ns.SetFade(ns.Menu.scope, value + delta)
    ns.Menu.Refresh()
end

local function AttachFadeSteppers(box)
    local parent = box:GetParent()
    local minus = CreateStepper(parent, "-")
    minus:SetPoint("RIGHT", box, "LEFT", -2, 0)
    minus:SetScript("OnClick", function()
        NudgeFade(-ns.FADE_STEP)
    end)
    local plus = CreateStepper(parent, "+")
    plus:SetPoint("LEFT", box, "RIGHT", 2, 0)
    plus:SetScript("OnClick", function()
        NudgeFade(ns.FADE_STEP)
    end)
    box.minus = minus
    box.plus = plus
end

local function ScopeLabel(scope)
    if scope == "global" then
        return "Global"
    end
    return ns.TYPE_LABELS[scope] or scope
end

local function CreateTab(parent, label, width)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(width, 26)

    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", 0, 2)
    text:SetText(label)
    tab.label = text

    local bar = tab:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("BOTTOMLEFT", 6, 0)
    bar:SetPoint("BOTTOMRIGHT", -6, 0)
    bar:SetHeight(2)
    if bar.SetColorTexture then
        bar:SetColorTexture(0.83, 0.66, 0.35, 1)
    else
        bar:SetTexture(1, 0.82, 0, 1)
    end
    tab.bar = bar

    function tab:SetSelected(selected)
        self.selected = selected and true or false
        if self.selected then
            self.label:SetTextColor(1, 0.82, 0)
            self.bar:Show()
        else
            self.label:SetTextColor(0.72, 0.72, 0.72)
            self.bar:Hide()
        end
    end

    tab:SetScript("OnEnter", function(self)
        if not self.selected then
            self.label:SetTextColor(1, 1, 1)
        end
    end)
    tab:SetScript("OnLeave", function(self)
        if self.selected then
            self.label:SetTextColor(1, 0.82, 0)
        else
            self.label:SetTextColor(0.72, 0.72, 0.72)
        end
    end)

    tab:SetSelected(false)
    return tab
end

local function BindTooltip(frame, text)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

local function CreateIconButton(parent, tooltip, normal, pushed)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(22, 22)
    button:SetNormalTexture(normal)
    if pushed then
        button:SetPushedTexture(pushed)
    end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    BindTooltip(button, tooltip)
    return button
end

local function CreateLabelHit(parent, text)
    local hit = CreateFrame("Frame", nil, parent)
    hit:SetSize(70, 16)
    hit:EnableMouse(true)
    if hit.SetFrameLevel and parent.GetFrameLevel then
        hit:SetFrameLevel(parent:GetFrameLevel() + 2)
    end
    BindTooltip(hit, text)
    return hit
end

local function PlaceLabelHit(hit, label, rel, relPoint, x, y)
    if not hit or not label then
        return
    end
    hit:ClearAllPoints()
    hit:SetPoint("LEFT", rel, relPoint, x, y)
    local width = label.GetStringWidth and label:GetStringWidth() or 0
    if type(width) ~= "number" or width < 8 then
        width = 70
    end
    hit:SetSize(width, 16)
end

local function PlaceSectionTitle(title, hit, check, isType, y)
    if not title then
        return
    end
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", 10, y)
    if check then
        check:SetShown(isType)
        if isType then
            check:ClearAllPoints()
            check:SetPoint("LEFT", title, "RIGHT", 6, 0)
        end
    end
    PlaceLabelHit(hit, title, title:GetParent(), "TOPLEFT", 10, y)
end

local function CreateOnOff(parent, label, getter, setter, tooltip)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(460, 28)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", 0, 0)
    text:SetText(label)

    local on = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    on:SetSize(50, 22)
    on:SetPoint("LEFT", 200, 0)
    on:SetText("On")

    local off = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    off:SetSize(50, 22)
    off:SetPoint("LEFT", on, "RIGHT", 6, 0)
    off:SetText("Off")

    if tooltip then
        local hit = CreateFrame("Frame", nil, row)
        hit:SetPoint("LEFT", row, "LEFT", 0, 0)
        hit:SetHeight(22)
        local width = text.GetStringWidth and text:GetStringWidth() or 0
        if type(width) ~= "number" or width < 8 then
            width = (strlen and strlen(label) or #label) * 7
        end
        hit:SetWidth(width)
        BindTooltip(hit, tooltip)
    end

    local function paint()
        if getter() then
            on:LockHighlight()
            off:UnlockHighlight()
        else
            off:LockHighlight()
            on:UnlockHighlight()
        end
    end
    on:SetScript("OnClick", function()
        setter(true)
        paint()
        ns.Menu.Refresh()
    end)
    off:SetScript("OnClick", function()
        setter(false)
        paint()
        ns.Menu.Refresh()
    end)
    row.Refresh = paint
    return row
end

local function SetDropdownLabel(dropdown, text)
    if dropdown.SetDefaultText then
        dropdown:SetDefaultText(text)
    end
    if dropdown.SetText then
        dropdown:SetText(text)
    end
    if dropdown.Left and UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(dropdown, text)
    end
end

local function CreateChoiceDropdown(parent, name, width, getOptions, getValue, setValue)
    local modern
    local ok, frame = pcall(CreateFrame, "DropdownButton", name, parent, "WowStyle1DropdownTemplate")
    if ok and frame and frame.SetupMenu then
        modern = frame
    elseif frame and frame.Hide then
        frame:Hide()
        frame:SetParent(nil)
    end

    local function currentLabel()
        local value = getValue()
        local options = getOptions()
        for i = 1, #options do
            if options[i].id == value then
                return options[i].label
            end
        end
        return tostring(value or "")
    end

    if modern then
        modern:SetWidth(width)
        local function rebuild()
            modern:SetupMenu(function(_, root)
                local options = getOptions()
                for i = 1, #options do
                    local opt = options[i]
                    root:CreateRadio(opt.label, function()
                        return getValue() == opt.id
                    end, function()
                        setValue(opt.id)
                    end)
                end
            end)
            SetDropdownLabel(modern, currentLabel())
        end
        modern.Rebuild = rebuild
        rebuild()
        return modern
    end

    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width - 20)
    local function rebuild()
        UIDropDownMenu_Initialize(dropdown, function()
            local options = getOptions()
            local selected = getValue()
            for i = 1, #options do
                local opt = options[i]
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt.label
                info.checked = opt.id == selected
                info.func = function()
                    setValue(opt.id)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        SetDropdownLabel(dropdown, currentLabel())
    end
    dropdown.Rebuild = rebuild
    rebuild()
    return dropdown
end

local function CreateProfileDropdown(parent)
    local modern
    local ok, frame = pcall(CreateFrame, "DropdownButton", ADDON_NAME .. "ProfileDropDown", parent, "WowStyle1DropdownTemplate")
    if ok and frame and frame.SetupMenu then
        modern = frame
    elseif frame and frame.Hide then
        frame:Hide()
        frame:SetParent(nil)
    end

    if modern then
        modern:SetWidth(200)
        local function rebuild()
            modern:SetupMenu(function(_, root)
                local names = ns.ProfileNames()
                for i = 1, #names do
                    local name = names[i]
                    root:CreateRadio(name, function()
                        return ns.GetActiveProfileName() == name
                    end, function()
                        ns.Menu.SwitchProfile(name)
                    end)
                end
            end)
            if modern.SetDefaultText then
                modern:SetDefaultText(ns.GetActiveProfileName())
            end
        end
        modern.Rebuild = rebuild
        rebuild()
        return modern
    end

    local dropdown = CreateFrame("Frame", ADDON_NAME .. "ProfileDropDown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 160)
    local function rebuild()
        UIDropDownMenu_Initialize(dropdown, function()
            local names = ns.ProfileNames()
            local active = ns.GetActiveProfileName()
            for i = 1, #names do
                local name = names[i]
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.checked = name == active
                info.func = function()
                    ns.Menu.SwitchProfile(name)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(dropdown, ns.GetActiveProfileName())
    end
    dropdown.Rebuild = rebuild
    rebuild()
    return dropdown
end

function ns.Menu.Refresh()
    local widgets = ns.Menu.widgets
    if not widgets then
        return
    end

    if ns.Menu.scope ~= "global" and not ns.IsConfiguredType(ns.Menu.scope) then
        ns.Menu.scope = "global"
    end
    local scope = ns.Menu.scope
    local profile = ns.GetActiveProfile()
    if widgets.profileDropdown and widgets.profileDropdown.Rebuild then
        widgets.profileDropdown.Rebuild()
    end
    local isDefault = ns.GetActiveProfileName() == ns.DEFAULT_PROFILE_NAME
    if widgets.clone then
        widgets.clone:SetShown(not isDefault)
    end
    if widgets.delete then
        widgets.delete:SetShown(not isDefault)
    end
    if widgets.profileLabel then
        widgets.profileLabel:SetText(ns.IsProfileDirty() and "Profile *" or "Profile")
    end
    if widgets.save then
        if ns.IsProfileDirty() then
            widgets.save:Enable()
        else
            widgets.save:Disable()
        end
    end

    if widgets.scopeDropdown and widgets.scopeDropdown.Rebuild then
        widgets.scopeDropdown.Rebuild()
    end

    local onSettings = ns.Menu.tab ~= "tooltip"
    if widgets.settingsPanel then
        widgets.settingsPanel:SetShown(onSettings)
    end
    if widgets.tooltipPanel then
        widgets.tooltipPanel:SetShown(not onSettings)
    end
    if widgets.save then
        widgets.save:SetShown(not onSettings)
    end
    if widgets.tabSettings and widgets.tabSettings.SetSelected then
        widgets.tabSettings:SetSelected(onSettings)
        widgets.tabTooltip:SetSelected(not onSettings)
    end
    if widgets.addonToggle and widgets.addonToggle.Refresh then
        widgets.addonToggle.Refresh()
    end
    if widgets.iconToggle and widgets.iconToggle.Refresh then
        widgets.iconToggle.Refresh()
    end

    local isType = scope ~= "global"
    local typeCfg = isType and ns.GetTypeConfig(scope) or nil
    local overridePosition = not isType or (typeCfg and typeCfg.overridePosition)
    local overrideContent = not isType or (typeCfg and typeCfg.overrideContent)
    local titleY = -132
    local titleRowH = 26
    local sectionGap = 12
    if widgets.overridePosition and isType then
        widgets.overridePosition:SetChecked(typeCfg.overridePosition and true or false)
    end
    PlaceSectionTitle(widgets.modeLabel, widgets.modeLabelHit, widgets.overridePosition, isType, titleY)

    local position = ns.GetPositionSource(isType and scope or nil)
    if widgets.mode and widgets.mode.Rebuild then
        widgets.mode.Rebuild()
    end
    local showCorner = overridePosition and position.mode == "corner"
    local showOffset = overridePosition and (position.mode == "cursor" or position.mode == "corner")
    local showPoint = overridePosition and position.mode == "point"
    local showEdit = overridePosition and (position.mode == "point" or position.mode == "corner")

    local boxPad = 14
    local rowH = 32
    local positionTop = titleY - titleRowH
    local row1 = positionTop - boxPad
    local row2 = row1 - rowH
    local row3 = row2 - rowH
    local positionRows = 0
    if overridePosition then
        positionRows = 1
        if showEdit then
            positionRows = positionRows + 1
        end
    end
    local positionHeight = (boxPad * 2) + (positionRows * rowH)

    if widgets.mode then
        widgets.mode:ClearAllPoints()
        widgets.mode:SetPoint("TOPLEFT", 16, row1)
        widgets.mode:SetShown(overridePosition)
    end
    widgets.cornerLabel:SetShown(showCorner)
    if widgets.corner then
        widgets.corner:SetShown(showCorner)
        if showCorner and widgets.corner.Rebuild then
            widgets.corner.Rebuild()
        end
    end
    if widgets.offsetXLabel then
        widgets.offsetXLabel:ClearAllPoints()
        widgets.offsetXLabel:SetShown(showOffset)
        widgets.offsetYLabel:SetShown(showOffset)
        SetOffsetGroupShown(widgets.offsetX, showOffset)
        SetOffsetGroupShown(widgets.offsetY, showOffset)
        if showOffset then
            widgets.offsetXLabel:SetPoint("LEFT", widgets.mode, "RIGHT", 12, 0)
            RefreshOffsetBox(widgets.offsetX, position.offsetX)
            RefreshOffsetBox(widgets.offsetY, position.offsetY)
        end
        if widgets.offsetXHit then
            widgets.offsetXHit:SetShown(showOffset)
            widgets.offsetYHit:SetShown(showOffset)
            if showOffset then
                PlaceLabelHit(widgets.offsetXHit, widgets.offsetXLabel, widgets.offsetXLabel, "LEFT", 0, 0)
                PlaceLabelHit(widgets.offsetYHit, widgets.offsetYLabel, widgets.offsetYLabel, "LEFT", 0, 0)
            end
        end
    end
    if widgets.pointXLabel then
        widgets.pointXLabel:ClearAllPoints()
        widgets.pointXLabel:SetShown(showPoint)
        widgets.pointYLabel:SetShown(showPoint)
        SetOffsetGroupShown(widgets.pointX, showPoint)
        SetOffsetGroupShown(widgets.pointY, showPoint)
        if showPoint then
            widgets.pointXLabel:SetPoint("LEFT", widgets.mode, "RIGHT", 12, 0)
            RefreshOffsetBox(widgets.pointX, position.pointX)
            RefreshOffsetBox(widgets.pointY, position.pointY)
        end
    end
    if widgets.edit then
        widgets.edit:SetShown(showEdit)
        widgets.edit:ClearAllPoints()
        if widgets.positionGroup then
            widgets.edit:SetPoint("BOTTOMRIGHT", widgets.positionGroup, "BOTTOMRIGHT", -12, 10)
        else
            widgets.edit:SetPoint("TOPLEFT", 16, row2)
        end
        widgets.edit:SetText("Move / Set X, Y")
    end

    local fadeTitleY = titleY - titleRowH - 4
    if overridePosition then
        fadeTitleY = positionTop - positionHeight - sectionGap
    end
    local cursorMode = (position.mode or "cursor") == "cursor"
    local fadeOn = not isType or (typeCfg and typeCfg.overrideFade)
    local showSeconds = fadeOn and not cursorMode
    local showDisabled = fadeOn and cursorMode
    if widgets.overrideFade then
        if cursorMode then
            widgets.overrideFade:Disable()
        else
            widgets.overrideFade:Enable()
        end
        if isType then
            widgets.overrideFade:SetChecked(typeCfg.overrideFade and true or false)
        end
    end
    if widgets.fadeTitle then
        if cursorMode then
            widgets.fadeTitle:SetTextColor(0.5, 0.5, 0.5)
        else
            widgets.fadeTitle:SetTextColor(1, 0.82, 0)
        end
    end
    if widgets.fadeTitleHit then
        local tip = cursorMode and "Fade stays instant while position is Cursor." or "Override Global Fade Settings"
        BindTooltip(widgets.fadeTitleHit, tip)
    end
    PlaceSectionTitle(widgets.fadeTitle, widgets.fadeTitleHit, widgets.overrideFade, isType, fadeTitleY)

    local fadeSource = ns.GetFadeSource(isType and scope or nil)
    local fadeTop = fadeTitleY - titleRowH
    local fadeRows = fadeOn and 1 or 0
    local fadeHeight = (boxPad * 2) + (fadeRows * rowH)
    if widgets.fadeLabel and widgets.fadeGroup then
        widgets.fadeLabel:ClearAllPoints()
        widgets.fadeLabel:SetShown(showSeconds)
        if showSeconds then
            widgets.fadeLabel:SetPoint("LEFT", widgets.fadeGroup, "LEFT", 12, 0)
        end
    end
    if widgets.fadeBox then
        SetOffsetGroupShown(widgets.fadeBox, showSeconds)
        if showSeconds then
            RefreshOffsetBox(widgets.fadeBox, ns.FormatFade(fadeSource.fade))
        end
    end
    if widgets.fadeHit then
        widgets.fadeHit:SetShown(showSeconds)
        if showSeconds and widgets.fadeLabel then
            PlaceLabelHit(widgets.fadeHit, widgets.fadeLabel, widgets.fadeLabel, "LEFT", 0, 0)
        end
    end
    if widgets.fadeDisabled then
        widgets.fadeDisabled:ClearAllPoints()
        widgets.fadeDisabled:SetShown(showDisabled)
        if showDisabled then
            widgets.fadeDisabled:SetPoint("LEFT", widgets.fadeGroup, "LEFT", 12, 0)
        end
    end

    local contentTitleY = fadeTitleY - titleRowH
    if fadeOn and fadeRows > 0 then
        contentTitleY = fadeTop - fadeHeight - sectionGap
    end
    if widgets.overrideContent and isType then
        widgets.overrideContent:SetChecked(typeCfg.overrideContent and true or false)
    end
    PlaceSectionTitle(widgets.contentTitle, widgets.contentTitleHit, widgets.overrideContent, isType, contentTitleY)

    local content = ns.GetContentSource(isType and scope or nil)
    local contentTop = contentTitleY - titleRowH
    local boxY = contentTop - boxPad
    local contentCount = 0
    for i = 1, #ns.CONTENT_KEYS do
        local spec = ns.CONTENT_KEYS[i]
        local box = widgets.content[spec.key]
        local show = overrideContent and ns.ContentKeyApplies(spec, isType and scope or "global")
        box:SetShown(show)
        if show then
            box:SetPoint("TOPLEFT", 16, boxY)
            box:SetChecked(content[spec.key] and true or false)
            boxY = boxY - 26
            contentCount = contentCount + 1
        end
    end
    local contentHeight = (boxPad * 2) + (contentCount * 26)

    local panel = widgets.tooltipPanel
    if panel and widgets.positionGroup then
        if overridePosition then
            LayoutSection(widgets.positionGroup, panel, positionTop, positionHeight, true, 6)
        else
            widgets.positionGroup:Hide()
        end
        if widgets.fadeGroup then
            if fadeOn and fadeRows > 0 then
                LayoutSection(widgets.fadeGroup, panel, fadeTop, fadeHeight, true, 6)
            else
                widgets.fadeGroup:Hide()
            end
        end
        if overrideContent and contentCount > 0 then
            LayoutSection(widgets.contentGroup, panel, contentTop, contentHeight, true, 6)
        else
            widgets.contentGroup:Hide()
        end
        local lastBottom = contentTitleY - titleRowH
        if overridePosition then
            local posBottom = positionTop - positionHeight
            if posBottom < lastBottom then
                lastBottom = posBottom
            end
        end
        if fadeOn and fadeRows > 0 then
            local fadeBottom = fadeTop - fadeHeight
            if fadeBottom < lastBottom then
                lastBottom = fadeBottom
            end
        end
        if overrideContent and contentCount > 0 then
            local contentBottom = contentTop - contentHeight
            if contentBottom < lastBottom then
                lastBottom = contentBottom
            end
        end
        local outerTop = -118
        local outerHeight = outerTop - lastBottom + 10
        if widgets.tooltipGroup then
            LayoutSection(widgets.tooltipGroup, panel, outerTop, outerHeight, "outer", 0)
        end
    end

    if ns.EditMode.IsActive() and not ns.Menu.refreshingEdit then
        ns.Menu.refreshingEdit = true
        ns.EditMode.Refresh()
        ns.Menu.refreshingEdit = false
    end
end

function ns.Menu.CommitCurrentProfile()
    if ns.EditMode.dirty and ns.EditMode.frame and ns.EditMode.CurrentMode() == "point" then
        ns.EditMode.Commit(ns.EditMode.frame.handle, { silent = true })
    end
end

function ns.Menu.ConfirmLeave(onProceed)
    ns.Menu.Create()
    ns.Menu.CommitCurrentProfile()
    if not ns.IsProfileDirty() then
        onProceed()
        return
    end
    ns.Menu.pendingLeave = onProceed
    ns.Menu.OpenSavePrompt()
end

function ns.Menu.FinishLeave(choice)
    local proceed = ns.Menu.pendingLeave
    ns.Menu.pendingLeave = nil
    if ns.Menu.savePrompt then
        ns.Menu.savePrompt:Hide()
    end
    if choice == "cancel" then
        return
    end
    if choice == "save" then
        ns.SaveDraft()
        print(ns.PREFIX .. " Saved profile " .. ns.GetActiveProfileName() .. ".")
    elseif choice == "discard" then
        ns.DiscardDraft()
    end
    if proceed then
        proceed()
    end
    if ns.Menu.frame and ns.Menu.frame:IsShown() then
        ns.Menu.Refresh()
    end
end

function ns.Menu.HideConfirmed()
    ns.Menu.hidingConfirmed = true
    if ns.Menu.profileModal then
        ns.Menu.profileModal:Hide()
    end
    if ns.Menu.savePrompt then
        ns.Menu.savePrompt:Hide()
    end
    if ns.Menu.resetPrompt then
        ns.Menu.resetPrompt:Hide()
    end
    if ns.Menu.deletePrompt then
        ns.Menu.deletePrompt:Hide()
    end
    ns.EditMode.Stop()
    if ns.Menu.frame then
        ns.Menu.frame:Hide()
    end
end

function ns.Menu.RequestClose()
    ns.Menu.ConfirmLeave(function()
        ns.Menu.HideConfirmed()
    end)
end

function ns.Menu.SwitchProfile(name)
    if name == ns.GetActiveProfileName() then
        return true
    end
    ns.Menu.ConfirmLeave(function()
        if not ns.SetActiveProfile(name) then
            return
        end
        if ns.EditMode.IsActive() then
            ns.EditMode.Cancel()
        end
        ns.Menu.Refresh()
    end)
end

function ns.Menu.SetScope(scope)
    if ns.EditMode.IsActive() then
        ns.EditMode.Cancel()
    end
    ns.Menu.scope = scope
    ns.Menu.Refresh()
end

function ns.Menu.SetTab(tab)
    if ns.EditMode.IsActive() and tab ~= ns.Menu.tab then
        ns.EditMode.Cancel()
    end
    ns.Menu.tab = tab
    ns.Menu.Refresh()
end

local function SubmitProfileModal()
    local modal = ns.Menu.profileModal
    if not modal then
        return
    end
    local name = strtrim(modal.box:GetText() or "")
    if name == "" then
        print(ns.PREFIX .. " Enter a profile name.")
        return
    end
    ns.Menu.CommitCurrentProfile()
    if ns.SaveProfileAs(name) then
        modal:Hide()
        ns.Menu.SetScope("global")
        print(ns.PREFIX .. " Now using profile " .. name .. ".")
    else
        print(ns.PREFIX .. " A profile named " .. name .. " already exists.")
    end
end

function ns.Menu.OpenProfileModal(mode)
    ns.Menu.ConfirmLeave(function()
        local modal = ns.Menu.profileModal
        if not modal then
            return
        end
        modal.mode = mode or "new"
        if modal.mode == "clone" then
            modal.title:SetText("Clone profile")
            modal.note:SetText("Copies this profile, then switches to the new one.")
        else
            modal.title:SetText("New profile")
            modal.note:SetText("Creates a new profile from the current one, then switches to it.")
        end
        modal.box:SetText(ns.SuggestedProfileName())
        modal:Show()
        modal.box:SetFocus()
        modal.box:HighlightText()
    end)
end

function ns.Menu.OpenSavePrompt()
    local prompt = ns.Menu.savePrompt
    if not prompt then
        return
    end
    local name = ns.GetActiveProfileName()
    prompt.note:SetText("Save changes to " .. name .. " before leaving?")
    prompt:Show()
end

local function CreateSavePrompt()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local prompt = CreateFrame("Frame", ADDON_NAME .. "SavePrompt", UIParent, template)
    prompt:SetSize(380, 150)
    prompt:SetPoint("CENTER")
    prompt:SetFrameStrata("FULLSCREEN_DIALOG")
    prompt:SetFrameLevel(130)
    prompt:EnableMouse(true)
    prompt:Hide()
    ApplyBackdrop(prompt)
    tinsert(UISpecialFrames, prompt:GetName())

    local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("Unsaved changes")

    local note = prompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    note:SetPoint("TOP", title, "BOTTOM", 0, -12)
    note:SetWidth(320)
    note:SetJustifyH("CENTER")
    prompt.note = note

    local save = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    save:SetSize(90, 22)
    save:SetPoint("BOTTOM", -100, 18)
    save:SetText("Save")
    save:SetScript("OnClick", function()
        ns.Menu.FinishLeave("save")
    end)

    local discard = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    discard:SetSize(100, 22)
    discard:SetPoint("BOTTOM", 0, 18)
    discard:SetText("Don't Save")
    discard:SetScript("OnClick", function()
        ns.Menu.FinishLeave("discard")
    end)

    local cancel = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    cancel:SetSize(90, 22)
    cancel:SetPoint("BOTTOM", 100, 18)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        ns.Menu.FinishLeave("cancel")
    end)

    prompt:SetScript("OnHide", function()
        if ns.Menu.pendingLeave then
            ns.Menu.pendingLeave = nil
        end
    end)

    ns.Menu.savePrompt = prompt
    return prompt
end

function ns.Menu.OpenResetPrompt()
    local prompt = ns.Menu.resetPrompt
    if not prompt then
        return
    end
    local name = ns.GetActiveProfileName()
    prompt.note:SetText("Reset " .. name .. " to default settings?")
    prompt:Show()
end

local function CreateResetPrompt()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local prompt = CreateFrame("Frame", ADDON_NAME .. "ResetPrompt", UIParent, template)
    prompt:SetSize(380, 150)
    prompt:SetPoint("CENTER")
    prompt:SetFrameStrata("FULLSCREEN_DIALOG")
    prompt:SetFrameLevel(130)
    prompt:EnableMouse(true)
    prompt:Hide()
    ApplyBackdrop(prompt)
    tinsert(UISpecialFrames, prompt:GetName())

    local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("Reset to defaults")

    local note = prompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    note:SetPoint("TOP", title, "BOTTOM", 0, -12)
    note:SetWidth(320)
    note:SetJustifyH("CENTER")
    prompt.note = note

    local reset = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    reset:SetSize(90, 22)
    reset:SetPoint("BOTTOM", -52, 18)
    reset:SetText("Reset")
    reset:SetScript("OnClick", function()
        prompt:Hide()
        if ns.ResetActiveProfile() then
            if ns.EditMode.IsActive() then
                ns.EditMode.Refresh()
            end
            ns.Menu.Refresh()
            print(ns.PREFIX .. " Reset " .. ns.GetActiveProfileName() .. " to defaults.")
        end
    end)

    local cancel = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    cancel:SetSize(90, 22)
    cancel:SetPoint("BOTTOM", 52, 18)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        prompt:Hide()
    end)

    ns.Menu.resetPrompt = prompt
    return prompt
end

function ns.Menu.OpenDeletePrompt()
    local prompt = ns.Menu.deletePrompt
    if not prompt then
        return
    end
    local name = ns.GetActiveProfileName()
    prompt.note:SetText("Delete " .. name .. "? This cannot be undone.")
    prompt:Show()
end

local function CreateDeletePrompt()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local prompt = CreateFrame("Frame", ADDON_NAME .. "DeletePrompt", UIParent, template)
    prompt:SetSize(380, 150)
    prompt:SetPoint("CENTER")
    prompt:SetFrameStrata("FULLSCREEN_DIALOG")
    prompt:SetFrameLevel(130)
    prompt:EnableMouse(true)
    prompt:Hide()
    ApplyBackdrop(prompt)
    tinsert(UISpecialFrames, prompt:GetName())

    local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("Delete profile")

    local note = prompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    note:SetPoint("TOP", title, "BOTTOM", 0, -12)
    note:SetWidth(320)
    note:SetJustifyH("CENTER")
    prompt.note = note

    local delete = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    delete:SetSize(90, 22)
    delete:SetPoint("BOTTOM", -52, 18)
    delete:SetText("Delete")
    delete:SetScript("OnClick", function()
        prompt:Hide()
        local name = ns.GetActiveProfileName()
        local _, action = ns.DeleteActiveProfile()
        if action == "deleted" then
            print(ns.PREFIX .. " Deleted profile " .. name .. ".")
        end
        if ns.EditMode.IsActive() then
            ns.EditMode.Refresh()
        end
        ns.Menu.Refresh()
    end)

    local cancel = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    cancel:SetSize(90, 22)
    cancel:SetPoint("BOTTOM", 52, 18)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        prompt:Hide()
    end)

    ns.Menu.deletePrompt = prompt
    return prompt
end

local function CreateProfileModal()
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local modal = CreateFrame("Frame", ADDON_NAME .. "ProfileModal", UIParent, template)
    modal:SetSize(360, 180)
    modal:SetPoint("CENTER")
    modal:SetFrameStrata("FULLSCREEN_DIALOG")
    modal:SetFrameLevel(120)
    modal:EnableMouse(true)
    modal:Hide()
    ApplyBackdrop(modal)
    tinsert(UISpecialFrames, modal:GetName())

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    modal.title = title

    local note = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOP", title, "BOTTOM", 0, -8)
    note:SetWidth(300)
    note:SetJustifyH("CENTER")
    modal.note = note

    local box = CreateFrame("EditBox", ADDON_NAME .. "ProfileModalName", modal, "InputBoxTemplate")
    box:SetSize(250, 22)
    box:SetPoint("TOP", 0, -86)
    box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", SubmitProfileModal)
    box:SetScript("OnEscapePressed", function()
        modal:Hide()
    end)
    modal.box = box

    local create = CreateFrame("Button", nil, modal, "UIPanelButtonTemplate")
    create:SetSize(80, 22)
    create:SetPoint("BOTTOM", -48, 18)
    create:SetText("Create")
    create:SetScript("OnClick", SubmitProfileModal)

    local cancel = CreateFrame("Button", nil, modal, "UIPanelButtonTemplate")
    cancel:SetSize(80, 22)
    cancel:SetPoint("BOTTOM", 48, 18)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        modal:Hide()
    end)

    ns.Menu.profileModal = modal
    return modal
end

function ns.Menu.Create()
    if ns.Menu.frame then
        return ns.Menu.frame
    end

    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", ADDON_NAME .. "Config", UIParent, template)
    frame:SetSize(520, 700)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    ApplyBackdrop(frame)
    tinsert(UISpecialFrames, frame:GetName())
    frame:SetScript("OnShow", ns.Menu.Refresh)
    frame:SetScript("OnHide", function()
        if ns.Menu.hidingConfirmed then
            ns.Menu.hidingConfirmed = false
            if ns.Menu.profileModal then
                ns.Menu.profileModal:Hide()
            end
            if ns.Menu.savePrompt then
                ns.Menu.savePrompt:Hide()
            end
            if ns.Menu.resetPrompt then
                ns.Menu.resetPrompt:Hide()
            end
            if ns.Menu.deletePrompt then
                ns.Menu.deletePrompt:Hide()
            end
            return
        end
        if ns.IsProfileDirty() then
            local function reshow()
                if ns.Menu.frame then
                    ns.Menu.frame:Show()
                end
                ns.Menu.RequestClose()
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0, reshow)
            else
                reshow()
            end
            return
        end
        if ns.Menu.profileModal then
            ns.Menu.profileModal:Hide()
        end
        ns.EditMode.Stop()
    end)

    local widgets = { scopes = {}, content = {} }
    ns.Menu.widgets = widgets

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(ns.IS_DEV and "Tooltip+ (dev)" or "Tooltip+")

    local tabSettings = CreateTab(frame, "Settings", 88)
    tabSettings:SetPoint("TOPLEFT", 20, -42)
    tabSettings:SetScript("OnClick", function()
        ns.Menu.SetTab("settings")
    end)
    widgets.tabSettings = tabSettings

    local tabTooltip = CreateTab(frame, "Tooltips", 88)
    tabTooltip:SetPoint("LEFT", tabSettings, "RIGHT", 4, 0)
    tabTooltip:SetScript("OnClick", function()
        ns.Menu.SetTab("tooltip")
    end)
    widgets.tabTooltip = tabTooltip

    local tabRule = frame:CreateTexture(nil, "ARTWORK")
    tabRule:SetPoint("TOPLEFT", 24, -68)
    tabRule:SetPoint("TOPRIGHT", -24, -68)
    tabRule:SetHeight(1)
    if tabRule.SetColorTexture then
        tabRule:SetColorTexture(0.45, 0.38, 0.24, 0.85)
    else
        tabRule:SetTexture(1, 1, 1, 0.2)
    end

    local settingsPanel = CreateFrame("Frame", nil, frame)
    settingsPanel:SetPoint("TOPLEFT", 16, -74)
    settingsPanel:SetPoint("BOTTOMRIGHT", -16, 44)
    widgets.settingsPanel = settingsPanel

    local tooltipPanel = CreateFrame("Frame", nil, frame)
    tooltipPanel:SetPoint("TOPLEFT", 16, -74)
    tooltipPanel:SetPoint("BOTTOMRIGHT", -16, 44)
    tooltipPanel:Hide()
    widgets.tooltipPanel = tooltipPanel

    local addonToggle = CreateOnOff(settingsPanel, "Tooltip+", function()
        return ns.GetAddonEnabled()
    end, function(checked)
        ns.SetAddonEnabled(checked)
    end, "Turn Tooltip+ on or off")
    addonToggle:SetPoint("TOPLEFT", 8, -12)
    widgets.addonToggle = addonToggle

    local iconToggle = CreateOnOff(settingsPanel, "Minimap Icon", function()
        return ns.GetMinimapShown()
    end, function(checked)
        ns.SetMinimapShown(checked)
    end, "Turn the anchored minimap icon on or off")
    iconToggle:SetPoint("TOPLEFT", 8, -48)
    widgets.iconToggle = iconToggle

    local profileLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    profileLabel:SetPoint("TOPLEFT", 8, -4)
    profileLabel:SetText("Profile")
    widgets.profileLabel = profileLabel

    local dropdown = CreateProfileDropdown(tooltipPanel)
    dropdown:SetPoint("TOPRIGHT", -8, -2)
    widgets.profileDropdown = dropdown

    local newBtn = CreateIconButton(
        tooltipPanel,
        "New",
        "Interface\\Buttons\\UI-PlusButton-Up",
        "Interface\\Buttons\\UI-PlusButton-Down"
    )
    newBtn:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -4)
    newBtn:SetScript("OnClick", function()
        ns.Menu.OpenProfileModal("new")
    end)
    widgets.newBtn = newBtn

    local reset = CreateIconButton(
        tooltipPanel,
        "Reset",
        "Interface\\Buttons\\UI-RefreshButton"
    )
    reset:SetPoint("RIGHT", newBtn, "LEFT", -4, 0)
    reset:SetScript("OnClick", function()
        ns.Menu.OpenResetPrompt()
    end)
    widgets.reset = reset

    local clone = CreateIconButton(
        tooltipPanel,
        "Clone",
        "Interface\\Buttons\\UI-GuildButton-PublicNote-Up",
        "Interface\\Buttons\\UI-GuildButton-PublicNote-Down"
    )
    clone:SetPoint("RIGHT", reset, "LEFT", -4, 0)
    clone:Hide()
    clone:SetScript("OnClick", function()
        ns.Menu.OpenProfileModal("clone")
    end)
    widgets.clone = clone

    local delete = CreateIconButton(
        tooltipPanel,
        "Delete",
        "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
        "Interface\\Buttons\\UI-GroupLoot-Pass-Down"
    )
    delete:SetPoint("RIGHT", clone, "LEFT", -4, 0)
    delete:Hide()
    delete:SetScript("OnClick", function()
        ns.Menu.OpenDeletePrompt()
    end)
    widgets.delete = delete

    CreateProfileModal()
    CreateSavePrompt()
    CreateResetPrompt()
    CreateDeletePrompt()

    local tooltipLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tooltipLabel:SetPoint("TOPLEFT", 8, -82)
    tooltipLabel:SetText("Tooltip")
    widgets.tooltipLabel = tooltipLabel

    local scopeDropdown = CreateChoiceDropdown(tooltipPanel, ADDON_NAME .. "TypeDropDown", 240, function()
        local options = { { id = "global", label = "Global" } }
        for i = 1, #ns.TYPE_ORDER do
            local id = ns.TYPE_ORDER[i]
            options[#options + 1] = { id = id, label = ns.TYPE_LABELS[id] or id }
        end
        return options
    end, function()
        return ns.Menu.scope
    end, function(value)
        ns.Menu.SetScope(value)
    end)
    scopeDropdown:SetPoint("LEFT", tooltipLabel, "RIGHT", 8, -2)
    widgets.scopeDropdown = scopeDropdown

    widgets.tooltipGroup = CreateSectionBox(tooltipPanel, 0)
    widgets.positionGroup = CreateSectionBox(tooltipPanel, 1)
    widgets.contentGroup = CreateSectionBox(tooltipPanel, 1)
    widgets.fadeGroup = CreateSectionBox(tooltipPanel, 1)

    local overridePosition = AddBareCheck(tooltipPanel)
    overridePosition:SetPoint("TOPLEFT", 2, -100)
    BindCheck(overridePosition, function()
        return ns.GetTypeConfig(ns.Menu.scope).overridePosition
    end, function(checked)
        if checked then
            ns.BeginPositionOverride(ns.Menu.scope)
        else
            ns.GetTypeConfig(ns.Menu.scope).overridePosition = false
        end
    end)
    widgets.overridePosition = overridePosition

    local modeLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    modeLabel:SetPoint("LEFT", overridePosition, "RIGHT", 2, 1)
    modeLabel:SetText("Position")
    widgets.modeLabel = modeLabel
    widgets.modeLabelHit = CreateLabelHit(tooltipPanel, "Override Global Position Settings")

    local mode = CreateChoiceDropdown(tooltipPanel, ADDON_NAME .. "PositionDropDown", 150, function()
        local options = {}
        for i = 1, #ns.MODES do
            local id = ns.MODES[i]
            options[i] = { id = id, label = ns.MODE_LABELS[id] or id }
        end
        return options
    end, function()
        return ns.GetPositionSource(ns.Menu.scope ~= "global" and ns.Menu.scope or nil).mode
    end, function(value)
        ns.SetPositionField(ns.Menu.scope, "mode", value)
        ns.Menu.Refresh()
    end)
    mode:SetPoint("TOPLEFT", 12, -134)
    widgets.mode = mode

    local cornerLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cornerLabel:SetPoint("LEFT", mode, "RIGHT", 16, 0)
    cornerLabel:SetText("Corner:")
    widgets.cornerLabel = cornerLabel

    local corner = CreateChoiceDropdown(tooltipPanel, ADDON_NAME .. "CornerDropDown", 150, function()
        local options = {}
        for i = 1, #ns.CORNER_ORDER do
            local id = ns.CORNER_ORDER[i]
            options[i] = { id = id, label = ns.CORNER_LABELS[id] or id }
        end
        return options
    end, function()
        return ns.GetPositionSource(ns.Menu.scope ~= "global" and ns.Menu.scope or nil).corner
    end, function(value)
        ns.SetPositionField(ns.Menu.scope, "corner", value)
        ns.Menu.Refresh()
    end)
    corner:SetPoint("LEFT", cornerLabel, "RIGHT", 8, 0)
    widgets.corner = corner

    local offsetXLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    offsetXLabel:SetPoint("TOPLEFT", 8, -270)
    offsetXLabel:SetText("X")
    widgets.offsetXLabel = offsetXLabel
    widgets.offsetXHit = CreateLabelHit(tooltipPanel, "X offset from cursor")

    local offsetX = CreateOffsetBox(tooltipPanel, ADDON_NAME .. "OffsetX", "offsetX")
    offsetX:SetPoint("LEFT", offsetXLabel, "RIGHT", 30, 0)
    AttachSteppers(offsetX, "offsetX")
    widgets.offsetX = offsetX

    local offsetYLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    offsetYLabel:SetPoint("LEFT", offsetX.plus, "RIGHT", 16, 0)
    offsetYLabel:SetText("Y")
    widgets.offsetYLabel = offsetYLabel
    widgets.offsetYHit = CreateLabelHit(tooltipPanel, "Y offset from cursor")

    local offsetY = CreateOffsetBox(tooltipPanel, ADDON_NAME .. "OffsetY", "offsetY")
    offsetY:SetPoint("LEFT", offsetYLabel, "RIGHT", 30, 0)
    AttachSteppers(offsetY, "offsetY")
    widgets.offsetY = offsetY

    local pointXLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pointXLabel:SetPoint("TOPLEFT", 8, -270)
    pointXLabel:SetText("X")
    widgets.pointXLabel = pointXLabel

    local pointX = CreateOffsetBox(tooltipPanel, ADDON_NAME .. "PointX", "pointX")
    pointX:SetPoint("LEFT", pointXLabel, "RIGHT", 30, 0)
    AttachSteppers(pointX, "pointX")
    widgets.pointX = pointX

    local pointYLabel = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pointYLabel:SetPoint("LEFT", pointX.plus, "RIGHT", 16, 0)
    pointYLabel:SetText("Y")
    widgets.pointYLabel = pointYLabel

    local pointY = CreateOffsetBox(tooltipPanel, ADDON_NAME .. "PointY", "pointY")
    pointY:SetPoint("LEFT", pointYLabel, "RIGHT", 30, 0)
    AttachSteppers(pointY, "pointY")
    widgets.pointY = pointY

    local edit = CreateFrame("Button", nil, tooltipPanel, "UIPanelButtonTemplate")
    edit:SetSize(176, 22)
    edit:SetPoint("TOPLEFT", 8, -294)
    widgets.edit = edit
    edit:SetScript("OnClick", function()
        ns.EditMode.Start(ns.Menu.scope)
    end)

    local overrideContent = AddBareCheck(tooltipPanel)
    overrideContent:SetPoint("TOPLEFT", 2, -206)
    BindCheck(overrideContent, function()
        return ns.GetTypeConfig(ns.Menu.scope).overrideContent
    end, function(checked)
        if checked then
            ns.BeginContentOverride(ns.Menu.scope)
        else
            ns.GetTypeConfig(ns.Menu.scope).overrideContent = false
        end
    end)
    widgets.overrideContent = overrideContent

    local contentTitle = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    contentTitle:SetPoint("LEFT", overrideContent, "RIGHT", 2, 1)
    contentTitle:SetText("Content")
    widgets.contentTitle = contentTitle
    widgets.contentTitleHit = CreateLabelHit(tooltipPanel, "Override Global Content Settings")

    local y = -352
    for i = 1, #ns.CONTENT_KEYS do
        local spec = ns.CONTENT_KEYS[i]
        local box = AddCheck(tooltipPanel, spec.label)
        box:SetPoint("TOPLEFT", 36, y)
        BindCheck(box, function()
            return ns.GetContentSource(ns.Menu.scope ~= "global" and ns.Menu.scope or nil)[spec.key]
        end, function(checked)
            ns.SetContentField(ns.Menu.scope, spec.key, checked)
        end)
        widgets.content[spec.key] = box
        y = y - 22
    end

    local overrideFade = AddBareCheck(tooltipPanel)
    overrideFade:SetPoint("TOPLEFT", 2, -206)
    BindCheck(overrideFade, function()
        return ns.GetTypeConfig(ns.Menu.scope).overrideFade
    end, function(checked)
        if checked then
            ns.BeginFadeOverride(ns.Menu.scope)
        else
            ns.GetTypeConfig(ns.Menu.scope).overrideFade = false
        end
    end)
    widgets.overrideFade = overrideFade

    local fadeTitle = tooltipPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fadeTitle:SetPoint("LEFT", overrideFade, "RIGHT", 2, 1)
    fadeTitle:SetText("Fade")
    widgets.fadeTitle = fadeTitle
    widgets.fadeTitleHit = CreateLabelHit(tooltipPanel, "Override Global Fade Settings")

    local fadeLabel = widgets.fadeGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fadeLabel:SetText("Seconds")
    widgets.fadeLabel = fadeLabel
    local fadeDisabled = widgets.fadeGroup:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    fadeDisabled:SetText("(disabled)")
    widgets.fadeDisabled = fadeDisabled
    widgets.fadeHit = CreateLabelHit(widgets.fadeGroup, "Fade time in seconds. 0 hides immediately.")

    local fadeBox = CreateFadeBox(widgets.fadeGroup, ADDON_NAME .. "FadeSeconds")
    fadeBox:SetPoint("LEFT", fadeLabel, "RIGHT", 30, 0)
    AttachFadeSteppers(fadeBox)
    widgets.fadeBox = fadeBox

    local save = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    save:SetSize(70, 22)
    save:SetPoint("BOTTOMRIGHT", -20, 16)
    save:SetText("Save")
    save:Disable()
    save:SetScript("OnClick", function()
        ns.Menu.CommitCurrentProfile()
        if ns.SaveDraft() then
            print(ns.PREFIX .. " Saved profile " .. ns.GetActiveProfileName() .. ".")
        end
        ns.Menu.Refresh()
    end)
    widgets.save = save

    local close
    local ok, btn = pcall(CreateFrame, "Button", ADDON_NAME .. "Close", frame, "UIPanelCloseButton")
    if ok and btn then
        close = btn
    else
        close = CreateFrame("Button", nil, frame)
        close:SetSize(24, 24)
        local mark = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        mark:SetPoint("CENTER", 1, 0)
        mark:SetText("X")
    end
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function()
        ns.Menu.RequestClose()
    end)
    close:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Close")
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", GameTooltip_Hide)
    widgets.close = close

    ns.Menu.frame = frame
    return frame
end

function ns.Menu.Toggle()
    local frame = ns.Menu.Create()
    if frame:IsShown() then
        ns.Menu.RequestClose()
    else
        frame:Show()
    end
end
