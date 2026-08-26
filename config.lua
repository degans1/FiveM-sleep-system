--[[
    -----------------------------------------------------------------------
    Resource: exe-sleep
    Author: ExeDevelopment
    Discord: https://discord.gg/H2ztYhzEGd
    GitHub: https://github.com/degans1
    Description: QBCore Gelişmiş Uyku & Yorgunluk Scripti Konfigürasyon Dosyası
    -----------------------------------------------------------------------
]]

Config = {}

-- Geliştirici Bilgileri & Bağlantılar
Config.Author = "ExeDevelopment"
Config.Discord = "https://discord.gg/H2ztYhzEGd"
Config.Github = "https://github.com/degans1"

-- Çerçeve ve Hata Ayıklama Ayarları
Config.CoreName = "qb-core" -- QBCore paketinizin adı
Config.Debug = true         -- Geliştirici test komutlarının (/sleepdev_*) aktifliği

-- =======================================================================
-- ETKİLEŞİM YÖNTEMİ SEÇENEKLERİ (QB-TARGET VE/VEYA TUŞ ETKİLEŞİMİ)
-- =======================================================================
Config.Interaction = {
    -- qb-target ile göz simgesi etkileşimi (ŞU ANDA AKTİF)
    UseTarget = true,

    -- Tuş ile etkileşim (Sol ALT tuşu ve 3D metin bildirimi)
    -- İki seçeneği de aynı anda true yapabilirsiniz veya birini seçebilirsiniz.
    UseKeypress = false,

    -- qb-target Ayarları
    TargetName = "qb-target",          -- Kullandığınız target scripti adı
    TargetDistance = 2.2,              -- Target göz algılama mesafesi
    BedIcon = "fas fa-bed",            -- Yataklar için target simgesi
    BedLabel = "Yatağa Uzan ve Uyu",   -- Yataklar için target metni
    SeatingIcon = "fas fa-couch",      -- Koltuk/Bank için target simgesi
    SeatingLabel = "Otur ve Dinlen",   -- Koltuk/Bank için target metni

    -- Tuş Ayarı (UseKeypress = true olduğunda kullanılır)
    Key = 19,                          -- Control 19: INPUT_CHARACTER_WHEEL / LMENU (Sol ALT)
    KeyName = "ALT"
}

-- Yorgunluk / Uyku Seviyesi Temel Ayarları
Config.SleepSettings = {
    MinSleep = 0.0,             -- Minimum yorgunluk değeri (0 = Tamamen Dinç)
    MaxSleep = 100.0,           -- Maksimum yorgunluk değeri (100 = Aşırı Yorgun/Bayılma)
    InitialSleep = 10.0,        -- Oyuna ilk girişte/yeni karakterde varsayılan yorgunluk
    
    -- Pasif Yorgunluk Artışı
    TickInterval = 60000,       -- Yorgunluk güncelleme aralığı (Milisaniye - 60000 = 1 Dakika)
    PassiveGain = 1.0,          -- Normal dururken/yürürken dakikalık yorgunluk artış miktarı
    SprintMultiplier = 1.5,     -- Koşarken/Sprint atarken yorgunluk artış çarpanı
    DrivingMultiplier = 1.2,    -- Araç kullanırken yorgunluk artış çarpanı
}

-- Yorgunluk Eşik Değerleri ve Efektler
Config.Effects = {
    -- Bildirim Eşikleri
    NoticeThresholds = {
        [50] = "Kendimi biraz yorgun hissetmeye başladım...",
        [70] = "Gözlerim ağırlaşıyor, biraz uyusam çok iyi olacak...",
        [90] = "Aşırı derecede uykum var, ayakta zor duruyorum!"
    },

    -- 70 Seviyesi ve Üzeri Efektleri (Bulanıklık, Sallantı, Göz Kırpma/Kararma)
    BlurThreshold = 70.0,            -- Efektlerin başlayacağı yorgunluk eşiği
    BlurIntensity = "hud_def_blur",  -- Uygulanacak Timecycle efekti ("hud_def_blur" veya "drug_drive_blend01")
    CameraShake = true,              -- Hafif baş dönmesi / kamera sallantısı aktif mi?
    ShakeIntensity = 0.4,            -- Kamera sallantı şiddeti
    
    -- Göz Kırpma (Blinking) Efekti
    BlinkMinInterval = 15000,        -- Minimum göz kırpma aralığı (15 saniye)
    BlinkMaxInterval = 30000,        -- Maksimum göz kırpma aralığı (30 saniye)
    BlinkFadeOutTime = 600,          -- Ekranın kararma süresi (ms)
    BlinkBlackTime = 900,            -- Ekranın tamamen siyah kaldığı süre (ms)
    BlinkFadeInTime = 700,           -- Ekranın normale dönme süresi (ms)

    -- 100 Seviyesi (Bayılma) Ayarları
    FaintThreshold = 100.0,          -- Bayılma eşiği
    RagdollDuration = 5000,          -- Yere düşüp bayılma süresi (5 saniye)
    FaintResetSleep = 90.0,          -- Bayıldıktan sonra uyanınca ayarlanacak uyku seviyesi
    FaintNotify = "Aşırı yorgunluk ve uykusuzluktan dolayı bayıldınız!"
}

-- Eşyalar (Usable Items)
Config.Items = {
    -- Uyku Hapı (sleeping_pill)
    SleepingPill = {
        ItemName = "sleeping_pill",
        Label = "Uyku Hapı",
        SleepIncrease = 85.0,        -- Kullanıldığında yorgunluğu bu seviyeye çeker veya artırır
        Animation = {
            Dict = "mp_suicide",
            Anim = "pill",
            Duration = 3000
        },
        Notify = "Uyku hapını içtiniz, gözleriniz ağırlaşıyor..."
    },

    -- Enerji / Uykusuzluk Hapı (energy_pill)
    EnergyPill = {
        ItemName = "energy_pill",
        Label = "Enerji Hapı",
        FreezeDuration = 300,        -- Yorgunluğun dondurulacağı süre (Saniye cinsinden - 300s = 5 Dakika)
        TemporaryReduction = 30.0,   -- Anlık rahatlama/yorgunluk düşüşü
        ReboundFatigue = 60.0,       -- Süre bittiğinde geri tepme (Rebound) ile eklenecek ani yorgunluk
        Animation = {
            Dict = "mp_suicide",
            Anim = "pill",
            Duration = 3000
        },
        NotifyStart = "Enerji hapı etkisini gösterdi, kendinizi çok dinç hissediyorsunuz!",
        NotifyEnd = "Enerji hapının etkisi geçti! Vücudunuz aniden ağırlaştı ve yorgunluk çöktü..."
    }
}

-- =======================================================================
-- 1. YATAKTA UYUMA SİSTEMİ
-- =======================================================================
Config.BedSystem = {
    SleepTimeSeconds = 30,          -- Yatakta uykunun %0'dan %100'e dolma süresi (Saniye)
    InteractDistance = 2.8,         -- Yatağa yaklaşma etkileşim mesafesi
    HelpText = "[ALT] Yatağa Uzan ve Uyu",

    -- GTA V Garantili Yatak Uyuma Animasyonu
    Animation = {
        Dict = "amb@world_human_sunbathe@male@back@base",
        Anim = "base",
        HeadingOffset = 180.0
    },

    -- Tanımlı Yatak Obje Hashleri / Modelleri
    BedProps = {
        `v_med_bed1`,
        `v_med_bed2`,
        `v_med_emptybed`,
        `v_res_d_bed`,
        `v_res_msonbed_s`,
        `v_res_tre_bed1`,
        `v_res_tre_bed2`,
        `v_res_tt_bed`,
        `apa_mp_h_bed_double_08`,
        `apa_mp_h_bed_double_09`,
        `apa_mp_h_bed_wide_05`,
        `apa_mp_h_bed_with_table_02`,
        `p_mbbed_s`,
        `p_lestersbed_s`,
        `p_v_res_sub_bed_s`,
        `bkr_prop_biker_campbed_01`,
        `gr_prop_gr_campbed_01`,
        `prop_rub_bed_01`,
        `prop_rub_bed_02`,
        `prop_bed_01`,
        `prop_bed_02`,
        `v_res_bed_double`
    },

    -- Haritada Özel Yatak Noktaları (Gerektiğinde vector3 koordinat eklenebilir)
    CustomBedLocations = {},

    -- Güvenli Çıkış (Quit) Mesajı
    QuitMessage = "Uykunuzu başarıyla aldınız ve güvenli bir şekilde oyundan ayrıldınız. Tekrar görüşmek üzere!"
}

-- =======================================================================
-- 2. OTURMA / KOLTUK / BANK DİNLENME SİSTEMİ (SEATING SLEEP SYSTEM)
-- =======================================================================
Config.SeatingSystem = {
    Enabled = true,                 -- Koltuk/Sandalye/Bank dinlenme sistemi aktif mi?
    SleepTimeSeconds = 35,          -- Koltukta uykunun dolma süresi (Saniye)
    InteractDistance = 2.4,         -- Etkileşim mesafesi
    HelpText = "[ALT] Otur ve Dinlen / Uyu",

    -- GTA V Garantili Koltukta/Sandalyede Dinlenme Animasyonu
    Animation = {
        Dict = "timetable@ron@ig_3_couch",
        Anim = "base",
        HeadingOffset = 180.0
    },

    -- Tanımlı Sandalye, Koltuk/Kanepe ve Sokak Bankı Modelleri
    SeatingProps = {
        -- Koltuklar & Kanepeler (Couches / Sofas)
        `prop_rub_couch01`,
        `prop_rub_couch02`,
        `prop_rub_couch03`,
        `prop_rub_couch04`,
        `p_couch_cs`,
        `p_res_sofa_l_s`,
        `p_v_med_p_sofa_s`,
        `v_ilev_m_sofa`,
        `v_med_couch1`,
        `v_med_couch2`,
        `v_res_d_armchair`,
        `v_res_mp_sofa`,
        `v_res_m_sofa`,
        `v_res_m_armchair`,
        `v_res_sofa_mess_a`,
        `v_res_sofa_mess_b`,
        `v_res_sofa_mess_c`,
        `v_res_tre_sofa`,
        `v_res_tre_sofa_mess_a`,
        `v_res_tre_sofa_mess_b`,
        `v_res_tt_sofa`,
        `apa_mp_h_stn_sofacorn_01`,
        `apa_mp_h_stn_sofacorn_05`,
        `apa_mp_h_stn_sofacorn_06`,
        `apa_mp_h_stn_sofacorn_07`,
        `apa_mp_h_stn_sofacorn_08`,
        `apa_mp_h_stn_sofacorn_09`,
        `apa_mp_h_stn_sofa_daybed_01`,
        `apa_mp_h_stn_sofa_daybed_02`,
        `apa_mp_h_stn_sofa_daybed_07`,
        `apa_mp_h_stn_sofa_daybed_09`,
        `apa_mp_h_stn_sofa_daybed_10`,
        `apa_mp_h_stn_sofa_daybed_11`,
        `apa_mp_h_stn_sofa_daybed_12`,
        `apa_mp_h_stn_sofa_daybed_14`,
        `apa_mp_h_stn_sofa_daybed_15`,
        `apa_mp_h_stn_sofa_daybed_16`,
        `apa_mp_h_stn_sofa_daybed_17`,

        -- Sandalyeler & Koltuklar (Chairs & Armchairs)
        `prop_chair_01a`,
        `prop_chair_01b`,
        `prop_chair_02`,
        `prop_chair_03`,
        `prop_chair_04a`,
        `prop_chair_04b`,
        `prop_chair_05`,
        `prop_chair_06`,
        `prop_chair_07`,
        `prop_chair_08`,
        `prop_chair_09`,
        `prop_chair_10`,
        `prop_chateau_chair_01`,
        `prop_clown_chair`,
        `prop_cs_office_chair`,
        `prop_direct_chair_01`,
        `prop_direct_chair_02`,
        `prop_gc_chair02`,
        `prop_off_chair_01`,
        `prop_off_chair_03`,
        `prop_off_chair_04`,
        `prop_off_chair_04b`,
        `prop_off_chair_04_cos`,
        `prop_off_chair_05`,
        `prop_rock_chair_01`,
        `prop_sol_chair`,
        `prop_wheelchair_01`,
        `prop_yaught_chair_01`,

        -- Banklar (Park & Street Benches)
        `prop_bench_01a`,
        `prop_bench_01b`,
        `prop_bench_01c`,
        `prop_bench_02`,
        `prop_bench_03`,
        `prop_bench_04`,
        `prop_bench_05`,
        `prop_bench_06`,
        `prop_bench_07`,
        `prop_bench_08`,
        `prop_bench_09`,
        `prop_bench_10`,
        `prop_bench_11`,
        `prop_fib_3b_bench`,
        `prop_ld_bench_01`
    }
}

-- =======================================================================
-- 3. HIZLI DİNLENME KOMUTLARI (/uyu)
-- =======================================================================
Config.Commands = {
    GroundSleep = {
        MaxReduction = 25.0,
        TickRate = 2000,
        PerTickHeal = 2.0,
        Cooldown = 180,
        Animation = {
            Dict = "amb@world_human_sunbathe@male@back@base",
            Anim = "base"
        },
        CancelKey = 73, -- 'X'
        NotifyLimit = "Burası çok rahatsız hissettiriyor, daha fazla dinlenemiyorum.",
        NotifyCancel = "Yerden kalktınız.",
        NotifyCooldown = "Zaten yakın zamanda yerde dinlendiniz! Lütfen biraz bekleyin (%s saniye)."
    },

    StandingSleep = {
        MaxReduction = 15.0,
        TickRate = 2000,
        PerTickHeal = 1.5,
        Cooldown = 120,
        Animation = {
            Dict = "amb@world_human_leaning@male@wall@back@foot_up@base",
            Anim = "base"
        },
        CancelKey = 73, -- 'X'
        NotifyLimit = "Ayakta daha fazla kestiremezsiniz, biraz açıldınız.",
        NotifyCancel = "Kendinize geldiniz ve dikleştiniz.",
        NotifyCooldown = "Yakın zamanda ayakta kestirdiniz! Lütfen biraz bekleyin (%s saniye)."
    }
}

-- Dil & Genel Bildirim Mesajları
Config.Locale = {
    ['already_sleeping'] = "Zaten şu anda uyuyorsunuz!",
    ['cannot_sleep_vehicle'] = "Araç içerisindeyken uyuyamazsınız!",
    ['cannot_sleep_dead'] = "Yaralı veya baygınken uyuyamazsınız!",
    ['woke_up_full'] = "Uykunuzu tamamen aldınız! Kendinizi mükemmel ve zinde hissediyorsunuz.",
    ['woke_up_partial'] = "Uyandınız. Dinlenme oranınıza göre yorgunluğunuz azaldı.",
    ['ground_sleep_started'] = "Yere uzandınız ve dinleniyorsunuz... (İptal etmek için [X])",
    ['standing_sleep_started'] = "Ayakta biraz kestirmeye başladınız... (İptal etmek için [X])",
    ['command_usage'] = "Kullanım: /uyu [yerde / ayakta / yatak / koltuk]",
    ['no_bed_nearby'] = "Yakınınızda uzanabileceğiniz bir yatak veya koltuk bulunamadı!",
    ['energy_active'] = "Enerji hapı etkisindeyken uyuyamazsınız!",
    ['freeze_enabled'] = "Yorgunluk artışınız bir yönetici tarafından donduruldu.",
    ['freeze_disabled'] = "Yorgunluk artış dondurması kaldırıldı, normal işleyişe döndünüz.",
    ['effects_cleared'] = "Tüm yorgunluk ve baş dönmesi efektleriniz temizlendi."
}
