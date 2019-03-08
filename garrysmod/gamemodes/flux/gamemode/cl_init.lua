fl = fl or {}
fl.start_time = os.clock()

-- Include pON, Cable and UTF-8 library
if !string.utf8upper or !pon or !cable then
  include 'lib/vendor/utf8.min.lua'
  include 'lib/vendor/pon.min.lua'
  include 'lib/vendor/cable.min.lua'
end

if fl.initialized then
  MsgC(Color(0, 255, 100, 255), 'Lua auto-reload in progress...\n')
else
  MsgC(Color(0, 255, 100, 255), 'Initializing...\n')
end

-- Initiate shared boot.
include 'shared.lua'

font.create_fonts()

if fl.initialized then
  MsgC(Color(0, 255, 100, 255), 'Auto-reloaded in '..math.Round(os.clock() - fl.start_time, 3)..' second(s)\n')
else
  MsgC(Color(0, 255, 100, 255), 'Flux v'..GM.version..' ('..GM.code_name..') has finished loading in '..math.Round(os.clock() - fl.start_time, 3)..' second(s)\n')

  fl.initialized = true
end
