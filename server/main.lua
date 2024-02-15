local playersProcessingCoke = {}
local outofbound = true
local alive = true

local function ValidatePickupCoke(src)
	local ECoords = Config.CircleZones.CokeField.coords
	local PCoords = GetEntityCoords(GetPlayerPed(src)) 
	local Dist = #(PCoords-ECoords)
	if Dist <= 90 then return true end
end

local function ValidateProcessCoke(src)
	local ECoords = Config.CircleZones.CokeProcessing.coords
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

RegisterServerEvent('hw_coke:sellDrug')
AddEventHandler('hw_coke:sellDrug', function(itemName, amount)
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

ESX.RegisterServerCallback('hw_coke:buyLicense', function(source, cb, licenseName)
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
		print(('hw_coke: %s attempted to buy an invalid license!'):format(xPlayer.identifier))
		cb(false)
	end
end)

RegisterServerEvent('hw_coke:pickedUpCoke')
AddEventHandler('hw_coke:pickedUpCoke', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local cime = math.random(5,10)
    if ValidatePickupCoke(src) then
        if xPlayer.canCarryItem('coke', cime) then
            xPlayer.addInventoryItem('coke', cime)
            SendDiscordLog("Coke Pickup", ('%s picked up %s coke'):format(xPlayer.identifier, cime), 65280)

            if Config.Debug then
                print("^7[^1DEBUG^7]A player picked up coke")
            end

        else
            xPlayer.showNotification(TranslateCap('coke_inventoryfull'))
        end
    else
        FoundExploiter(src, 'Coke Pickup Trigger')
    end
end)

ESX.RegisterServerCallback('hw_coke:canPickUp', function(source, cb, item)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.canCarryItem(item, 1))
end)

RegisterServerEvent('hw_coke:outofbound')
AddEventHandler('hw_coke:outofbound', function()
	outofbound = true
end)

ESX.RegisterServerCallback('hw_coke:coke_count', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xCoke = xPlayer.getInventoryItem('coke').count
	cb(xCoke)
end)

RegisterServerEvent('hw_coke:processCoke')
AddEventHandler('hw_coke:processCoke', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    -- Validate the player is in the processing area
    if ValidateProcessCoke(_source) then
        -- Ensure the player has enough coke to start processing
        if xPlayer.getInventoryItem('coke').count >= 3 then
            -- Flag this player as processing
            if not playersProcessingCoke[_source] then
                playersProcessingCoke[_source] = true
                
                -- Inform the player processing has started
                xPlayer.showNotification(TranslateCap('coke_processing_started'))

                -- Start processing loop
                Citizen.CreateThread(function()
                    while playersProcessingCoke[_source] do
                        Citizen.Wait(Config.Delays.CokeProcessing)
                        if xPlayer.getInventoryItem('coke').count >= 3 then
                            if xPlayer.canSwapItem('coke', 3, 'pure_coke', 1) then
                                xPlayer.removeInventoryItem('coke', 3)
                                xPlayer.addInventoryItem('pure_coke', 1)
                                SendDiscordLog("Coke Processed", ('%s processed coke into pure_coke'):format(xPlayer.identifier), 65280)

                                if Config.Debug then
                                    print("^7[^1DEBUG^7]A player processed coke into marijuana")
                                end

                            else
                                xPlayer.showNotification(TranslateCap('coke_processingfull'))
                                playersProcessingCoke[_source] = false
                            end
                        else
                            xPlayer.showNotification(TranslateCap('coke_processingenough'))
                            playersProcessingCoke[_source] = false
                        end
                    end
                end)
            end
        else
            xPlayer.showNotification(TranslateCap('coke_processingenough'))
        end
    else
        FoundExploiter(_source, 'Coke Processing Trigger')
    end
end)

function CancelProcessing(playerId)
	if playersProcessingCoke[playerId] then
		ESX.ClearTimeout(playersProcessingCoke[playerId])
		playersProcessingCoke[playerId] = nil
	end
end

RegisterServerEvent('hw_coke:stopProcessing')
AddEventHandler('hw_coke:stopProcessing', function()
    local _source = source
    if playersProcessingCoke[_source] then
        playersProcessingCoke[_source] = false
        SendDiscordLog("Processing Stopped", ('%s stopped processing coke.'):format(ESX.GetPlayerFromId(_source).identifier), 65280)

        if Config.Debug then
            print("^7[^1DEBUG^7]A player stopped the processing of coke.")
        end

    end
end)

RegisterServerEvent('hw_coke:cancelProcessing')
AddEventHandler('hw_coke:cancelProcessing', function()
	CancelProcessing(source)
	SendDiscordLog("Coke Cancel", ('%s canceled coke progress'):format(xPlayer.identifier), 65280)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	CancelProcessing(playerId)
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	CancelProcessing(source)
end)
