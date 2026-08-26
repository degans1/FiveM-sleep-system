--[[
    -----------------------------------------------------------------------
    Resource: exe-sleep
    Author: ExeDevelopment
    Discord: https://discord.gg/H2ztYhzEGd
    GitHub: https://github.com/degans1
    Description: QBCore Gelişmiş Uyku & Koltuk/Yatak Dinlenme Sistemi - Client
    -----------------------------------------------------------------------
]]

local QBCore = exports[Config.CoreName]:GetCoreObject()

-- =======================================================================
-- YEREL DEĞİŞKENLER & DURUM KONTROLLERİ
-- =======================================================================
local currentSleep = 0.0
local isSleepingInBed = false
local isRestingGround = false
local isRestingStanding = false
local isEnergyActive = false
local energyExpiresAt = 0
local isFainted = false
local isFrozen = false
local devEffectsForced = false
local devSpeedMultiplier = 1.0

local lastGroundRest = 0
local lastStandingRest = 0
local currentRestEntity = nil
local currentRestType = nil
local lastNotifiedThreshold = 0

-- =======================================================================
-- YARDIMCI FONKSİYONLAR
-- =======================================================================

--- Oyuncu Hazır mı Kontrolü
local function IsPlayerReady()
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        return true
    end
    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
        local pData = QBCore.Functions.GetPlayerData()
        if pData and pData.citizenid then
            return true
        end
    end
    return DoesEntityExist(PlayerPedId())
end

--- Bildirim Gönderme Fonksiyonu
local function ShowNotification(msg, type, length)
    if not msg or msg == "" then return end
    QBCore.Functions.Notify(msg, type or "primary", length or 5000)
end

--- 3D Metin Çizdirme (DrawText3D)
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 85)
    ClearDrawOrigin()
end

--- Güvenli Animasyon Sözlüğü Yükleyici (Zaman Aşımı Korumalı)
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
    end
    return HasAnimDictLoaded(dict)
end

--- Yorgunluk Değerini Güncelleme ve Sunucuyla Eşitleme
local function UpdateSleepLevel(newVal)
    currentSleep = math.min(Config.SleepSettings.MaxSleep, math.max(Config.SleepSettings.MinSleep, newVal + 0.0))
    TriggerServerEvent('exe-sleep:server:UpdateSleep', currentSleep)
end

--- Görsel Efektleri Sıfırlama
local function ClearAllSleepEffects()
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    DoScreenFadeIn(500)
    devEffectsForced = false
end

-- =======================================================================
-- SENKRONİZASYON & EVENT DİNLEYİCİLERİ
-- =======================================================================

RegisterNetEvent('exe-sleep:client:SyncSleep', function(sleepVal)
    if sleepVal ~= nil then
        currentSleep = tonumber(sleepVal) + 0.0
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('exe-sleep:server:RequestSync')
    SetupTargetSystem()
end)

RegisterNetEvent('exe-sleep:client:SetFrozenState', function(frozen)
    isFrozen = frozen
end)

RegisterNetEvent('exe-sleep:client:ResetSleepEffects', function()
    currentSleep = 0.0
    ClearAllSleepEffects()
    UpdateSleepLevel(0.0)
    ShowNotification(Config.Locale['effects_cleared'], "success")
end)

RegisterNetEvent('exe-sleep:client:RequestCheckDetails', function(adminSrc)
    local remainingSec = 0
    if isEnergyActive and energyExpiresAt and energyExpiresAt > GetGameTimer() then
        remainingSec = math.ceil((energyExpiresAt - GetGameTimer()) / 1000)
    end
    TriggerServerEvent('exe-sleep:server:SendCheckDetails', adminSrc, currentSleep, isEnergyActive, remainingSec, isFrozen)
end)

-- =======================================================================
-- PASİF YORGUNLUK ARTIŞ DÖNGÜSÜ (0.00 ms Optimize)
-- =======================================================================
CreateThread(function()
    while true do
        local tickTime = math.floor((Config.SleepSettings.TickInterval or 60000) / devSpeedMultiplier)
        Wait(math.max(1000, tickTime))

        local ped = PlayerPedId()
        if IsPlayerReady() and not isSleepingInBed and not isRestingGround and not isRestingStanding and not isFainted and not isFrozen then
            if not isEnergyActive then
                local gain = (Config.SleepSettings.PassiveGain or 1.0) * devSpeedMultiplier

                if IsPedSprinting(ped) or IsPedRunning(ped) then
                    gain = gain * (Config.SleepSettings.SprintMultiplier or 1.5)
                elseif IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped then
                    gain = gain * (Config.SleepSettings.DrivingMultiplier or 1.2)
                end

                currentSleep = math.min(Config.SleepSettings.MaxSleep, currentSleep + gain)
                TriggerServerEvent('exe-sleep:server:UpdateSleep', currentSleep)

                for threshold, message in pairs(Config.Effects.NoticeThresholds) do
                    if currentSleep >= threshold and lastNotifiedThreshold < threshold then
                        ShowNotification(message, "primary")
                        lastNotifiedThreshold = threshold
                        break
                    end
                end

                if currentSleep < 50 then
                    lastNotifiedThreshold = 0
                end
            end
        end
    end
end)

-- =======================================================================
-- YORGUNLUK EFEKTLERİ & GÖZ KIRPMA (BLINKING) DÖNGÜSÜ
-- =======================================================================
local function TriggerFaintSequence()
    if isFainted then return end
    isFainted = true
    local ped = PlayerPedId()

    ShowNotification(Config.Effects.FaintNotify, "error", 6000)
    DoScreenFadeOut(800)
    Wait(800)

    SetPedToRagdoll(ped, Config.Effects.RagdollDuration or 5000, Config.Effects.RagdollDuration or 5000, 0, 0, 0, 0)
    Wait(Config.Effects.RagdollDuration or 5000)

    UpdateSleepLevel(Config.Effects.FaintResetSleep or 90.0)
    DoScreenFadeIn(1200)
    isFainted = false
end

CreateThread(function()
    local isBlurActive = false

    while true do
        local sleepWait = 2000

        if IsPlayerReady() and not isSleepingInBed and not isFainted then
            if currentSleep >= Config.Effects.FaintThreshold then
                TriggerFaintSequence()
                sleepWait = 1000

            elseif currentSleep >= Config.Effects.BlurThreshold or devEffectsForced then
                sleepWait = math.random(Config.Effects.BlinkMinInterval or 15000, Config.Effects.BlinkMaxInterval or 30000)

                if not isBlurActive then
                    SetTimecycleModifier(Config.Effects.BlurIntensity or "hud_def_blur")
                    SetTimecycleModifierStrength(0.7)
                    isBlurActive = true
                end

                if Config.Effects.CameraShake then
                    ShakeGameplayCam('DRUNK_SHAKE', Config.Effects.ShakeIntensity or 0.4)
                end

                DoScreenFadeOut(Config.Effects.BlinkFadeOutTime or 600)
                Wait(Config.Effects.BlinkFadeOutTime or 600)
                Wait(Config.Effects.BlinkBlackTime or 900)
                DoScreenFadeIn(Config.Effects.BlinkFadeInTime or 700)

            else
                if isBlurActive then
                    ClearTimecycleModifier()
                    StopGameplayCamShaking(true)
                    isBlurActive = false
                end
                sleepWait = 3000
            end
        else
            if isBlurActive then
                ClearTimecycleModifier()
                StopGameplayCamShaking(true)
                isBlurActive = false
            end
            sleepWait = 3000
        end

        Wait(sleepWait)
    end
end)

-- =======================================================================
-- YATAK VE KOLTUK/SANDALYE TESPİT FONKSİYONU
-- =======================================================================
local function GetNearbyRestTarget()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)

    -- 1. Yatakları Kontrol Et
    for _, modelHash in ipairs(Config.BedSystem.BedProps) do
        local obj = GetClosestObjectOfType(pCoords.x, pCoords.y, pCoords.z, Config.BedSystem.InteractDistance or 2.8, modelHash, false, false, false)
        if obj ~= 0 and DoesEntityExist(obj) then
            return 'bed', obj, GetEntityCoords(obj)
        end
    end

    -- 2. Koltuk, Sandalye ve Bankları Kontrol Et
    if Config.SeatingSystem and Config.SeatingSystem.Enabled then
        for _, modelHash in ipairs(Config.SeatingSystem.SeatingProps) do
            local obj = GetClosestObjectOfType(pCoords.x, pCoords.y, pCoords.z, Config.SeatingSystem.InteractDistance or 2.4, modelHash, false, false, false)
            if obj ~= 0 and DoesEntityExist(obj) then
                return 'seating', obj, GetEntityCoords(obj)
            end
        end
    end

    -- 3. Özel Yatak Koordinatlarını Kontrol Et
    if Config.BedSystem.CustomBedLocations then
        for _, bedCoord in ipairs(Config.BedSystem.CustomBedLocations) do
            if #(pCoords - bedCoord) <= (Config.BedSystem.InteractDistance or 2.8) then
                return 'bed', nil, bedCoord
            end
        end
    end

    return nil, nil, nil
end

-- =======================================================================
-- DİNLENME / UYUMA BAŞLATMA (YATAK VEYA KOLTUK)
-- =======================================================================
function StartRest(restType, obj, coords)
    CreateThread(function()
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            ShowNotification(Config.Locale['cannot_sleep_vehicle'], "error")
            return
        end

        if isEnergyActive then
            ShowNotification(Config.Locale['energy_active'], "error")
            return
        end

        isSleepingInBed = true
        currentRestEntity = obj
        currentRestType = restType

        local isSeating = (restType == 'seating')
        local animConfig = isSeating and Config.SeatingSystem.Animation or Config.BedSystem.Animation
        local durationSec = isSeating and (Config.SeatingSystem.SleepTimeSeconds or 35) or (Config.BedSystem.SleepTimeSeconds or 30)

        -- 1. NUI Arayüzünü Aç ve Odaklan
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({
            action = "openBedSleep",
            duration = durationSec,
            isSeating = isSeating
        })

        if Config.Debug then
            print(string.format("^2[exe-sleep] StartRest tetiklendi! Tip: %s | Sure: %s sn^0", tostring(restType), tostring(durationSec)))
        end

        -- 2. Animasyonu Yükle ve Konumlandır
        LoadAnimDict(animConfig.Dict)

        if coords then
            local zOffset = isSeating and 0.05 or 0.35
            SetEntityCoords(ped, coords.x, coords.y, coords.z + zOffset, true, true, true, false)
            if obj and DoesEntityExist(obj) then
                local heading = GetEntityHeading(obj) + (animConfig.HeadingOffset or 0.0)
                SetEntityHeading(ped, heading)
            end
        end

        -- 3. Animasyonu Oynat ve Fiziği Kilitle
        TaskPlayAnim(ped, animConfig.Dict, animConfig.Anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        Wait(300)
        if isSleepingInBed then
            FreezeEntityPosition(ped, true)
        end
    end)
end

local function StopRest(completedFully, wakeProgress)
    local ped = PlayerPedId()
    isSleepingInBed = false

    -- NUI Kapat
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeBedSleep" })

    -- Animasyon ve Fiziği Sıfırla
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    currentRestEntity = nil
    currentRestType = nil

    if completedFully then
        UpdateSleepLevel(0.0)
        ShowNotification(Config.Locale['woke_up_full'], "success")
        TriggerServerEvent('exe-sleep:server:CompleteBedSleep', 0.0)
    else
        local progress = (wakeProgress or 0) / 100.0
        local reducedAmount = currentSleep * progress
        local finalSleep = math.max(0.0, currentSleep - reducedAmount)
        UpdateSleepLevel(finalSleep)
        ShowNotification(Config.Locale['woke_up_partial'], "primary")
        TriggerServerEvent('exe-sleep:server:CompleteBedSleep', finalSleep)
    end
end

-- =======================================================================
-- QB-TARGET ENTEGRASYONU
-- =======================================================================
function SetupTargetSystem()
    if not Config.Interaction or not Config.Interaction.UseTarget then return end

    local targetScript = Config.Interaction.TargetName or 'qb-target'
    if GetResourceState(targetScript) ~= 'started' then
        if Config.Debug then
            print(string.format("^3[exe-sleep] '%s' kaynağı aktif değil veya bulunamadı.^0", targetScript))
        end
        return
    end

    -- Yataklar için qb-target
    if Config.BedSystem and Config.BedSystem.BedProps and #Config.BedSystem.BedProps > 0 then
        exports[targetScript]:AddTargetModel(Config.BedSystem.BedProps, {
            options = {
                {
                    type = "client",
                    icon = Config.Interaction.BedIcon or "fas fa-bed",
                    label = Config.Interaction.BedLabel or "Yatağa Uzan ve Uyu",
                    action = function(entity)
                        if entity and DoesEntityExist(entity) then
                            StartRest('bed', entity, GetEntityCoords(entity))
                        end
                    end,
                    canInteract = function(entity, distance, data)
                        return not isSleepingInBed and not isRestingGround and not isRestingStanding and not isEnergyActive
                    end
                }
            },
            distance = Config.Interaction.TargetDistance or 2.2
        })
    end

    -- Koltuk, Sandalye ve Banklar için qb-target
    if Config.SeatingSystem and Config.SeatingSystem.Enabled and Config.SeatingSystem.SeatingProps and #Config.SeatingSystem.SeatingProps > 0 then
        exports[targetScript]:AddTargetModel(Config.SeatingSystem.SeatingProps, {
            options = {
                {
                    type = "client",
                    icon = Config.Interaction.SeatingIcon or "fas fa-couch",
                    label = Config.Interaction.SeatingLabel or "Otur ve Dinlen",
                    action = function(entity)
                        if entity and DoesEntityExist(entity) then
                            StartRest('seating', entity, GetEntityCoords(entity))
                        end
                    end,
                    canInteract = function(entity, distance, data)
                        return not isSleepingInBed and not isRestingGround and not isRestingStanding and not isEnergyActive
                    end
                }
            },
            distance = Config.Interaction.TargetDistance or 2.2
        })
    end

    if Config.Debug then
        print("^2[exe-sleep] qb-target yatak ve koltuk modelleri başarıyla kaydedildi!^0")
    end
end

-- Başlangıçta Target Kurulumu
CreateThread(function()
    Wait(1000)
    SetupTargetSystem()
end)

-- =======================================================================
-- ALT TUŞU ENTEGRASYONU (UseKeypress = true olduğunda)
-- =======================================================================

RegisterKeyMapping('+sleep_interact', 'Yatağa Uzan / Dinlen', 'keyboard', 'LMENU')

RegisterCommand('+sleep_interact', function()
    if not Config.Interaction or not Config.Interaction.UseKeypress then return end
    if isSleepingInBed or isRestingGround or isRestingStanding then return end
    if not IsPlayerReady() then return end

    local restType, restObj, restCoords = GetNearbyRestTarget()
    if restCoords then
        StartRest(restType, restObj, restCoords)
    end
end, false)

RegisterCommand('-sleep_interact', function() end, false)

local function IsAltKeyPressed()
    return IsControlJustPressed(0, 19)
        or IsDisabledControlJustPressed(0, 19)
        or IsControlJustReleased(0, 19)
        or IsDisabledControlJustReleased(0, 19)
end

CreateThread(function()
    while true do
        local sleep = 1500

        if Config.Interaction and Config.Interaction.UseKeypress then
            if not isSleepingInBed and not isRestingGround and not isRestingStanding and IsPlayerReady() then
                local restType, restObj, restCoords = GetNearbyRestTarget()
                if restCoords then
                    sleep = 0
                    local promptText = (restType == 'seating') and Config.SeatingSystem.HelpText or Config.BedSystem.HelpText
                    DrawText3D(restCoords.x, restCoords.y, restCoords.z + 0.5, promptText)

                    if IsAltKeyPressed() then
                        StartRest(restType, restObj, restCoords)
                        Wait(500)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- =======================================================================
-- NUI CALLBACKS (JS -> LUA)
-- =======================================================================

RegisterNUICallback('sleepCompleted', function(data, cb)
    StopRest(true, 100)
    cb('ok')
end)

RegisterNUICallback('wakeUp', function(data, cb)
    local progress = data and data.progress or 0
    StopRest(false, progress)
    cb('ok')
end)

RegisterNUICallback('quitServer', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeBedSleep" })
    TriggerServerEvent('exe-sleep:server:BedQuit')
    cb('ok')
end)

-- =======================================================================
-- KULLANILABİLİR EŞYALARIN CLIENT EFEKTLERİ
-- =======================================================================

RegisterNetEvent('exe-sleep:client:UseSleepingPill', function()
    local ped = PlayerPedId()
    LoadAnimDict(Config.Items.SleepingPill.Animation.Dict)
    TaskPlayAnim(ped, Config.Items.SleepingPill.Animation.Dict, Config.Items.SleepingPill.Animation.Anim, 8.0, -8.0, Config.Items.SleepingPill.Animation.Duration, 49, 0, false, false, false)

    QBCore.Functions.Progressbar("use_sleeping_pill", "Uyku hapı içiliyor...", Config.Items.SleepingPill.Animation.Duration, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        ClearPedTasks(ped)
        local targetSleep = Config.Items.SleepingPill.SleepIncrease or 85.0
        UpdateSleepLevel(math.max(currentSleep, targetSleep))
        ShowNotification(Config.Items.SleepingPill.Notify, "primary")
    end, function()
        ClearPedTasks(ped)
    end)
end)

RegisterNetEvent('exe-sleep:client:UseEnergyPill', function()
    local ped = PlayerPedId()
    LoadAnimDict(Config.Items.EnergyPill.Animation.Dict)
    TaskPlayAnim(ped, Config.Items.EnergyPill.Animation.Dict, Config.Items.EnergyPill.Animation.Anim, 8.0, -8.0, Config.Items.EnergyPill.Animation.Duration, 49, 0, false, false, false)

    QBCore.Functions.Progressbar("use_energy_pill", "Enerji hapı içiliyor...", Config.Items.EnergyPill.Animation.Duration, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        ClearPedTasks(ped)
        isEnergyActive = true
        energyExpiresAt = GetGameTimer() + ((Config.Items.EnergyPill.FreezeDuration or 300) * 1000)

        local reduced = math.max(0.0, currentSleep - (Config.Items.EnergyPill.TemporaryReduction or 30.0))
        UpdateSleepLevel(reduced)
        ShowNotification(Config.Items.EnergyPill.NotifyStart, "success")

        SetTimeout((Config.Items.EnergyPill.FreezeDuration or 300) * 1000, function()
            isEnergyActive = false
            energyExpiresAt = 0
            local rebound = math.min(100.0, currentSleep + (Config.Items.EnergyPill.ReboundFatigue or 60.0))
            UpdateSleepLevel(rebound)
            ShowNotification(Config.Items.EnergyPill.NotifyEnd, "error")
        end)
    end, function()
        ClearPedTasks(ped)
    end)
end)

-- =======================================================================
-- KOMUTLAR (/uyu & /yat)
-- =======================================================================

local function StartGroundSleep()
    local currentTime = GetGameTimer() / 1000
    local cooldown = Config.Commands.GroundSleep.Cooldown or 180

    if (currentTime - lastGroundRest) < cooldown then
        local remaining = math.ceil(cooldown - (currentTime - lastGroundRest))
        ShowNotification(string.format(Config.Commands.GroundSleep.NotifyCooldown, remaining), "error")
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        ShowNotification(Config.Locale['cannot_sleep_vehicle'], "error")
        return
    end

    isRestingGround = true
    lastGroundRest = currentTime
    LoadAnimDict(Config.Commands.GroundSleep.Animation.Dict)
    TaskPlayAnim(ped, Config.Commands.GroundSleep.Animation.Dict, Config.Commands.GroundSleep.Animation.Anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    ShowNotification(Config.Locale['ground_sleep_started'], "primary")

    local maxHeal = Config.Commands.GroundSleep.MaxReduction or 25.0
    local healedSoFar = 0.0

    CreateThread(function()
        while isRestingGround do
            Wait(Config.Commands.GroundSleep.TickRate or 2000)

            if not isRestingGround then break end

            local healStep = Config.Commands.GroundSleep.PerTickHeal or 2.0
            healedSoFar = healedSoFar + healStep
            currentSleep = math.max(0.0, currentSleep - healStep)
            UpdateSleepLevel(currentSleep)

            if healedSoFar >= maxHeal or currentSleep <= 0.0 then
                isRestingGround = false
                ClearPedTasks(PlayerPedId())
                ShowNotification(Config.Commands.GroundSleep.NotifyLimit, "primary")
                break
            end

            if IsControlJustPressed(0, Config.Commands.GroundSleep.CancelKey) or IsPedRagdoll(PlayerPedId()) then
                isRestingGround = false
                ClearPedTasks(PlayerPedId())
                ShowNotification(Config.Commands.GroundSleep.NotifyCancel, "primary")
                break
            end
        end
    end)
end

local function StartStandingSleep()
    local currentTime = GetGameTimer() / 1000
    local cooldown = Config.Commands.StandingSleep.Cooldown or 120

    if (currentTime - lastStandingRest) < cooldown then
        local remaining = math.ceil(cooldown - (currentTime - lastStandingRest))
        ShowNotification(string.format(Config.Commands.StandingSleep.NotifyCooldown, remaining), "error")
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        ShowNotification(Config.Locale['cannot_sleep_vehicle'], "error")
        return
    end

    isRestingStanding = true
    lastStandingRest = currentTime
    LoadAnimDict(Config.Commands.StandingSleep.Animation.Dict)
    TaskPlayAnim(ped, Config.Commands.StandingSleep.Animation.Dict, Config.Commands.StandingSleep.Animation.Anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    ShowNotification(Config.Locale['standing_sleep_started'], "primary")

    local maxHeal = Config.Commands.StandingSleep.MaxReduction or 15.0
    local healedSoFar = 0.0

    CreateThread(function()
        while isRestingStanding do
            Wait(Config.Commands.StandingSleep.TickRate or 2000)

            if not isRestingStanding then break end

            local healStep = Config.Commands.StandingSleep.PerTickHeal or 1.5
            healedSoFar = healedSoFar + healStep
            currentSleep = math.max(0.0, currentSleep - healStep)
            UpdateSleepLevel(currentSleep)

            if healedSoFar >= maxHeal or currentSleep <= 0.0 then
                isRestingStanding = false
                ClearPedTasks(PlayerPedId())
                ShowNotification(Config.Commands.StandingSleep.NotifyLimit, "primary")
                break
            end

            if IsControlJustPressed(0, Config.Commands.StandingSleep.CancelKey) or IsPedRagdoll(PlayerPedId()) then
                isRestingStanding = false
                ClearPedTasks(PlayerPedId())
                ShowNotification(Config.Commands.StandingSleep.NotifyCancel, "primary")
                break
            end
        end
    end)
end

RegisterCommand('uyu', function(source, args)
    local subCommand = args[1] and string.lower(args[1]) or ""

    if isSleepingInBed then
        ShowNotification(Config.Locale['already_sleeping'], "error")
        return
    end

    if isEnergyActive then
        ShowNotification(Config.Locale['energy_active'], "error")
        return
    end

    if subCommand == "yerde" then
        StartGroundSleep()
    elseif subCommand == "ayakta" then
        StartStandingSleep()
    elseif subCommand == "yatak" or subCommand == "koltuk" then
        local restType, restObj, restCoords = GetNearbyRestTarget()
        if restCoords then
            StartRest(restType, restObj, restCoords)
        else
            ShowNotification(Config.Locale['no_bed_nearby'], "error")
        end
    else
        ShowNotification(Config.Locale['command_usage'], "primary")
    end
end, false)

RegisterCommand('yat', function()
    if isSleepingInBed then
        ShowNotification(Config.Locale['already_sleeping'], "error")
        return
    end
    local restType, restObj, restCoords = GetNearbyRestTarget()
    if restCoords then
        StartRest(restType, restObj, restCoords)
    else
        ShowNotification(Config.Locale['no_bed_nearby'], "error")
    end
end, false)

-- =======================================================================
-- /uykudurumu KOMUTU (Detaylı Oyuncu Yorgunluk & Buff/Debuff Raporu)
-- =======================================================================
RegisterCommand('uykudurumu', function()
    TriggerServerEvent('exe-sleep:server:UpdateSleep', currentSleep)
    local roundedSleep = math.floor(currentSleep)
    local stateText = "Dinç & Enerjik"
    local notifyType = "success"

    if currentSleep >= Config.Effects.FaintThreshold then
        stateText = "Bayılmak Üzere! (Kritik)"
        notifyType = "error"
    elseif currentSleep >= (Config.Effects.BlurThreshold or 70.0) then
        stateText = "Çok Yorgun (Gözler Kapanıyor / Baş Dönmesi)"
        notifyType = "error"
    elseif currentSleep >= 50.0 then
        stateText = "Hafif Yorgun (Dinlenme Tavsiye Edilir)"
        notifyType = "primary"
    elseif currentSleep >= 25.0 then
        stateText = "Normal (Hafif Yıpranma)"
        notifyType = "primary"
    end

    -- Hap ve Kilit Durumları
    local pillStatus = "Yok"
    if isEnergyActive then
        local remainingSec = 0
        if energyExpiresAt and energyExpiresAt > GetGameTimer() then
            remainingSec = math.ceil((energyExpiresAt - GetGameTimer()) / 1000)
        end
        if remainingSec > 0 then
            local mins = math.floor(remainingSec / 60)
            local secs = remainingSec % 60
            pillStatus = string.format("Enerji Hapı Aktif (Kalan: %02d:%02d)", mins, secs)
        else
            pillStatus = "Enerji Hapı Aktif (Sona Eriyor)"
        end
    end

    local freezeNote = ""
    if isFrozen then
        freezeNote = " [Yorgunluk Yönetici Tarafından Donduruldu]"
    end

    local finalNotify = string.format(
        "💤 Yorgunluk Seviyesi: %%%s\n📊 Durum: %s%s\n💊 Aktif Hap/Etki: %s",
        roundedSleep,
        stateText,
        freezeNote,
        pillStatus
    )

    ShowNotification(finalNotify, notifyType, 8000)
end, false)

CreateThread(function()
    while true do
        local sleep = 1000
        if isRestingGround or isRestingStanding then
            sleep = 0
            if IsControlJustPressed(0, 73) then
                if isRestingGround then
                    isRestingGround = false
                    ClearPedTasks(PlayerPedId())
                    ShowNotification(Config.Commands.GroundSleep.NotifyCancel, "primary")
                elseif isRestingStanding then
                    isRestingStanding = false
                    ClearPedTasks(PlayerPedId())
                    ShowNotification(Config.Commands.StandingSleep.NotifyCancel, "primary")
                end
            end
        end
        Wait(sleep)
    end
end)

-- =======================================================================
-- GELİŞTİRİCİ TEST KOMUTLARI (DEV / DEBUG MODE)
-- =======================================================================

RegisterCommand('sleepdev_faint', function()
    if not Config.Debug then
        ShowNotification("Geliştirici modu kapalı!", "error")
        return
    end
    ShowNotification("[DEV] Bayılma sekansı tetiklendi...", "primary")
    TriggerFaintSequence()
end, false)

RegisterCommand('sleepdev_effects', function()
    if not Config.Debug then
        ShowNotification("Geliştirici modu kapalı!", "error")
        return
    end
    devEffectsForced = not devEffectsForced
    if devEffectsForced then
        ShowNotification("[DEV] %70+ Yorgunluk efektleri AÇILDI.", "success")
    else
        ClearAllSleepEffects()
        ShowNotification("[DEV] Efektler KAPATILDI.", "primary")
    end
end, false)

RegisterCommand('sleepdev_ui', function()
    if not Config.Debug then
        ShowNotification("Geliştirici modu kapalı!", "error")
        return
    end
    ShowNotification("[DEV] Test Dinlenme NUI Açıldı.", "primary")
    isSleepingInBed = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openBedSleep",
        duration = Config.BedSystem.SleepTimeSeconds or 30,
        isSeating = false
    })
end, false)

RegisterCommand('sleepdev_speed', function(source, args)
    if not Config.Debug then
        ShowNotification("Geliştirici modu kapalı!", "error")
        return
    end
    local mult = tonumber(args[1]) or 1.0
    devSpeedMultiplier = math.max(0.1, mult)
    ShowNotification(string.format("[DEV] Yorgunluk hızı: %.1fx yapıldı.", devSpeedMultiplier), "success")
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ClearAllSleepEffects()
    SetNuiFocus(false, false)
    if Config.Interaction and Config.Interaction.UseTarget then
        pcall(function()
            local targetScript = Config.Interaction.TargetName or 'qb-target'
            if Config.BedSystem and Config.BedSystem.BedProps then
                exports[targetScript]:RemoveTargetModel(Config.BedSystem.BedProps)
            end
            if Config.SeatingSystem and Config.SeatingSystem.SeatingProps then
                exports[targetScript]:RemoveTargetModel(Config.SeatingSystem.SeatingProps)
            end
        end)
    end
end)
