Config = {}

Config.Debug = true -- enable this for printing certain server actions

Config.checkForUpdates = true  -- recommended to leave on true :)

Config.WebhookURL = "https://discord.com/api/webhooks/1204168742683021375/lNTrahrse2SgMvw7AXqEm3yQ3R8hylrVoUPt_wDxmzQZ2Jo2soVCW0g4HeYHIdud2QDB" -- place youre webhook URL here

Config.Locale = GetConvar('esx:locale', 'en')

Config.Delays = {
	CokeProcessing = 1000 * 7
}

Config.DrugDealerItems = {  -- price for selling
	pure_coke = 250
}

Config.LicenseEnable = true -- enable processing licenses? The player will be required to buy a license in order to process drugs. Requires esx_license

Config.LicensePrices = {
	coke_processing = {label = TranslateCap('license_coke'), price = 15000}
}

Config.GiveBlack = true -- give black money? if disabled it'll give regular cash.

Config.CircleZones = {
	CokeField = {coords = vector3(2220.72, 5582.52, 53.81), name = TranslateCap('blip_cokefield'), color = 25, sprite = 496, radius = 100.0},
	CokeProcessing = {coords = vector3(2329.02, 2571.29, 46.68), name = TranslateCap('blip_cokeprocessing'), color = 25, sprite = 496},

	DrugDealer = {coords = vector3(-1172.02, -1571.98, 4.66), name = TranslateCap('blip_drugdealer'), color = 6, sprite = 378},
}

Config.Marker = {
	Distance = 100.0,
	Color = {r=60,g=230,b=60,a=255},
	Size = vector3(1.5,1.5,1.0),
	Type = 1,
}

-- min amount of Config.DrugDealerItems to sell
-- max amount of Config.DrugDealerItems to sell
Config.SellMenu = {
	Min = 1,
	Max = 50
}
