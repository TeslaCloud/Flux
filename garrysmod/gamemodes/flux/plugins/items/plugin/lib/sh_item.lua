library.new 'item'

-- Item Templates storage.
local stored = item.stored or {}
item.stored = stored

-- Actual items.
local instances = item.instances or {}
item.instances = instances

-- Instances table indexed by instance ID.
-- For quicker item lookups.
local sorted = item.sorted or {}
item.sorted = sorted

-- Items currently dropped and lying on the ground.
local entities = item.entities or {}
item.entities = entities

function item.GetAll()
  return stored
end

function item.GetInstances()
  return instances
end

function item.GetSorted()
  return sorted
end

function item.GetEntities()
  return entities
end

function item.register(id, data)
  if !data then return end

  if !isstring(data.name) and isstring(data.print_name) then
    data.name = data.print_name
  end

  if !isstring(id) and !isstring(data.name) then
    ErrorNoHalt('Attempt to register an item without a valid ID!')
    debug.Trace()

    return
  end

  if !id then
    id = data.name:to_id()
  end

  fl.dev_print('Registering item: ' .. tostring(id))

  data.id = id
  data.name = data.name or 'Unknown Item'
  data.print_name = data.print_name or data.name
  data.description = data.description or 'This item has no description!'
  data.weight = data.weight or 1
  data.stackable = data.stackable or false
  data.max_stack = data.max_stack or 64
  data.model = data.model or 'models/props_lab/cactus.mdl'
  data.skin = data.skin or 0
  data.color = data.color or nil
  data.cost = data.cost or 0
  data.special_color = data.special_color or nil
  data.category = data.category or t('item.category.other')
  data.is_base = data.is_base or false
  data.instance_id = ITEM_TEMPLATE
  data.data = data.data or {}
  data.custom_buttons = data.custom_buttons or {}
  data.action_sounds = data.action_sounds or {}
  data.use_text = data.use_text
  data.take_text = data.take_text
  data.cancel_text = data.cancel_text
  data.use_icon = data.use_icon
  data.take_icon = data.take_icon
  data.cancel_icon = data.cancel_icon
  data.slot_id = data.slot_id

  stored[id] = data
  instances[id] = instances[id] or {}
end

function item.ToSave(item_table)
  if !item_table then return end

  return {
    id = item_table.id,
    name = item_table.name,
    print_name = item_table.print_name,
    description = item_table.description,
    weight = item_table.weight,
    stackable = item_table.stackable,
    max_stack = item_table.max_stack,
    model = item_table.model,
    skin = item_table.skin,
    color = item_table.color,
    cost = item_table.cost,
    special_color = item_table.special_color,
    is_base = item_table.is_base,
    instance_id = item_table.instance_id,
    data = item_table.data,
    action_sounds = item_table.action_sounds,
    use_text = item_table.use_text,
    take_text = item_table.take_text,
    cancel_text = item_table.cancel_text,
    use_icon = item_table.use_icon,
    take_icon = item_table.take_icon,
    cancel_icon = item_table.cancel_icon,
    slot_id = item_table.slot_id,
    inventory_type = item_table.inventory_type
  }
end

-- Find item's template by it's ID.
function item.find_by_id(id)
  for k, v in pairs(stored) do
    if k == id or v.id == id then
      return v
    end
  end
end

-- Find all instances of certain template ID.
function item.FindAllInstances(id)
  if instances[id] then
    return instances[id]
  end
end

-- Finds instance by it's ID.
function item.FindInstanceByID(instance_id)
  for item_id, item_instances in pairs(instances) do
    if istable(item_instances) then
      for k, item_table in pairs(item_instances) do
        if item_table.instance_id == instance_id then
          return item_table
        end
      end
    end
  end
end

-- Finds an item template that belongs to certain instance ID.
function item.FindByInstanceID(instance_id)
  if !instance_id then return end

  if !sorted[instance_id] then
    sorted[instance_id] = item.FindInstanceByID(instance_id)
  end

  return sorted[instance_id]
end

function item.Find(name)
  if isnumber(name) then
    return item.FindInstanceByID(name)
  end

  if stored[id] then
    return stored[id]
  end

  for k, v in pairs(stored) do
    if v.id and v.name and v.print_name then
      if v.id == name or v.name:find(name) or v.print_name:find(name) then
        return v
      end

      if CLIENT then
        if v.print_name:find(name) then
          return v
        end
      end
    end
  end
end

function item.GenerateID()
  instances.count = instances.count or 0
  instances.count = instances.count + 1

  return instances.count
end

function item.New(id, data, forcedID)
  local item_table = item.find_by_id(id)

  if item_table then
    local itemID = forcedID or item.GenerateID()

    instances[id] = instances[id] or {}
    instances[id][itemID] = table.Copy(item_table)

    if istable(data) then
      table.safe_merge(instances[id][itemID], data)
    end

    instances[id][itemID].instance_id = itemID

    if SERVER then
      item.AsyncSave()
      cable.send(nil, 'ItemNewInstance', id, (data or 1), itemID)
    end

    return instances[id][itemID]
  end
end

function item.Remove(instance_id)
  local item_table = (istable(instance_id) and instance_id) or item.FindInstanceByID(instance_id)

  if item_table and item.IsInstance(item_table) then
    if IsValid(item_table.entity) then
      item_table.entity:Remove()
    end

    instances[item_table.id][item_table.instance_id] = nil

    if SERVER then
      item.AsyncSave()
    end

    fl.dev_print('Removed item instance ID: '..item_table.instance_id)
  end
end

function item.IsInstance(item_table)
  if !istable(item_table) then return end

  return (item_table.instance_id or ITEM_TEMPLATE) > ITEM_INVALID
end

function item.CreateBase(name)
  class(name, Item)
end

pipeline.register('item', function(id, file_name, pipe)
  ITEM = Item.new(id)

  util.include(file_name)

  if pipeline.is_aborted() then ITEM = nil return end

  ITEM:register() ITEM = nil
end)

function item.IncludeItems(directory)
  pipeline.include_folder('item', directory)
end

if SERVER then
  function item.Load()
    local loaded = data.load_schema('items/instances', {})

    if loaded and table.Count(loaded) > 0 then
      -- Returns functions to instances table after loading.
      for id, instanceTable in pairs(loaded) do
        local item_table = item.find_by_id(id)

        if item_table then
          for k, v in pairs(instanceTable) do
            local newItem = table.Copy(item_table)

            table.safe_merge(newItem, v)

            loaded[id][k] = newItem
          end
        end
      end

      instances = loaded
      item.instances = loaded
    end

    local loaded = data.load_schema('items/entities', {})

    if loaded and table.Count(loaded) > 0 then
      for id, instanceTable in pairs(loaded) do
        for k, v in pairs(instanceTable) do
          if instances[id] and instances[id][k] then
            item.Spawn(v.position, v.angles, instances[id][k])
          else
            loaded[id][k] = nil
          end
        end
      end

      entities = loaded
      item.entities = loaded
    end
  end

  function item.SaveInstances()
    local toSave = {}

    for k, v in pairs(instances) do
      if k == 'count' then
        toSave[k] = v
      else
        toSave[k] = {}
      end

      if istable(v) then
        for k2, v2 in pairs(v) do
          if istable(v2) then
            toSave[k][k2] = item.ToSave(v2)
          end
        end
      end
    end

    data.save_schema('items/instances', toSave)
  end

  function item.SaveEntities()
    local itemEnts = ents.FindByClass('fl_item')

    entities = {}

    for k, v in ipairs(itemEnts) do
      if IsValid(v) and v.item then
        entities[v.item.id] = entities[v.item.id] or {}

        entities[v.item.id][v.item.instance_id] = {
          position = v:GetPos(),
          angles = v:GetAngles()
        }
      end
    end

    data.save_schema('items/entities', entities)
  end

  function item.SaveAll()
    item.SaveInstances()
    item.SaveEntities()
  end

  function item.AsyncSave()
    local handle = coroutine.create(item.SaveAll)
    coroutine.resume(handle)
  end

  function item.AsyncSaveInstances()
    local handle = coroutine.create(item.SaveInstances)
    coroutine.resume(handle)
  end

  function item.AsyncSaveEntities()
    local handle = coroutine.create(item.SaveEntities)
    coroutine.resume(handle)
  end

  function item.NetworkItemData(player, item_table)
    if item.IsInstance(item_table) then
      cable.send(player, 'ItemData', item_table.id, item_table.instance_id, item_table.data)
    end
  end

  function item.NetworkItem(player, instance_id)
    cable.send(player, 'NetworkItem', instance_id, item.ToSave(item.FindInstanceByID(instance_id)))
  end

  function item.NetworkEntityData(player, ent)
    if IsValid(ent) then
      cable.send(player, 'ItemEntData', ent:EntIndex(), ent.item.id, ent.item.instance_id)
    end
  end

  -- A function to send info about items in the world.
  function item.SendToPlayer(player)
    local itemEnts = ents.FindByClass('fl_item')

    for k, v in ipairs(itemEnts) do
      if v.item then
        item.NetworkItem(player, v.item.instance_id)
      end
    end

    hook.run_client(player, 'OnItemDataReceived')
  end

  function item.Spawn(position, angles, item_table)
    if !position or !istable(item_table) then
      ErrorNoHalt('No position or item table is not a table!\n')

      return
    end

    if !item.IsInstance(item_table) then
      ErrorNoHalt('Cannot spawn non-instantiated item!\n')

      return
    end

    local ent = ents.Create('fl_item')

    ent:SetItem(item_table)

    local mins, maxs = ent:GetCollisionBounds()

    ent:SetPos(position + Vector(0, 0, maxs.z))

    if angles then
      ent:SetAngles(angles)
    end

    ent:Spawn()

    item_table:set_entity(ent)
    item.NetworkItem(player, item_table.instance_id)

    entities[item_table.id] = entities[item_table.id] or {}
    entities[item_table.id][item_table.instance_id] = entities[item_table.id][item_table.instance_id] or {}
    entities[item_table.id][item_table.instance_id] = {
      position = position,
      angles = angles
    }

    item.AsyncSaveEntities()

    return ent, item_table
  end

  cable.receive('RequestItemData', function(player, entIndex)
    local ent = Entity(entIndex)

    if IsValid(ent) then
      item.NetworkEntityData(player, ent)
    end
  end)
else
  cable.receive('ItemData', function(id, instance_id, data)
    if istable(instances[id][instance_id]) then
      instances[id][instance_id].data = data
    end
  end)

  cable.receive('NetworkItem', function(instance_id, item_table)
    if item_table and stored[item_table.id] then
      local newTable = table.Copy(stored[item_table.id])
      table.safe_merge(newTable, item_table)

      instances[newTable.id][instance_id] = newTable

      print('Received instance ID '..tostring(newTable))
    else
      print('FAILED TO RECEIVE INSTANCE ID '..instance_id)
    end
  end)

  cable.receive('ItemEntData', function(entIndex, id, instance_id)
    local ent = Entity(entIndex)

    if IsValid(ent) then
      local item_table = instances[id][instance_id]

      -- Client has to know this shit too I guess?
      ent:SetModel(item_table:GetModel())
      ent:SetSkin(item_table.skin)
      ent:SetColor(item_table:GetColor())

      -- Restore item's functions. For some weird reason they aren't properly initialized.
      table.safe_merge(ent, scripted_ents.Get('fl_item'))

      ent.item = item_table
    end
  end)

  cable.receive('ItemNewInstance', function(id, data, itemID)
    item.New(id, data, itemID)
  end)
end
