fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'HenkW'
description 'Simple coke script for harvesting, processing and selling'

version '1.0.1'

shared_script '@es_extended/imports.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'server/main.lua',
	'server/version.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/main.lua',
	'client/coke.lua'
}

dependencies {
	'es_extended'
}

shared_script '@es_extended/imports.lua'