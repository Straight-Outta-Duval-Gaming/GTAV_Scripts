fx_version 'cerulean'
game 'gta5'

author 'GTAV Scripting'
description 'Buy and release attack monkeys from your trunk with QBCore'
version '2.0.0'

dependencies {
    'qb-core',
    'qb-target'
}

shared_script 'shared/main.lua'
shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

lua54 'yes'
