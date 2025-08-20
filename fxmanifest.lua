fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

shared_scripts {
  'config.lua',
  'lib/shared-logger.lua',
}

client_scripts {
  'clipping/client-*.lua',
  'datavein/client-main.lua',
  'screenshot/client-main.lua',
  'lib/client-main.lua',
}

server_scripts {
  'clipping/server-*.lua' ,
  'datavein/server-main.lua',
  'lib/server-main.lua',
}

files {
  'ui/dist/index.html',
  'ui/dist/**/*',
}

ui_page 'ui/dist/index.html'