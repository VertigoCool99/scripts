--Remote Bypass
local Communicator = require(game:GetService("ReplicatedStorage"):WaitForChild("Libraries"):WaitForChild("Communicator"))
local RemoteCache = {}
local originalListener = Communicator.listenerFunction

-- Use pcall to prevent errors from crashing
local success, hookResult = pcall(function()
    local old; old = hookfunction(originalListener, function(name)
        local result = old(name)
        RemoteCache[name] = result
        print("📡 Remote cached:", name)
        return result
    end)
end)

if not success then
    warn("Failed to hook listenerFunction, anti-cheat may be active")
end

local function GetRemote(name)
    -- Check cache first
    if RemoteCache[name] then
        return RemoteCache[name]
    end
    
    -- Try to get it directly
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
        warn("Remote not found: " .. name)
        return nil
    end
    
    -- Safely get the metatable and invoke
    local success, result = pcall(function()
        local mt = getmetatable(remote)
        if not mt or not mt.__index or not mt.__index.Invoke then
            error("Remote has no Invoke method: " .. name)
        end
        return mt.__index.Invoke(remote, ...)
    end)
    
    if not success then
        warn("Failed to call remote " .. name .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Rest of your Library setup code here...
-- [Your existing Library code remains the same]

-- Add a test button to actually USE the remote bypass
local TestGroupBox = Tabs.Main:AddLeftGroupbox('Remote Testing')

TestGroupBox:AddButton({
    Text = 'Test LoadBlueprint',
    Func = function()
        local result = CallRemote("LoadBlueprint", 1)
        Library:Notify("LoadBlueprint result: " .. tostring(result))
    end
})

TestGroupBox:AddButton({
    Text = 'List Cached Remotes',
    Func = function()
        local msg = "Cached remotes:\n"
        for name, _ in pairs(RemoteCache) do
            msg = msg .. "- " .. name .. "\n"
        end
        Library:Notify(msg)
    end
})

-- Wait for remotes to load
task.spawn(function()
    task.wait(5)
    print("Cached remotes after 5 seconds:")
    for name, _ in pairs(RemoteCache) do
        print("  -", name)
    end
end)
