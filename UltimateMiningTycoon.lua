local Library = loadstring(game:HttpGet("https://gist.githubusercontent.com/VertigoCool99/282c9e98325f6b79299c800df74b2849/raw/d9efe72dc43a11b5237a43e2de71b7038e8bb37b/library.lua"))()
local Window = Library:CreateWindow({Title=" Ultimate Mining Tycoon",TweenTime=.15,Center=true})

--Locals
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Character = LocalPlayer.Character
local Tool = nil
local Plot = game:GetService("Workspace").Plots[LocalPlayer:GetAttribute("PlotId")]
local PlayersUnloader = game:GetService("Workspace").Placeables[LocalPlayer:GetAttribute("PlotId")].UnloaderSystem
local OldPlayerPosition
local PlayersBackpack = Character:WaitForChild("OrePackCargo",5)
local HeartbeatService = game:GetService("RunService").Heartbeat
local FirstRun = true

--Tables
local Settings = {
    Farming = {AutoSell = false,AutoMine = false,AutoMineRange=70},
}

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
                   
local FarmGroupbox = MainTab:AddLeftGroupbox("Farming")
local TeleportGroupbox = MainTab:AddRightGroupbox("Teleports")

local AutoMineToggle = FarmGroupbox:AddToggle("AutoMineToggle",{Text = "Auto Mine",Default = false,Risky = false})
AutoMineToggle:OnChanged(function(value)
    Settings.Farming.AutoMine = value
end)
local AutoSellToggle = FarmGroupbox:AddToggle("AutoSellToggle",{Text = "Auto Sell",Default = false,Risky = false})
AutoSellToggle:OnChanged(function(value)
    Settings.Farming.AutoSell = value
end)

local AutoMineRangeSlider = FarmGroupbox:AddSlider("AutoMineRangeSlider",{Text = "Mining Range",Default = 70,Min = 10,Max = 70,Rounding = 0})
AutoMineRangeSlider:OnChanged(function(Value)
    Settings.Farming.AutoMineRange = Value
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


Library:SetWatermark("Float.Balls [UMT]")


--Main Script Function
local Connection = HeartbeatService:Connect(function()
    if Settings.Farming.AutoMine == true then
        for i,v in pairs(workspace.SpawnedBlocks:GetChildren()) do
            if (Character:GetPivot().p-v:getPivot().p).Magnitude < Settings.Farming.AutoMineRange then
                task.spawn(function()
                    local OrePos = v:GetPivot().p
                    local args = {i,vector.create(OrePos.X-4, OrePos.Y-4, OrePos.Z-4)}
                    ReplicatedStorage.MadCommEvents[Tool:GetAttribute("MadCommId")].Activate:FireServer(table.unpack(args))
                end)
            end
        end
    end
end)
task.spawn(function()
    while true do task.wait(.5)
        Tool = GetTool()
    end
end)
Tool = GetTool()

PlayersBackpack:GetAttributeChangedSignal("NumContents"):Connect(function()
    if Settings.Farming.AutoSell == true then
        OldPlayerPosition = Character:GetPivot()
        if Character.OrePackCargo:GetAttribute("NumContents") > 0 then
            repeat task.wait()
                Character:PivotTo(PlayersUnloader:GetPivot())
                task.wait(.2)
                fireproximityprompt(PlayersUnloader.Unloader.CargoVolume.CargoPrompt)
                Character:PivotTo(OldPlayerPosition)
            until PlayersBackpack:GetAttribute("NumContents") < PlayersBackpack:GetAttribute("Capacity")
        end
    end
end)

--Settings Start
local Settings = Window:AddTab("Settings")
local SettingsUI = Settings:AddLeftGroupbox("UI")

local SettingsUnloadButton = SettingsUI:AddButton({Text="Unload",Func=function()
    Library:Unload()
    Connection:Disconnect()
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

FirstRun = false
