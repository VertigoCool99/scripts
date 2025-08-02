--Locals
local cloneref = cloneref or function() return end
local Players = cloneref(game:GetService("Players"))
local Character = Players.LocalPlayer.Character
local ClientBuildings = workspace.ClientBuildings
local Ore = workspace.Ore
local PlotMod = require(game:GetService("ReplicatedStorage").Plot.PlotClient)
local HttpService = game:GetService("HttpService")
local GameFunsMod = require(game:GetService("ReplicatedStorage").Tool.Game.GameFunctions)
local UiSrcMod = require(game:GetService("ReplicatedStorage").UISrc.UIModules.PlotActions)
local AutoLoadedPlot = false

--Tables
local Settings = {AutoCrates=false,AutoAllUpgraders=false,AutoOpenCrates=false,AutoSelectedUpgrader=false,SelectedUpgrader="",AutoRebirth=false,PlotName="",AutoPlotUpgrade=false,AutoLoadLayout=false}
local Boxes = {["Regular Box"]=1,["Unreal Box"]=2,["Rebirth Box"]=3}
local PlotList = {}

--Init
assert(listfiles,"Executor Not Supported | Missing listfiles")
assert(readfile,"Executor Not Supported | Missing readfile")
assert(writefile,"Executor Not Supported | Missing writefile")
assert(getupvalues,"Executor Not Supported | Missing getupvalues")
assert(getupvalue,"Executor Not Supported | Missing getupvalue")

makefolder("DrillBitAndCo")
if #listfiles("DrillBitAndCo") > 0 then
    for i,v in pairs(listfiles("DrillBitAndCo")) do
        if isfile(v) then 
            local old = string.split(v,"DrillBitAndCo")[2]
            table.insert(PlotList,string.sub(old,2,string.len(old)-5)) 
        end
    end
end


--Functions
local PlotPrices = getupvalues(UiSrcMod.Setup)[6].plotSize

function GetMyPlot() 
	return ClientBuildings:FindFirstChild(Players.LocalPlayer.Name)
end

function GetMyOres() 
	return Ore:FindFirstChild(Players.LocalPlayer.Name):GetChildren()
end

function GetMyUpgraders()
	local tbl = {}
	for i,v in pairs(GetMyPlot():GetChildren()) do
		if v:FindFirstChild("UpgradePart") then
			tbl[v.Name] = v.UpgradePart
		end
	end
	return tbl
end

function ItemLookup(Name)
    assert(Name,"No name provided [ItemLookup]")
    for i,v in pairs(game:GetService("ReplicatedStorage").Collection.Item:GetChildren()) do
        for i2,v2 in pairs(v:GetChildren()) do
            if v2:IsA("ModuleScript") and Name == v2.Name then
                return v2,v2:GetAttribute("id")
            end
        end
    end
    return "",0
end
function ItemLookupId(Id)
    assert(Id,"No id provided [ItemLookup]")
    for i,v in pairs(game:GetService("ReplicatedStorage").Collection.Item:GetChildren()) do
        for i2,v2 in pairs(v:GetChildren()) do
            if v2:IsA("ModuleScript") and Id == v2:GetAttribute("id") then
                return v2,v2:GetAttribute("id")
            end
        end
    end
    return "",0
end

function GetSelectedUpgrader(UpgraderName)
    local Upgrader,UpgraderId = ItemLookup(UpgraderName)
    if not Upgrader.Name == UpgraderName then return end
    for i,v in pairs(GetMyPlot():GetChildren()) do
        if v:GetAttribute("itemId") == UpgraderId then
            return v:FindFirstChild("UpgradePart")
        end
    end
end

function PlaceItem(Id,CellData,Rotation)
    local BuildId = getupvalue(PlotMod.PlaceItems,16)
    game:GetService("ReplicatedStorage").Plot.Remote.RequestPlace:InvokeServer(BuildId+1,{id=Id,frontLeftCell=CellData,rotation=Rotation})
    setupvalue(PlotMod.PlaceItems,16,BuildId+1)
end

function SaveMyPlot(PlotName)
    local tbl = {}
    for i,v in pairs(GetMyPlot():GetChildren()) do
        if v:IsA("Model") then
            table.insert(tbl,{Id=v:GetAttribute("itemId"),CellData=v:GetAttribute("frontLeftCell"),Rotation=v:GetAttribute("rotation")})
        end
    end
    local PlotEncoded = HttpService:JSONEncode(tbl)
    writefile("DrillBitAndCo/"..PlotName..".json",PlotEncoded)
end
function LoadMyPlot(PlotName)
    if not isfile("DrillBitAndCo/"..PlotName..".json") then return end
    local Decoded = HttpService:JSONDecode(readfile("DrillBitAndCo/"..PlotName..".json"))

    for i,v in pairs(Decoded) do
        PlaceItem(v.Id,v.CellData,v.Rotation)
    end
end

function CategorizeUpgraders()
	local withRange = {}
	local noRange = {}
	local special = {}
	local oreWash = nil
	for _, model in pairs(GetMyPlot():GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("UpgradePart") and model:GetAttribute("itemId") then
			local Module, _ = ItemLookupId(model:GetAttribute("itemId"))
			local upgradePart = model.UpgradePart
			if Module then
				module = require(Module)
				local isSpecial = rawget(module, "upgradeFunction")
				local range = rawget(module, "upgradeRange")

				if string.find(Module.Name:lower(), "wash") then
					oreWash = upgradePart
				elseif isSpecial then
					table.insert(special, {Part = upgradePart, Model = model})
				elseif range then
					table.insert(withRange, {
						Part = upgradePart,
						Model = model,
						Min = range[1] or 0,
						Max = range[2]
					})
				else
					table.insert(noRange, {Part = upgradePart, Model = model})
				end
			end
		end
	end
	table.sort(withRange, function(a, b)
		return a.Max > b.Max
	end)

	return withRange, noRange, special, oreWash
end

function RunSmartUpgraderLoop()
	local withRange, noRange, special, oreWash = CategorizeUpgraders()
	while Settings.AutoAllUpgraders == true do
		task.wait()
		for _, ore in pairs(GetMyOres()) do
			local value = ore:GetAttribute("Value") or 0
			local upgraded = false
			for _, upgrader in pairs(withRange) do
				if value >= upgrader.Min and value <= upgrader.Max then
					firetouchinterest(upgrader.Part, ore, 0)
					firetouchinterest(upgrader.Part, ore, 1)
					upgraded = true
				end
			end
			if not upgraded then
				for _, upgrader in pairs(noRange) do
					firetouchinterest(upgrader.Part, ore, 0)
					firetouchinterest(upgrader.Part, ore, 1)
				end
			end
			for _, upgrader in pairs(special) do
				firetouchinterest(upgrader.Part, ore, 0)
				firetouchinterest(upgrader.Part, ore, 1)
                if oreWash then
                    firetouchinterest(oreWash, ore, 0)
                    firetouchinterest(oreWash, ore, 1)
                end
			end
		end
	end
end

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Drill Bit And Co | Vertigo',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local OresGroupBox = Tabs.Main:AddLeftGroupbox('Ores')
local CratesGroupBox = Tabs.Main:AddLeftGroupbox('Crates')
local RebirthGroupBox = Tabs.Main:AddRightGroupbox('Rebirthing')
local PlotGroupBox = Tabs.Main:AddRightGroupbox('Plot')

local PlotNameText = PlotGroupBox:AddInput("PlotName",{Text = "Plot Name";Default = "MainPlot",Numeric = false,Finished = true})
PlotNameText:OnChanged(function(Value)
    Settings.PlotName = Value
end)
PlotGroupBox:AddButton({Text = "Save Plot",Func = function()
    SaveMyPlot(Settings.PlotName)
end})

local PlotSelectedDrop = PlotGroupBox:AddDropdown("PlotNameSelected",{Text = "Plot", AllowNull = true,Values = PlotList,Multi = false,Default=PlotList[1]})
PlotSelectedDrop:OnChanged(function(Value)
    Settings.PlotName = Value
end)
PlotGroupBox:AddButton({Text = "Load Plot",Func = function()
    LoadMyPlot(Settings.PlotName)
end})

OresGroupBox:AddToggle('AutoOres', {
    Text = 'Auto Upgrade All Ores',
    Default = false,
    Callback = function(Value)
        Settings.AutoAllUpgraders = Value
        task.spawn(function()
            RunSmartUpgraderLoop(Settings.AutoSellOres)
        end)
    end
})

local SelectedUpgrader = OresGroupBox:AddInput("SelectedUpgrader",{Text = "Selected Upgrader";Default = "Upgrader",Numeric = false,Finished = true})
SelectedUpgrader:OnChanged(function(Value)
    Settings.SelectedUpgrader = Value
end)

OresGroupBox:AddToggle('AutoOreSelected', {
    Text = 'Auto Upgrade Selected',
    Default = false,
    Callback = function(Value)
        Settings.AutoSelectedUpgrader = Value
        task.spawn(function()
            local Upgrader = GetSelectedUpgrader(Settings.SelectedUpgrader)
            while Settings.AutoSelectedUpgrader == true do task.wait()
                for i,v in pairs(GetMyOres()) do
                    if v and Upgrader ~= nil then
                        firetouchinterest(Upgrader,v,0)
                        firetouchinterest(Upgrader,v,1) 
                    end
                end
            end
        end)
    end
})

OresGroupBox:AddButton({Text = "Sell Ores",Func = function()
    for i,v in pairs(GetMyOres()) do
        task.spawn(function()
            for i,v in pairs(GetMyOres()) do
                for i2,v2 in pairs(GetMyPlot():GetChildren()) do
                    if v2:FindFirstChild("FurnacePart") then
                        firetouchinterest(v2.FurnacePart, v, 0)
                        firetouchinterest(v2.FurnacePart, v, 1)
                    end
                end
            end
        end)
    end
end,})

RebirthGroupBox:AddToggle('AutoRebirth', {
    Text = 'Auto Rebirth',
    Default = false,
    Callback = function(value)
        Settings.AutoRebirth = value
        task.spawn(function()
            while Settings.AutoRebirth == true do task.wait()
                if Players.LocalPlayer:GetAttribute("cash") >= GameFunsMod.GetRebirthPrice(Players.LocalPlayer.leaderstats.Life.Value) then
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("Rebirth"):InvokeServer()
                    AutoLoadedPlot = false
                end
            end
        end)
    end
})
RebirthGroupBox:AddToggle('AutoLoadLayout', {
    Text = 'Auto Load Layout',
    Tooltip = "Loads Selected layout when the plot size is max",
    Default = false,
    Callback = function(value)
        Settings.AutoLoadLayout = value
        task.spawn(function()
            while Settings.AutoLoadLayout == true do task.wait(1)
                if Players.LocalPlayer:GetAttribute("plotSize") == 10 and AutoLoadedPlot == false then
                    AutoLoadedPlot = true
                    game:GetService("ReplicatedStorage").Plot.Remote.WithdrawAll:FireServer()
                    LoadMyPlot(Settings.PlotName)
                end
            end
        end)
    end
})
RebirthGroupBox:AddDivider()
RebirthGroupBox:AddToggle('AutoPlotUpgrade', {
    Text = 'Auto Plot Size Upgrade',
    Default = false,
    Callback = function(value)
        Settings.AutoPlotUpgrade = value
        task.spawn(function()
            while Settings.AutoPlotUpgrade == true do task.wait(.2)
                if Players.LocalPlayer:GetAttribute("plotSize") == 10 then return end
                if Players.LocalPlayer:GetAttribute("cash") >= PlotPrices[Players.LocalPlayer:GetAttribute("plotSize")+1] then
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PurchaseMasteryUpgrade"):InvokeServer("plotSize")
                end
            end
        end)
    end
})

CratesGroupBox:AddToggle('AutoCrates', {
    Text = 'Crate Farm',
    Default = false,
    Callback = function(value)
        for i,v in pairs(workspace.Crates:getChildren()) do
            if v:FindFirstChild("Hitbox") and value == true then
                firetouchinterest(v.Hitbox, Character.HumanoidRootPart, 0)
                firetouchinterest(v.Hitbox, Character.HumanoidRootPart, 1)
            end
        end
        Settings.AutoCrates = value
    end
})
CratesGroupBox:AddToggle('AutoOpenCrates', {
    Text = 'Open Crates',
    Default = false,
    Callback = function(value)
        Settings.AutoOpenCrates = value
        task.spawn(function() 
            while Settings.AutoOpenCrates == true do task.wait(.2) 
                for i=0,3 do
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnboxBox"):InvokeServer(i)
                end
            end
        end)
    end
})




Library:SetWatermarkVisibility(false)
Library.KeybindFrame.Visible = false;
Library:OnUnload(function()
    Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('DrillBitAndCo')
SaveManager:SetFolder('DrillBitAndCo/DrillBitAndCo')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

--Connections
workspace.Crates.ChildAdded:Connect(function(box)
	if box and box:FindFirstChild("Hitbox") and Settings.AutoCrates == true and box:IsDescendantOf(workspace.Crates) then 
		firetouchinterest(box.Hitbox, Character.HumanoidRootPart, 0)
        firetouchinterest(box.Hitbox, Character.HumanoidRootPart, 1)
	end
end)
