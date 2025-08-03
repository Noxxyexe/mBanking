-- Generated automaticly by RB Generator.
fx_version('cerulean')
game('gta5')

author('Noxxy')
description('Advanced Banking System')
version('1.0.0')

dependency('es_extended')

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page('web/index.html')

files {
    'web/index.html',
    'web/styles.css',
    'web/script.js',
    'web/img/card.png',
    'web/img/gift.png',
}

-- Crédit : https://discord.gg/WaNB7dCRZW