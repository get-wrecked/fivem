fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

shared_scripts {
  'config.lua',
  'lib/shared-*.lua',
}

client_scripts {
  'clipping/client-main.lua',
  'gameVein/client-main.lua',
  'gameVein/shaft/client-overseer.lua',
  'gameVein/shaft/client-minecart.lua',
  'gameVein/assayer/client-assayer.lua',
  'gameVein/ore/client-name.lua',
  'gameVein/ore/client-community-name.lua',
  'gameVein/ore/client-heartbeat.lua',
  'gameVein/ore/client-entity-matrix.lua',
  'gameVein/ore/client-camera-matrix.lua',
  'gameVein/ore/client-job.lua',
  'screenshot/client-main.lua',
  'lib/client-*.lua',
}

server_scripts {
  'clipping/server-main.lua' ,
  'gameVein/server-main.lua',
  'gameVein/assayer/server-assayer.lua',
  'gameVein/ore/server-community-name.lua',
  'gameVein/ore/server-job.lua',
  'lib/server-*.lua',
}

files {
  'ui/dist/index.html',
  'ui/dist/**/*',
}

ui_page 'ui/dist/index.html'