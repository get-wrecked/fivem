fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

shared_scripts {
  'config.lua',
  'lib/shared-*.lua',
}

client_scripts {
  'clipping/client-*.lua',
  'datavein/client-main.lua',
  'screenshot/client-main.lua',
  'lib/client-*.lua',
}

server_scripts {
  'clipping/server-*.lua' ,
  'datavein/server-main.lua',
  'lib/server-*.lua',
}

files {
  'ui/dist/index.html',
  'ui/dist/**/*',
}

ui_page 'ui/dist/index.html'