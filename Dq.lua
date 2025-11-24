repeat task.wait() until game:IsLoaded()

--Locals
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Character = Players.LocalPlayer.Character
local WaitingToTp = false
local GreggCoin,RealCoin = false,nil
local oldTick = tick()
local BestDungeon,BestDifficulty = "nil","Insane"
local NameHideName,NameHideTitle = "",""
local RemoteModule
local LastplayerPos,StuckTime = Vector3.zero,0
local PlayerGui = Players.LocalPlayer.PlayerGui
local OldName,OldTitle

--Tables
local Settings = {
    AutoFarm={Enabled=false,Delay=2,Distance=6,UseSkills=false,RaidFarm=false},
    Dungeon={Enabled=false,EnabledBest=false,Name="",Diffculty="",Mode="Normal",RaidEnabled=false,RaidName="",Tier="1"},
    AutoSell = {Enabled = false,Raritys = {},ItemTypes = {}};
    Misc={AutoRetry=false,GetGreggCoin=false,NameHide=false,RejoinIfStuck=false,RejoinStuckDelay=120},
    DebugMode=false,
}
local DungeonLevels = {
    ["0"] = {["Dungeon"] = "Desert Temple", ["Easy"] = 0, ["Medium"] = 5, ["Hard"] = 15},
    ["30"] = {["Dungeon"] = "Winter Outpost", ["Easy"] = 30, ["Medium"] = 40, ["Hard"] = 50},
    ["60"] = {["Dungeon"] = "Pirate Island", ["Insane"] = 60, ["Nightmare"] = 65},
    ["70"] = {["Dungeon"] = "King's Castle", ["Insane"] = 70, ["Nightmare"] = 75},
    ["80"] = {["Dungeon"] = "The Underworld", ["Insane"] = 80, ["Nightmare"] = 85},
    ["90"] = {["Dungeon"] = "Samurai Palace", ["Insane"] = 90, ["Nightmare"] = 95},
    ["100"] = {["Dungeon"] = "The Canals", ["Insane"] = 100, ["Nightmare"] = 105},
    ["110"] = {["Dungeon"] = "Ghastly Harbor", ["Insane"] = 110, ["Nightmare"] = 115},
    ["120"] = {["Dungeon"] = "Steampunk Sewers", ["Insane"] = 120, ["Nightmare"] = 125},
    ["135"] = {["Dungeon"] = "Orbital Outpost", ["Insane"] = 135, ["Nightmare"] = 140},
    ["150"] = {["Dungeon"] = "Volcanic Chambers", ["Insane"] = 150, ["Nightmare"] = 155},   
    ["160"] = {["Dungeon"] = "Aquatic Temple", ["Insane"] = 160, ["Nightmare"] = 165},
    ["170"] = {["Dungeon"] = "Enchanted Forest", ["Insane"] = 170, ["Nightmare"] = 175},
    ["180"] = {["Dungeon"] = "Northern Lands", ["Insane"] = 180, ["Nightmare"] = 185},
    ["190"] = {["Dungeon"] = "Gilded Skies", ["Insane"] = 190, ["Nightmare"] = 195},
    ["200"] = {["Dungeon"] = "Yokai Peak", ["Insane"] = 200, ["Nightmare"] = 205},
    ["210"] = {["Dungeon"] = "Abyssal Void", ["Insane"] = 210, ["Nightmare"] = 215},
}
local Raritys = {
    ["Legendary"]=Color3.fromRGB(244, 154, 9);
    ["Epic"]=Color3.fromRGB(146, 70, 159);
    ["Rare"]=Color3.fromRGB(75, 77, 195);
    ["Uncommon"]=Color3.fromRGB(91, 194, 80);
    ["Common"]=Color3.fromRGB(152, 152, 152);
}
local RemoteCodes = {}
local Functions = {}

--Functions
Players.LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    repeat task.wait() until Character:FindFirstChild("HumanoidRootPart")
end)

function Functions:GetInventoryItems()
    local tbl = {}
    for i,v in pairs(Players.LocalPlayer.PlayerGui.sellShop.Frame.innerFrame.rightSideFrame.ScrollingFrame:GetChildren()) do
        if v:IsA("ImageLabel") and v:FindFirstChild("itemType") and v.itemType:FindFirstChild("uniqueItemNum") then
            local Item = {["index"]=v:FindFirstChild("itemType"):FindFirstChild("uniqueItemNum").Value,["rarity"]="";["itemType"]=v:FindFirstChild("itemType").Value}
            for i2,v2 in pairs(Raritys) do
                if v.ImageColor3 == v2 then
                    Item["rarity"] = i2
                end
            end
            table.insert(tbl,Item)
        end
    end
    return tbl
end
function Functions:DoSkills(RepeatCount)
    for i, v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
        for i = 0,RepeatCount do
            task.spawn(function()
                if v:FindFirstChild("cooldown") and v.cooldown.Value and (v:FindFirstChild("abilityEvent") or v:FindFirstChild("spellEvent")) then
                    (v:FindFirstChild("abilityEvent") or v:FindFirstChild("spellEvent")):FireServer()
                elseif v:FindFirstChild("cooldown") and v.cooldown.Value then
                    game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer({[1] = {["\t"] = v},[2] = RemoteCodes["Abilities"]})
                end
            end)
        end
    end
    task.wait()
end

function Functions:Teleport(Cframe)
    if not Character:FindFirstChild("HumanoidRootPart") then return end
    LastplayerPos = Character:GetPivot().p
    if WaitingToTp == true then return end
    local bodyPosition = Character.HumanoidRootPart:FindFirstChildOfClass("BodyPosition")
    local bodyGyro = Character.HumanoidRootPart:FindFirstChildOfClass("BodyGyro")
    if not Character.HumanoidRootPart:FindFirstChildOfClass("BodyGyro") then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000);bodyGyro.CFrame = Character.HumanoidRootPart.CFrame;bodyGyro.D = 500;bodyGyro.Parent = Character.HumanoidRootPart
    end
    if not Character.HumanoidRootPart:FindFirstChildOfClass("BodyPosition") then
        bodyPosition = Instance.new("BodyPosition")
        bodyPosition.MaxForce = Vector3.new(400000, 400000, 400000);bodyPosition.Position = Cframe.Position;bodyPosition.D = 300;bodyPosition.Parent = Character.HumanoidRootPart;Character.HumanoidRootPart.Velocity = Vector3.zero
    end
    local oldTime = tick()
    WaitingToTp = true
    Character.HumanoidRootPart.Anchored = false
    repeat task.wait()
        if Character:FindFirstChild("HumanoidRootPart") and bodyPosition ~= nil and bodyGyro ~= nil then
            Character:PivotTo(CFrame.new(Cframe.p + Vector3.new(0, Settings.AutoFarm.Distance * 2, 0))* CFrame.Angles(math.rad(90), 0, 0))
            bodyPosition.Position = Cframe.Position + Vector3.new(0, Settings.AutoFarm.Distance * 2, 0)
            bodyGyro.CFrame = CFrame.new(Character:GetPivot().p, Cframe.Position) * CFrame.Angles(math.rad(90), 0, 0)
        end
    until tick() - oldTime >= Settings.AutoFarm.Delay or not Character:FindFirstChild("HumanoidRootPart")
    WaitingToTp = false
    if Character:FindFirstChild("HumanoidRootPart") then
        Character.HumanoidRootPart.Anchored = true
        bodyPosition:Destroy()
    end
end
function Functions:GetEnemys()
    local Dungeon,temp = nil,{}
    if not workspace:FindFirstChild("dungeon") then 
        Dungeon = workspace:FindFirstChild("enemies")
    else
        Dungeon = workspace:FindFirstChild("dungeon")
    end
    for i, v in pairs(Dungeon:GetChildren()) do
        if v:FindFirstChild("enemyFolder") and v.enemyFolder:FindFirstChildOfClass("Model") then
			for i,v in pairs(v.enemyFolder:GetChildren()) do
				if v.Name ~= "spawn" then
					table.insert(temp,v)
				end
			end
        elseif v:FindFirstChildOfClass("Humanoid") then
            table.insert(temp,v)
        end
    end
    return temp
end
function Functions:GetClosestEnemy()
    if not Character:FindFirstChild("HumanoidRootPart") then return end
    if Functions:GetEnemys() == nil then return end

    local closestEnemy = nil
    local shortestDistance = math.huge
    
    for _, v in pairs(Functions:GetEnemys()) do
        local enemyRoot = v:FindFirstChild("HumanoidRootPart")
        local enemyHumanoid = v:FindFirstChild("Humanoid")
        local enemyHead = v:FindFirstChild("Head")
        
        if enemyRoot and enemyHumanoid and enemyHead then
            -- Safe nameplate checking
            local hasShield = false
            local nameplate = enemyHead:FindFirstChild("enemyNameplate")
            
            if nameplate then
                local frame = nameplate:FindFirstChild("Frame")
                if frame then
                    local healthBackground = frame:FindFirstChild("healthBackground")
                    if healthBackground then
                        local healthBar = healthBackground:FindFirstChild("healthBar")
                        if healthBar and healthBar:IsA("ImageLabel") then
                            hasShield = healthBar.ImageColor3 == Color3.fromRGB(84, 195, 255)
                        end
                    end
                end
            end
            
            -- Only target non-shielded enemies
            if not hasShield then
                local distance = (Character.HumanoidRootPart.Position - enemyRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = v
                end
            end
        end
    end

    return closestEnemy
end



function Functions:GetBestDungeon()
    local highestLevelDungeon = 0
    for i, v in pairs(DungeonLevels) do
        if Players.LocalPlayer.leaderstats.Level.Value >= tonumber(i) then
            if tonumber(i) > highestLevelDungeon then
                highestLevelDungeon = tonumber(i)
                if v["Nightmare"] and Players.LocalPlayer.leaderstats.Level.Value >= v["Nightmare"] then
                    BestDungeon = v["Dungeon"];BestDifficulty = "Nightmare"
                elseif v["Insane"] and Players.LocalPlayer.leaderstats.Level.Value >= v["Insane"] then
                    BestDungeon = v["Dungeon"];BestDifficulty = "Insane"
                elseif v["Hard"] and Players.LocalPlayer.leaderstats.Level.Value >= v["Hard"] then
                    BestDungeon = v["Dungeon"];BestDifficulty = "Hard"
                elseif v["Medium"] and Players.LocalPlayer.leaderstats.Level.Value >= v["Medium"] then
                    BestDungeon = v["Dungeon"];BestDifficulty = "Medium"
                elseif v["Easy"] and Players.LocalPlayer.leaderstats.Level.Value >= v["Easy"] then
                    BestDungeon = v["Dungeon"];BestDifficulty = "Easy"
                end
            end
        end
    end
end

--Grab Codes
if getupvalue ~= nil then
    repeat task.wait() until game:GetService("ReplicatedStorage"):FindFirstChild("Utility") and game:GetService("ReplicatedStorage").Utility:FindFirstChild("BridgeNet2") and game:GetService("ReplicatedStorage").Utility.BridgeNet2:FindFirstChild("Client") and game:GetService("ReplicatedStorage").Utility.BridgeNet2.Client:FindFirstChild("ClientIdentifiers")
    RemoteModule = require(game:GetService("ReplicatedStorage").Utility.BridgeNet2.Client.ClientIdentifiers)
    for i,v in pairs(getupvalue(RemoteModule["deser"],2)) do
        RemoteCodes[v] = i
    end
else
    RemoteCodes={["DungeonRetryBridge"]="/",["CharacterSelection"]="M",["PartySystem"]="d",["Cutscene"]="\184",["Intro"]="5",["DungeonHandler"]=";",["Abilities"]="G"}
end

repeat task.wait() until Players.LocalPlayer and Players.LocalPlayer.PlayerGui
for i=0,5 do task.wait(.2)
    if Players.LocalPlayer.PlayerGui:FindFirstChild("CharacterSelection") and not Character then
        game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer({[1] = {[1] = "\1",[2] = {["\3"] = "select",["characterIndex"] = 1}},[2] = RemoteCodes["CharacterSelection"]})
        game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer({[1] = {[1] = "\1"},[2] = RemoteCodes["Intro"]})
    end
end

--Librarys
local Library = loadstring(game:HttpGet("https://gist.githubusercontent.com/VertigoCool99/282c9e98325f6b79299c800df74b2849/raw/d9efe72dc43a11b5237a43e2de71b7038e8bb37b/library.lua"))()

local Window = Library:CreateWindow({Title=" Dungeon Quest",TweenTime=.15,Center=true})
   
local FarmingTab = Window:AddTab("Farming")
local MiscTab = Window:AddTab("Misc")

local NormalFarm = FarmingTab:AddLeftGroupbox("Auto Farm")
local DungeonCreateGroup = FarmingTab:AddRightGroupbox("Dungeon Creation")
local SettingsGroup = FarmingTab:AddLeftGroupbox("Settings")
local AutoSellGroup = MiscTab:AddLeftGroupbox("Auto Sell")
local NameHideGroup = MiscTab:AddRightGroupbox("Name Hider")
local RejoinStuckGroup = MiscTab:AddRightGroupbox("Rejoin When Stuck")

--Farming Start
local NormalFarmToggle = NormalFarm:AddToggle("NormalFarmToggle",{Text = "Enabled",Default = false,Risky = false})
NormalFarmToggle:OnChanged(function(value)
    Settings.AutoFarm.Enabled = value
end)
local UseSkillsToggle = NormalFarm:AddToggle("UseSkillsToggle",{Text = "Use Skills",Default = false,Risky = false})
UseSkillsToggle:OnChanged(function(value)
    Settings.AutoFarm.UseSkills = value
end)
NormalFarm:AddDivider()
local TeleportDelaySlider = NormalFarm:AddSlider("TeleportDelaySlider",{Text = "Teleport Delay",Default = 2,Min = 1,Max = 4,Rounding = 1})
TeleportDelaySlider:OnChanged(function(Value)
    Settings.AutoFarm.Delay = Value
end)
local DistanceSlider = NormalFarm:AddSlider("DistanceSlider",{Text = "Distance",Default = 6,Min = 0,Max = 10,Rounding = 0})
DistanceSlider:OnChanged(function(Value)
    Settings.AutoFarm.Distance = Value
end)
--Farming End
--DungeonCreateGroup Start
local AutoCreateBestToggle = DungeonCreateGroup:AddToggle("AutoCreateBestToggle",{Text = "Auto Create Best",Default = false,Risky = false})
AutoCreateBestToggle:OnChanged(function(value)
    Settings.Dungeon.EnabledBest = value
end)
local AutoCreateToggle = DungeonCreateGroup:AddToggle("AutoCreateToggle",{Text = "Auto Create",Default = false,Risky = false})
AutoCreateToggle:OnChanged(function(value)
    Settings.Dungeon.Enabled = value
end)
local AutoCreateDungeonNameDrop = DungeonCreateGroup:AddDropdown("AutoCreateDungeonNameDrop",{Text = "Dungeon", AllowNull = false,Values = {"Desert Temple","Winter Outpost","Pirate Island","King's Castle","The Underworld","Samurai Palace","The Canals","Ghastly Harbor","Steampunk Sewers","Orbital Outpost","Volcanic Chambers","Aquatic Temple","Enchanted Forest","Northen Lands","Gilded Skies","Yokai Peak","Abyssal Void"},Default=BestDungeon,Multi = false,})
AutoCreateDungeonNameDrop:OnChanged(function(Value)
    Settings.Dungeon.Name = Value
end)
local AutoCreateDungeonDiffcultyDrop = DungeonCreateGroup:AddDropdown("AutoCreateDungeonDiffcultyDrop",{Text = "Diffculty", AllowNull = false,Values = {"Insane","Nightmare"},Default=BestDifficulty,Multi = false,})
AutoCreateDungeonDiffcultyDrop:OnChanged(function(Value)
    Settings.Dungeon.Diffculty = Value
end)
local AutoCreateDungeonModeDrop = DungeonCreateGroup:AddDropdown("AutoCreateDungeonModeDrop",{Text = "Mode", AllowNull = false,Values = {"Normal","Hardcore"},Default="Normal",Multi = false,})
AutoCreateDungeonModeDrop:OnChanged(function(Value)
    Settings.Dungeon.Mode = Value
end)
DungeonCreateGroup:AddDivider()
local AutoCreateRaidToggle = DungeonCreateGroup:AddToggle("AutoCreateRaidToggle",{Text = "Auto Create Raid",Default = false,Risky = false})
AutoCreateRaidToggle:OnChanged(function(value)
    Settings.Dungeon.RaidEnabled = value
end)
local AutoCreateDungeonNameRaidDrop = DungeonCreateGroup:AddDropdown("AutoCreateDungeonNameRaidDrop",{Text = "Raid Dungeon", AllowNull = false,Values = {"Hela Raid","Goliath Raid"},Default=BestDungeon,Multi = false,})
AutoCreateDungeonNameRaidDrop:OnChanged(function(Value)
    Settings.Dungeon.RaidName = Value
end)
local AutoCreateDungeonTierDrop = DungeonCreateGroup:AddDropdown("AutoCreateDungeonTierDrop",{Text = "Tier", AllowNull = false,Values = {"1","2","3","4","5"},Default="1",Multi = false,})
AutoCreateDungeonTierDrop:OnChanged(function(Value)
    Settings.Dungeon.Tier = Value
end)
--DungeonCreateGroup End
--Settings Group Start
local AutoRetryToggle = SettingsGroup:AddToggle("AutoRetryToggle",{Text = "Auto Retry",Default = false,Risky = false})
AutoRetryToggle:OnChanged(function(value)
    Settings.Misc.AutoRetry = value
end)
local RaidFarmToggle = SettingsGroup:AddToggle("RaidFarmToggle",{Text = "Raid Farm",Default = false,Risky = false})
RaidFarmToggle:OnChanged(function(value)
    Settings.AutoFarm.RaidFarm = value
end)
Players.LocalPlayer.PlayerGui:WaitForChild("RetryVote").Changed:Connect(function(change)
    if change == "Enabled" and Settings.Misc.AutoRetry == true then
        game:GetService("ReplicatedStorage").dataRemoteEvent:FireServer({[1] = {["\3"] = "vote",["vote"] = true},[2] = RemoteCodes["DungeonRetryBridge"]})    
    end
end)
local GetGreggCoinToggle = SettingsGroup:AddToggle("GetGreggCoin",{Text = "Get Gregg Coin",Default = false,Risky = false})
GetGreggCoinToggle:OnChanged(function(value)
    Settings.Misc.GetGreggCoin = value
end)
--Settings Group End

--Auto Sell Start
local AutoSellEnabledToggle = AutoSellGroup:AddToggle("AutoSellEnabledToggle",{Text = "Auto Sell",Default = false,Risky = false})
AutoSellEnabledToggle:AddTooltip("This Will Sell All Selected Raritys!")
AutoSellEnabledToggle:OnChanged(function(value)
    Settings.AutoSell.Enabled = value
end)
local AutoSellItemTypeDrop = AutoSellGroup:AddDropdown("AutoCreateDungeonTierDrop",{Text = "Item Type", AllowNull = false,Values = {"weapon","ability","ring","helmet","chest"},Default={""},Multi = true,})
AutoSellItemTypeDrop:OnChanged(function(Value)
    table.clear(Settings.AutoSell.ItemTypes)
    for i, v in pairs(Value) do
        if v == true then
            table.insert(Settings.AutoSell.ItemTypes,i)
        end
    end
end)
local AutoSellRarirtyDrop = AutoSellGroup:AddDropdown("AutoCreateDungeonTierDrop",{Text = "Raritys", AllowNull = false,Values = {"Ultimate","Legendary","Epic","Rare","Uncommon","Common"},Default={""},Multi = true,})
AutoSellRarirtyDrop:OnChanged(function(Value)
    table.clear(Settings.AutoSell.Raritys)
    for i, v in pairs(Value) do
        if v == true then
            table.insert(Settings.AutoSell.Raritys,i)
        end
    end
end)
--Auto Sell End
--Name Hide Start
local NameHideEnabledToggle = NameHideGroup:AddToggle("NameHideEnabledToggle",{Text = "Enabled",Default = false,Risky = false})
NameHideEnabledToggle:OnChanged(function(value)
    Settings.Misc.NameHide = value
end)
local NameHideNameTextbox = NameHideGroup:AddInput("NameHideNameTextbox",{Text = "Name";Default = "Float.Balls",Numeric = false,Finished = true})
NameHideNameTextbox:OnChanged(function(Value)
    NameHideName = Value
end)
local NameHideTitleTextbox = NameHideGroup:AddInput("NameHideTitleTextbox",{Text = "Title";Default = "🤖",Numeric = false,Finished = true})
NameHideTitleTextbox:OnChanged(function(Value)
    NameHideTitle = Value
end)
--Name Hide End
--Rejoin Stuck Start
local RejoinStuckEnabledToggle = RejoinStuckGroup:AddToggle("RejoinStuckEnabledToggle",{Text = "Enabled",Default = false,Risky = false})
RejoinStuckEnabledToggle:OnChanged(function(value)
    Settings.Misc.RejoinIfStuck = value
end)
local RejoinStuckDelaySlider = RejoinStuckGroup:AddSlider("RejoinStuckDelaySlider",{Text = "Time",Default = 120,Min = 30,Max = 300,Rounding = 0})
RejoinStuckDelaySlider:AddTooltip("Time Is In Seconds")
RejoinStuckDelaySlider:OnChanged(function(Value)
    Settings.Misc.RejoinStuckDelay = Value
end)
--Rejoin Stuck End

--Connections

task.spawn(function()
    while true do task.wait(1)
        if Settings.Misc.RejoinIfStuck == true then
            if LastplayerPos and Character and (LastplayerPos - Character:GetPivot().p).Magnitude < 1 then
                StuckTime = StuckTime + 1
            elseif StuckTime == Settings.Misc.RejoinStuckDelay then
                game:GetService("TeleportService"):Teleport(2414851778,game.Players.LocalPlayer)
            else
                StuckTime = 0
            end
        end
    end
end)


task.spawn(function()
    while true do task.wait(1)
        if Character and Character:FindFirstChild("Head") and Character.Head:FindFirstChild("playerNameplate") and Players.LocalPlayer and Players.LocalPlayer.PlayerGui and Players.LocalPlayer.PlayerGui:FindFirstChild("HUD") and Players.LocalPlayer.PlayerGui.HUD:FindFirstChild("Main") and Players.LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("PlayerStatus") and Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus:FindFirstChild("PlayerStatus") and Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus:FindFirstChild("PlayerName") then
            if Settings.Misc.NameHide == true then
                Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.Portrait.Frame.ImageLabel.Visible = false
                Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.PlayerName.Text = NameHideName
                Character.Head.playerNameplate.PlayerName.Text = NameHideName
                Character.Head.playerNameplate.Title.Text=NameHideTitle
                PlayerGui.PartyUi.Frame.PartyScreen.InfoFrame.PartyData.Owner.Text = "by ["..NameHideName.."]"
                PlayerGui.PartyUi.Frame.PartyScreen.InfoFrame.PartyData.PartyName.Text = NameHideName.." Party"
                PlayerGui.PartyUi.Frame.CreateScreen.DungeonInfo.Owner.Text = NameHideName
                PlayerGui.PartyUi.Frame.CreateScreen.DungeonInfo.PartyName.Text = NameHideName.." Party"
                if PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content:FindFirstChild(tostring(Players.LocalPlayer.UserId)) then
                    PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberImage.Visible = false
                    PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberData.DisplayName.Text = NameHideName
                    PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberData.Username.Text = "@"..NameHideName
                end
            else
                if PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content:FindFirstChild(tostring(Players.LocalPlayer.UserId)) then
                    PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberImage.Visible = true
                    PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberData.DisplayName.Text = OldName or "Nil"
                    PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberData.Username.Text = "@"..OldName or "@Nil"
                end
                Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.Portrait.Frame.ImageLabel.Visible = true
                Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.PlayerName.Text = OldName or "Nil"
                Character.Head.playerNameplate.PlayerName.Text = OldName or "Nil"
                Character.Head.playerNameplate.Title.Text=OldTitle or "Nil"
                PlayerGui.PartyUi.Frame.CreateScreen.DungeonInfo.Owner.Text = OldName or "Nil"
                PlayerGui.PartyUi.Frame.CreateScreen.DungeonInfo.PartyName.Text = OldName.." Party" or "Nil Party"
            end
        end
    end    
end)

task.spawn(function()
    while true do task.wait(.05)
        if Settings.AutoSell.Enabled == true then
            local args = {["chest"] = {},["helmet"] = {},["ability"] = {},["ring"] = {},["weapon"] = {}}
            local counters = {["chest"] = 0, ["helmet"] = 0, ["ability"] = 0, ["ring"] = 1, ["weapon"] = 0}
            for i,v in pairs(Functions:GetInventoryItems()) do
                if table.find(Settings.AutoSell.ItemTypes,v["itemType"]) and table.find(Settings.AutoSell.Raritys,v["rarity"]) then
                    counters[v["itemType"]] = counters[v["itemType"]] + 1
                    args[v["itemType"]][counters[v["itemType"]]] = tonumber(v["index"])
                end
            end 
            game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("sellItemEvent"):FireServer(args)
        end
        if workspace:FindFirstChild("CharacterSelectScene") and Settings.Dungeon.Enabled == true then
            local DunArgs = {[1] = {[1] = {[1] = "\1",[2] = {["\3"] = "PlaySolo",["partyData"] = {
                                ["difficulty"] = Settings.Dungeon.Diffculty,
                                ["mode"] = Settings.Dungeon.Mode,
                                ["dungeonName"] = Settings.Dungeon.Name,
                                ["tier"] = 1,
                            }}},[2] = RemoteCodes["PartySystem"]}}
            game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer(unpack(DunArgs))
        elseif workspace:FindFirstChild("CharacterSelectScene") and Settings.Dungeon.RaidEnabled == true then
            local RaidArgs = {[1] = {[1] = {[1] = "\1",[2] = {["\3"] = "PlaySolo",["partyData"] = {
                                ["difficulty"] = "Nightmare",
                                ["minimumJoinLevel"] = 0,
                                ["tier"] = Settings.Dungeon.Tier,
                                ["dungeonName"] = Settings.Dungeon.RaidName,
                                ["mode"] = "Raid",
                                ["visibility"] = "Public",
                                ["maxPlayers"] = 40
                            }}},[2] = RemoteCodes["PartySystem"]}}
            game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer(unpack(RaidArgs))
        elseif Settings.Dungeon.EnabledBest == true then
            local DunArgs = {[1] = {[1] = {[1] = "\1",[2] = {["\3"] = "PlaySolo",["partyData"] = {
                ["difficulty"] = BestDifficulty,
                ["mode"] = "Normal",
                ["dungeonName"] = BestDungeon,
                ["tier"] = 1,
            }}},[2] = RemoteCodes["PartySystem"]}}
            game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer(unpack(DunArgs))
        end
        if not workspace:FindFirstChild("CharacterSelectScene") and Settings.AutoFarm.Enabled == true and Character == Players.LocalPlayer.Character and Character:FindFirstChild("HumanoidRootPart") then
            if Players.LocalPlayer.PlayerGui.HUD.Main.StartButton.Visible == true or Players.LocalPlayer.PlayerGui.RaidReadyCheck.Enabled == true then
                game:GetService("ReplicatedStorage").dataRemoteEvent:FireServer({[1] = {[utf8.char(3)] = "vote",["vote"] = true},[2] = utf8.char(28)}) --UPDATE CODE
                game:GetService("ReplicatedStorage").remotes.changeStartValue:FireServer() 
                game:GetService("ReplicatedStorage").dataRemoteEvent:FireServer(unpack({[1] = {["\3"] = "raidReady"},[2] = RemoteCodes["DungeonHandler"]}))        
                game:GetService("ReplicatedStorage"):WaitForChild("Utility"):WaitForChild("AssetRequester"):WaitForChild("Remote"):InvokeServer({[1] = "ui",[2] = "raidTimeLeftGui"})                  
            end
            if Settings.Misc.GetGreggCoin == true and GreggCoin == true and RealCoin ~= nil then
                Functions:Teleport(RealCoin:GetPivot()-Vector3.new(0,Settings.AutoFarm.Distance*2,0))
                GreggCoin = false;RealCoin=nil
            end
            local Enemy = Functions:GetClosestEnemy()
            if GreggCoin == false and Enemy ~= nil then
                Functions:Teleport(Functions:GetClosestEnemy():GetPivot())
                if Settings.AutoFarm.UseSkills == true then
                    Functions:DoSkills(5)
                end
            end
        end
    end 
end)

workspace.ChildAdded:Connect(function(child)
    if Settings.DebugMode == false then
        if child:IsA("Part") and child.Name == "pulseWavesWave" then
            child:Destroy()
        elseif child:IsA("MeshPart") and child.Name == "groundAura" then
            child:Destroy()
        elseif child:IsA("Model") and child.Name == "pulseWavesHitbox" then
            child:Destroy()
        end 
    end
end)

--Settings Start
local Settings = Window:AddTab("Settings")
local SettingsUI = Settings:AddLeftGroupbox("UI")
local SettingsUnloadButton = SettingsUI:AddButton({Text="Unload",Func=function()
    if PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content:FindFirstChild(tostring(Players.LocalPlayer.UserId)) then
        PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberImage.Visible = true
        PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberData.DisplayName.Text = OldName
        PlayerGui.PartyUi.Frame.PartyScreen.MainFrame.Members.Content[Players.LocalPlayer.UserId].MemberData.Username.Text = "@"..OldName
    end
    if Players.LocalPlayer.PlayerGui and Players.LocalPlayer.PlayerGui:FindFirstChild("HUD") and Players.LocalPlayer.PlayerGui.HUD:FindFirstChild("Main") and Players.LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("PlayerStatus") and Players.LocalPlayer.PlayerGui and Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus:FindFirstChild("PlayerStatus") and Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus:FindFirstChild("PlayerName") then
        Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.Portrait.Frame.ImageLabel.Visible = true
        Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.PlayerName.Text = OldName or "Nil"
        Character.Head.playerNameplate.PlayerName.Text = OldName or "Nil"
        Character.Head.playerNameplate.Title.Text=OldTitle or "Nil"
        PlayerGui.PartyUi.Frame.CreateScreen.DungeonInfo.Owner.Text = OldName or "Nil"
        PlayerGui.PartyUi.Frame.CreateScreen.DungeonInfo.PartyName.Text = OldName.." Party" or "Nil Party"
    end
    Library:Unload()
end})
local SettingsMenuLabel = SettingsUI:AddLabel("SettingsMenuKeybindLabel","Menu Keybind")
local SettingsMenuKeyPicker = SettingsMenuLabel:AddKeyPicker("SettingsMenuKeyBind",{Default="Insert",IgnoreKeybindFrame=true})
Library.Options["SettingsMenuKeyBind"]:OnClick(function()
    Library:Toggle()
    Library:Notify({Title="Float.balls";Text=string.format('Press Ins To Open The UI');Duration=5})
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
Library.SaveManager:SetFolder('DungeonQuest')
Library.SaveManager:BuildConfigSection(Settings)
Library.KeybindContainer.Visible = false
Library.SaveManager:LoadAutoloadConfig()
--Settings End

--Init
Players.LocalPlayer.PlayerGui.rewardGuiHolder.holder.ChildAdded:Connect(function()
    if Settings.AutoFarm.RaidFarm == true then
        game:GetService("TeleportService"):Teleport(2414851778,game.Players.LocalPlayer)
    end
end)
Players.LocalPlayer.PlayerGui.cutscene.Changed:Connect(function(change)
    if change == "Enabled" then
        game:GetService("ReplicatedStorage").dataRemoteEvent:FireServer({[1] = {["\3"] = "skip"},[2] = RemoteCodes["Cutscene"]})        
    end
end)
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Coin" then
        GreggCoin = true;RealCoin = child
    end
end)

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    game:GetService("TeleportService"):Teleport(2414851778,game.Players.LocalPlayer)
end)

Library:Notify({Title="Loaded";Text=string.format('Loaded In '..(tick()-oldTick));Duration=5})

if queue_on_teleport ~= nil then
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/VertigoCool99/scripts/refs/heads/main/Dq.lua"))()')
end

repeat task.wait() until Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.PlayerGui and Players.LocalPlayer.PlayerGui:FindFirstChild("HUD") and Players.LocalPlayer.PlayerGui.HUD:FindFirstChild("Main") and Players.LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("PlayerStatus") and Players.LocalPlayer.PlayerGui and Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus:FindFirstChild("PlayerStatus") and Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus:FindFirstChild("PlayerName")
Functions:GetBestDungeon()
AutoCreateDungeonNameDrop:SetValue(BestDungeon)
AutoCreateDungeonDiffcultyDrop:SetValue(BestDifficulty)
OldName,OldTitle = Players.LocalPlayer.PlayerGui.HUD.Main.PlayerStatus.PlayerStatus.PlayerName.Text,Character.Head.playerNameplate.Title.Text
