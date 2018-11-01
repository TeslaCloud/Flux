PLUGIN:set_global('Observer')

util.include('cl_hooks.lua')
util.include('sv_hooks.lua')

if fl.admin then
  fl.admin:register_permission('noclip', 'Noclip', 'Lets the player use observer mode / noclip.', 'general')
end

if SERVER then
  config.set('observer_reset', false)
else
  config.add_to_menu('observer_reset', 'Observer Reset', "Whether or not should player's position be restored when they leave observer mode?", 'boolean')
end
