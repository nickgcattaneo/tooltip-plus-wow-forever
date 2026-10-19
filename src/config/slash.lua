local ADDON_NAME, ns = ...

local function PrintHelp()
    print(ns.PREFIX .. " commands:")
    print("  " .. ns.SLASH .. "            open the menu")
    print("  " .. ns.SLASH .. " edit")
    print("  " .. ns.SLASH .. " profile")
    print("  " .. ns.SLASH .. " help")
end

local function PrintStatus()
    local profile = ns.GetActiveProfile()
    print(ns.PREFIX .. " profile " .. ns.GetActiveProfileName()
        .. (ns.GetAddonEnabled() and " on" or " off")
        .. ", " .. tostring(profile.position.mode))
    for i = 1, #ns.TYPE_ORDER do
        local typeId = ns.TYPE_ORDER[i]
        local resolved = ns.Resolve(typeId)
        local extra = ns.GetTypeConfig(typeId).overridePosition and " override" or ""
        print("  " .. ns.TYPE_LABELS[typeId] .. ": " .. (resolved.enabled and "on" or "off") .. extra)
    end
end

_G["SLASH_" .. ns.SLASH_KEY .. "1"] = ns.SLASH
_G["SLASH_" .. ns.SLASH_KEY .. "2"] = "/tooltipplus"
SlashCmdList[ns.SLASH_KEY] = function(msg)
    local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = string.lower(cmd or "")

    if cmd == "" or cmd == "config" or cmd == "options" or cmd == "menu" then
        ns.Menu.Toggle()
    elseif cmd == "edit" then
        ns.Menu.Create()
        ns.EditMode.Start(ns.Menu.scope or "global")
    elseif cmd == "profile" then
        local sub, name = (rest or ""):match("^(%S*)%s*(.-)$")
        sub = string.lower(sub or "")
        if sub == "" or sub == "list" then
            print(ns.PREFIX .. " profiles: " .. table.concat(ns.ProfileNames(), ", "))
            print("  active: " .. ns.GetActiveProfileName())
        elseif sub == "use" and name ~= "" then
            ns.Menu.ConfirmLeave(function()
                if ns.SetActiveProfile(name) then
                    print(ns.PREFIX .. " using profile " .. name .. ".")
                    if ns.Menu.frame and ns.Menu.frame:IsShown() then
                        ns.Menu.Refresh()
                    end
                else
                    print(ns.PREFIX .. " no profile named " .. name .. ".")
                end
            end)
        elseif sub == "save" and name == "" then
            ns.Menu.CommitCurrentProfile()
            if ns.SaveDraft() then
                print(ns.PREFIX .. " Saved profile " .. ns.GetActiveProfileName() .. ".")
                if ns.Menu.frame and ns.Menu.frame:IsShown() then
                    ns.Menu.Refresh()
                end
            end
        elseif sub == "save" and name ~= "" then
            ns.Menu.ConfirmLeave(function()
                if ns.SaveProfileAs(name) then
                    print(ns.PREFIX .. " saved profile " .. name .. ".")
                    ns.Menu.SetScope("global")
                else
                    print(ns.PREFIX .. " A profile named " .. name .. " already exists.")
                end
            end)
        else
            print(ns.PREFIX .. " usage: " .. ns.SLASH .. " profile [list|use <name>|save <name>]")
        end
    elseif cmd == "on" then
        ns.SetSetting("enabled", true)
        print(ns.PREFIX .. " enabled.")
    elseif cmd == "off" then
        ns.SetSetting("enabled", false)
        print(ns.PREFIX .. " disabled.")
    elseif cmd == "status" then
        PrintStatus()
    elseif cmd == "help" then
        PrintHelp()
    else
        PrintHelp()
    end
end
