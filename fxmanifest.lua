fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'SeaM_Appearance'
author 'SeaM'
description 'Ped appearance, clothing stores, barbers, tattoo parlours and surgeons for SeaM_Core'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/data.lua',
}

client_scripts {
    'client/ped.lua',
    'client/camera.lua',
    'client/customization.lua',
    'client/shops.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/*',
}

dependency 'SeaM_Core'
