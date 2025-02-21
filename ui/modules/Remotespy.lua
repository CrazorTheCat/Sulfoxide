local typeenc = import("modules/luatypeencode.lua")
local tableenc = import("modules/luaencode.lua")
local contextmenu = import("ui/controls/Contextmenu.lua")
local rendercode = customrequire(ui.Main.group.Codeviewer.ide)	
local getdebugid = game.GetDebugId
local function castnumtobool(num)
	if num == 1 then
		return true
	else
		return false
	end
end
local getnil = [[local function getnil(name,class,id)
	for _,v in next, getnilinstances() do 
		if v.ClassName==class and v.Name==name and v.GetDebugId(v) == id then 
			return v;
		end 
	end 
end]]
local function codegenerator(remote)
	local output = ""
	if #remote.args ~= 0 then
		output = output.."local args = "..tableenc(remote.args, {Prettify=true, Pairs=getrawmetatable(remote.args).__pairs}).."\n"
	end
	if remote.method~="OnClientEvent" and remote.method~="OnClientInvoke" then
		if remote.remote.Parent == nil then
			if #remote.args == 0 then
				output = getnil.."\n"..output..'\ngetnil("'..remote.remote.Name..'", "'..remote.remote.ClassName..'", "'..getdebugid(remote.remote)..'"):'..remote.method..'()'
			else
				output = getnil.."\n"..output..'\ngetnil("'..remote.remote.Name..'", "'..remote.remote.ClassName..'", "'..getdebugid(remote.remote)..'"):'..remote.method..'(unpack(args))'
			end
			return output	
		end
		local fullname = typeenc(remote.remote)
		if #remote.args == 0 then
			output = output..fullname..":"..remote.method.."()"
		else
			output = output..fullname..":"..remote.method.."(unpack(args))"
		end
	elseif remote.method == "OnClientEvent" then
		if remote.remote.Parent == nil then
			if #remote.args == 0 then
				output = getnil.."\n"..output..'\ngetnil("'..remote.remote.Name..'", "'..remote.remote.ClassName..'", "'..getdebugid(remote.remote)..'"):'..remote.method..'").OnClientEvent)'
			else
				output = getnil.."\n"..output..'\ngetnil("'..remote.remote.Name..'", "'..remote.remote.ClassName..'", "'..getdebugid(remote.remote)..'")'..'.OnClientEvent, unpack(args))'
			end
			return output
		end
		local fullname = typeenc(remote.remote)
		output = output.."firesignal("
		if #remote.args == 0 then
			output = output..fullname.."."..remote.method..")"
		else
			output = output..fullname.."."..remote.method..", unpack(args))"
		end
	elseif remote.method == "OnClientInvoke" then
		if remote.remote.Parent == nil then
			if #remote.args == 0 then
				output = getnil.."\n"..'local func = getcallbackvalue(getnil("'..remote.remote.Name..'", "'..remote.remote.ClassName..'", "'..getdebugid(remote.remote)..'"), "'..remote.method..'")\n'..output.."\nfunc()"
			else
				output = getnil.."\n"..'local func = getcallbackvalue(getnil("'..remote.remote.Name..'", "'..remote.remote.ClassName..'", "'..getdebugid(remote.remote)..'"), "'..remote.method..'")\n'..output.."\nfunc(unpack(args))"
			end
			return output	
		end
		local fullname = typeenc(remote.remote)
		local output2 = output
		local islp = false
		output = "local func = getcallbackvalue("
		if #remote.args == 0 then
			output = output..fullname..")\n"..output2.."\nfunc()"
		else
			output = output..fullname..")\n"..output2.."\nfunc(unpack(args))"
		end
	end
	return output
end
local functions = {}
getgenv().loggedremotes = {
	blockedremotes = {["All"]={},["Args"]={}},
	ignoredremotes = {["All"]={},["Args"]={}},
}
local selectedremote = nil
local logexample = ui.Main.group.Remotespy.Logs.examplelog
logexample.Parent = nil
local callexample = ui.Main.group.Remotespy.Args.example
local argexample = callexample.Frame
local lastselectedlog
argexample.Parent = nil
callexample.Parent = nil
getgenv().iscaller = false
getgenv().autoblockenabled = false
local ids = {
	["Invoke"] = "rbxassetid://104496650657465",
	["OnClientInvoke"] = "rbxassetid://81620962510087",
	["FireServer"] = "rbxassetid://107881214525428",
	["InvokeServer"] = "rbxassetid://78888324456423",
	["Fire"] = "rbxassetid://96274652157241",
	["OnClientEvent"] = "rbxassetid://133871620937064"
}
ui.Main.group.Remotespy.Buttons.Clearlogs.Activated:Connect(function()
	if ui.Main.group.Remotespy.Visible == true then
		for i,v in pairs(ui.Main.group.Remotespy.Logs:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
		for i,v in pairs(ui.Main.group.Remotespy.Args:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
		for i,v in pairs(getgenv().loggedremotes) do
			if i~="blockedremotes" and i ~= "ignoredremotes" then
				getgenv().loggedremotes[i] = nil
			end	
		end
	end
end)
ui.Main.group.Remotespy.Buttons.Checkcaller.Activated:Connect(function()
	if ui.Main.group.Remotespy.Visible == true then
		getgenv().iscaller = not getgenv().iscaller
		if getgenv().iscaller == true then
			ui.Main.group.Remotespy.Buttons.Checkcaller.UIStroke.Color = Color3.fromRGB(101, 236, 10)
		else
			ui.Main.group.Remotespy.Buttons.Checkcaller.UIStroke.Color = Color3.fromRGB(35, 35, 35)
		end
	end
end)
ui.Main.group.Remotespy.Buttons.Clearblocks.Activated:Connect(function()
	if ui.Main.group.Remotespy.Visible == true then
		getgenv().loggedremotes.blockedremotes = {["All"]={},["Args"]={}}
	end
end)
ui.Main.group.Remotespy.Buttons.Clearexclusions.Activated:Connect(function()
	if ui.Main.group.Remotespy.Visible == true then
		getgenv().loggedremotes.ignoredremotes = {["All"]={},["Args"]={}}
	end
end)

ui.Main.group.Remotespy.Buttons.Autoblock.Activated:Connect(function()
	if ui.Main.group.Remotespy.Visible == true then
		getgenv().autoblockenabled = not getgenv().autoblockenabled
		if getgenv().autoblockenabled == true then
			ui.Main.group.Remotespy.Buttons.Autoblock.UIStroke.Color = Color3.fromRGB(101, 236, 10)
		else
			ui.Main.group.Remotespy.Buttons.Autoblock.UIStroke.Color = Color3.fromRGB(35, 35, 35)
		end
	end
end)
local function getremotecallfuncs(remote)
		local remotecallfunctions = {--format is made for contextmenu
		{
			Text = "Get source script",
			Func = function()
				local scriptinstance = getfenv(remote.callingfunction).script
				if not scriptinstance then
					warn("failed to get script instance") --this won't happen with debug.getinfo (will use in the future)
				else
					toclipboard(typeenc(scriptinstance))
				end
			end
		},
		{
			Text = "Get calling script",
			Func = function()
				toclipboard(typeenc(remote.callingscript))
			end
		},
		{
			Text = "Get path",
			Func = function()
				toclipboard(typeenc(remote.remote) or "nil")
			end
		},
		{
			Text = "Get returned value",
			Func = function()
				toclipboard(typeenc(remote.returnedvalue))
			end
		},
		{
			Text = "Copy code",
			Func = function()
				toclipboard(codegenerator(remote))
			end
		},
		{
			Text = "Get function info",
			Func = function()
				if remote:functioninfo() then
					local func = remote.callingfunction
					local funcinfo = remote:functioninfo()
					local callingscript = remote.callingscript
					local sourcescript = getfenv(func).script
					local functioninfo = {
						["script"] = 
							{
								["sourcescript"] = sourcescript,
								["callingscript"] = callingscript
							},
						["info"] = funcinfo,
						["upvalues"] = debug.getupvalues(func),
						["constants"] = debug.getconstants(func)
					}
					return toclipboard("local functioninfo = "..tableenc(functioninfo,{Prettify=true}))
				end
			end
		},
		{
			Text = "View code",
			Func = function()
				rendercode(codegenerator(remote))
			end
		},
		{
			Text = "View func info",
			Func = function()
				if remote:functioninfo() then
					local func = remote.callingfunction
					local funcinfo = remote:functioninfo()
					local callingscript = remote.callingscript
					local sourcescript = getfenv(func).script
					local functioninfo = {
						["script"] = 
							{
								["sourcescript"] = sourcescript,
								["callingscript"] = callingscript
							},
						["info"] = funcinfo,
						["upvalues"] = debug.getupvalues(func),
						["constants"] = debug.getconstants(func)
					}
					return rendercode("local functioninfo = "..tableenc(functioninfo,{Prettify=true}))
				end
			end
		},
		{
			Text = "Call remote",
			Func = function()
				local f = loadstring(codegenerator(remote))
				f()
			end
		},
		{
			Text = "Ignore args",
			Func = function()
				getgenv().loggedremotes.ignoredremotes["Args"][(getdebugid(remote.remote))..remote.method] = remote
			end
		},
		{
			Text = "Block args",
			Func = function()
				getgenv().loggedremotes.blockedremotes["Args"][(getdebugid(remote.remote))..remote.method] = remote
			end
		},
	}
	return remotecallfunctions
end
function addcall(remote)
	local remoteinstance = remote.remote
	if not getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method] then
		local newlog = logexample.Clone(logexample)
		getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method] = {}
		getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method].lastcall = tick()
		getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method][1] = remote
		newlog.Frame.calls.Text = "1"
		newlog.Frame.name.Text = remoteinstance.Name
		newlog.Parent = ui.Main.group.Remotespy.Logs
		newlog.Name = (getdebugid(remoteinstance))..remote.method
		newlog.Frame.ImageLabel.Image = ids[remote.method]
		newlog.Visible = not castnumtobool(ui.Main.group.Remotespy.Filters[remote.method].Frame.ImageLabel.ImageTransparency)
		newlog.Activated:Connect(function()
			if ui.Main.group.Remotespy.Visible == true then
				if not remoteinstance then
					warn("Remote is nil")
				end
				if lastselectedlog then lastselectedlog.Transparency = 0.87 end
				newlog.BackgroundTransparency = 0.75
				lastselectedlog = newlog
				if selectedremote and compareinstances(remoteinstance, selectedremote.remote) then 
					return 
				else
					for i,v in pairs(ui.Main.group.Remotespy.Args:GetChildren()) do
						if v:IsA("TextButton") then
							v:Destroy()
						end
					end
				end
				for a,b in pairs(getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method]) do
					if a ~= "lastcall" then --make sure that we're not indexing lastcall
						local remotecallfunctions = getremotecallfuncs(b)
						local newcall = callexample.Clone(callexample)
						newcall.Parent = ui.Main.group.Remotespy.Args
						newcall.Title.Text = "Call "..tostring(a)
						if not #remotecallfunctions == 10 then
							table.insert(remotecallfunctions, {
								Text = "Clear call",
								Func = function()
									newcall:Destroy()
									getgenv().loggedremotes[(getdebugid(b.remote))..remote.method][a] = nil
									newlog.Frame.calls.Text = tostring(tonumber(newlog.Frame.calls.Text)-1)
								end
							})
						end
						contextmenu(newcall, newcall.Parent.Parent, remotecallfunctions)
						if #b.args == 0 then local new = argexample.Clone(argexample) new.Parent = newcall end
						for i,v in getrawmetatable(b.args).__pairs(b.args) do
							local newarg = argexample.Clone(argexample)
							newarg.Parent = newcall
							newarg.Index.Text = tostring(i)
							if typeof(v) == "table" then
								newarg.Key.Text = tostring(v)
							else
								newarg.Key.Text = typeenc(v)
							end
						end
					end
				end
				selectedremote = remote
			end
		end)
		contextmenu(newlog, newlog.Parent.Parent, {
			{
				Text = "Exclude",
				Func = function()
					if not getgenv().loggedremotes.ignoredremotes["All"][(getdebugid(remote.remote))..remote.method] then
						getgenv().loggedremotes.ignoredremotes["All"][(getdebugid(remote.remote))..remote.method] = remote
					end
				end
			},
			{
				Text = "Unexclude",
				Func = function()
					if getgenv().loggedremotes.ignoredremotes["All"][(getdebugid(remote.remote))..remote.method] then
						getgenv().loggedremotes.ignoredremotes["All"][(getdebugid(remote.remote))..remote.method] = nil
					end
				end
			},
			{
				Text = "Block",
				Func = function()
					if not getgenv().loggedremotes.blockedremotes["All"][(getdebugid(remote.remote))..remote.method] then
						getgenv().loggedremotes.blockedremotes["All"][(getdebugid(remote.remote))..remote.method] = remote
					end
				end
			},
			{
				Text = "Unblock",
				Func = function()
					if getgenv().loggedremotes.blockedremotes["All"][(getdebugid(remote.remote))..remote.method] then
						getgenv().loggedremotes.blockedremotes["All"][(getdebugid(remote.remote))..remote.method] = nil
					end
				end
			},
			{
				Text = "Clear",
				Func = function()
					ui.Main.group.Remotespy.Logs[(getdebugid(remoteinstance))..remote.method]:Destroy()
					for i,v in pairs(ui.Main.group.Remotespy.Args:GetChildren()) do
						if v:IsA("TextButton") then
							v:Destroy()
						end
					end
					getgenv().loggedremotes[getdebugid(remoteinstance)..remote.method] = nil
				end
			}
		})
	else
		if getgenv().autoblockenabled and 0.5 > tick()-getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method].lastcall then 
			return
		else
			getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method].lastcall = tick()
		end
		local remotelog = ui.Main.group.Remotespy.Logs[(getdebugid(remoteinstance))..remote.method]
		local newcalls = tostring(tonumber(remotelog.Frame.calls.Text)+1)
		remotelog.Frame.calls.Text = newcalls
		getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method][newcalls] = remote
		if selectedremote and compareinstances(remoteinstance,selectedremote.remote) and rawequal(remote.method, selectedremote.method)	then --check if the called remote is the same as the selected remote
			local newcall = callexample.Clone(callexample)
			local remotecallfunctions = getremotecallfuncs(remote)
			newcall.Parent = ui.Main.group.Remotespy.Args
			newcall.Title.Text = "Call "..remotelog.Frame.calls.Text
			table.insert(remotecallfunctions, {
				Text = "Clear call",
				Func = function()
					newcall:Destroy()
					getgenv().loggedremotes[(getdebugid(remoteinstance))..remote.method][newcalls] = nil
					remotelog.Frame.calls.Text = tostring(tonumber(remotelog.Frame.calls.Text)-1)
				end
			})
			contextmenu(newcall, newcall.Parent.Parent, remotecallfunctions)
			if #remote.args == 0 then 
				local new = argexample.Clone(argexample) 
				new.Parent = newcall 
			end
			for i,v in getrawmetatable(remote.args).__pairs(remote.args) do
				local newarg = argexample.Clone(argexample)
				newarg.Parent = newcall
				newarg.Index.Text = tostring(i)
				if typeof(v) == "table" then
					newarg.Key.Text = tostring(v)
				else
					newarg.Key.Text = typeenc(v)
				end
			end
		end
	end
end
return addcall
