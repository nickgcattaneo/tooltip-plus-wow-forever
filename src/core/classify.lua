local ADDON_NAME, ns = ...

ns.Classify = ns.Classify or {}

local detectors = {}

local function FrameName(frame)
    if not frame then
        return ""
    end
    local ok, name = pcall(frame.GetName, frame)
    if not ok or type(name) ~= "string" then
        return ""
    end
    return name
end

local function WalkNames(frame, depth)
    depth = depth or 0
    local names = {}
    local current = frame
    while current and depth < 6 do
        local name = FrameName(current)
        if name ~= "" then
            names[#names + 1] = name
        end
        local ok, parent = pcall(current.GetParent, current)
        if not ok then
            break
        end
        current = parent
        depth = depth + 1
    end
    return names
end

function ns.Classify.FrameName(frame)
    return FrameName(frame)
end

function ns.Classify.AncestorNames(frame)
    return WalkNames(frame)
end

function ns.Classify.NameMatches(frame, patterns)
    local names = WalkNames(frame)
    for i = 1, #names do
        local name = names[i]
        for j = 1, #patterns do
            if name:find(patterns[j]) then
                return true
            end
        end
    end
    return false
end

function ns.Classify.Register(detector)
    detectors[#detectors + 1] = detector
    table.sort(detectors, function(a, b)
        return (a.priority or 50) < (b.priority or 50)
    end)
end

function ns.Classify.All()
    return detectors
end

function ns.Classify.FromOwner(tooltip, parent)
    for i = 1, #detectors do
        local detector = detectors[i]
        if detector.detect and detector.detect(tooltip, parent) then
            return detector.id
        end
    end
    return nil
end

function ns.Classify.FromDataType(dataType)
    local types = Enum and Enum.TooltipDataType
    if not types or dataType == nil then
        return nil
    end
    if dataType == types.Object or dataType == types.Corpse then
        return ns.TYPE.WORLD
    end
    return nil
end

function ns.Classify.FromTooltip(tooltip, parent)
    local byOwner = ns.Classify.FromOwner(tooltip, parent)
    if byOwner and ns.IsConfiguredType(byOwner) then
        return byOwner
    end

    local dataType
    if tooltip and tooltip.GetTooltipData then
        local ok, data = pcall(tooltip.GetTooltipData, tooltip)
        if ok and type(data) == "table" then
            dataType = data.type
        end
    end
    local byData = ns.Classify.FromDataType(dataType)
    if byData and ns.IsConfiguredType(byData) then
        return byData
    end

    if ns.IsConfiguredType(ns.TYPE.WORLD) and (parent == UIParent or parent == WorldFrame) then
        if tooltip and tooltip.GetUnit then
            local ok, name, unit = pcall(tooltip.GetUnit, tooltip)
            if ok then
                if type(issecretvalue) == "function" and (issecretvalue(name) or issecretvalue(unit)) then
                    return ns.TYPE.WORLD
                end
                if type(unit) == "string" and unit ~= "" and not unit:find("^nameplate") then
                    return ns.TYPE.WORLD
                end
            end
        end
    end
    return nil
end
