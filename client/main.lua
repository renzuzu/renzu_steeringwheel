if GetResourceState('renzu_tuners') ~= 'started' then print("renzu_tuners missing") return end
local wheels = false
local ped
local vehicle
local maxgear = 1
local vehicleflags
local invehicle = false
RegisterCommand('steeringwheel', function(source, args, raw)
	if not invehicle then return end
	wheels = not wheels
	maxgear = exports.renzu_tuners:SetVehicleManualGears(vehicle)
	vehicleflags = GetVehicleHandlingInt(vehicle, 'CHandlingData', 'strHandlingFlags')
	SendNUIMessage({
		apistart = wheels
	})
end)

local throttle = 0.0
local brake
local clutch
local lastgear = -1
local wheel = 0.0
RegisterNUICallback('nuicb', function(data,cb)
	cb(1)
	if data.wheel then
		wheel = data.wheel
	end
	if data.throttle then
		throttle = data.throttle
	end
	if data.brake then
		brake = data.brake
	end
	if data.clutch then
		clutch = data.clutch
	end
	if data.gear and lastgear ~= data.gear then
		lastgear = data.gear
		exports.renzu_tuners:Gear(tonumber(data.gear))
	end
	handbrake = data.handbrake or false
end)

Citizen.CreateThreadNow(function()
	while true do
		ped = PlayerPedId()
		vehicle = GetVehiclePedIsIn(ped)
		invehicle = DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle,-1) == ped
		Wait(1000)
	end
end)

Citizen.CreateThread(function()
    while true do
		local sleep = 500
        if invehicle and wheels and vehicle ~= nil then
			sleep = 0
			SetVehicleSteerBias(vehicle,tonumber(wheel / 7.5))
		    if handbrake then
			    SetControlNormal(0, 76, 1.0)
		        SetControlNormal(1, 76, 1.0)
		        SetControlNormal(2, 76, 1.0)
			end
			if brake then
				SetVehicleHandlingInt(vehicle , "CHandlingData", "strHandlingFlags", vehicleflags+0x200)
		        SetControlNormal(0, 72, brake+0.0)
		        SetControlNormal(1, 72, brake+0.0)
		        SetControlNormal(2, 72, brake+0.0)
		    end
		    if throttle and maxgear >= lastgear then
		        SetControlNormal(0, 71, throttle+0.0)
		        SetControlNormal(1, 71, throttle+0.0)
		        SetControlNormal(2, 71, throttle+0.0)
			elseif throttle and maxgear < lastgear then
				SetControlNormal(0, 72, throttle+0.0)
				SetControlNormal(1, 72, throttle+0.0)
		        SetControlNormal(2, 72, throttle+0.0)
		    end
			if clutch then
		        SetControlNormal(0, 21, clutch+0.0)
		        SetControlNormal(1, 21, clutch+0.0)
		        SetControlNormal(2, 21, clutch+0.0)
				if lastgear == 0 then
					SetVehicleClutch(vehicle,1.0)
				else
					SetVehicleClutch(vehicle,1.0 - clutch+0.0)
				end
				if clutch > 0.1 then
					SetVehicleHandlingFloat(vehicle , "CHandlingData", "fDriveInertia", 1.0)
					SetVehicleHandlingInt(vehicle , "CHandlingData", "strHandlingFlags", vehicleflags+0x10+0x100)
				else
					SetVehicleHandlingInt(vehicle , "CHandlingData", "strHandlingFlags", vehicleflags)
				end
		    end
		elseif wheels then
			exports.renzu_tuners:SetVehicleManualGears(vehicle)
			wheels = false
			lastgear = -1
			SetVehicleHandlingInt(GetVehiclePedIsIn(PlayerPedId(),true) , "CHandlingData", "strHandlingFlags", vehicleflags)
        end
		Citizen.Wait(sleep)
    end
end)