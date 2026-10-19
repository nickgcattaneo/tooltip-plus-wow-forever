-- Tooltip+ bootstrap. Files listed above this one in the TOC have already
-- attached themselves to the addon table (`ns`). There is no require().

local ADDON_NAME, ns = ...

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, loaded)
    if event ~= "ADDON_LOADED" or loaded ~= ADDON_NAME then
        return
    end
    ns.EnsureDB()
    ns.Menu.Create()
    ns.MinimapButton.Create()
    ns.Content.Hook()
    ns.Fade.Hook()
    self:UnregisterEvent("ADDON_LOADED")
    print(ns.PREFIX .. " loaded. Type " .. ns.SLASH .. " for options.")
end)
