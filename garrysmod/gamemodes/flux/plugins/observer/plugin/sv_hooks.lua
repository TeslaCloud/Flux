function flObserver:ShouldObserverReset(player)
  return config.get('observer_reset')
end

function flObserver:PlayerEnterNoclip(player)
  if !player:can('noclip') then
    fl.player:notify(player, 'You do not have permission to do this.')

    return false
  end

  player.observer_data = {
    position = player:GetPos(),
    angles = player:EyeAngles(),
    color = player:GetColor(),
    move_type = player:GetMoveType(),
    should_reset = (plugin.call('ShouldObserverReset', player) != false)
  }

  player:SetMoveType(MOVETYPE_NOCLIP)
  player:DrawWorldModel(false)
  player:DrawShadow(false)
  player:SetNoDraw(true)
  player:SetNotSolid(true)
  player:SetColor(Color(0, 0, 0, 0))

  player:set_nv('observer', true)

  return false
end

function flObserver:PlayerExitNoclip(player)
  local data = player.observer_data

  if data then
    player:SetMoveType(data.move_type or MOVETYPE_WALK)
    player:DrawWorldModel(true)
    player:DrawShadow(true)
    player:SetNoDraw(false)
    player:SetNotSolid(false)
    player:SetColor(data.color)

    if data.should_reset then
      timer.Simple(FrameTime(), function()
        if IsValid(player) then
          player:SetPos(data.position)
          player:SetEyeAngles(data.angles)
        end
      end)
    end
  end

  player.observer_data = nil
  player:set_nv('observer', false)

  return false
end
