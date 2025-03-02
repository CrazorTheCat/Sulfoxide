local addcall = import("ui/modules/Remotespy.lua")
local luaencode = import("modules/luaencode.lua")
local randomstr = crypt.generatebytes(25) --making sure games can't mess with this system
local function createtablewithnil()
    local tbl = {}
    local storage = {}
    setrawmetatable(tbl, {
        __index = function(t, k)
            if storage[k] == randomstr then
                return nil
            else
                return storage[k]
            end
        end,
        __newindex = function(t, k, v)
            if v == nil then
                storage[k] = randomstr -- represting nil with a random string
            else
                storage[k] = v
            end
        end,
        __pairs = function() --will be needed for luaencode
            return function(_, k)
                local next_key, next_value = next(storage, k)
                if next_value == randomstr then
                    return next_key, nil
                else
                    return next_key, next_value
                end
            end
        end,
        __len = function()
            return #storage
        end
    })
    return tbl
end

local function comparetables(t1,t2)
    local t1string = luaencode(t1)
    local t2string = luaencode(t2)
    return t1string==t2string
end

local remoteclass = {}
remoteclass.__index = remoteclass
function remoteclass.new(remote, method, args, returnedvalue, callingscript, callingfunction)
    local class = {}
    class.remote, class.method, class.args, class.returnedvalue, class.callingscript, class.callingfunction = remote, method, args, returnedvalue, callingscript, callingfunction
    return setmetatable(class, remoteclass)
end

function remoteclass:functioninfo()
    if self.callingfunction == nil then
        warn("failed to get callingfunction, can't get function's info")
        return {}
    end
    return debug.getinfo(self.callingfunction)
end

local GetDebugId = game.GetDebugId
local old; old = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local self = ...
    local initialargs = {...}
    local args = createtablewithnil()
    for i = 2, select("#",...) do
        args[i-1] = initialargs[i]
    end
    local method = getnamecallmethod()
    local callingscript = getcallingscript()
    if typeof(self) == "Instance" and (string.gsub(method, "^%l", string.upper) == "FireServer" or method == "InvokeServer" or method == "Fire" or method == "Invoke") and (self.ClassName and self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction" or self.ClassName == "BindableEvent" or self.ClassName == "BindableFunction") then
        --appendfile("DEBUGGING.txt", "\nNamecall type", method, "Callingscript", callingscript, "Returned value", old(...))
        local oldid = getthreadidentity()
        setthreadidentity(8)
        if getgenv().loggedremotes.blockedremotes["All"][GetDebugId(self)..method] or (getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(self))..method] and comparetables(getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(self))..method].args,args)) then
            return old(...)
        elseif getgenv().loggedremotes.ignoredremotes["All"][(GetDebugId(self))..method] or (getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(self))..method] and comparetables(getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(self))..method].args,args)) or getgenv().iscaller and caller then
            return old(...)
        end
        local returnedvalue = old(...)
        local remote = remoteclass.new(cloneref(self),method,args,returnedvalue,callingscript,debug.info(3,"f"))
        appendfile("DEBUGGING.txt", "\nNamecall type", method, "Callingscript", callingscript, "Returned value", old(...))
        task.spawn(addcall,remote)
        setthreadidentity(oldid)
        return returnedvalue
    end
    return old(...)
end))

for i,v in pairs(getinstances()) do
    if typeof(v) == Instance then
        if v:IsA("BaseRemoteEvent") then
            --[[hooksignal(v.OnClientEvent,function(info,...)
                print("hooksignal works")
                local remote = remoteclass.new(v, "OnClientEvent", {...}, nil, nil)
                addcall(remote)
                return true, ...
            end)]]
            v.OnClientEvent:Connect(function(...)
                local method = "OnClientEvent"
                local caller = checkcaller()
                appendfile("DEBUGGING.txt", "\nFound a BaseRemoteEvent type", method)
                if getgenv().loggedremotes.blockedremotes["All"][GetDebugId(v)..method] or (getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method].args,args)) then
                    return
                elseif getgenv().loggedremotes.ignoredremotes["All"][(GetDebugId(v))..method] or (getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method].args,args)) or getgenv().iscaller and caller then
                    return
                end
                local initialargs = {...}
                local args = createtablewithnil()
                for i = 1, select("#",...) do
                    args[i] = initialargs[i]
                end
                local remote = remoteclass.new(cloneref(v), method, args, nil, nil, nil)
                task.spawn(addcall,remote)
            end)
        elseif v:IsA("RemoteFunction") then
            if getcallbackvalue and pcall(getcallbackvalue,v, "OnClientInvoke") then
            local old; 
            local _,old = pcall(hookfunction,getcallbackvalue(v, "OnClientInvoke"), newcclosure(function(...)
                local oldid = getthreadidentity()
                setthreadidentity(8)
                local addcall = loadstring(game:HttpGet("https://raw.githubusercontent.com/CrazorTheCat/Sulfoxide/refs/heads/main/ui/modules/Remotespy.lua"))()--upvalue exceeded fix
                local method = "OnClientInvoke"
                local caller = checkcaller()
                local returnedvalue = old(...)
                appendfile("DEBUGGING.txt", "\nFound a RemoteFunction type", method, "Caller", caller, "Returned value", returnedvalue)
                local initialargs = {...}
                local args = createtablewithnil()
                for i = 1, select("#",...) do
                    args[i] = initialargs[i]
                end
                if getgenv().loggedremotes.blockedremotes["All"][GetDebugId(v)..method] or (getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method].args,args)) then
                    return returnedvalue
                elseif getgenv().loggedremotes.ignoredremotes["All"][(GetDebugId(v))..method] or (getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method].args,args)) or getgenv().iscaller and caller then
                    return returnedvalue
                end
                local remote = remoteclass.new(cloneref(v), method, args, returnedvalue, nil, nil)
                task.spawn(addcall,remote)
                setthreadidentity(oldid)
                return returnedvalue
            end))
        end
    end
end
end

local fireserver = Instance.new("RemoteEvent").FireServer
local invokeserver = Instance.new("RemoteFunction").InvokeServer
local fire = Instance.new("BindableEvent").Fire
local invoke = Instance.new("BindableFunction").Invoke
local hooks = {
    FireServer = fireserver,
    InvokeServer = invokeserver,
    Fire = fire,
    Invoke = invoke
}

for i,v in pairs(hooks) do
    appendfile("DEBUGGING.txt", string.format("\nHooked to %s", i))
    local old; old = hookfunction(v,newcclosure(function(...)
        local self = ...
        local initialargs = {...}
        local args = createtablewithnil()
        for i = 2, select("#", ...) do
            args[i-1] = initialargs[1]
        end
        local callingscript = getcallingscript()
        local caller = checkcaller()
        local method = tostring(i)
        local returnedvalue = old(...)
        appendfile("DEBUGGING.txt", "\nHooked Type", method, "Callingscript", callingscript, "Caller", caller, "Returned value", returnedvalue)
        local oldid = getthreadidentity()
        setthreadidentity(8)
        if getgenv().loggedremotes.blockedremotes["All"][GetDebugId(self)..method] or (getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(self))..method] and comparetables(getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(self))..method].args,args)) then
            return returnedvalue
        elseif getgenv().loggedremotes.ignoredremotes["All"][(GetDebugId(self))..method] or (getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(self))..method] and comparetables(getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(self))..method].args,args)) or getgenv().iscaller and caller
            then
            return returnedvalue
        end
        local remote = remoteclass.new(cloneref(self),method,args,returnedvalue,callingscript,debug.info(3,"f"))
        task.spawn(addcall,remote)
        setthreadidentity(oldid)
        return returnedvalue
    end))
end

game.DescendantAdded:Connect(function(v)
    if typeof(v) == "Instance" then
        if v:IsA("BaseRemoteEvent") then
            v.OnClientEvent:Connect(function(...)
                local method = "OnClientEvent"
                local initialargs = {...}
                local caller = checkcaller()
                local args = createtablewithnil()
                appendfile("DEBUGGING.txt", "\nNew BaseRemoteEvent", method, "Caller", caller)
                for i = 1, select("#",...) do
                    args[i] = initialargs[i]
                end
                if getgenv().loggedremotes.blockedremotes["All"][GetDebugId(v)..method] or (getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method].args,args)) then
                    return
                elseif getgenv().loggedremotes.ignoredremotes["All"][(GetDebugId(v))..method] or (getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method].args,args)) or getgenv().iscaller and caller
                    then
                        return
                end
                local remote = remoteclass.new(cloneref(v), method, args, nil, function() end)
                addcall(remote)
            end)
        elseif v:IsA("RemoteFunction") then
            task.wait(0.01)
            if getcallbackvalue and pcall(getcallbackvalue,v, "OnClientInvoke") then
                local old; 
                local _,old = pcall(hookfunction,getcallbackvalue(v, "OnClientInvoke"), newcclosure(function(...)
                    local oldid = getthreadidentity()
                    setthreadidentity(8)
                    local addcall = loadstring(game:HttpGet("https://raw.githubusercontent.com/CrazorTheCat/Sulfoxide/refs/heads/main/ui/modules/Remotespy.lua"))()--upvalue exceeded fix
                    local method = "OnClientInvoke"
                    local initialargs = {...}
                    local caller = checkcaller()
                    local returnedvalue = old(...)
                    local args = createtablewithnil()
                    appendfile("DEBUGGING.txt", "\nNew RemoteFunction", method, "Caller", caller, "Returned value", returnedvalue)
                    for i = 1, select("#",...) do
                        args[i] = initialargs[i]
                    end
                    if getgenv().loggedremotes.blockedremotes["All"][GetDebugId(v)..method] or (getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.blockedremotes["Args"][(GetDebugId(v))..method].args,args)) then
                        return returnedvalue
                    elseif getgenv().loggedremotes.ignoredremotes["All"][(GetDebugId(v))..method] or (getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method] and comparetables(getgenv().loggedremotes.ignoredremotes["Args"][(GetDebugId(v))..method].args,args)) or getgenv().iscaller and caller
                        then
                            return returnedvalue
                    end
                    local remote = remoteclass.new(cloneref(v), method, args, nil, function() end)
                    task.spawn(addcall,remote)
                    setthreadidentity(oldid)
                    return returnedvalue
                end))
            else
                print(pcall(getcallbackvalue,v, "OnClientInvoke"))
            end
        end
    end
end)
