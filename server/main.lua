local playersProcessingCannabis = {}
local outofbound = true
local alive = true

local function ValidatePickupCannabis(src)
	local ECoords = Config.CircleZones.WeedField.coords
	local PCoords = GetEntityCoords(GetPlayerPed(src)) 
	local Dist = #(PCoords-ECoords)
	if Dist <= 90 then return true end
end

local function ValidateProcessCannabis(src)
	local ECoords = Config.CircleZones.WeedProcessing.coords
	local PCoords = GetEntityCoords(GetPlayerPed(src))
	local Dist = #(PCoords-ECoords)
	if Dist <= 5 then return true end
end

local function FoundExploiter(src,reason)
	-- ADD YOUR BAN EVENT HERE UNTIL THEN IT WILL ONLY KICK THE PLAYER --
	DropPlayer(src,reason)
	SendDiscordLog("Exploit Attempt", "Player ID: "..src.." tried to exploit: "..reason, 16711680) -- Red color for alert
end

function SendDiscordLog(name, message, color)
    local embed = {
        {
            ["title"] = name,
            ["description"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] = {
                ["text"] = "HW Scripts | Logs"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({username = "Server Logs", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

RegisterServerEvent('hw_weed:sellDrug')
AddEventHandler('hw_weed:sellDrug', function(itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.DrugDealerItems[itemName]
    local xItem = xPlayer.getInventoryItem(itemName)

    if type(amount) ~= 'number' or type(itemName) ~= 'string' then
        SendDiscordLog("Invalid Sale Attempt", ('%s attempted to sell with invalid input type!'):format(xPlayer.identifier), 16711680)
        FoundExploiter(xPlayer.source, 'SellDrugs Event Trigger')
        return
    end

    if not price then
        SendDiscordLog("Invalid Drug Sale", ('%s attempted to sell an invalid drug!'):format(xPlayer.identifier), 16711680)
        return
    end

    if amount < 0 or xItem == nil or xItem.count < amount then
        xPlayer.showNotification(TranslateCap('dealer_notenough'))
        return
    end

    price = ESX.Math.Round(price * amount)

    if Config.GiveBlack then
        xPlayer.addAccountMoney('black_money', price, "Drugs Sold")
    else
        xPlayer.addMoney(price, "Drugs Sold")
    end

    xPlayer.removeInventoryItem(xItem.name, amount)
    xPlayer.showNotification(TranslateCap('dealer_sold', amount, xItem.label, ESX.Math.GroupDigits(price)))
    SendDiscordLog("Drug Sale", ('%s sold %s amount of %s for %s'):format(xPlayer.identifier, amount, itemName, price), 65280) -- Green color for success

    if Config.Debug then
        print("^7[^1DEBUG^7]A player sold drugs: " .. itemName .. " for " .. price)
    end
end)

ESX.RegisterServerCallback('hw_weed:buyLicense', function(source, cb, licenseName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local license = Config.LicensePrices[licenseName]

	if license then
		if xPlayer.getMoney() >= license.price then
			xPlayer.removeMoney(license.price)

			TriggerEvent('esx_license:addLicense', source, licenseName, function()
				cb(true)

                if Config.Debug then
                    print("^7[^1DEBUG^7]A player bought license:" .. licenseName)
                end

			end)
		else
			cb(false)
		end
	else
		print(('hw_weed: %s attempted to buy an invalid license!'):format(xPlayer.identifier))
		cb(false)
	end
end)

RegisterServerEvent('hw_weed:pickedUpCannabis')
AddEventHandler('hw_weed:pickedUpCannabis', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local cime = math.random(5,10)
    if ValidatePickupCannabis(src) then
        if xPlayer.canCarryItem('cannabis', cime) then
            xPlayer.addInventoryItem('cannabis', cime)
            SendDiscordLog("Cannabis Pickup", ('%s picked up %s cannabis'):format(xPlayer.identifier, cime), 65280)

            if Config.Debug then
                print("^7[^1DEBUG^7]A player picked up cannabis")
            end

        else
            xPlayer.showNotification(TranslateCap('weed_inventoryfull'))
        end
    else
        FoundExploiter(src, 'Cannabis Pickup Trigger')
    end
end)

ESX.RegisterServerCallback('hw_weed:canPickUp', function(source, cb, item)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.canCarryItem(item, 1))
end)

RegisterServerEvent('hw_weed:outofbound')
AddEventHandler('hw_weed:outofbound', function()
	outofbound = true
end)

ESX.RegisterServerCallback('hw_weed:cannabis_count', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xCannabis = xPlayer.getInventoryItem('cannabis').count
	cb(xCannabis)
end)

RegisterServerEvent('hw_weed:processCannabis')
AddEventHandler('hw_weed:processCannabis', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    -- Validate the player is in the processing area
    if ValidateProcessCannabis(_source) then
        -- Ensure the player has enough cannabis to start processing
        if xPlayer.getInventoryItem('cannabis').count >= 3 then
            -- Flag this player as processing
            if not playersProcessingCannabis[_source] then
                playersProcessingCannabis[_source] = true
                
                -- Inform the player processing has started
                xPlayer.showNotification(TranslateCap('weed_processing_started'))

                -- Start processing loop
                Citizen.CreateThread(function()
                    while playersProcessingCannabis[_source] do
                        Citizen.Wait(Config.Delays.WeedProcessing)
                        if xPlayer.getInventoryItem('cannabis').count >= 3 then
                            if xPlayer.canSwapItem('cannabis', 3, 'marijuana', 1) then
                                xPlayer.removeInventoryItem('cannabis', 3)
                                xPlayer.addInventoryItem('marijuana', 1)
                                SendDiscordLog("Cannabis Processed", ('%s processed cannabis into marijuana'):format(xPlayer.identifier), 65280)

                                if Config.Debug then
                                    print("^7[^1DEBUG^7]A player processed cannabis into marijuana")
                                end

                            else
                                xPlayer.showNotification(TranslateCap('weed_processingfull'))
                                playersProcessingCannabis[_source] = false
                            end
                        else
                            xPlayer.showNotification(TranslateCap('weed_processingenough'))
                            playersProcessingCannabis[_source] = false
                        end
                    end
                end)
            end
        else
            xPlayer.showNotification(TranslateCap('weed_processingenough'))
        end
    else
        FoundExploiter(_source, 'Cannabis Processing Trigger')
    end
end)

function CancelProcessing(playerId)
	if playersProcessingCannabis[playerId] then
		ESX.ClearTimeout(playersProcessingCannabis[playerId])
		playersProcessingCannabis[playerId] = nil
	end
end

RegisterServerEvent('hw_weed:stopProcessing')
AddEventHandler('hw_weed:stopProcessing', function()
    local _source = source
    if playersProcessingCannabis[_source] then
        playersProcessingCannabis[_source] = false
        SendDiscordLog("Processing Stopped", ('%s stopped processing cannabis.'):format(ESX.GetPlayerFromId(_source).identifier), 65280)

        if Config.Debug then
            print("^7[^1DEBUG^7]A player stopped the processing of cannabis.")
        end

    end
end)

RegisterServerEvent('hw_weed:cancelProcessing')
AddEventHandler('hw_weed:cancelProcessing', function()
	CancelProcessing(source)
	SendDiscordLog("Cannabis Cancel", ('%s canceled cannabis progress'):format(xPlayer.identifier), 65280)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	CancelProcessing(playerId)
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	CancelProcessing(source)
end)
