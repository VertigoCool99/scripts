--Remote Bypass
local Communicator = require(game:GetService("ReplicatedStorage"):WaitForChild("Libraries"):WaitForChild("Communicator"))
local RemoteCache = {}
local originalListener = Communicator.listenerFunction
local old; old = hookfunction(originalListener, function(name)
    local result = old(name)
    RemoteCache[name] = result  -- Store in cache
    print("📡 Remote cached:", name)
    return result
end)

local function GetRemote(name)
    if RemoteCache[name] then
        return RemoteCache[name]
    end
    local success, remote = pcall(function()
        return Communicator.listenerFunction(name)
    end)
    
    if success and remote then
        RemoteCache[name] = remote
        return remote
    end
    
    return nil
end

local function CallRemote(name, ...)
    local remote = GetRemote(name)
    if not remote then
        error("Remote not found: " .. name)
    end
    
    local mt = getmetatable(remote)
    if not mt or not mt.__index or not mt.__index.Invoke then
        error("Remote has no Invoke method: " .. name)
    end

    return mt.__index.Invoke(remote, ...)
end

local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

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

local Tabs = {
	Main = Window:AddTab('Main'),
	['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Game services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variables for features
local oreBoostLoopRunning = false
local crateFarmRunning = false
local highlightsEnabled = false
local crateFarmConnection = nil

-- Function to get current Tycoon (fresh each time)
local function getTycoon()
    for i, v in pairs(workspace.Game.Bases:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then
            return v
        end
    end
    return nil
end

-- Highlight system
local function setupHighlights()
    if not highlightsEnabled then return end
    
    local Dump = workspace:FindFirstChild("Dump")
    if not Dump then
        warn("workspace.Dump does not exist")
        return
    end

    -- Function to add highlight to a part/object
    local function addHighlight(object)
        if object:IsA("BasePart") or object:IsA("Model") then
            -- Check if highlight already exists
            if not object:FindFirstChildOfClass("Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "CrateHighlighter"
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.Parent = object
            end
        end
    end

    -- Check all existing descendants
    for _, descendant in pairs(Dump:GetDescendants()) do
        if string.find(descendant.Name:lower(), "crate") then
            addHighlight(descendant)
        end
    end

    -- Event listener for new descendants
    Dump.DescendantAdded:Connect(function(descendant)
        task.wait()
        if string.find(descendant.Name:lower(), "crate") then
            addHighlight(descendant)
        end
    end)
end

-- Remove all highlights
local function removeHighlights()
    local Dump = workspace:FindFirstChild("Dump")
    if not Dump then return end
    
    for _, descendant in pairs(Dump:GetDescendants()) do
        local highlight = descendant:FindFirstChildOfClass("Highlight")
        if highlight and highlight.Name == "CrateHighlighter" then
            highlight:Destroy()
        end
    end
end

-- Boost ores once
local function boostOresOnce()
    local Tycoon = getTycoon()
    
    if not Tycoon then
        Library:Notify("Could not find player's tycoon")
        return
    end
    
    -- Safely get ores
    local OresFolder = Tycoon:FindFirstChild("Ores")
    local ItemsFolder = Tycoon:FindFirstChild("Items")
    
    if not OresFolder or not ItemsFolder then
        Library:Notify("Tycoon missing required folders")
        return
    end
    
    local ores = OresFolder:GetChildren()
    if #ores == 0 then
        Library:Notify("No ores to process")
        return
    end
    
    -- Find upgraders
    local Upgraders = {}
    for i, v in pairs(ItemsFolder:GetChildren()) do
        if v:FindFirstChild("Model") and v.Model:FindFirstChild("Upgrade") then
            table.insert(Upgraders, v.Model.Upgrade)
        end
    end
    
    -- Find furnace
    local Furnace = nil
    for i, v in pairs(ItemsFolder:GetChildren()) do
        if v:FindFirstChild("Model") and v.Model:FindFirstChild("Process") and not v.Model:FindFirstChild("Conv") then
            Furnace = v.Model.Process
            break
        end
    end
    
    -- Only proceed if we have at least an upgrader or furnace
    if #Upgraders == 0 and not Furnace then
        Library:Notify("No upgraders or furnace found")
        return
    end
    
    -- Process ores with upgraders
    if #Upgraders > 0 then
        for spamRound = 1, 5 do
            for i, ore in pairs(ores) do
                if ore:IsA("BasePart") then
                    for j, upgrader in ipairs(Upgraders) do
                        firetouchinterest(ore, upgrader, 0)
                        firetouchinterest(ore, upgrader, 1)
                    end
                end
            end
            task.wait(0.1)
        end
    end
    
    -- Process ores with furnace
    if Furnace then
        for i, ore in pairs(ores) do
            if ore:IsA("BasePart") then
                firetouchinterest(ore, Furnace, 0)
                firetouchinterest(ore, Furnace, 1)
            end
        end
    end
    
    Library:Notify("Ores boosted successfully!")
end

-- Ore boost loop function
local function oreBoostLoop()
    while oreBoostLoopRunning do
        task.wait(4)
        
        local Tycoon = getTycoon()
        
        if not Tycoon then
            warn("Could not find player's tycoon, skipping cycle")
            task.wait(4)
            continue
        end
        
        local OresFolder = Tycoon:FindFirstChild("Ores")
        local ItemsFolder = Tycoon:FindFirstChild("Items")
        
        if not OresFolder or not ItemsFolder then
            warn("Tycoon missing required folders, skipping cycle")
            task.wait(4)
            continue
        end
        
        local ores = OresFolder:GetChildren()
        if #ores == 0 then
            task.wait(4)
            continue
        end
        
        local Upgraders = {}
        for i, v in pairs(ItemsFolder:GetChildren()) do
            if v:FindFirstChild("Model") and v.Model:FindFirstChild("Upgrade") then
                table.insert(Upgraders, v.Model.Upgrade)
            end
        end
        
        local Furnace = nil
        for i, v in pairs(ItemsFolder:GetChildren()) do
            if v:FindFirstChild("Model") and v.Model:FindFirstChild("Process") and not v.Model:FindFirstChild("Conv") then
                Furnace = v.Model.Process
                break
            end
        end
        
        if #Upgraders == 0 and not Furnace then
            warn("No upgraders or furnace found")
            task.wait(4)
            continue
        end
        
        if #Upgraders > 0 then
            for spamRound = 1, 6 do
                for i, ore in pairs(ores) do
                    if ore:IsA("BasePart") then
                        for j, upgrader in ipairs(Upgraders) do
                            firetouchinterest(ore, upgrader, 0)
                            firetouchinterest(ore, upgrader, 1)
                        end
                    end
                end
                task.wait(0.1)
            end
        end
        
        if Furnace then
            for i, ore in pairs(ores) do
                if ore:IsA("BasePart") then
                    firetouchinterest(ore, Furnace, 0)
                    firetouchinterest(ore, Furnace, 1)
                end
            end
        end
    end
end

-- Crate farm function
local function crateFarm()
    if not crateFarmRunning then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local Tycoon = getTycoon()
    if not Tycoon then
        Library:Notify("Could not find player's tycoon")
        crateFarmRunning = false
        return
    end
    
    local TycoonCenter = Tycoon:FindFirstChild("Center")
    if not TycoonCenter then return end
    
    local Dump = workspace:FindFirstChild("Dump")
    if not Dump then
        Library:Notify("No dump found")
        crateFarmRunning = false
        return
    end
    
    -- Find crates
    local crates = {}
    for _, descendant in pairs(Dump:GetDescendants()) do
        if string.find(descendant.Name:lower(), "crate") and descendant:IsA("BasePart") then
            table.insert(crates, descendant)
        end
    end
    
    if #crates == 0 then
        Library:Notify("No crates found")
        task.wait(2)
        return
    end
    
    -- Teleport to each crate
    for _, crate in pairs(crates) do
        if not crateFarmRunning then break end
        
        -- Teleport to crate
        humanoidRootPart.CFrame = crate.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.5)
        
        -- Collect crate (simulate touch)
        firetouchinterest(humanoidRootPart, crate, 0)
        firetouchinterest(humanoidRootPart, crate, 1)
        task.wait(0.5)
    end
    
    -- Return to tycoon
    if crateFarmRunning then
        humanoidRootPart.CFrame = TycoonCenter.CFrame
        Library:Notify("Crate farm completed")
    end
end

-- Start crate farm loop
local function startCrateFarm()
    if crateFarmConnection then
        crateFarmConnection:Disconnect()
        crateFarmConnection = nil
    end
    
    crateFarmConnection = RunService.Heartbeat:Connect(function()
        if crateFarmRunning then
            crateFarm()
            task.wait(5) -- Wait 5 seconds between farm cycles
        end
    end)
end

local OreBoostGroupBox = Tabs.Main:AddLeftGroupbox('Ore Boost')
local ReincanationGroupBox = Tabs.Main:AddLeftGroupbox('Reincanation')
local CratesGroupBox = Tabs.Main:AddLeftGroupbox('Crates')

-- Ore Boost Loop Toggle
OreBoostGroupBox:AddToggle('OreBoostLoopToggle', {
	Text = 'Ore Boost Loop',
	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,
	Callback = function(Value)
		oreBoostLoopRunning = Value
		if Value then
			coroutine.wrap(oreBoostLoop)()
			Library:Notify("Ore Boost Loop: Enabled")
		else
			Library:Notify("Ore Boost Loop: Disabled")
		end
	end
})

-- Boost Once Button
local OreBoostButton = OreBoostGroupBox:AddButton({
	Text = 'Boost Ores Once',
	Func = function()
		boostOresOnce()
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true
})

-- Highlight Crates Toggle
CratesGroupBox:AddToggle('HighlightCrates', {
	Text = 'Highlight Crates',
	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,
	Callback = function(Value)
		highlightsEnabled = Value
		if Value then
			setupHighlights()
			Library:Notify("Crate Highlights: Enabled")
		else
			removeHighlights()
			Library:Notify("Crate Highlights: Disabled")
		end
	end
})

-- Crate Farm Toggle
CratesGroupBox:AddToggle('CrateFarm', {
	Text = 'Crate Farm',
	Default = false,
	Disabled = false,
	Visible = true,
	Risky = true,
	Callback = function(Value)
		crateFarmRunning = Value
		if Value then
			startCrateFarm()
			Library:Notify("Crate Farm: Enabled")
		else
			if crateFarmConnection then
				crateFarmConnection:Disconnect()
				crateFarmConnection = nil
			end
			Library:Notify("Crate Farm: Disabled")
		end
	end
})

-- Collect Crates Once Button
CratesGroupBox:AddButton({
	Text = 'Collect Crates Once',
	Func = function()
		if not crateFarmRunning then
			local oldValue = crateFarmRunning
			crateFarmRunning = true
			crateFarm()
			crateFarmRunning = oldValue
		end
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true
})

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;
local GetPing = (function() return math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()) end)
local CanDoPing = pcall(function() return GetPing(); end)

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
	FrameCounter += 1;

	if (tick() - FrameTimer) >= 1 then
		FPS = FrameCounter;
		FrameTimer = tick();
		FrameCounter = 0;
	end;

	if CanDoPing then
		Library:SetWatermark(('Reincarnated | %d fps | %d ms'):format(
			math.floor(FPS),
			GetPing()
		));
	else
		Library:SetWatermark(('Reincarnated | %d fps'):format(
			math.floor(FPS)
		));
	end
end);

-- Cleanup function
Library:OnUnload(function()
	WatermarkConnection:Disconnect()
	
	-- Stop all features
	oreBoostLoopRunning = false
	crateFarmRunning = false
	highlightsEnabled = false
	
	-- Remove highlights
	removeHighlights()
	
	-- Disconnect crate farm connection
	if crateFarmConnection then
		crateFarmConnection:Disconnect()
		crateFarmConnection = nil
	end
	
	print('Unloaded!')
	Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddToggle("ShowCustomCursor", {Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('Reincarnated')
SaveManager:SetFolder('Reincarnated')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

if queue_on_teleport ~= nil then
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/VertigoCool99/scripts/refs/heads/main/Reincarnated.lua"))()')
end

task.spawn(function()
    task.wait(5)
    print("Cached remotes after 5 seconds:")
    if RemoteCache < 1 then
        game:GetService("TeleportService"):Teleport(126642046443487,game.Players.LocalPlayer)
    end
    for name, _ in pairs(RemoteCache) do
        print("  -", name)
    end
end)
