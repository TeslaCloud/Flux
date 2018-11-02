AddCSLuaFile()

--
-- Library: library
-- Description: Provides function for library and class creation, manipulation and instantiation.
--
library = library or {}
library.stored = library.stored or {}

-- A function to include a file based on it's prefix.
function util.include(file_name)
  if SERVER then
    if string.find(file_name, 'cl_') then
      AddCSLuaFile(file_name)
    elseif string.find(file_name, 'sv_') or string.find(file_name, 'init.lua') then
      return include(file_name)
    else
      AddCSLuaFile(file_name)
      return include(file_name)
    end
  else
    if !string.find(file_name, 'sv_') and file_name != 'init.lua' and !file_name:EndsWith('/init.lua') then
      return include(file_name)
    end
  end
end

-- A function to add a file to clientside downloads list based on it's prefix.
function util.add_cs_lua(file_name)
  if SERVER then
    if string.find(file_name, 'sh_') or string.find(file_name, 'cl_') or string.find(file_name, 'shared.lua') then
      AddCSLuaFile(file_name)
    end
  end
end

-- A function to include all files in a directory.
function util.include_folder(dir, base, recursive)
  if base then
    if isbool(base) then
      base = 'flux/gamemode/'
    elseif !base:EndsWith('/') then
      base = base..'/'
    end

    dir = base..dir
  end

  if !dir:EndsWith('/') then
    dir = dir..'/'
  end

  if recursive then
    local files, folders = _file.Find(dir..'*', 'LUA', 'namedesc')

    -- First include the files.
    for k, v in ipairs(files) do
      if v:GetExtensionFromFilename() == 'lua' then
        util.include(dir..v)
      end
    end

    -- Then include all directories.
    for k, v in ipairs(folders) do
      util.include_folder(dir..v, recursive)
    end
  else
    local files, _ = _file.Find(dir..'*.lua', 'LUA', 'namedesc')

    for k, v in ipairs(files) do
      util.include(dir..v)
    end
  end
end

--
-- Function: fl.print (any message)
-- Description: Prints a message to the console.
-- Argument: any message - Any variable to be printed. If it's table, PrintTable will automatically be used.
--
-- Returns: nil
--
function fl.print(message)
  if !istable(message) then
    print(message)
  else
    PrintTable(message)
  end
end

function fl.dev_print(message)
  if fl.development then
    Msg('Debug: ')
    MsgC(Color(200, 200, 200), message)
    Msg('\n')
  end
end

--
-- Function: file.Write (string file_name, string fileContents)
-- Description: Writes a file to the data/ folder. This detour adds the ability for it to create all of the folders leading to the file path automatically.
-- Argument: string file_name - The name of the file to write. See http://wiki.garrysmod.com/page/file/Write for futher documentation.
-- Argument: string fileContents - Contents of the file as a NULL-terminated string.
--
-- Returns: nil
--
file.old_write = file.old_write or file.Write

function file.Write(file_name, contents)
  local pieces = file_name:split('/')
  local current_path = ''

  for k, v in ipairs(pieces) do
    if string.GetExtensionFromFilename(v) != nil then
      break
    end

    current_path = current_path..v..'/'

    if !file.Exists(current_path, 'DATA') then
      file.CreateDir(current_path)
    end
  end

  return file.old_write(file_name, contents)
end

--
-- Function: library.new (string name, table parent = _G)
-- Description: Creates a library inside the parent table.
-- Argument: string name - The name of the library. Must comply with Lua variable name requirements.
-- Argument: table parent (default: _G) - The parent table to put the library into.
--
-- Returns: table - The created library.
--
function library.new(name, parent)
  parent = parent or _G

  if !name then return end

  parent[name] = parent[name] or {}

  return parent[name]
end

-- Set library table's Metatable so that we can call it like a function.
setmetatable(library, { __call = function(tab, name, parent) return tab.Get(name, parent) end })

--
-- Function: class(string name, table parent = _G, class base_class = nil)
-- Description: Creates a new class. Supports constructors and inheritance.
-- Argument: string name - The name of the library. Must comply with Lua variable name requirements.
-- Argument: table parent (default: _G) - The parent table to put the class into.
-- Argument: class base_class (default: nil) - The base class this new class should extend.
--
-- Alias: class (string name, class base_class = nil, table parent = _G)
--
-- Returns: table - The created class.
--
function class(name, base_class)
  if isstring(base_class) then
    base_class = base_class:parse_table()
  end

  local parent = nil
  parent, name = name:parse_parent()
  parent[name] = {}

  local obj = parent[name]
  obj.ClassName = name
  obj.BaseClass = base_class or false
  obj.class_name = obj.ClassName
  obj.base_class = obj.BaseClass
  obj.static_class = true
  obj.class = obj

  -- If this class is based off some other class - copy it's parent's data.
  if istable(base_class) then
    local copy = table.Copy(base_class)
    table.safe_merge(copy, obj)

    if isfunction(base_class.class_extended) then
      try {
        base_class.class_extended, base_class, copy
      } catch {
        function(exception)
          ErrorNoHalt(tostring(exception) + '\n')
        end
      }
    end

    obj = copy
  end

  library.last_class = { name = name, parent = parent }

  obj.new = function(...)
    local new_obj = {}
    local real_class = parent[name]

    -- Set new object's meta table and copy the data from original class to new object.
    setmetatable(new_obj, real_class)
    table.safe_merge(new_obj, real_class)

    -- If there is a base class, call their constructor.
    local base_class = real_class.BaseClass
    local has_base_class = true

    while istable(base_class) and has_base_class do
      if base_class.BaseClass and base_class.ClassName != base_class.BaseClass.ClassName then
        base_class = base_class.BaseClass
      else
        has_base_class = false
      end
    end

    -- If there is a constructor - call it.
    if real_class.init then
      local success, value = pcall(real_class.init, new_obj, ...)

      if !success then
        ErrorNoHalt('['..name..'] Class constructor has failed to run!\n')
        ErrorNoHalt(value..'\n')
      end
    end

    new_obj.class = real_class
    new_obj.static_class = false
    new_obj.IsValid = function() return true end

    -- Return our newly generated object.
    return new_obj
  end

  obj.include = function(self, what)
    local module_table = isstring(what) and what:parse_table() or what

    if !istable(module_table) then return end

    for k, v in pairs(module_table) do
      if !self[k] then
        self[k] = v
      end
    end
  end

  return parent[name]
end

function delegate(obj, t)
  if !istable(obj) or !istable(t) or !t.to then return end

  local class = isstring(t.to) and t.to:parse_table() or t.to

  if istable(class) and class.class_name then
    for k, v in ipairs(t) do
      obj[v] = class[v]
    end
  end

  return true
end

--
-- Function: extends (class base_class)
-- Description: Sets the base class of the class that is currently being created.
-- Argument: class base_class - The base class to extend.
--
-- Alias: implements
-- Alias: inherits
--
-- Returns: bool - Whether or not did the extension succeed.
--
function extends(base_class)
  if isstring(base_class) then
    base_class = base_class:parse_table()
  end

  if istable(library.last_class) and istable(base_class) then
    local obj = library.last_class.parent[library.last_class.name]
    local copy = table.Copy(base_class)

    table.safe_merge(copy, obj)

    if isfunction(base_class.class_extended) then
      try {
        base_class.class_extended, base_class, copy
      } catch {
        function(exception)
          ErrorNoHalt(tostring(exception) + '\n')
        end
      }
    end

    obj = copy
    obj.BaseClass = base_class
    obj.base_class = obj.BaseClass

    hook.run('OnClassExtended', obj, base_class)

    library.last_class.parent[library.last_class.name] = obj
    library.last_class = nil

    return true
  end

  return false
end

--
-- class 'SomeClass' extends SomeOtherClass
-- class 'SomeClass' extends 'SomeOtherClass'
--

do
  local action_storage = fl.action_storage or {}
  fl.action_storage = action_storage

  --
  -- Function: fl.register_action (string id, function callback)
  -- Description: Registers an action that can be assigned to a player.
  -- Argument: string id - Identifier of the action.
  -- Argument: function callback - Function to call when the action is executed.
  --
  -- Returns: nil
  --
  function fl.register_action(id, callback)
    action_storage[id] = callback
  end

  --
  -- Function: fl.get_action (string id)
  -- Description: Retreives the action callback with the specified identifier.
  -- Argument: string id - ID of the action to get the callback of.
  --
  -- Returns: function - The callback.
  --
  function fl.get_action(id)
    return action_storage[id]
  end

  --
  -- Function: fl.get_all_actions ()
  -- Description: Can be used to directly access the table storing all of the actions.
  --
  -- Returns: table - The action_storage table.
  --
  function fl.get_all_actions()
    return action_storage
  end

  fl.register_action('spawning')
  fl.register_action('idle')
end

--
-- Function: fl.get_schema_folder ()
-- Description: Gets the folder of the currently loaded schema.
--
-- Returns: string - The folder of the currently loaded schema.
--
function fl.get_schema_folder()
  if SERVER then
    return fl.schema
  else
    return fl.shared.schema_folder or 'flux'
  end
end

-- A function to get schema's name.
function fl.get_schema_name()
  return Schema and Schema:get_name() or fl.schema or 'Unknown'
end

--
-- Function: fl.serialize (table toSerialize)
-- Description: Converts a table into the string format.
-- Argument: table toSerialize - Table to convert.
--
-- Returns: string - pON-encoded table. If pON fails then JSON is returned.
--
function fl.serialize(tab)
  if istable(tab) then
    local success, value = pcall(pon.encode, tab)

    if !success then
      success, value = pcall(util.TableToJSON, tab)

      if !success then
        ErrorNoHalt('Failed to serialize a table!\n')
        ErrorNoHalt(value..'\n')

        return ''
      end
    end

    return value
  else
    print('You must serialize a table, not '..type(tab)..'!')
    return ''
  end
end

--
-- Function: fl.deserialize (string toDeserialize)
-- Description: Converts a string back into table. Uses pON at first, if it fails it falls back to JSON.
-- Argument: string toDeserialize - String to convert.
--
-- Returns: table - Decoded string.
--
function fl.deserialize(data)
  if isstring(data) then
    local success, value = pcall(pon.decode, data)

    if !success then
      success, value = pcall(util.JSONToTable, data)

      if !success then
        ErrorNoHalt('Failed to deserialize a string!\n')
        ErrorNoHalt(value..'\n')

        return {}
      end
    end

    return value
  else
    print('You must deserialize a string, not '..type(data)..'!')
    return {}
  end
end

--
-- Function: fl.include_schema ()
-- Description: Includes the currently loaded schema's files. Performs deferred load on client.
--
-- Returns: nil
--
function fl.include_schema()
  if SERVER then
    return plugin.include_schema()
  else
    plugin.include_schema()

    -- Wait just a tiny bit for stuff to catch up
    timer.Simple(0.2, function()
      cable.send('fl_client_included_schema', true)
      hook.run('FluxClientSchemaLoaded')
    end)
  end
end

--
-- Function: fl.include_plugins (string folder)
-- Description: Includes all of the plugins inside the folder. Includes files first, then folders. Does not handle plugin-inside-of-plugin scenarios.
-- Argument: string folder - Folder relative to Lua's PATH (lua/, gamemodes/).
--
-- Returns: nil
--
function fl.include_plugins(folder)
  return plugin.include_plugins(folder)
end

--
-- Function: fl.get_schema_info ()
-- Description: Gets the table containing all of the information about the currently loaded schema.
--
-- Returns: table - The schema info table.
--
function fl.get_schema_info()
  if SERVER then
    if fl.schema_info then return fl.schema_info end

    local schema_folder = string.lower(fl.get_schema_folder())
    local schema_data = util.KeyValuesToTable(
      fileio.Read('gamemodes/'..schema_folder..'/'..schema_folder..'.txt')
    ) or {}

    if schema_data['Gamemode'] then
      schema_data = schema_data['Gamemode']
    end

    fl.schema_info = {}
      fl.schema_info['name']        = schema_data['title'] or 'Undefined'
      fl.schema_info['author']      = schema_data['author'] or 'Undefined'
      fl.schema_info['description'] = schema_data['description'] or 'Undefined'
      fl.schema_info['version']     = schema_data['version'] or 'Undefined'
      fl.schema_info['folder']      = string.gsub(schema_folder, '/schema', '')
    return fl.schema_info
  else
    return fl.shared.schema_info
  end
end

if SERVER then
  fl.shared.schema_info = fl.get_schema_info()
end
