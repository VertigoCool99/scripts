--Librarys
local Library = loadstring(game:HttpGet("https://gist.githubusercontent.com/VertigoCool99/282c9e98325f6b79299c800df74b2849/raw/d9efe72dc43a11b5237a43e2de71b7038e8bb37b/library.lua"))()
local EspLibrary,EspLibraryFunctions = loadstring(game:HttpGet("https://gist.githubusercontent.com/VertigoCool99/2bcff189f55663147f8d63cb5b2012d9/raw/c15541927610e44cfc31d640a1ddce50cda9e680/EspLibrary.lua"))()
local Window = Library:CreateWindow({Title=" Ultimate Mining Tycoon",TweenTime=.15,Center=true})


--Locals
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Character = LocalPlayer.Character
local Plot = game:GetService("Workspace").Plots[LocalPlayer:GetAttribute("PlotId")]
local PlayersUnloader = game:GetService("Workspace").Placeables[LocalPlayer:GetAttribute("PlotId")].UnloaderSystem
local PlayersBackpack = Character:WaitForChild("OrePackCargo",5)
local FirstRun,oldTick,Selling,OldPlayerPosition,Tool = true,tick(),false,Vector3.new(0,0,0),nil

--Tables
local Settings = {
    Farming = {AutoSell = false,AutoMine = false,AutoMineRange=70,OreHitboxes=false,OreHitboxesSize = 4,OreIgnoreList={}},
    Player = {Walkspeed = 16},
    Visuals = {OresEnabled = false,OreNames=false,OreDistances=false,OreIgnoreList={}},
}
local ActiveOreList,OreList = {},{"Tin","Iron","Lead","Cobalt","Silver","Aluminium","Uranium","Vanadium","Titanium","Gold","Tungsten","Plutonium","Palladium","Iridium","Adamantium","Thorium","Mithril","Rhodium","Unobtainium","Topaz","Emerald","Ruby","Sapphire","Diamond","Poudretteite","Zultanite","Grandidierite","Musgravite","Painite"}

--Functions
function GetTool()
    for i,v in pairs(LocalPlayer.Character:GetChildren()) do
        if v:FindFirstChild("EquipRemote") then
            return v
        end
    end
    for i,v in pairs(LocalPlayer.InnoBackpack:GetChildren()) do
        if v:FindFirstChild("EquipRemote") and string.find(v.Name,"Pickaxe") then
            return v
        end
    end
end

local MainTab = Window:AddTab("Main")
local VisualTab = Window:AddTab("Visual")
                   
local FarmGroupbox = MainTab:AddLeftGroupbox("Farming")
local TeleportGroupbox = MainTab:AddRightGroupbox("Teleports")
local PlayerGroupbox = MainTab:AddRightGroupbox("Player")
local ExploitsGroupbox = MainTab:AddRightGroupbox("Exploits")

local AutoMineToggle = FarmGroupbox:AddToggle("AutoMineToggle",{Text = "Auto Mine",Default = false,Risky = false})
AutoMineToggle:OnChanged(function(value)
    Settings.Farming.AutoMine = value
end)
local AutoSellToggle = FarmGroupbox:AddToggle("AutoSellToggle",{Text = "Auto Sell",Default = false,Risky = false})
AutoSellToggle:OnChanged(function(value)
    Settings.Farming.AutoSell = value
end)

local AutoMineRangeSlider = FarmGroupbox:AddSlider("AutoMineRangeSlider",{Text = "Mining Range",Default = 150,Min = 10,Max = 150,Rounding = 0})
AutoMineRangeSlider:OnChanged(function(Value)
    Settings.Farming.AutoMineRange = Value
end)
local FarmOreIgnoreListDropdown = FarmGroupbox:AddDropdown("FarmOreIgnoreListDropdown",{Text = "Ignore Ores", AllowNull = true,Values = OreList,Multi = true,})
FarmOreIgnoreListDropdown:OnChanged(function(Value)
    Settings.Farming.OreIgnoreList = Value
end)
FarmGroupbox:AddDivider()
local OreHitboxToggle = FarmGroupbox:AddToggle("OreHitboxToggle",{Text = "Ore Hitbox",Default = false,Risky = false})
OreHitboxToggle:OnChanged(function(value)
    Settings.Farming.OreHitboxes = value
    if value == false then
        for _,v in pairs(workspace.SpawnedBlocks:GetChildren()) do
            if v:IsA("MeshPart") then
                v.Size = Vector3.new(4.4,4.4,4.4)
            end
        end
    end
end)
local OreHitboxSizeSlider = FarmGroupbox:AddSlider("OreHitboxSizeSlider",{Text = "Size",Default = 5,Min = 5,Max = 30,Rounding = 0})
OreHitboxSizeSlider:OnChanged(function(Value)
    Settings.Farming.OreHitboxesSize = Value
end)

local MainLocationTeleportDropdown = TeleportGroupbox:AddDropdown("MainLocationTeleportDropdown",{Text = "Locations", AllowNull = false,Default="My Plot",Values = {"My Plot","Mine"},Multi = false,})
MainLocationTeleportDropdown:OnChanged(function(Value)
    if FirstRun == true then return end
    if Value == "My Plot" then
        Character:PivotTo(Plot.Centre:GetPivot()-Vector3.new(0,25,0))
    else
        Character:PivotTo(CFrame.new(-1856, 5,-195))
    end
end)
local ShopLocationTeleportDropdown = TeleportGroupbox:AddDropdown("MainLocationTeleportDropdown",{Text = "Locations", AllowNull = false,Default="Upgrade Shop",Values = {"Upgrade Shop","Rebirth Shop","Explosive Shop"},Multi = false,})
ShopLocationTeleportDropdown:OnChanged(function(Value)
    if FirstRun == true then return end
    if Value == "Upgrade Shop" then
        Character:PivotTo(CFrame.new(-1571, 10, -3))
    elseif Value == "Rebirth Shop" then
        Character:PivotTo(CFrame.new(-1467, 10, 190))
    else
        Character:PivotTo(CFrame.new(415, 78.19, -734))
    end
end)

local AutoMineRangeSlider = PlayerGroupbox:AddSlider("WalkspeedCharacter",{Text = "Walkspeed",Default = 16,Min = 16,Max = 150,Rounding = 0})
AutoMineRangeSlider:OnChanged(function(Value)
    Settings.Player.Walkspeed = Value
    Character.Humanoid.WalkSpeed = Value
end)

ExploitsGroupbox:AddButton({Text = "Insta Mine",Func = function()
    for i,v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v,"Hardness") and rawget(v,"Speed") then
            rawset(v,"Speed",2.5)
        end
    end
end,})

local OreEspGroupbox = VisualTab:AddLeftGroupbox("Ore Esp")

local NameOreEnabledToggle = OreEspGroupbox:AddToggle("NameOreEnabledToggle",{Text = "Names",Default = false,Risky = false})
NameOreEnabledToggle:OnChanged(function(value)
    EspLibrary.ItemNames.Enabled = value
end)
local NameOreColorPicker = NameOreEnabledToggle:AddColorPicker("NameOreColorPicker",{Default = Color3.fromRGB(255,255,255);Rainbow = false})
NameOreColorPicker:OnChanged(function(Color)
    EspLibrary.ItemNames.Color = Color
end)
local DistanceOreEnabledToggle = OreEspGroupbox:AddToggle("DistanceOreEnabledToggle",{Text = "Distance",Default = false,Risky = false})
DistanceOreEnabledToggle:OnChanged(function(value)
    EspLibrary.ItemDistances.Enabled = value
end)
local DistanceOreColorPicker = DistanceOreEnabledToggle:AddColorPicker("DistanceOreColorPicker",{Default = Color3.fromRGB(255,255,255);Rainbow = false})
DistanceOreColorPicker:OnChanged(function(Color)
    EspLibrary.ItemDistances.Color = Color
end)
local OreItemRenderDistance = OreEspGroupbox:AddSlider("ItemRenderDistance",{Text = "Render Distance",Default = 200,Min = 1,Max = 500,Rounding = 0})
OreItemRenderDistance:OnChanged(function(Value)
    EspLibrary.GeneralSettings.ItemRenderDistance = Value
end)

local OreIgnoreListDropdown = OreEspGroupbox:AddDropdown("OreIgnoreListDropdown",{Text = "Ignore Ores", AllowNull = true,Values = OreList,Multi = true,})
OreIgnoreListDropdown:OnChanged(function(Value)
    Settings.Visuals.OreIgnoreList = Value
    for i,v in next, game:GetService("Workspace").SpawnedBlocks:GetChildren() do
        if v:IsA("MeshPart") and v:GetAttribute("MineId") then
            if Settings.Visuals.OreIgnoreList[v:GetAttribute("MineId")] ~= nil then
                table.insert(EspLibrary.ObjectIgnoreList,v)
            elseif Settings.Visuals.OreIgnoreList[v:GetAttribute("MineId")] == nil and table.find(EspLibrary.ObjectIgnoreList,v) then
                table.remove(EspLibrary.ObjectIgnoreList,table.find(EspLibrary.ObjectIgnoreList,v))
            end
        end
    end
end)


Library:SetWatermark("Float.Balls [UMT]")


--Main Script Function [Messy Code, there is better ways ik]
task.spawn(function()
    while true do task.wait(.8)
        if Settings.Farming.AutoMine == true and Character.OrePackCargo:GetAttribute("NumContents") ~= PlayersBackpack:GetAttribute("Capacity") then
            for i,v in pairs(workspace.SpawnedBlocks:GetChildren()) do
                if (Character:GetPivot().p-v:getPivot().p).Magnitude < Settings.Farming.AutoMineRange and Settings.Farming.OreIgnoreList[v:GetAttribute("MineId")] == nil and Tool ~= nil then
                    task.spawn(function()
                        local OrePos = v:GetPivot().p
                        local args = {i,vector.create(OrePos.X-4, OrePos.Y-4, OrePos.Z-4)}
                        ReplicatedStorage.MadCommEvents[Tool:GetAttribute("MadCommId")].Activate:FireServer(table.unpack(args))
                    end)
                end
            end
        end
    end
end)
task.spawn(function()
    while true do task.wait(.3)
        PlayersBackpack = Character:WaitForChild("OrePackCargo",5)
        Tool = GetTool()
        if Settings.Farming.AutoSell == true and Selling == false then
            OldPlayerPosition = Character:GetPivot()
            if Character.OrePackCargo:GetAttribute("NumContents") == PlayersBackpack:GetAttribute("Capacity") then
                Selling = true
                Character:PivotTo(PlayersUnloader:GetPivot()+Vector3.new(0,3,0))
                task.wait(.2)
                fireproximityprompt(PlayersUnloader.Unloader.CargoVolume.CargoPrompt)
                task.wait(.1)
                Character:PivotTo(OldPlayerPosition)
                Selling = false
            end
        end
    end
end)
Tool = GetTool()
LocalPlayer.CharacterAdded:Connect(function(character)
    Tool = GetTool()
    Character = character
    character:WaitForChild("Humanoid",5).WalkSpeed = Settings.Player.Walkspeed
end)

game:GetService("Workspace").SpawnedBlocks.ChildAdded:Connect(function(v)
    if v:IsA("MeshPart") and v:GetAttribute("MineId") then
        ActiveOreList[v] = {Name=v:GetAttribute("MineId"),Type="Ore"}
        if Settings.Visuals.OreIgnoreList[v:GetAttribute("MineId")] ~= nil then
            table.insert(EspLibrary.ObjectIgnoreList,v)
        elseif Settings.Visuals.OreIgnoreList[v:GetAttribute("MineId")] == nil and table.find(EspLibrary.ObjectIgnoreList,v) then
            table.remove(EspLibrary.ObjectIgnoreList,table.find(EspLibrary.ObjectIgnoreList,v))
        end
        EspLibraryFunctions:CreateItemEsp(v,ActiveOreList[v])
    end
    if Settings.Farming.OreHitboxes == true then
        for _,v in pairs(workspace.SpawnedBlocks:GetChildren()) do
            if v:IsA("MeshPart") then
                v.Size = Vector3.new(Settings.Farming.OreHitboxesSize,Settings.Farming.OreHitboxesSize,Settings.Farming.OreHitboxesSize)
            end
        end
    end
end)
for i,v in next, game:GetService("Workspace").SpawnedBlocks:GetChildren() do
    if v:IsA("MeshPart") and v:GetAttribute("MineId") then
        ActiveOreList[v] = {Name=v:GetAttribute("MineId"),Type="Ore_"..v:GetAttribute("MineId")}
        EspLibraryFunctions:CreateItemEsp(v,ActiveOreList[v])

        if table.find(Settings.Visuals.OreIgnoreList,v:GetAttribute("MineId")) then
            table.insert(EspLibrary.ObjectIgnoreList,v)
        elseif not table.find(Settings.Visuals.OreIgnoreList,v:GetAttribute("MineId")) and table.find(EspLibrary.ObjectIgnoreList,v) then
            table.remove(EspLibrary.ObjectIgnoreList,table.find(EspLibrary.ObjectIgnoreList,v))
        end
    end
end

--Settings Start
local Settings = Window:AddTab("Settings")
local SettingsUI = Settings:AddLeftGroupbox("UI")

local SettingsUnloadButton = SettingsUI:AddButton({Text="Unload",Func=function()
    Library:Unload()
    EspLibraryFunctions:Unload()
end})

local SettingsMenuLabel = SettingsUI:AddLabel("SettingsMenuKeybindLabel","Menu Keybind")
local SettingsMenuKeyPicker = SettingsMenuLabel:AddKeyPicker("SettingsMenuKeyBind",{Default="Insert",IgnoreKeybindFrame=true})
Library.Options["SettingsMenuKeyBind"]:OnClick(function()
    Library:Toggle()
end)
local SettingsNotiPositionDropdown = SettingsUI:AddDropdown("SettingsNotiPositionDropdown",{Text="Notification Position",Values={"Top_Left","Top_Right","Bottom_Left","Bottom_Right"},Default="Top_Left"})
SettingsNotiPositionDropdown:OnChanged(function(Value)
    Library.NotificationPosition = Value
end)

Library.ThemeManager:SetLibrary(Library)
Library.SaveManager:SetLibrary(Library)
Library.ThemeManager:ApplyToTab(Settings)
Library.SaveManager:IgnoreThemeSettings()
Library.SaveManager:SetIgnoreIndexes({"MenuKeybind","BackgroundColor", "ActiveColor", "ItemBorderColor", "ItemBackgroundColor", "TextColor" , "DisabledTextColor", "RiskyColor"})
Library.SaveManager:SetFolder('Test')
Library.SaveManager:BuildConfigSection(Settings)
--Settings End

--Init
FirstRun = false
Library:Notify({Title="Loaded";Text=string.format('Loaded In '..(tick()-oldTick));Duration=5})
