local ADDON_NAME, ns = ...

ns.Fade = ns.Fade or {}

local fading = false
local elapsedFade = 0
local fadeDuration = ns.DEFAULT_FADE
local owning = false

local function Locked(frame)
    return frame.IsForbidden and frame:IsForbidden()
end

local function ResetAlpha(tooltip)
    if tooltip and tooltip.SetAlpha and not Locked(tooltip) then
        tooltip:SetAlpha(1)
    end
end

-- Nil leaves the client fade alone: unmatched tips, disabled types, cursor
-- position, and the default of one second. Cursor hide is instant, so a
-- custom duration is not applied. FadeOut has no duration argument.
local function ResolvedFade(tooltip)
    if not tooltip or Locked(tooltip) then
        return nil
    end
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    local typeId = ns.Classify.FromTooltip(tooltip, owner)
    if not typeId then
        return nil
    end
    local resolved = ns.Resolve(typeId)
    if not resolved.enabled then
        return nil
    end
    local mode = resolved.position and resolved.position.mode or "cursor"
    if mode == "cursor" then
        return nil
    end
    local seconds = ns.ClampFade(resolved.fade)
    if seconds == ns.DEFAULT_FADE then
        return nil
    end
    return seconds
end

-- FadeOut starts a fixed client fade. Show() aborts it and restores opacity.
local function CancelNativeFade(tooltip)
    if tooltip.StopAnimating then
        pcall(tooltip.StopAnimating, tooltip)
    end
    tooltip.fadeOut = nil
    if type(UIFrameFadeRemoveFrame) == "function" then
        pcall(UIFrameFadeRemoveFrame, tooltip)
    end
    owning = true
    tooltip:Show()
    ResetAlpha(tooltip)
    owning = false
end

function ns.Fade.Hook()
    if ns.Fade.hooked or not GameTooltip or not GameTooltip.FadeOut or not GameTooltip.HookScript then
        return
    end
    ns.Fade.hooked = true

    hooksecurefunc(GameTooltip, "FadeOut", function(tooltip)
        if tooltip ~= GameTooltip or owning or Locked(tooltip) then
            return
        end
        local seconds = ResolvedFade(tooltip)
        if seconds == nil then
            return
        end
        if seconds <= 0 then
            fading = false
            tooltip:Hide()
            ResetAlpha(tooltip)
            return
        end
        CancelNativeFade(tooltip)
        if not tooltip:IsShown() then
            fading = false
            return
        end
        fading = true
        elapsedFade = 0
        fadeDuration = seconds
    end)

    GameTooltip:HookScript("OnUpdate", function(tooltip, dt)
        if not fading or Locked(tooltip) then
            return
        end
        if type(dt) ~= "number" or (type(issecretvalue) == "function" and issecretvalue(dt)) then
            return
        end
        if tooltip.IsShown and not tooltip:IsShown() then
            fading = false
            return
        end
        elapsedFade = elapsedFade + dt
        if fadeDuration <= 0 or elapsedFade >= fadeDuration then
            fading = false
            tooltip:Hide()
            ResetAlpha(tooltip)
            return
        end
        tooltip:SetAlpha(1 - (elapsedFade / fadeDuration))
    end)

    GameTooltip:HookScript("OnShow", function(tooltip)
        if owning then
            return
        end
        fading = false
        elapsedFade = 0
        ResetAlpha(tooltip)
    end)

    GameTooltip:HookScript("OnHide", function(tooltip)
        fading = false
        elapsedFade = 0
        ResetAlpha(tooltip)
    end)
end
