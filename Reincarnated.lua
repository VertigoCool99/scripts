--[[
	Reincarnated - Project Vertigo Style
	Inspired by Miners Haven automation scripts
]]

-- Remote Bypass System
local Communicator = require(game:GetService("ReplicatedStorage"):WaitForChild("Libraries"):WaitForChild("Communicator"))
local RemoteCache = {}
local originalListener = Communicator.listenerFunction
local old; old = hookfunction(originalListener, function(name)
    local result = old(name)
    RemoteCache[name] = result
    print("📡 Remote cached:", name)
    return result
end)

local function GetRemote(name)
    if RemoteCache[name] then return RemoteCache[name] end
    local success, remote = pcall(function() return Communicator.listenerFunction(name) end)
    if success and remote then
        RemoteCache[name] = remote
        return remote
    end
    return nil
end

local function CallRemote(name, ...)
    local remote = GetRemote(name)
    if not remote then error("Remote not found: " .. name) end
    local mt = getmetatable(remote)
    if not mt or not mt.__index or not mt.__index.Invoke then
        error("Remote has no Invoke method: " .. name)
    end
    return mt.__index.Invoke(remote, ...)
end

-- Libs
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = Library.Options
local Toggles = Library.Toggles

-- Window (single tab only)
local Window = Library:CreateWindow({
    Title = 'Reincarnated',
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    UnlockMouseWhileOpen = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Single tab for everything
local MainTab = Window:AddTab('Main')
local UISettingsTab = Window:AddTab('UI Settings')

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Modules
local SuffixModule = require(game:GetService("ReplicatedStorage").Libraries.Suffix)
local ProgressionModule = require(game:GetService("ReplicatedStorage").Libraries.Progression)
local DataModule = require(game:GetService("ReplicatedFirst").Client.Libraries.Data)

-- Settings
local Settings = {
    -- Ore Boost
    OreBoostLoop = false,
    BoostCycles = 6,
    
    -- Rebirth
    AutoRebirth = false,
    RebirthDelay = 10,
    LoadBlueprint = false,
    BlueprintSlot = 1,
    NextBlueprintSlot = 2,
    ReloadBlueprint = false,
    ReloadDelay = 5,
    
    -- Crates
    CrateFarm = false,
    HighlightCrates = false,
}

-- ============== UTILITY FUNCTIONS ==============

local function getTycoon()
    for i, v in pairs(workspace.Game.Bases:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then
            return v
        end
    end
    return nil
end

local function getTycoonCenter()
    local tycoon = getTycoon()
    if not tycoon then return nil end
    return tycoon:FindFirstChild("Center") or tycoon:FindFirstChild("Spawn") or tycoon
end

local function getOres()
    local tycoon = getTycoon()
    if not tycoon then return {} end
    local ores = tycoon:FindFirstChild("Ores")
    return ores and ores:GetChildren() or {}
end

local function getUpgraders()
    local tycoon = getTycoon()
    if not tycoon then return {} end
    local items = tycoon:FindFirstChild("Items")
    if not items then return {} end
    
    local upgraders = {}
    for _, item in pairs(items:GetChildren()) do
        local model = item:FindFirstChild("Model")
        if model and model:FindFirstChild("Upgrade") then
            table.insert(upgraders, model.Upgrade)
        end
    end
    return upgraders
end

local function getFurnace()
    local tycoon = getTycoon()
    if not tycoon then return nil end
    local items = tycoon:FindFirstChild("Items")
    if not items then return nil end
    
    for _, item in pairs(items:GetChildren()) do
        local model = item:FindFirstChild("Model")
        if model and model:FindFirstChild("Process") and not model:FindFirstChild("Conv") then
            return model.Process
        end
    end
    return nil
end

-- ============== ORE BOOST SYSTEM ==============

local function boostOres(cycles)
    cycles = cycles or Settings.BoostCycles
    local ores = getOres()
    local upgraders = getUpgraders()
    local furnace = getFurnace()
    
    if #ores == 0 then return end
    
    -- Boost with upgraders
    if #upgraders > 0 then
        for cycle = 1, cycles do
            for _, ore in pairs(ores) do
                if ore:IsA("BasePart") then
                    for _, upgrader in ipairs(upgraders) do
                        firetouchinterest(ore, upgrader, 0)
                        firetouchinterest(ore, upgrader, 1)
                    end
                end
            end
            if cycle < cycles then task.wait(0.05) end
        end
    end
    
    -- Process with furnace
    if furnace then
        for _, ore in pairs(ores) do
            if ore:IsA("BasePart") then
                firetouchinterest(ore, furnace, 0)
                firetouchinterest(ore, furnace, 1)
                task.wait()
            end
        end
    end
end

local function oreBoostLoop()
    while Settings.OreBoostLoop do
        boostOres(Settings.BoostCycles)
        task.wait(2)
    end
end

-- ============== REBIRTH SYSTEM ==============

local function canRebirth()
    local data = DataModule.GetData()
    local reincarnations = data.GameStats.Reincarnation
    local money = data.Currencies.Money
    local price = ProgressionModule.CalculateReincarnationPrice(nil, reincarnations)
    
    local moneyNum = SuffixModule.GetInput(tostring(money))
    local priceNum = SuffixModule.GetInput(tostring(price))
    
    return moneyNum >= priceNum, moneyNum, priceNum
end

local function doRebirth()
    local available = canRebirth()
    if not available then return false end
    
    print("💰 Attempting rebirth...")
    Library:Notify("💰 Attempting rebirth...")
    
    local success = pcall(function() CallRemote("Reincarnate") end)
    
    if success then
        print("✅ Rebirth successful!")
        Library:Notify("✅ Rebirth successful!")
        
        task.wait(3)
        
        if Settings.LoadBlueprint then
            local loadSuccess = pcall(function() CallRemote("LoadBlueprint", Settings.BlueprintSlot) end)
            if loadSuccess then
                print("✅ Blueprint " .. Settings.BlueprintSlot .. " loaded")
                Library:Notify("✅ Blueprint " .. Settings.BlueprintSlot .. " loaded")
                
                if Settings.ReloadBlueprint then
                    task.wait(Settings.ReloadDelay)
                    pcall(function() CallRemote("LoadBlueprint", Settings.NextBlueprintSlot) end)
                    print("✅ Blueprint reloaded")
                end
            end
        end
        return true
    else
        print("❌ Rebirth failed")
        Library:Notify("❌ Rebirth failed")
        return false
    end
end

local function rebirthLoop()
    while Settings.AutoRebirth do
        doRebirth()
        task.wait(Settings.RebirthDelay)
    end
end

-- ============== CRATE SYSTEM ==============

local function findCrates()
    local dump = workspace:FindFirstChild("Dump")
    if not dump then return {} end
    
    local crates = {}
    for _, v in pairs(dump:GetDescendants()) do
        if v:IsA("BasePart") and string.find(v.Name:lower(), "crate") then
            table.insert(crates, v)
        end
    end
    return crates
end

local function collectCrates()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local center = getTycoonCenter()
    if not center then return end
    
    local crates = findCrates()
    if #crates == 0 then return end
    
    Library:Notify("📦 Found " .. #crates .. " crates")
    
    for _, crate in ipairs(crates) do
        hrp.CFrame = crate.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
        firetouchinterest(hrp, crate, 0)
        firetouchinterest(hrp, crate, 1)
        task.wait(0.2)
    end
    
    hrp.CFrame = center.CFrame + Vector3.new(0, 5, 0)
    Library:Notify("✅ Crate run complete")
end

local function crateFarmLoop()
    while Settings.CrateFarm do
        collectCrates()
        task.wait(10)
    end
end

-- ============== HIGHLIGHT SYSTEM ==============

local function setupHighlights()
    if not Settings.HighlightCrates then return end
    
    local dump = workspace:FindFirstChild("Dump")
    if not dump then return end
    
    local function addHighlight(obj)
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if not obj:FindFirstChildOfClass("Highlight") then
                local h = Instance.new("Highlight")
                h.Name = "CrateHighlight"
                h.FillColor = Color3.fromRGB(0, 255, 0)
                h.OutlineColor = Color3.fromRGB(0, 200, 0)
                h.FillTransparency = 0.3
                h.Parent = obj
            end
        end
    end
    
    for _, v in pairs(dump:GetDescendants()) do
        if string.find(v.Name:lower(), "crate") then
            addHighlight(v)
        end
    end
    
    dump.DescendantAdded:Connect(function(v)
        task.wait()
        if string.find(v.Name:lower(), "crate") then
            addHighlight(v)
        end
    end)
end

local function removeHighlights()
    local dump = workspace:FindFirstChild("Dump")
    if not dump then return end
    
    for _, v in pairs(dump:GetDescendants()) do
        local h = v:FindFirstChildOfClass("Highlight")
        if h and h.Name == "CrateHighlight" then
            h:Destroy()
        end
    end
end

-- ============== UI CONSTRUCTION ==============
-- All GroupBoxes in the Main Tab

-- Left Column
local OreGroup = MainTab:AddLeftGroupbox('⚡ Ore Boost')
local RebirthGroup = MainTab:AddLeftGroupbox('🔄 Auto Rebirth')
local CrateGroup = MainTab:AddLeftGroupbox('📦 Crate Farming')

-- Right Column
local BlueprintGroup = MainTab:AddRightGroupbox('📋 Blueprint Settings')
local ServerGroup = MainTab:AddRightGroupbox('🌐 Server')
local VisualGroup = MainTab:AddRightGroupbox('🎨 Visuals')

-- ============== ORE BOOST GROUP ==============

OreGroup:AddToggle('OreBoostToggle', {
    Text = 'Ore Boost Loop',
    Default = false,
    Callback = function(v)
        Settings.OreBoostLoop = v
        if v then
            coroutine.wrap(oreBoostLoop)()
            Library:Notify("🔄 Ore boost loop enabled")
        else
            Library:Notify("⏹️ Ore boost loop disabled")
        end
    end
})

OreGroup:AddSlider('BoostCycles', {
    Text = 'Boost Cycles',
    Default = 6,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(v) Settings.BoostCycles = v end
})

OreGroup:AddButton({
    Text = 'Boost Ores Once',
    Func = function() boostOres(Settings.BoostCycles) end
})

-- ============== REBIRTH GROUP ==============

RebirthGroup:AddToggle('AutoRebirthToggle', {
    Text = 'Auto Rebirth',
    Default = false,
    Callback = function(v)
        Settings.AutoRebirth = v
        if v then
            coroutine.wrap(rebirthLoop)()
            Library:Notify("🔄 Auto rebirth enabled")
        else
            Library:Notify("⏹️ Auto rebirth disabled")
        end
    end
})

RebirthGroup:AddSlider('RebirthDelay', {
    Text = 'Check Delay (seconds)',
    Default = 10,
    Min = .1,
    Max = 10,
    Rounding = 1,
    Callback = function(v) Settings.RebirthDelay = v end
})

RebirthGroup:AddDivider()

RebirthGroup:AddButton({
    Text = 'Rebirth Now',
    Func = doRebirth
})

RebirthGroup:AddButton({
    Text = 'Check Rebirth Status',
    Func = function()
        local available, money, price = canRebirth()
        Library:Notify(string.format("Money: %.2f | Price: %.2f | Can rebirth: %s", 
            money, price, available and "✅" or "❌"))
    end
})

-- ============== CRATE GROUP ==============

CrateGroup:AddToggle('CrateFarmToggle', {
    Text = 'Crate Farm Loop',
    Default = false,
    Risky = true,
    Callback = function(v)
        Settings.CrateFarm = v
        if v then
            coroutine.wrap(crateFarmLoop)()
            Library:Notify("📦 Crate farm enabled")
        else
            Library:Notify("📦 Crate farm disabled")
        end
    end
})

CrateGroup:AddButton({
    Text = 'Collect Crates Once',
    Func = collectCrates
})

-- ============== BLUEPRINT GROUP ==============

BlueprintGroup:AddToggle('LoadBlueprintToggle', {
    Text = 'Load Blueprint After Rebirth',
    Default = false,
    Callback = function(v) Settings.LoadBlueprint = v end
})

BlueprintGroup:AddDropdown('BlueprintSlot', {
    Values = {1, 2, 3, 4, 5},
    Default = 1,
    Multi = false,
    Text = 'Blueprint Slot',
    Callback = function(v) Settings.BlueprintSlot = v end
})

BlueprintGroup:AddDropdown('NextBlueprintSlot', {
    Values = {1, 2, 3},
    Default = 1,
    Multi = false,
    Text = 'Blueprint Slot',
    Callback = function(v) Settings.NextBlueprintSlot = v end
})

BlueprintGroup:AddToggle('ReloadBlueprintToggle', {
    Text = 'Reload Blueprint After Delay',
    Default = false,
    Callback = function(v) Settings.ReloadBlueprint = v end
})

BlueprintGroup:AddSlider('ReloadDelay', {
    Text = 'Reload Delay',
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(v) Settings.ReloadDelay = v end
})

BlueprintGroup:AddButton({
    Text = 'Load Blueprint Now',
    Func = function()
        local success = pcall(function() CallRemote("LoadBlueprint", Settings.BlueprintSlot) end)
        Library:Notify(success and "✅ Blueprint loaded" or "❌ Failed to load blueprint")
    end
})

-- ============== SERVER GROUP ==============

ServerGroup:AddButton({
    Text = 'Server Hop [Cache Remotes]',
    Func = function()
        local file = "Reincarnated_Hopped.txt"
        if isfile and isfile(file) then delfile(file) end
        if writefile then writefile(file, "true") end
        
        -- Queue on teleport
        if queue_on_teleport then
            queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/VertigoCool99/scripts/refs/heads/main/Reincarnated.lua"))()')
        end
        
        game:GetService("TeleportService"):Teleport(126642046443487, LocalPlayer)
    end
})

-- ============== VISUAL GROUP ==============

VisualGroup:AddToggle('HighlightCratesToggle', {
    Text = 'Highlight Crates',
    Default = false,
    Callback = function(v)
        Settings.HighlightCrates = v
        if v then
            setupHighlights()
            Library:Notify("🔆 Crate highlights on")
        else
            removeHighlights()
            Library:Notify("🔆 Crate highlights off")
        end
    end
})

-- ============== WATERMARK ==============

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60
local GetPing = function() return math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()) end
local CanDoPing = pcall(GetPing)

RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if tick() - FrameTimer >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('Reincarnated | %d fps | %d ms'):format(FPS, CanDoPing and GetPing() or 0))
end)

-- ============== CLEANUP ==============

Library:OnUnload(function()
    Settings.OreBoostLoop = false
    Settings.AutoRebirth = false
    Settings.CrateFarm = false
    Settings.HighlightCrates = false
    removeHighlights()
    Library.Unloaded = true
end)

-- ============== UI SETTINGS ==============

local MenuGroup = UISettingsTab:AddLeftGroupbox('Menu')

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v) Library.ShowCustomCursor = v end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('Reincarnated')
SaveManager:SetFolder('Reincarnated')
SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

-- ============== INIT ==============

task.spawn(function()
    task.wait(3)
    print("✅ Reincarnated script loaded!")
    Library:Notify("✅ Reincarnated loaded!")
    
    -- Show cached remotes
    print("📡 Cached remotes:")
    for name, _ in pairs(RemoteCache) do
        print("  -", name)
    end
end)
