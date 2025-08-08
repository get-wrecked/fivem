fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

shared_scripts {
  'shared/config.lua'
}
client_scripts { 
  'client/*.lua' ,
}
server_scripts {
  'server/*.lua' ,
}



files {
  'ui/dist/index.html',
  'ui/dist/**/*',
}

ui_page 'ui/dist/index.html'