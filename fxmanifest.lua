--[[
    -----------------------------------------------------------------------
    Resource: exe-sleep
    Author: ExeDevelopment
    Discord: https://discord.gg/H2ztYhzEGd
    GitHub: https://github.com/degans1
    Description: QBCore Uyumlu Gelişmiş, Tam Optimize (0.00 ms) Uyku & Yorgunluk Sistemi
    -----------------------------------------------------------------------
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'ExeDevelopment'
description 'ExeDevelopment - QBCore Gelişmiş Uyku & Yorgunluk Scripti'
version '1.2.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core'
}
