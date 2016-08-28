--[[ 
	Rework � 2016 Mr. Meow and NightAngel
	Do not share, re-distribute or sell.
--]]

if (plugin) then return; end;

library.New("plugin", _G);
local stored = {};
local hooksCache = {};

function plugin.GetStored()
	return stored;
end;

function plugin.GetCache()
	return hooksCache;
end;

library.NewClass("NewPlugin", _G);

function NewPlugin:NewPlugin(name, data)
	self.m_Name = name or data.name or "Unknown Plugin";
	self.m_Author = data.author or "Unknown Author";
	self.m_Folder = data.folder or name:gsub(" ", "_"):lower();
	self.m_Description = data.description or "Undescribed plugin or schema.";
	self.m_uniqueID = data.id or name:gsub(" ", "_"):lower() or "unknown";
end;

function NewPlugin:GetName()
	return self.m_Name;
end;

function NewPlugin:GetFolder()
	return self.m_Folder;
end;

function NewPlugin:GetAuthor()
	return self.m_Author;
end;

function NewPlugin:GetDescription()
	return self.m_Description;
end;

function NewPlugin:SetData(data)
	table.Merge(self, data);
end;

function NewPlugin:Register()
	plugin.Register(self);
end;

function plugin.CacheFunctions(obj)
	for k, v in pairs(obj) do
		if (isfunction(v)) then
			hooksCache[k] = hooksCache[k] or {};
			table.insert(hooksCache[k], {v, obj});
		end;
	end;
end;

function plugin.Register(obj)
	plugin.CacheFunctions(obj);

	stored[obj:GetFolder()] = obj;
end;

function plugin.Include(folder)
	local hasMainFile = false;
	local id = folder:GetFileFromFilename();
	local ext = id:GetExtensionFromFilename();
	local data = {};
	data.folder = folder;
	data.id = id;
	data.pluginFolder = folder;

	if (ext != "lua") then
		if (file.Exists(folder.."/plugin.ini", "LUA")) then
			local iniData = util.JSONToTable(file.Read(folder.."/plugin.ini", "LUA"));
			data.pluginFolder = folder.."/plugin";
			table.Merge(data, iniData);
		end;
	end;

	PLUGIN = NewPlugin(id, data);

	if (stored[folder]) then
		PLUGIN = stored[folder];
	end;

	if (ext != "lua") then
		if (file.Exists(data.pluginFolder.."/sh_plugin.lua", "LUA")) then
			rw.core:Include(data.pluginFolder.."/sh_plugin.lua");
			hasMainFile = true;
		end;

		if (file.Exists(data.pluginFolder.."/sh_"..(data.name or id)..".lua", "LUA")) then
			rw.core:Include(data.pluginFolder.."/sh_"..(data.name or id)..".lua");
			hasMainFile = true;
		end;
	else
		if (file.Exists(folder, "LUA")) then
			rw.core:Include(folder);
			hasMainFile = true;
		end;
	end;

	if (!hasMainFile) then
		ErrorNoHalt("[Rework] Plugin "..id.." doesn't have main file!\n");
		PLUGIN = nil;
		return;
	end;

	PLUGIN:Register();
	PLUGIN = nil;
end;

function plugin.IncludeSchema(folder)
	Schema = NewPlugin("Schema", {});

	Schema:Register();
end;

do
	plugin.OldHookCall = plugin.OldHookCall or hook.Call;

	function hook.Call(name, bGM, ...)
		if (hooksCache[name]) then
			for k, v in ipairs(hooksCache[name]) do
				local result = {pcall(v[1], v[2], ...)};
				local success = result[1];
				table.remove(result, 1);

				if (!success) then
					ErrorNoHalt("[Rework:"..v[2]:GetName().."] The "..name.." hook has failed to run!\n");
					ErrorNoHalt(unpack(result), "\n");
				elseif (result[1] != nil) then
					return unpack(result);
				end;
			end;
		end;

		return plugin.OldHookCall(name, bGM, ...);
	end;

	function plugin.Call(name, ...)
		return hook.Run(name, ...);
	end;
end;

plugin.Include("rework/gamemode/plugins/sh_test.lua")
plugin.Include("rework/gamemode/plugins/test")