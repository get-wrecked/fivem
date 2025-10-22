fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

version '1.13.6'

description 'Medal for FiveM'

shared_scripts {
  'config.lua',
  'lib/shared-*.lua',
  'services/shared-*.lua',
}

client_scripts {
  'lib/client-*.lua',
  'services/client-*.lua',
  'gameVein/client-*.lua',
  'gameVein/shaft/client-*.lua',
  'gameVein/assayer/client-*.lua',
  'gameVein/ore/client-*.lua',
  'clipping/client-*.lua',
  'clipping/lookout/client-*.lua',
  'clipping/signal/client-*.lua',
  'clipping/vessel/client-*.lua',
  'superSoaker/client-*.lua',
}

server_scripts {
  'lib/server-*.lua',
  'services/server-*.lua',
  'gameVein/server-*.lua',
  'gameVein/assayer/server-*.lua',
  'gameVein/ore/server-*.lua',
  'superSoaker/server-*.lua',
}

files {
  'ui/dist/index.html',
  'ui/dist/**/*',
}

ui_page 'ui/dist/index.html'

provide 'screenshot-basic'
