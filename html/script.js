/*
    -----------------------------------------------------------------------
    Resource: exe-sleep
    Author: ExeDevelopment
    Discord: https://discord.gg/H2ztYhzEGd
    GitHub: https://github.com/degans1
    Description: QBCore Uyku & Dinlenme Sistemi NUI Javascript Mantığı
    -----------------------------------------------------------------------
*/

let isSleeping = false;
let currentProgress = 0;
let sleepInterval = null;
let totalDurationMs = 30000;

const sleepContainer = document.getElementById('sleep-container');
const progressBar = document.getElementById('progress-bar');
const progressText = document.getElementById('progress-text');
const btnWake = document.getElementById('btn-wake');
const btnQuit = document.getElementById('btn-quit');

const sleepHeading = document.getElementById('sleep-heading');
const sleepSubheading = document.getElementById('sleep-subheading');
const badgeTitle = document.getElementById('badge-title');
const centerIconBox = document.getElementById('center-icon-box');

// =======================================================================
// NUI MESAJ DİNLEYİCİSİ (LUA -> JS)
// =======================================================================
window.addEventListener('message', function (event) {
    try {
        const data = event.data;
        if (!data) return;

        if (data.action === 'openBedSleep') {
            const isSeating = (data.isSeating === true);
            
            // Başlık ve Açıklamaları Ayarla
            if (sleepHeading) {
                sleepHeading.innerText = isSeating ? "Dinleniyorsun..." : "Uyuyorsun...";
            }
            if (sleepSubheading) {
                sleepSubheading.innerText = isSeating ? "Koltukta oturarak vücudunu dinlendiriyorsun" : "Yatakta derin uykudasın ve enerjin yenileniyor";
            }
            if (badgeTitle) {
                badgeTitle.innerText = isSeating ? "Oturma Dinlenme Modu" : "Derin Uyku Modu";
            }

            // Güvenli İkon Değişimi (DIV konteyner innerHTML kullanarak SVG parse hatasını önler)
            if (centerIconBox) {
                if (isSeating) {
                    centerIconBox.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 9V6a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v3"></path><path d="M3 16a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5a2 2 0 0 0-4 0v1.5a.5.5 0 0 1-.5.5h-9a.5.5 0 0 1-.5-.5V11a2 2 0 0 0-4 0z"></path><path d="M5 18v2"></path><path d="M19 18v2"></path></svg>';
                } else {
                    centerIconBox.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 4v16M2 8h18a2 2 0 0 1 2 2v10M2 17h20M6 8v9"></path></svg>';
                }
            }

            openSleepUI(Number(data.duration) || 30);
        } else if (data.action === 'closeBedSleep') {
            closeSleepUI();
        } else if (data.action === 'updateProgress') {
            setProgress(Number(data.progress) || 0);
        }
    } catch (err) {
        console.error("[exe-sleep] NUI Mesaj Hatası:", err);
    }
});

// =======================================================================
// UYKU ARAYÜZÜNÜ AÇMA / BAŞLATMA
// =======================================================================
function openSleepUI(durationInSeconds) {
    isSleeping = true;
    currentProgress = 0;
    totalDurationMs = Math.max(5, durationInSeconds) * 1000;

    setProgress(0);

    // CEF Zorunlu Flex Render
    if (sleepContainer) {
        sleepContainer.style.setProperty('display', 'flex', 'important');
        sleepContainer.style.opacity = '1';
        sleepContainer.style.visibility = 'visible';
    }

    if (sleepInterval) {
        clearInterval(sleepInterval);
        sleepInterval = null;
    }

    const stepInterval = 100;
    const stepIncrement = (stepInterval / totalDurationMs) * 100;

    sleepInterval = setInterval(() => {
        if (!isSleeping) {
            clearInterval(sleepInterval);
            sleepInterval = null;
            return;
        }

        currentProgress += stepIncrement;
        if (currentProgress >= 100) {
            currentProgress = 100;
            setProgress(100);
            clearInterval(sleepInterval);
            sleepInterval = null;
            
            setTimeout(() => {
                sendNuiCallback('sleepCompleted', { progress: 100 });
            }, 300);
        } else {
            setProgress(currentProgress);
        }
    }, stepInterval);
}

// =======================================================================
// UYKU ARAYÜZÜNÜ KAPATMA
// =======================================================================
function closeSleepUI() {
    isSleeping = false;
    if (sleepInterval) {
        clearInterval(sleepInterval);
        sleepInterval = null;
    }
    if (sleepContainer) {
        sleepContainer.style.setProperty('display', 'none', 'important');
        sleepContainer.style.opacity = '0';
    }
    setProgress(0);
}

// =======================================================================
// İLERLEME ÇUBUĞUNU GÜNCELLEME
// =======================================================================
function setProgress(percent) {
    const clamped = Math.min(100, Math.max(0, percent));
    if (progressBar) progressBar.style.width = clamped + '%';
    if (progressText) progressText.innerText = Math.floor(clamped) + '%';
}

// =======================================================================
// BUTON ETKİLEŞİMLERİ & NUI CALLBACKS
// =======================================================================

// "Uyan / Kalk" Butonu
if (btnWake) {
    btnWake.addEventListener('click', function () {
        if (!isSleeping) return;
        const progressAtWake = currentProgress;
        closeSleepUI();
        sendNuiCallback('wakeUp', { progress: progressAtWake });
    });
}

// "Uykunu Tamamen Al (Quit)" Butonu
if (btnQuit) {
    btnQuit.addEventListener('click', function () {
        if (!isSleeping) return;
        closeSleepUI();
        sendNuiCallback('quitServer', {});
    });
}

// ESC Tuşu ile Uyanma
window.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && isSleeping) {
        const progressAtWake = currentProgress;
        closeSleepUI();
        sendNuiCallback('wakeUp', { progress: progressAtWake });
    }
});

// =======================================================================
// NUI CALLBACK YARDIMCISI (JS -> LUA)
// =======================================================================
function sendNuiCallback(endpoint, payload) {
    const resource = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'exe-sleep';
    fetch(`https://${resource}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(payload || {})
    }).catch(() => {});
}
