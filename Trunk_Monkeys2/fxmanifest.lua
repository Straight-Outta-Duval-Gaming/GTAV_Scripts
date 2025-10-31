fx_version 'cerulean'
game 'gta5'

author 'GTAV Scripting'
description 'Buy and release attack monkeys from your trunk'
version '1.0.0'

dependencies {
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

lua54 'yes'
