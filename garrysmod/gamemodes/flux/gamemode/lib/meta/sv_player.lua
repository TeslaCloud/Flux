local player_meta = FindMetaTable('Player')

function player_meta:save_player()
  local saveData = {
    steam_id = self:SteamID(),
    name = self:Name(),
    joinTime = self.flJoinTime or os.time(),
    lastPlayTime = os.time(),
    data = fl.serialize(self:get_data())
  }

  hook.run('SavePlayerData', self, saveData)

  if self.record then self.record:save() end
end

function player_meta:set_data(data)
  self:set_nv('fl_data', data or {})
end

function player_meta:SetPlayerData(key, value)
  local data = self:get_data()

  data[key] = value

  self:set_data(data)
end

function player_meta:GetPlayerData(key, default)
  return self:get_data()[key] or default
end

function player_meta:SetInitialized(initialized)
  if initialized == nil then initialized = true end

  self:SetDTBool(BOOL_INITIALIZED, initialized)
end

function player_meta:notify(message, arguments)
  fl.player:notify(self, message, arguments)
end

function player_meta:GetAmmoTable()
  local ammoTable = {}

  for k, v in pairs(game.get_ammo_list()) do
    local ammoCount = self:GetAmmoCount(k)

    if ammoCount > 0 then
      ammoTable[k] = ammoCount
    end
  end

  return ammoTable
end

function player_meta:RestorePlayer()
  if self:IsBot() then
    self.record = User.new()
    return hook.run('PlayerRestored', self, self.record)
  end

  User:where('steam_id', self:SteamID()):expect(function(obj)
    obj.player = self
    self.record = obj
    hook.run('PlayerRestored', self, obj)
  end):rescue(function(obj)
    ServerLog(self:Name()..' has joined for the first time!')
    obj.player = self
    obj.steam_id = self:SteamID()
    obj.name = self:Name()
    obj.role = 'user'
    self.record = obj
    hook.run('PlayerCreated', self, obj)
    obj:save()
    hook.run('PlayerRestored', self, obj)
  end)
end
