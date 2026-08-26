--[[
    -----------------------------------------------------------------------
    Resource: exe-sleep
    Author: ExeDevelopment
    Discord: https://discord.gg/H2ztYhzEGd
    GitHub: https://github.com/degans1
    Description: QBCore Gelişmiş Uyku & Yorgunluk Sistemi - Server Tarafı
    -----------------------------------------------------------------------
]]

local QBCore = exports[Config.CoreName]:GetCoreObject()

-- Dondurulmuş Oyuncular Listesi (Admin /sleepfreeze)
local frozenPlayers = {}

-- =======================================================================
-- KONSOL BAŞLANGIÇ DUYURUSU (CMD ASCII ART & BRANDING)
-- =======================================================================
local function PrintStartupMessage()
    local banner = [[
^5  ███████╗██╗   ██╗███████╗    ███████╗██╗     ███████╗███████╗██████╗ 
^5  ██╔════╝╚██╗ ██╔╝██╔════╝    ██╔════╝██║     ██╔════╝██╔════╝██╔══██╗
^6  █████╗   ╚████╔╝ █████╗      ███████╗██║     █████╗  █████╗  ██████╔╝
^6  ██╔══╝    ╚██╔╝  ██╔══╝      ╚════██║██║     ██╔══╝  ██╔══╝  ██╔═══╝ 
^4  ███████╗   ██║   ███████╗    ███████║███████╗███████╗███████╗██║     
^4  ╚══════╝   ╚═╝   ╚══════╝    ╚══════╝╚══════╝╚══════╝╚══════╝╚═╝     
^0
^2========================================================================^0
^3[ExeDevelopment]^0 Gelişmiş QBCore Uyku & Yorgunluk Scripti Başarıyla Başlatıldı!
^2Versiyon:^0 1.2.0 | ^2Durum:^0 Aktif (0.00 ms Resmon)
^2Geliştirici:^0 ExeDevelopment
^2Discord:^0 %s
^2GitHub:^0  %s
^2========================================================================^0
]]
    print(string.format(banner, Config.Discord, Config.Github))
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    PrintStartupMessage()
end)

-- =======================================================================
-- OYUNCU YÜKLENDİĞİNDE VERİ ÇEKME & SENKRONİZASYON
-- =======================================================================
local function LoadPlayerSleep(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentSleep = Player.PlayerData.metadata['sleepiness']
    if currentSleep == nil then
        currentSleep = Config.SleepSettings.InitialSleep or 10.0
        Player.Functions.SetMetaData('sleepiness', currentSleep)
    end

    TriggerClientEvent('exe-sleep:client:SyncSleep', src, currentSleep)
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    LoadPlayerSleep(src)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    LoadPlayerSleep(src)
end)

-- Manuel Senkronizasyon İsteği
RegisterNetEvent('exe-sleep:server:RequestSync', function()
    local src = source
    LoadPlayerSleep(src)
end)

-- =======================================================================
-- YORGUNLUK / UYKU DEĞERİ GÜNCELLEME
-- =======================================================================
RegisterNetEvent('exe-sleep:server:UpdateSleep', function(newSleepValue)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Eğer oyuncunun uyku artışı dondurulduysa işlemi yoksay
    if frozenPlayers[src] then return end

    local clampedValue = math.min(Config.SleepSettings.MaxSleep, math.max(Config.SleepSettings.MinSleep, newSleepValue))
    Player.Functions.SetMetaData('sleepiness', clampedValue)
end)

-- =======================================================================
-- YATAKTA UYUMA & ÇIKIŞ YAPMA İŞLEMLERİ
-- =======================================================================

-- Yatakta Uyku Tamamlandığında veya Kısmi Uyandığında
RegisterNetEvent('exe-sleep:server:CompleteBedSleep', function(finalSleepValue)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local clampedValue = math.min(Config.SleepSettings.MaxSleep, math.max(Config.SleepSettings.MinSleep, finalSleepValue or 0))
    Player.Functions.SetMetaData('sleepiness', clampedValue)
    TriggerClientEvent('exe-sleep:client:SyncSleep', src, clampedValue)
end)

-- "Uykunu Tamamen Al (Quit)" Butonuna Basıldığında
RegisterNetEvent('exe-sleep:server:BedQuit', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Yorgunluğu sıfırla ve veritabanına kaydet
    Player.Functions.SetMetaData('sleepiness', 0.0)
    Player.Functions.Save()

    -- Oyuncuyu nazikçe sunucudan düşür
    DropPlayer(src, Config.BedSystem.QuitMessage or "Uykunuzu aldınız ve güvenle çıktınız.")
end)

-- =======================================================================
-- KULLANILABİLİR EŞYALAR (USABLE ITEMS)
-- =======================================================================

-- Uyku Hapı (sleeping_pill)
QBCore.Functions.CreateUseableItem(Config.Items.SleepingPill.ItemName, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('inventory:client:ItemBox', src, item, 'remove')
        TriggerClientEvent('exe-sleep:client:UseSleepingPill', src)
    end
end)

-- Enerji / Uykusuzluk Hapı (energy_pill)
QBCore.Functions.CreateUseableItem(Config.Items.EnergyPill.ItemName, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('inventory:client:ItemBox', src, item, 'remove')
        TriggerClientEvent('exe-sleep:client:UseEnergyPill', src)
    end
end)

-- =======================================================================
-- YÖNETİCİ KOMUTLARI (ADMIN COMMANDS - 'god'/'admin')
-- =======================================================================

-- 1. /sleepset [target_id] [amount]
QBCore.Commands.Add('sleepset', 'Bir oyuncunun uyku/yorgunluk seviyesini doğrudan ayarlar (Admin)', {
    { name = 'id', help = 'Hedef Oyuncu ID' },
    { name = 'miktar', help = 'Yorgunluk Miktarı (0 - 100)' }
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local sleepValue = tonumber(args[2])

    if not targetId or not sleepValue then
        TriggerClientEvent('QBCore:Notify', source, 'Kullanım: /sleepset [ID] [0-100]', 'error')
        return
    end

    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Belirtilen ID bulunamadı!', 'error')
        return
    end

    local clamped = math.min(100.0, math.max(0.0, sleepValue + 0.0))
    TargetPlayer.Functions.SetMetaData('sleepiness', clamped)
    TriggerClientEvent('exe-sleep:client:SyncSleep', targetId, clamped)
    
    TriggerClientEvent('QBCore:Notify', source, string.format('ID %s için yorgunluk seviyesi %%%.1f olarak ayarlandı.', targetId, clamped), 'success')
    TriggerClientEvent('QBCore:Notify', targetId, string.format('Yorgunluk seviyeniz yönetici tarafından %%%.1f yapıldı.', clamped), 'primary')
end, 'admin')

-- 2. /sleepreset [target_id]
QBCore.Commands.Add('sleepreset', 'Hedef oyuncunun uykusunu sıfırlar ve tüm efektleri temizler (Admin)', {
    { name = 'id', help = 'Hedef Oyuncu ID' }
}, true, function(source, args)
    local targetId = tonumber(args[1]) or source
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)

    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Belirtilen ID bulunamadı!', 'error')
        return
    end

    TargetPlayer.Functions.SetMetaData('sleepiness', 0.0)
    TriggerClientEvent('exe-sleep:client:ResetSleepEffects', targetId)
    
    TriggerClientEvent('QBCore:Notify', source, string.format('ID %s oyuncusunun uykusu sıfırlandı ve efektleri temizlendi.', targetId), 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'Yorgunluğunuz tamamen sıfırlandı ve kendinizi dinç hissediyorsunuz!', 'success')
end, 'admin')

-- 3. /sleepfreeze [target_id]
QBCore.Commands.Add('sleepfreeze', 'Hedef oyuncunun yorgunluk ilerlemesini dondurur veya çözer (Admin)', {
    { name = 'id', help = 'Hedef Oyuncu ID' }
}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Kullanım: /sleepfreeze [ID]', 'error')
        return
    end

    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Belirtilen ID bulunamadı!', 'error')
        return
    end

    frozenPlayers[targetId] = not frozenPlayers[targetId]
    local isFrozen = frozenPlayers[targetId]

    TriggerClientEvent('exe-sleep:client:SetFrozenState', targetId, isFrozen)

    if isFrozen then
        TriggerClientEvent('QBCore:Notify', source, string.format('ID %s için yorgunluk artışı DONDURULDU.', targetId), 'success')
        TriggerClientEvent('QBCore:Notify', targetId, Config.Locale['freeze_enabled'], 'primary')
    else
        TriggerClientEvent('QBCore:Notify', source, string.format('ID %s için yorgunluk artışı NORMALE DÖNDÜ.', targetId), 'primary')
        TriggerClientEvent('QBCore:Notify', targetId, Config.Locale['freeze_disabled'], 'primary')
    end
end, 'admin')

-- 4. /sleepcheck [target_id]
QBCore.Commands.Add('sleepcheck', 'Hedef oyuncunun yorgunluk ve hap durumlarını kontrol eder (Admin)', {
    { name = 'id', help = 'Hedef Oyuncu ID' }
}, true, function(source, args)
    local targetId = tonumber(args[1]) or source
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)

    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Belirtilen ID bulunamadı veya oyuncu oyunda değil!', 'error')
        return
    end

    TriggerClientEvent('exe-sleep:client:RequestCheckDetails', targetId, source)
end, 'admin')

-- /sleepcheck yanıtını admin tarafına bildirme
RegisterNetEvent('exe-sleep:server:SendCheckDetails', function(adminSrc, liveSleep, isEnergyActive, remainingSec, isFrozenClient)
    local src = source
    local TargetPlayer = QBCore.Functions.GetPlayer(src)
    if not TargetPlayer then return end

    -- Canlı veriyi sunucu metadata'sına da hemen yazıp eşitle
    local currentSleepVal = tonumber(liveSleep) or 0.0
    TargetPlayer.Functions.SetMetaData('sleepiness', currentSleepVal)

    local playerName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    local rounded = math.floor(currentSleepVal)

    -- /uykudurumu ile %100 birebir aynı durum metinleri ve eşikleri
    local stateText = "Dinç & Enerjik"
    local notifyType = "primary"
    if currentSleepVal >= Config.Effects.FaintThreshold then
        stateText = "Bayılmak Üzere! (Kritik)"
        notifyType = "error"
    elseif currentSleepVal >= (Config.Effects.BlurThreshold or 70.0) then
        stateText = "Çok Yorgun (Gözler Kapanıyor / Baş Dönmesi)"
        notifyType = "error"
    elseif currentSleepVal >= 50.0 then
        stateText = "Hafif Yorgun (Dinlenme Tavsiye Edilir)"
        notifyType = "primary"
    elseif currentSleepVal >= 25.0 then
        stateText = "Normal (Hafif Yıpranma)"
        notifyType = "primary"
    end

    local pillStatus = "Yok"
    if isEnergyActive then
        if remainingSec and remainingSec > 0 then
            local mins = math.floor(remainingSec / 60)
            local secs = remainingSec % 60
            pillStatus = string.format("Enerji Hapı Aktif (Kalan: %02d:%02d)", mins, secs)
        else
            pillStatus = "Enerji Hapı Aktif (Sona Eriyor)"
        end
    end

    local isFrozenText = (frozenPlayers[src] or isFrozenClient) and "Evet (Kilitli)" or "Hayır"

    local msg = string.format(
        "👤 Oyuncu: %s (ID: %s)\n💤 Yorgunluk Seviyesi: %%%s\n📊 Durum: %s\n💊 Aktif Hap/Etki: %s\n❄️ Donduruldu: %s",
        playerName, src, rounded, stateText, pillStatus, isFrozenText
    )

    TriggerClientEvent('QBCore:Notify', adminSrc, msg, notifyType, 8000)
end)

-- 5. /givepill [target_id] [sleeping_pill/energy_pill] [amount]
QBCore.Commands.Add('givepill', 'Hedef oyuncuya uyku veya enerji hapı verir (Admin)', {
    { name = 'id', help = 'Hedef Oyuncu ID' },
    { name = 'hap_tipi', help = 'sleeping_pill / energy_pill' },
    { name = 'miktar', help = 'Adet' }
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local itemType = tostring(args[2])
    local amount = tonumber(args[3]) or 1

    if not targetId or not itemType then
        TriggerClientEvent('QBCore:Notify', source, 'Kullanım: /givepill [ID] [sleeping_pill/energy_pill] [Miktar]', 'error')
        return
    end

    if itemType ~= "sleeping_pill" and itemType ~= "energy_pill" then
        TriggerClientEvent('QBCore:Notify', source, 'Geçersiz eşya tipi! (sleeping_pill veya energy_pill olmalı)', 'error')
        return
    end

    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Belirtilen ID bulunamadı!', 'error')
        return
    end

    TargetPlayer.Functions.AddItem(itemType, amount)
    TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[itemType], 'add')
    
    TriggerClientEvent('QBCore:Notify', source, string.format('ID %s oyuncusuna %s adet %s verildi.', targetId, amount, itemType), 'success')
    TriggerClientEvent('QBCore:Notify', targetId, string.format('Envanterinize %s adet %s eklendi.', amount, itemType), 'success')
end, 'admin')
