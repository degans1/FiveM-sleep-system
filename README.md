# 🌙 exe-sleep - QBCore Gelişmiş Uyku & Yorgunluk Sistemi

**Geliştirici:** ExeDevelopment  
**Discord:** [https://discord.gg/H2ztYhzEGd](https://discord.gg/H2ztYhzEGd)  
**GitHub:** [https://github.com/degans1](https://github.com/degans1)  
**Performans:** 0.00 ms (Boşta ve Aktifken Tam Optimize)  
**Uyumluluk:** QBCore Framework  

---

## 📖 Genel Bakış

**`exe-sleep`**, FiveM sunucularınız için oyuncu yorgunluğunu, uyku düzenini ve gerçekçi dinlenme mekaniklerini simüle eden; hem **yatakları** hem de **koltuk, sandalye ve sokak banklarını (Seating Sleep)** destekleyen modern **HTML/CSS/JS (Glassmorphic Dark NUI)** arayüzüne sahip, yüksek performanslı bir scripttir.

---

## ✨ Temel Özellikler

### 1. Yorgunluk Seviyesi ve Görsel Efektler
- **0 - 100 Arası Dinamik Yorgunluk:** Oyuncular dururken, yürürken, koşarken (çarpanlı) veya araç kullanırken yorulur.
- **Kademeli Türkçe Bildirimler:** %50, %70 ve %90 eşiklerinde oyuncuya durumunu anlatan uyarılar gönderilir.
- **%70 ve Üzeri Efektler:**
  - Ekran bulanıklaşması (Screen Blur).
  - Hafif baş dönmesi ve kamera sallantısı (Drunk/Dizziness Shake).
  - **Göz Kırpma / Kararma Efekti (Blinking Eyes):** Göz kapaklarının ağırlaşmasını simüle eden periyodik ekran kararmaları.
- **%100 Bayılma Mekaniği:** Oyuncu aşırı yorgunluktan yere yığılır (5 saniye Ragdoll baygınlık), ardından %90 yorgunluk seviyesiyle uyanır.

### 2. Yatak ve Koltuk / Bank Dinlenme Sistemi (Seating Sleep)
- **Yataklar:** Haritadaki yatak prop'ları ve özel koordinatlar otomatik taranır. `[ALT] Yatağa Uzan ve Uyu` uyarısı çıkar, uzanma animasyonu oynatılır.
- **Koltuk, Sandalye ve Banklar:** Dünya üzerindeki tüm kanepeler, ofis/ev sandalyeleri ve sokak bankları taranır. `[ALT] Otur ve Dinlen / Uyu` uyarısı çıkar, oturarak dinlenme/uyuma animasyonu oynatılır.
- **Glassmorphic Dark NUI:**
  - **Sol Buton ("Uyan / Kalk"):** Karakteri hemen ayağa kaldırır. İlerleme çubuğunun doluluk oranına göre yorgunluk orantılı olarak azaltılır.
  - **Sağ Buton ("Uykunu Tamamen Al - Quit"):** Yorgunluğu doğrudan %0 yapar, QBCore veritabanına kaydeder ve oyuncuyu sunucudan güvenle çıkarır.
  - **Orta İlerleme Çubuğu ("Uyuyorsun..." / "Dinleniyorsun..."):** Süre dolduğunda (%100) yorgunluk sıfırlanır ve karakter otomatik kalkar.

### 3. Özel Eşyalar (Usable Items)
- **`sleeping_pill` (Uyku Hapı):** İçildiğinde yorgunluk seviyesini anında %85-%100 arasına çıkarır.
- **`energy_pill` (Enerji Hapı):** Anlık yorgunluğu düşürür ve belirli bir süre yorgunluk artışını dondurur. Süre bitiminde **Geri Tepme (Rebound)** etkisi devreye girerek ani yorgunluk yükler.

### 4. Hızlı Dinlenme Komutları
- **`/uyu yerde`:** Karakter yere uzanır ve dinlenir (Maksimum %25-%30 yorgunluk düşürür).
- **`/uyu ayakta`:** Karakter ayakta kestirir (Maksimum %15-%20 dinlenme sağlar).
- Dinlenmeler istendiğinde **[X]** tuşu ile iptal edilebilir.

---

## 🛠️ Kurulum & Entegrasyon

### 1. `server.cfg` Ayarı
`server.cfg` dosyanıza şu satırı ekleyin:
```cfg
ensure exe-sleep
```

### 2. QBCore Eşya Tanımlamaları (`qb-core/shared/items.lua`)
Aşağıdaki eşyaları `qb-core/shared/items.lua` dosyanıza ekleyin:

```lua
['sleeping_pill'] = {
    ['name'] = 'sleeping_pill',
    ['label'] = 'Uyku Hapı',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'painkillers.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Hızlıca uyku getiren ve vücudu rahatlatan bir uyku hapı.'
},
['energy_pill'] = {
    ['name'] = 'energy_pill',
    ['label'] = 'Enerji Hapı',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'ephedrine.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Geçici olarak yorgunluğu donduran fakat etkisi geçince yoran hap.'
},
```

---

## ⌨️ Komut Listesi

### 1. Oyuncu Komutları
| Komut | Açıklama |
| :--- | :--- |
| `/uyu yerde` | Yerde uzanarak dinlenir (Maksimum %25-30 düşürür, [X] ile iptal). |
| `/uyu ayakta` | Ayakta kestirir (Maksimum %15-20 düşürür, [X] ile iptal). |
| `/yat` | Yakındaki yatak veya koltukta dinlenmeyi doğrudan başlatır. |
| `/uykudurumu` | Oyuncunun mevcut yorgunluk yüzdesini, durum tanımını ve aktif hap/buff etkilerini gösterir. |

### 2. Yönetici Komutları (`admin` / `god` Yetkisi)
| Komut | Parametreler | Açıklama |
| :--- | :--- | :--- |
| `/sleepset` | `[target_id] [amount]` | Belirtilen oyuncunun yorgunluk değerini ayarlar (0 - 100). |
| `/sleepreset` | `[target_id]` | Hedef oyuncunun yorgunluğunu sıfırlar ve tüm efektleri temizler. |
| `/sleepfreeze` | `[target_id]` | Hedef oyuncunun yorgunluk artışını dondurur veya çözer. |
| `/sleepcheck` | `[target_id]` | Hedef oyuncunun yorgunluk durumunu ve aktif haplarını görüntüler. |
| `/givepill` | `[target_id] [sleeping_pill / energy_pill] [amount]` | Hedef oyuncunun envanterine uyku veya enerji hapı verir. |

### 3. Geliştirici Test Komutları (`Config.Debug = true`)
| Komut | Parametreler | Açıklama |
| :--- | :--- | :--- |
| `/sleepdev_faint` | - | Anında %100 bayılma döngüsünü ve 5 saniyelik ragdoll sekansını tetikler. |
| `/sleepdev_effects` | - | %70+ yorgunluk görsel ve göz kırpma efektlerini anında açar / kapatır. |
| `/sleepdev_ui` | - | Haritanın her yerinde dinlenme NUI arayüzünü anında açarak test eder. |
| `/sleepdev_speed` | `[multiplier]` | Yorgunluk birikme hızını çarpanla hızlandırır (Örn: `/sleepdev_speed 10`). |

---

## 📞 Destek ve İletişim

- **Discord:** [https://discord.gg/H2ztYhzEGd](https://discord.gg/H2ztYhzEGd)
- **GitHub:** [https://github.com/degans1](https://github.com/degans1)
- **Geliştirici:** ExeDevelopment
