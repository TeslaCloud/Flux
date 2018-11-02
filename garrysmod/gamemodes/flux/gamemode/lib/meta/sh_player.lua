local player_meta = FindMetaTable('Player')

function player_meta:has_initialized()
  return self:GetDTBool(BOOL_INITIALIZED) or false
end

function player_meta:get_data()
  return self:get_nv('fl_data', {})
end

player_meta.fl_name = player_meta.fl_name or player_meta.Name

function player_meta:name(force_true_name)
  return (!force_true_name and hook.run('GetPlayerName', self)) or self:get_nv('name', self:fl_name())
end

function player_meta:steam_name()
  return self:fl_name()
end

function player_meta:SetModel(path)
  local old_model = self:GetModel()

  hook.run('PlayerModelChanged', self, path, old_model)

  if SERVER then
    cable.send(nil, 'fl_player_model_changed', self:EntIndex(), path, old_model)
  end

  return self:flSetModel(path)
end

--[[
  Actions system
--]]

function player_meta:set_action(id, force)
  if force or self:get_action() == 'none' then
    self:set_nv('action', id)

    return true
  end
end

function player_meta:get_action()
  return self:get_nv('action', 'none')
end

function player_meta:is_doing_action(id)
  return (self:get_action() == id)
end

function player_meta:reset_action()
  self:set_action('none', true)
end

function player_meta:do_action(id)
  local act = self:get_action()

  if isstring(id) then
    act = id
  end

  if act and act != 'none' then
    local action_table = fl.get_action(act)

    if istable(action_table) and isfunction(action_table.callback) then
      try {
        action_table.callback, self, act
      } catch {
        function(exception)
          ErrorNoHalt("Player action '"..tostring(act).."' has failed to run!\n"..exception..'\n')
        end
      }
    end
  end
end

function player_meta:running()
  if self:Alive() and !self:Crouching() and self:GetMoveType() == MOVETYPE_WALK
  and (self:OnGround() or self:WaterLevel() > 0) and self:GetVelocity():Length2DSqr() > (config.get('walk_speed', 100) + 20)^2 then
    return true
  end

  return false
end

--[[
  Admin system

  Hook your admin mods to these functions, they're universally used
  throughout the Flux framework.
--]]

function player_meta:can(action, object)
  return hook.run('PlayerHasPermission', self, action, object)
end

function player_meta:is_root()
  return hook.run('PlayerIsRoot', self)
end

function player_meta:has_group(group)
  if self:GetUserGroup() == group then
    return true
  end

  return hook.run('PlayerHasGroup', self, group)
end
