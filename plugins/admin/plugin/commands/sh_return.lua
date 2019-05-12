local COMMAND = Command.new('return')
COMMAND.name = 'Return'
COMMAND.description = 'returncmd.description'
COMMAND.syntax = 'returncmd.syntax'
COMMAND.permission = 'assistant'
COMMAND.category = 'categories.administration'
COMMAND.arguments = 1
COMMAND.immunity = true
COMMAND.aliases = { 'return', 'back' }

function COMMAND:on_run(player, targets)
  for k, v in pairs(targets) do
    if IsValid(v) and v.prev_pos then
      v:teleport(v.prev_pos)
      v.prev_pos = nil
    end
  end

  player:notify('returncmd.notify', util.player_list_to_string(targets))
end

COMMAND:register()