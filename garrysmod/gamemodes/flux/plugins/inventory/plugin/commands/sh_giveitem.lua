local COMMAND = Command.new('giveitem')
COMMAND.name = 'GiveItem'
COMMAND.description = t'give_item.description'
COMMAND.syntax = t'give_item.syntax'
COMMAND.category = 'character_management'
COMMAND.arguments = 2
COMMAND.player_arg = 1
COMMAND.aliases = { 'chargiveitem', 'plygiveitem' }

function COMMAND:on_run(player, targets, item_name, amount)
  local item_table = item.Find(item_name)

  if item_table then
    amount = tonumber(amount) or 1

    for k, v in ipairs(targets) do
      for i = 1, amount do
        v:GiveItem(item_table.id)
      end

      fl.player:notify(v, t('give_item.target_message', { get_player_name(player), amount, item_table.name }))
    end

    fl.player:notify(player, t('give_item.player_message', { util.player_list_to_string(targets), amount, item_table.name }))
  else
    fl.player:notify(player, t('give_item.invalid_item', item_name))
  end
end

COMMAND:register()
