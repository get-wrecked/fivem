fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

version '0.0.0'

shared_scripts {
  'config.lua',
  'lib/shared-*.lua',
}

client_scripts {
  'lib/client-*.lua',
  'services/client-*.lua',
  'gameVein/client-main.lua',
  'gameVein/shaft/client-overseer.lua',
  'gameVein/shaft/client-minecart.lua',
  'gameVein/assayer/client-assayer.lua',
  'gameVein/ore/client-name.lua',
  'gameVein/ore/client-heartbeat.lua',
  'gameVein/ore/client-cfx-id.lua',
  'gameVein/ore/client-entity-matrix.lua',
  'gameVein/ore/client-camera-matrix.lua',
  'gameVein/ore/client-job.lua',
  'gameVein/ore/client-vehicle.lua',
  'clipping/client-*.lua',
  'clipping/lookout/client-*.lua',
  'clipping/signal/client-*.lua',
  'clipping/vessel/client-*.lua',
  'superSoaker/client-main.lua',
}

server_scripts {
  'lib/server-*.lua',
  'services/server-*.lua',
  'gameVein/server-main.lua',
  'gameVein/ore/server-cfx-id.lua',
  'gameVein/ore/server-community-name.lua',
  'gameVein/ore/server-job.lua',
  'superSoaker/server-main.lua',
  'lib/server-*.lua',
}

files {
  'ui/dist/index.html',
  'ui/dist/**/*',
}

ui_page 'ui/dist/index.html'

provide 'screenshot-basic'
