local spawnedCokes = 0
local cokePlants = {}
local isPickingUp, isProcessing = false, false

CreateThread(function() 
	while true do
		Wait(700)
		local coords = GetEntityCoords(PlayerPedId())

		if #(coords - Config.CircleZones.CokeField.coords) < 50 then
			SpawnCokePlants()
		end
	end
end)

CreateThread(function()
	while true do
		local wait = 1000
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if #(coords - Config.CircleZones.CokeProcessing.coords) < 1 then
			wait = 2
			if not isProcessing then
				ESX.ShowHelpNotification(TranslateCap('coke_processprompt'))
			end

			if IsControlJustReleased(0, 38) and not isProcessing then
				ESX.TriggerServerCallback('hw_coke:coke_count', function(xCoke)
					if Config.LicenseEnable then
						ESX.TriggerServerCallback('esx_license:checkLicense', function(hasProcessingLicense)
							if hasProcessingLicense then
								ProcessCoke(xCoke)
							else
								OpenBuyLicenseMenu('coke_processing')
							end
						end, GetPlayerServerId(PlayerId()), 'coke_processing')
					else
						ProcessCoke(xCoke)
					end
				end)
			end
		end
		Wait(wait)
	end
end)

function ProcessCoke(xCoke)
	isProcessing = true
	ESX.ShowNotification(TranslateCap('coke_processingstarted'))
  TriggerServerEvent('hw_coke:processCoke')
	if(xCannabis <= 3) then
		xCannabis = 0
	end
  local timeLeft = (Config.Delays.CokeProcessing * xCannabis) / 1000
	local playerPed = PlayerPedId()

	while timeLeft > 0 do
		Wait(1000)
		timeLeft = timeLeft - 1

		if #(GetEntityCoords(playerPed) - Config.CircleZones.CokeProcessing.coords) > 4 then
			ESX.ShowNotification(TranslateCap('coke_processingtoofar'))
			TriggerServerEvent('hw_coke:cancelProcessing')
			TriggerServerEvent('hw_coke:outofbound')
			break
		end
	end

	isProcessing = false
end

CreateThread(function()
	while true do
		local Sleep = 1500

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #cokePlants, 1 do
			if #(coords - GetEntityCoords(cokePlants[i])) < 1.5 then
				nearbyObject, nearbyID = cokePlants[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then
			Sleep = 0
			if not isPickingUp then
				ESX.ShowHelpNotification(TranslateCap('coke_pickupprompt'))
			end

			if IsControlJustReleased(0, 38) and not isPickingUp then
				isPickingUp = true

				ESX.TriggerServerCallback('hw_coke:canPickUp', function(canPickUp)
					if canPickUp then
						TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)

						Wait(2000)
						ClearPedTasks(playerPed)
						Wait(1500)
		
						ESX.Game.DeleteObject(nearbyObject)
		
						table.remove(cokePlants, nearbyID)
						spawnedCokes = spawnedCokes - 1
		
						TriggerServerEvent('hw_coke:pickedUpCannabis')
					else
						ESX.ShowNotification(TranslateCap('coke_inventoryfull'))
					end

					isPickingUp = false
				end, 'coke')
			end
		end
	Wait(Sleep)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(cokePlants) do
			ESX.Game.DeleteObject(v)
		end
	end
end)

function SpawnCokePlants()
	while spawnedCokes < 25 do
		Wait(0)
		local cokeCoords = GenerateCokeCoords()

		ESX.Game.SpawnLocalObject('prop_weed_02', cokeCoords, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)

			table.insert(cokePlants, obj)
			spawnedCokes = spawnedCokes + 1
		end)
	end
end

function ValidateCokeCoord(plantCoord)
	if spawnedCokes > 0 then
		local validate = true

		for k, v in pairs(cokePlants) do
			if #(plantCoord - GetEntityCoords(v)) < 5 then
				validate = false
			end
		end

		if #(plantCoord - Config.CircleZones.CokeField.coords) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateCokeCoords()
	while true do
		Wait(0)

		local cokeCoordX, cokeCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-90, 90)

		Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-90, 90)

		cokeCoordX = Config.CircleZones.CokeField.coords.x + modX
		cokeCoordY = Config.CircleZones.CokeField.coords.y + modY

		local coordZ = GetCoordZ(cokeCoordX, cokeCoordY)
		local coord = vector3(cokeCoordX, cokeCoordY, coordZ)

		if ValidateCokeCoord(coord) then
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 48.0, 49.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 43.0
end
