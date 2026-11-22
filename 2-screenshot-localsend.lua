-- Screenshot LocalSend for KOReader, version 1.1.2.
local InfoMessage = require("ui/widget/infomessage")
local Screenshoter = require("ui/widget/screenshoter")
local UIManager = require("ui/uimanager")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local userpatch = require("userpatch")
local gettext = require("gettext")

-- Keep the catalog in the patch so a single file can be copied to the device.
-- Columns follow the order in message_index. Region variants share their base
-- language unless they need different wording or script.
local message_index = {
    send = 1,
    searching = 2,
    unavailable = 3,
    not_installed = 4,
    disabled = 5,
    error = 6,
    missing_file = 7,
    start_error = 8,
    transfer_timeout = 9,
    wifi_error = 10,
}
local catalogs = [=[
af|Stuur via LocalSend|Soek na LocalSend-toestelle…|LocalSend is nie beskikbaar nie. Gaan die inprop se installasie na.|LocalSend is nie geïnstalleer nie.|LocalSend is in KOReader gedeaktiveer.|Kon LocalSend nie gebruik nie.|Die skermskootlêer ontbreek.|Kon die oordrag nie begin nie.|Die LocalSend-oordrag het uitgetel.|Kon nie aan Wi-Fi koppel nie.
ar|إرسال عبر LocalSend|جارٍ البحث عن أجهزة LocalSend…|‏LocalSend غير متاح. تحقّق من تثبيت الإضافة.|‏LocalSend غير مثبت.|‏LocalSend معطّل في KOReader.|تعذّر استخدام LocalSend.|ملف لقطة الشاشة مفقود.|تعذّر بدء النقل.|انتهت مهلة النقل عبر LocalSend.|تعذّر الاتصال بشبكة Wi-Fi.
be|Адправіць праз LocalSend|Пошук прылад LocalSend…|LocalSend недаступны. Праверце ўсталяванне ўбудовы.|LocalSend не ўсталяваны.|LocalSend адключаны ў KOReader.|Не ўдалося выкарыстаць LocalSend.|Файл здымка экрана адсутнічае.|Не ўдалося пачаць перадачу.|Час чакання перадачы праз LocalSend скончыўся.|Не ўдалося падключыцца да Wi-Fi.
bg|Изпращане чрез LocalSend|Търсене на устройства с LocalSend…|LocalSend не е достъпен. Проверете инсталацията на добавката.|LocalSend не е инсталиран.|LocalSend е изключен в KOReader.|LocalSend не може да се използва.|Файлът със снимката на екрана липсва.|Прехвърлянето не можа да започне.|Времето за прехвърляне чрез LocalSend изтече.|Неуспешно свързване с Wi-Fi.
bn|LocalSend দিয়ে পাঠান|LocalSend ডিভাইস খোঁজা হচ্ছে…|LocalSend উপলভ্য নয়। প্লাগইনের ইনস্টলেশন পরীক্ষা করুন।|LocalSend ইনস্টল করা নেই।|KOReader-এ LocalSend নিষ্ক্রিয় আছে।|LocalSend ব্যবহার করা যায়নি।|স্ক্রিনশট ফাইলটি নেই।|স্থানান্তর শুরু করা যায়নি।|LocalSend-এ স্থানান্তরের সময়সীমা পেরিয়ে গেছে।|Wi-Fi-এ সংযোগ করা যায়নি।
ca|Envia amb LocalSend|S'estan cercant dispositius LocalSend…|LocalSend no està disponible. Comproveu la instal·lació del connector.|LocalSend no està instal·lat.|LocalSend està desactivat al KOReader.|No s'ha pogut utilitzar LocalSend.|Falta el fitxer de la captura de pantalla.|No s'ha pogut iniciar la transferència.|S'ha esgotat el temps d'espera de la transferència amb LocalSend.|No s'ha pogut connectar a la Wi-Fi.
cs|Odeslat přes LocalSend|Hledají se zařízení LocalSend…|LocalSend není dostupný. Zkontrolujte instalaci doplňku.|LocalSend není nainstalovaný.|LocalSend je v KOReaderu vypnutý.|LocalSend se nepodařilo použít.|Soubor se snímkem obrazovky chybí.|Přenos se nepodařilo zahájit.|Časový limit přenosu přes LocalSend vypršel.|Nepodařilo se připojit k Wi-Fi.
cy|Anfon drwy LocalSend|Yn chwilio am ddyfeisiau LocalSend…|Nid yw LocalSend ar gael. Gwiriwch osodiad yr ategyn.|Nid yw LocalSend wedi'i osod.|Mae LocalSend wedi'i analluogi yn KOReader.|Methu defnyddio LocalSend.|Mae ffeil y ciplun ar goll.|Methu cychwyn y trosglwyddiad.|Daeth amser y trosglwyddiad LocalSend i ben.|Methu cysylltu â Wi-Fi.
da|Send via LocalSend|Søger efter LocalSend-enheder…|LocalSend er ikke tilgængelig. Kontrollér installationen af udvidelsen.|LocalSend er ikke installeret.|LocalSend er deaktiveret i KOReader.|LocalSend kunne ikke bruges.|Skærmbilledfilen mangler.|Overførslen kunne ikke startes.|Tidsfristen for LocalSend-overførslen udløb.|Kunne ikke oprette forbindelse til Wi-Fi.
de|Mit LocalSend senden|LocalSend-Geräte werden gesucht…|LocalSend ist nicht verfügbar. Prüfe die Installation des Plugins.|LocalSend ist nicht installiert.|LocalSend ist in KOReader deaktiviert.|LocalSend konnte nicht verwendet werden.|Die Bildschirmfoto-Datei fehlt.|Die Übertragung konnte nicht gestartet werden.|Zeitüberschreitung bei der LocalSend-Übertragung.|Keine Verbindung zum WLAN möglich.
el|Αποστολή μέσω LocalSend|Αναζήτηση συσκευών LocalSend…|Το LocalSend δεν είναι διαθέσιμο. Ελέγξτε την εγκατάσταση του πρόσθετου.|Το LocalSend δεν είναι εγκατεστημένο.|Το LocalSend είναι απενεργοποιημένο στο KOReader.|Δεν ήταν δυνατή η χρήση του LocalSend.|Λείπει το αρχείο του στιγμιότυπου οθόνης.|Δεν ήταν δυνατή η έναρξη της μεταφοράς.|Έληξε το χρονικό όριο της μεταφοράς μέσω LocalSend.|Δεν ήταν δυνατή η σύνδεση στο Wi-Fi.
en|Send via LocalSend|Searching for LocalSend devices…|LocalSend is unavailable. Check the plugin installation.|LocalSend is not installed.|LocalSend is disabled in KOReader.|Could not use LocalSend.|Screenshot file is missing.|Could not start the transfer.|LocalSend transfer timed out.|Could not connect to Wi-Fi.
eo|Sendi per LocalSend|Serĉante aparatojn kun LocalSend…|LocalSend ne disponeblas. Kontrolu la instalon de la kromprogramo.|LocalSend ne estas instalita.|LocalSend estas malŝaltita en KOReader.|Ne eblis uzi LocalSend.|La ekrankopia dosiero mankas.|Ne eblis komenci la transigon.|La tempolimo de la transigo per LocalSend pasis.|Ne eblis konektiĝi al Wi-Fi.
es|Enviar con LocalSend|Buscando dispositivos LocalSend…|LocalSend no está disponible. Comprueba la instalación del complemento.|LocalSend no está instalado.|LocalSend está desactivado en KOReader.|No se pudo usar LocalSend.|Falta el archivo de la captura de pantalla.|No se pudo iniciar la transferencia.|Se agotó el tiempo de espera de la transferencia con LocalSend.|No se pudo conectar a la red Wi-Fi.
et|Saada LocalSendiga|LocalSendi seadmete otsimine…|LocalSend pole saadaval. Kontrolli lisamooduli paigaldust.|LocalSend pole paigaldatud.|LocalSend on KOReaderis välja lülitatud.|LocalSendi ei õnnestunud kasutada.|Kuvatõmmise fail puudub.|Edastust ei õnnestunud alustada.|LocalSendi edastus aegus.|Wi-Fi ühendus ebaõnnestus.
eu|Bidali LocalSend bidez|LocalSend gailuak bilatzen…|LocalSend ez dago erabilgarri. Egiaztatu gehigarriaren instalazioa.|LocalSend ez dago instalatuta.|LocalSend desgaituta dago KOReader-en.|Ezin izan da LocalSend erabili.|Pantaila-argazkiaren fitxategia falta da.|Ezin izan da transferentzia hasi.|LocalSend bidezko transferentziaren denbora-muga gainditu da.|Ezin izan da Wi-Fi sarera konektatu.
fa|ارسال با LocalSend|در حال جست‌وجوی دستگاه‌های LocalSend…|‏LocalSend در دسترس نیست. نصب افزونه را بررسی کنید.|‏LocalSend نصب نشده است.|‏LocalSend در KOReader غیرفعال است.|استفاده از LocalSend ممکن نبود.|فایل تصویر صفحه موجود نیست.|انتقال شروع نشد.|مهلت انتقال با LocalSend به پایان رسید.|اتصال به Wi-Fi ممکن نبود.
fi|Lähetä LocalSendillä|Etsitään LocalSend-laitteita…|LocalSend ei ole käytettävissä. Tarkista lisäosan asennus.|LocalSendiä ei ole asennettu.|LocalSend on poistettu käytöstä KOReaderissa.|LocalSendiä ei voitu käyttää.|Kuvakaappaustiedosto puuttuu.|Siirtoa ei voitu aloittaa.|LocalSend-siirto aikakatkaistiin.|Wi-Fi-yhteyttä ei voitu muodostaa.
fr|Envoyer via LocalSend|Recherche d’appareils LocalSend…|LocalSend est indisponible. Vérifiez l’installation de l’extension.|LocalSend n’est pas installé.|LocalSend est désactivé dans KOReader.|Impossible d’utiliser LocalSend.|Le fichier de capture d’écran est introuvable.|Impossible de démarrer le transfert.|Le délai du transfert via LocalSend a expiré.|Impossible de se connecter au Wi-Fi.
ga|Seol le LocalSend|Gléasanna LocalSend á lorg…|Níl LocalSend ar fáil. Seiceáil suiteáil an bhreiseáin.|Níl LocalSend suiteáilte.|Tá LocalSend díchumasaithe in KOReader.|Níorbh fhéidir LocalSend a úsáid.|Tá comhad an scáileáin ar iarraidh.|Níorbh fhéidir an t-aistriú a thosú.|Chuaigh aistriú LocalSend thar am.|Níorbh fhéidir ceangal le Wi-Fi.
gl|Enviar con LocalSend|Buscando dispositivos LocalSend…|LocalSend non está dispoñible. Comproba a instalación do complemento.|LocalSend non está instalado.|LocalSend está desactivado en KOReader.|Non se puido usar LocalSend.|Falta o ficheiro da captura de pantalla.|Non se puido iniciar a transferencia.|Esgotouse o tempo de espera da transferencia con LocalSend.|Non se puido conectar á rede Wi-Fi.
he|שליחה דרך LocalSend|מתבצע חיפוש אחר מכשירי LocalSend…|‏LocalSend אינו זמין. יש לבדוק את התקנת התוסף.|‏LocalSend אינו מותקן.|‏LocalSend מושבת ב־KOReader.|לא ניתן להשתמש ב־LocalSend.|קובץ צילום המסך חסר.|לא ניתן להתחיל בהעברה.|הזמן שהוקצב להעברה דרך LocalSend חלף.|לא ניתן להתחבר לרשת ה־Wi-Fi.
hi|LocalSend से भेजें|LocalSend डिवाइस खोजे जा रहे हैं…|LocalSend उपलब्ध नहीं है। प्लगइन की स्थापना जाँचें।|LocalSend इंस्टॉल नहीं है।|KOReader में LocalSend बंद है।|LocalSend का उपयोग नहीं हो सका।|स्क्रीनशॉट फ़ाइल नहीं मिली।|स्थानांतरण शुरू नहीं हो सका।|LocalSend स्थानांतरण की समय-सीमा समाप्त हो गई।|Wi-Fi से कनेक्ट नहीं हो सका।
hr|Pošalji putem LocalSenda|Traženje LocalSend uređaja…|LocalSend nije dostupan. Provjerite instalaciju dodatka.|LocalSend nije instaliran.|LocalSend je onemogućen u KOReaderu.|LocalSend se nije mogao koristiti.|Datoteka snimke zaslona nedostaje.|Prijenos nije bilo moguće započeti.|Isteklo je vrijeme za prijenos putem LocalSenda.|Nije se moguće povezati s Wi-Fi mrežom.
hu|Küldés LocalSenddel|LocalSend-eszközök keresése…|A LocalSend nem érhető el. Ellenőrizd a bővítmény telepítését.|A LocalSend nincs telepítve.|A LocalSend le van tiltva a KOReaderben.|A LocalSend nem használható.|Hiányzik a képernyőkép fájlja.|Nem sikerült elindítani az átvitelt.|A LocalSend-átvitel túllépte az időkorlátot.|Nem sikerült csatlakozni a Wi-Fihez.
ia|Inviar per LocalSend|Cercante dispositivos LocalSend…|LocalSend non es disponibile. Verifica le installation del extension.|LocalSend non es installate.|LocalSend es disactivate in KOReader.|Impossibile usar LocalSend.|Le file del captura de schermo manca.|Impossibile initiar le transferimento.|Le tempore limite del transferimento per LocalSend ha expirate.|Impossibile connecter a Wi-Fi.
id|Kirim lewat LocalSend|Mencari perangkat LocalSend…|LocalSend tidak tersedia. Periksa pemasangan plugin.|LocalSend belum terpasang.|LocalSend dinonaktifkan di KOReader.|Tidak dapat menggunakan LocalSend.|Berkas tangkapan layar tidak ditemukan.|Tidak dapat memulai transfer.|Waktu transfer LocalSend habis.|Tidak dapat terhubung ke Wi-Fi.
ie|Inviar per LocalSend|Sercha por aparates LocalSend…|LocalSend ne es disponibil. Controla li installation del extension.|LocalSend ne es installat.|LocalSend es desactivat in KOReader.|Ne posset usar LocalSend.|Li file del captura de ecran manca.|Ne posset iniciar li transferte.|Li témpor por li transferte per LocalSend expirat.|Ne posset conecter se al Wi-Fi.
it|Invia con LocalSend|Ricerca dispositivi LocalSend…|LocalSend non è disponibile. Controlla l’installazione del plugin.|LocalSend non è installato.|LocalSend è disattivato in KOReader.|Impossibile usare LocalSend.|Il file dello screenshot non è più disponibile.|Impossibile avviare il trasferimento.|Tempo scaduto per l’invio con LocalSend.|Impossibile connettersi al Wi-Fi.
ja|LocalSend で送信|LocalSend のデバイスを検索中…|LocalSend を利用できません。プラグインのインストールを確認してください。|LocalSend がインストールされていません。|KOReader で LocalSend が無効になっています。|LocalSend を使用できませんでした。|スクリーンショットのファイルが見つかりません。|転送を開始できませんでした。|LocalSend の転送がタイムアウトしました。|Wi-Fi に接続できませんでした。
kab|Azen s LocalSend|Anadi n yibenk n LocalSend…|LocalSend ur yewjid ara. Senqed asebded n uzegrir.|LocalSend ur yettusbedd ara.|LocalSend yensa deg KOReader.|D awezɣi aseqdec n LocalSend.|Afaylu n tuṭṭfa n ugdil ulac-it.|D awezɣi ad yebdu usiweḍ.|Yemmed wakud n usiweḍ s LocalSend.|D awezɣi tuqqna ɣer Wi-Fi.
ka|გაგზავნა LocalSend-ით|LocalSend-ის მოწყობილობების ძიება…|LocalSend მიუწვდომელია. შეამოწმეთ დანამატის ინსტალაცია.|LocalSend დაყენებული არ არის.|LocalSend გამორთულია KOReader-ში.|LocalSend-ის გამოყენება ვერ მოხერხდა.|ეკრანის ანაბეჭდის ფაილი ვერ მოიძებნა.|გადაცემის დაწყება ვერ მოხერხდა.|LocalSend-ით გადაცემის დრო ამოიწურა.|Wi-Fi-სთან დაკავშირება ვერ მოხერხდა.
kk|LocalSend арқылы жіберу|LocalSend құрылғылары ізделуде…|LocalSend қолжетімсіз. Плагиннің орнатылуын тексеріңіз.|LocalSend орнатылмаған.|LocalSend KOReader жүйесінде өшірілген.|LocalSend қолданылмады.|Экран суретінің файлы табылмады.|Тасымалдауды бастау мүмкін болмады.|LocalSend арқылы тасымалдау уақыты аяқталды.|Wi-Fi желісіне қосылу мүмкін болмады.
kn|LocalSend ಮೂಲಕ ಕಳುಹಿಸಿ|LocalSend ಸಾಧನಗಳನ್ನು ಹುಡುಕಲಾಗುತ್ತಿದೆ…|LocalSend ಲಭ್ಯವಿಲ್ಲ. ಪ್ಲಗಿನ್ ಸ್ಥಾಪನೆಯನ್ನು ಪರಿಶೀಲಿಸಿ.|LocalSend ಸ್ಥಾಪಿಸಲಾಗಿಲ್ಲ.|KOReader ನಲ್ಲಿ LocalSend ನಿಷ್ಕ್ರಿಯವಾಗಿದೆ.|LocalSend ಬಳಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.|ಸ್ಕ್ರೀನ್‌ಶಾಟ್ ಕಡತ ಕಾಣುತ್ತಿಲ್ಲ.|ವರ್ಗಾವಣೆಯನ್ನು ಪ್ರಾರಂಭಿಸಲಾಗಲಿಲ್ಲ.|LocalSend ವರ್ಗಾವಣೆಯ ಸಮಯ ಮೀರಿದೆ.|Wi-Fi ಗೆ ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.
ko|LocalSend로 보내기|LocalSend 기기 검색 중…|LocalSend를 사용할 수 없습니다. 플러그인 설치 상태를 확인하세요.|LocalSend가 설치되어 있지 않습니다.|KOReader에서 LocalSend가 비활성화되어 있습니다.|LocalSend를 사용하지 못했습니다.|스크린샷 파일을 찾을 수 없습니다.|전송을 시작하지 못했습니다.|LocalSend 전송 시간이 초과되었습니다.|Wi-Fi에 연결하지 못했습니다.
lt|Siųsti per LocalSend|Ieškoma LocalSend įrenginių…|LocalSend nepasiekiamas. Patikrinkite, ar tinkamai įdiegtas papildinys.|LocalSend neįdiegtas.|LocalSend išjungtas programoje KOReader.|Nepavyko naudoti LocalSend.|Ekrano nuotraukos failas nerastas.|Nepavyko pradėti perdavimo.|Baigėsi perdavimo per LocalSend laukimo laikas.|Nepavyko prisijungti prie Wi-Fi.
lv|Sūtīt ar LocalSend|Meklē LocalSend ierīces…|LocalSend nav pieejams. Pārbaudiet spraudņa instalāciju.|LocalSend nav instalēts.|LocalSend ir atspējots programmā KOReader.|Neizdevās izmantot LocalSend.|Trūkst ekrānuzņēmuma faila.|Neizdevās sākt pārsūtīšanu.|Beidzās LocalSend pārsūtīšanas laiks.|Neizdevās izveidot savienojumu ar Wi-Fi.
mk|Испрати преку LocalSend|Се бараат уреди со LocalSend…|LocalSend не е достапен. Проверете ја инсталацијата на додатокот.|LocalSend не е инсталиран.|LocalSend е исклучен во KOReader.|LocalSend не може да се користи.|Недостасува датотеката со сликата од екранот.|Преносот не можеше да се започне.|Истече времето за пренос преку LocalSend.|Не може да се поврзе со Wi-Fi.
ms|Hantar melalui LocalSend|Mencari peranti LocalSend…|LocalSend tidak tersedia. Semak pemasangan pemalam.|LocalSend belum dipasang.|LocalSend dinyahdayakan dalam KOReader.|LocalSend tidak dapat digunakan.|Fail tangkapan skrin tiada.|Pemindahan tidak dapat dimulakan.|Masa pemindahan LocalSend tamat.|Tidak dapat menyambung ke Wi-Fi.
nb|Send via LocalSend|Søker etter LocalSend-enheter…|LocalSend er utilgjengelig. Kontroller at programtillegget er riktig installert.|LocalSend er ikke installert.|LocalSend er deaktivert i KOReader.|Kunne ikke bruke LocalSend.|Skjermbildefilen mangler.|Kunne ikke starte overføringen.|Tidsavbrudd under LocalSend-overføringen.|Kunne ikke koble til Wi-Fi.
nl|Versturen via LocalSend|Zoeken naar LocalSend-apparaten…|LocalSend is niet beschikbaar. Controleer de installatie van de plug-in.|LocalSend is niet geïnstalleerd.|LocalSend is uitgeschakeld in KOReader.|LocalSend kon niet worden gebruikt.|Het schermafbeeldingsbestand ontbreekt.|De overdracht kon niet worden gestart.|De LocalSend-overdracht duurde te lang.|Kan geen verbinding maken met wifi.
or|LocalSend ମାଧ୍ୟମରେ ପଠାନ୍ତୁ|LocalSend ଡିଭାଇସ୍ ଖୋଜା ଚାଲିଛି…|LocalSend ଉପଲବ୍ଧ ନାହିଁ। ପ୍ଲଗଇନ୍ ସଂସ୍ଥାପନା ଯାଞ୍ଚ କରନ୍ତୁ।|LocalSend ସଂସ୍ଥାପିତ ହୋଇନାହିଁ।|KOReader ରେ LocalSend ନିଷ୍କ୍ରିୟ ଅଛି।|LocalSend ବ୍ୟବହାର କରିହେଲା ନାହିଁ।|ସ୍କ୍ରିନ୍‌ସଟ୍ ଫାଇଲ୍ ମିଳୁନାହିଁ।|ସ୍ଥାନାନ୍ତର ଆରମ୍ଭ କରିହେଲା ନାହିଁ।|LocalSend ସ୍ଥାନାନ୍ତରର ସମୟସୀମା ଶେଷ ହୋଇଗଲା।|Wi-Fi ସହ ସଂଯୋଗ ହୋଇପାରିଲା ନାହିଁ।
pl|Wyślij przez LocalSend|Wyszukiwanie urządzeń LocalSend…|LocalSend jest niedostępny. Sprawdź instalację wtyczki.|LocalSend nie jest zainstalowany.|LocalSend jest wyłączony w KOReaderze.|Nie udało się użyć LocalSend.|Brakuje pliku zrzutu ekranu.|Nie udało się rozpocząć przesyłania.|Przekroczono limit czasu przesyłania przez LocalSend.|Nie udało się połączyć z Wi-Fi.
pt_BR|Enviar com LocalSend|Procurando dispositivos LocalSend…|O LocalSend não está disponível. Verifique a instalação do plugin.|O LocalSend não está instalado.|O LocalSend está desativado no KOReader.|Não foi possível usar o LocalSend.|O arquivo da captura de tela não foi encontrado.|Não foi possível iniciar a transferência.|O tempo limite da transferência pelo LocalSend foi atingido.|Não foi possível conectar à rede Wi-Fi.
pt_PT|Enviar com LocalSend|A procurar dispositivos LocalSend…|O LocalSend não está disponível. Verifique a instalação do módulo.|O LocalSend não está instalado.|O LocalSend está desativado no KOReader.|Não foi possível utilizar o LocalSend.|O ficheiro da captura de ecrã não foi encontrado.|Não foi possível iniciar a transferência.|Esgotou-se o tempo da transferência por LocalSend.|Não foi possível ligar à rede Wi-Fi.
ro|Trimite prin LocalSend|Se caută dispozitive LocalSend…|LocalSend nu este disponibil. Verifică instalarea modulului.|LocalSend nu este instalat.|LocalSend este dezactivat în KOReader.|LocalSend nu a putut fi folosit.|Fișierul capturii de ecran lipsește.|Transferul nu a putut fi pornit.|Transferul prin LocalSend a expirat.|Conectarea la Wi-Fi nu a reușit.
ru|Отправить через LocalSend|Поиск устройств LocalSend…|LocalSend недоступен. Проверьте установку плагина.|LocalSend не установлен.|LocalSend отключён в KOReader.|Не удалось использовать LocalSend.|Файл снимка экрана не найден.|Не удалось начать передачу.|Истекло время ожидания передачи через LocalSend.|Не удалось подключиться к Wi-Fi.
si|LocalSend හරහා යවන්න|LocalSend උපාංග සොයමින්…|LocalSend ලබා ගත නොහැක. ප්ලගිනය ස්ථාපනය කර ඇති ආකාරය පරීක්ෂා කරන්න.|LocalSend ස්ථාපනය කර නැත.|KOReader තුළ LocalSend අක්‍රිය කර ඇත.|LocalSend භාවිත කළ නොහැකි විය.|තිර රුවේ ගොනුව හමු නොවීය.|හුවමාරුව ආරම්භ කළ නොහැකි විය.|LocalSend හුවමාරුවට නියමිත කාලය ඉක්මවා ගියේය.|Wi-Fi වෙත සම්බන්ධ වීමට නොහැකි විය.
sk|Odoslať cez LocalSend|Vyhľadávajú sa zariadenia LocalSend…|LocalSend nie je dostupný. Skontrolujte inštaláciu doplnku.|LocalSend nie je nainštalovaný.|LocalSend je v KOReaderi vypnutý.|LocalSend sa nepodarilo použiť.|Súbor snímky obrazovky chýba.|Prenos sa nepodarilo spustiť.|Časový limit prenosu cez LocalSend vypršal.|Nepodarilo sa pripojiť k Wi-Fi.
sl|Pošlji prek LocalSend|Iskanje naprav LocalSend…|LocalSend ni na voljo. Preverite namestitev vtičnika.|LocalSend ni nameščen.|LocalSend je v KOReaderju onemogočen.|LocalSend ni bilo mogoče uporabiti.|Datoteka s posnetkom zaslona manjka.|Prenosa ni bilo mogoče začeti.|Časovna omejitev prenosa prek LocalSend je potekla.|Povezava z omrežjem Wi-Fi ni uspela.
sr|Пошаљи преко LocalSend-а|Претрага LocalSend уређаја…|LocalSend није доступан. Проверите инсталацију додатка.|LocalSend није инсталиран.|LocalSend је онемогућен у KOReader-у.|LocalSend није могао да се користи.|Недостаје датотека снимка екрана.|Пренос није могао да се покрене.|Истекло је време за пренос преко LocalSend-а.|Повезивање на Wi-Fi мрежу није успело.
sv|Skicka via LocalSend|Söker efter LocalSend-enheter…|LocalSend är inte tillgängligt. Kontrollera installationen av insticksprogrammet.|LocalSend är inte installerat.|LocalSend är inaktiverat i KOReader.|Det gick inte att använda LocalSend.|Skärmbildsfilen saknas.|Det gick inte att starta överföringen.|Tidsgränsen för LocalSend-överföringen överskreds.|Det gick inte att ansluta till Wi-Fi.
th|ส่งผ่าน LocalSend|กำลังค้นหาอุปกรณ์ LocalSend…|LocalSend ไม่พร้อมใช้งาน โปรดตรวจสอบการติดตั้งปลั๊กอิน|ยังไม่ได้ติดตั้ง LocalSend|LocalSend ถูกปิดใช้งานใน KOReader|ไม่สามารถใช้ LocalSend ได้|ไม่พบไฟล์ภาพหน้าจอ|ไม่สามารถเริ่มถ่ายโอนไฟล์ได้|หมดเวลาถ่ายโอนผ่าน LocalSend|ไม่สามารถเชื่อมต่อ Wi-Fi ได้
tr|LocalSend ile gönder|LocalSend cihazları aranıyor…|LocalSend kullanılamıyor. Eklenti kurulumunu kontrol edin.|LocalSend yüklü değil.|LocalSend, KOReader’da devre dışı.|LocalSend kullanılamadı.|Ekran görüntüsü dosyası bulunamadı.|Aktarım başlatılamadı.|LocalSend aktarımı zaman aşımına uğradı.|Wi-Fi ağına bağlanılamadı.
uk|Надіслати через LocalSend|Пошук пристроїв LocalSend…|LocalSend недоступний. Перевірте встановлення плагіна.|LocalSend не встановлено.|LocalSend вимкнено в KOReader.|Не вдалося скористатися LocalSend.|Файл знімка екрана відсутній.|Не вдалося розпочати передавання.|Вичерпано час очікування передавання через LocalSend.|Не вдалося під’єднатися до Wi-Fi.
ur|LocalSend کے ذریعے بھیجیں|LocalSend والے آلات تلاش کیے جا رہے ہیں…|‏LocalSend دستیاب نہیں ہے۔ پلگ اِن کی تنصیب چیک کریں۔|‏LocalSend انسٹال نہیں ہے۔|‏KOReader میں LocalSend غیر فعال ہے۔|‏LocalSend استعمال نہیں ہو سکا۔|اسکرین شاٹ کی فائل موجود نہیں ہے۔|منتقلی شروع نہیں ہو سکی۔|‏LocalSend کی منتقلی کی مقررہ مدت ختم ہو گئی۔|‏Wi-Fi سے کنکشن نہیں ہو سکا۔
vi|Gửi qua LocalSend|Đang tìm thiết bị LocalSend…|LocalSend không khả dụng. Hãy kiểm tra việc cài đặt tiện ích.|Chưa cài đặt LocalSend.|LocalSend đã bị tắt trong KOReader.|Không thể sử dụng LocalSend.|Không tìm thấy tệp ảnh chụp màn hình.|Không thể bắt đầu truyền tệp.|Đã hết thời gian chờ truyền tệp qua LocalSend.|Không thể kết nối Wi-Fi.
zh_CN|通过 LocalSend 发送|正在搜索 LocalSend 设备…|LocalSend 不可用。请检查插件是否正确安装。|未安装 LocalSend。|LocalSend 已在 KOReader 中停用。|无法使用 LocalSend。|找不到截图文件。|无法开始传输。|LocalSend 传输超时。|无法连接到 Wi-Fi。
zh_TW|透過 LocalSend 傳送|正在搜尋 LocalSend 裝置…|無法使用 LocalSend，請檢查外掛程式是否正確安裝。|尚未安裝 LocalSend。|LocalSend 已在 KOReader 中停用。|無法使用 LocalSend。|找不到螢幕截圖檔案。|無法開始傳輸。|LocalSend 傳輸逾時。|無法連線至 Wi-Fi。
]=]

local function activeLocale()
    local language = gettext.current_lang
    if type(language) ~= "string" or language == "" or language == "C" then
        language = G_reader_settings and G_reader_settings:readSetting("language")
        if type(language) ~= "string" or language == "" then
            language = os.getenv("LC_ALL") or os.getenv("LC_MESSAGES") or os.getenv("LANG") or "C"
        end
    end
    return (language:match("^[^%.@:]+") or "C"):gsub("-", "_"):lower()
end

local function loadCatalog(locale)
    local base = locale:match("^[a-z]+")
    if base == "zh" then
        if locale:find("_hant", 1, true) or locale:find("_tw", 1, true)
            or locale:find("_hk", 1, true) or locale:find("_mo", 1, true) then
            locale = "zh_tw"
        else
            locale = "zh_cn"
        end
    elseif base == "pt" and locale ~= "pt_br" then
        locale = "pt_pt"
    end

    local base_row, english_row
    for code, row in catalogs:gmatch("([^|\n]+)|([^\n]+)") do
        if code:lower() == locale then return row end
        if code == base then base_row = row end
        if code == "en" then english_row = row end
    end
    return base_row or english_row
end

local cached_locale, messages
local function translate(key)
    local locale = activeLocale()
    if locale ~= cached_locale then
        messages = {}
        for message in loadCatalog(locale):gmatch("[^|]+") do
            messages[#messages + 1] = message
        end
        cached_locale = locale
    end
    return messages[message_index[key]]
end

local function showMessage(message)
    UIManager:show(InfoMessage:new{ text = message, timeout = 4 })
end

local function reportError(err)
    logger.warn("Screenshot LocalSend:", err)
    showMessage(translate("error"))
end

local function safely(action, ...)
    local ok, err = pcall(action, ...)
    if not ok then reportError(err) end
end

local function screenshotExists(path)
    if lfs.attributes(path, "mode") == "file" then return true end
    showMessage(translate("missing_file"))
end

local SHARED_CONTROL_DIR = "/tmp/localsend-control"
local SHARED_CONTROL_SOCKET = SHARED_CONTROL_DIR .. "/control.sock"

local function prepareSharedControlDirectory()
    local ffi = require("ffi")
    require("ffi/posix_h")
    ffi.cdef[[
        unsigned int geteuid(void);
        int mkdir(const char *path, unsigned int mode);
        int fchmod(int fd, unsigned int mode);
    ]]
    local C = ffi.C
    local uid = tonumber(C.geteuid())
    local directory = lfs.symlinkattributes(SHARED_CONTROL_DIR)
    if not directory then
        C.mkdir(SHARED_CONTROL_DIR, C.S_IRWXU)
        directory = lfs.symlinkattributes(SHARED_CONTROL_DIR)
    end
    if not directory or directory.mode ~= "directory" or directory.uid ~= uid then return false end

    if directory.permissions ~= "rwx------" then
        local fd = C.open(SHARED_CONTROL_DIR, C.O_RDONLY + C.O_CLOEXEC + C.O_NONBLOCK)
        if fd < 0 then return false end
        -- Verify the open inode before chmod. Never apply permissions through a symlink or to another user’s directory.
        local stat_ok, opened = pcall(lfs.attributes, "/proc/self/fd/" .. tostring(fd))
        local repaired = stat_ok and opened and opened.mode == "directory" and opened.uid == uid
            and opened.dev == directory.dev and opened.ino == directory.ino and C.fchmod(fd, C.S_IRWXU) == 0
        C.close(fd)
        if not repaired then return false end
        local verified = lfs.symlinkattributes(SHARED_CONTROL_DIR)
        if not verified or verified.mode ~= "directory" or verified.uid ~= uid
            or verified.dev ~= directory.dev or verified.ino ~= directory.ino
            or verified.permissions ~= "rwx------" then return false end
    end

    local socket = lfs.symlinkattributes(SHARED_CONTROL_SOCKET)
    return not socket or (socket.mode == "socket" and socket.uid == uid)
end

local guarded_discovery
local starting_scan

local function guardScreenshotDiscovery(discovery, constants)
    if guarded_discovery == discovery then return end
    local nativeScanDevices = discovery.scanDevices
    local screenshot_callbacks = setmetatable({}, { __mode = "k" })
    discovery.scanDevices = function(callback, options)
        if starting_scan and starting_scan.discovery == discovery and callback then
            -- The native progress dialog is already on the stack when scanDevices is called.
            screenshot_callbacks[callback] = starting_scan.use_fallback
            starting_scan.close_progress()
        end
        local use_fallback = screenshot_callbacks[callback]
        if use_fallback == nil then
            return nativeScanDevices(callback, options)
        end

        local dialog = UIManager:getTopmostVisibleWidget()
        local row = dialog and dialog.buttons and dialog.buttons[1]
        local button = row and row[1]
        if button and type(button.callback) == "function" and type(dialog.setTitle) == "function"
            and userpatch.getUpValue(button.callback, "onCancel") then
            local title = translate("searching")
            if dialog.title ~= title then safely(dialog.setTitle, dialog, title) end
        end

        -- Paint the native dialog before the scanner prepares the firewall and starts its process.
        local painted, paint_err = pcall(UIManager.forceRePaint, UIManager)
        if not painted then logger.warn("Screenshot LocalSend: could not repaint discovery dialog", paint_err) end
        if not use_fallback then return nativeScanDevices(callback, options) end

        -- Rescans reuse the callback. An empty option asks LocalSend for its per-user socket.
        local socket = constants.CONTROL_SOCKET_FILE
        constants.CONTROL_SOCKET_FILE = ""
        local ok, result = pcall(nativeScanDevices, callback, options)
        constants.CONTROL_SOCKET_FILE = socket
        if not ok then error(result, 0) end
        return result
    end
    guarded_discovery = discovery
end

local SEND_TIMEOUT_SECONDS = 120
local screenshot_send = {}
local guarded_sender

local function guardScreenshotSends(sender, state)
    if guarded_sender == sender then return end
    local nativeSend = assert(sender.sendFile)
    sender.sendFile = function(device, path, pin, callback, options)
        if not options or options.screenshot_send ~= screenshot_send then
            return nativeSend(device, path, pin, callback, options)
        end

        local initiating, timeout = true, nil
        local function clearTimeout()
            if timeout then
                UIManager:unschedule(timeout)
                timeout = nil
            end
        end
        local existing_widgets = {}
        for widget in UIManager:topdown_widgets_iter() do existing_widgets[widget] = true end
        local previous_op_id = state.send_op_id
        local ok, err = pcall(nativeSend, device, path, pin, function(success, message)
            clearTimeout()
            if initiating and not success then
                -- The native sender reports preflight errors through this callback alone.
                showMessage(message or translate("start_error"))
            end
            -- The native sender shows the result. A screenshot send ends there.
        end, options)
        initiating = false

        local op_id = state.send_op_id
        local owns_send = state.send_in_progress and op_id ~= previous_op_id
        local progress
        if owns_send then
            for widget in UIManager:topdown_widgets_iter() do
                if not existing_widgets[widget] and widget.dismissable == false then
                    progress = widget
                    break
                end
            end
        end
        if not ok then
            if owns_send then safely(sender.stopActiveOperationsSync) end
            if progress then UIManager:close(progress) end
            reportError(err)
            return
        end
        if not owns_send then return end

        timeout = function()
            timeout = nil
            if not state.send_in_progress or state.send_op_id ~= op_id then return end
            safely(function()
                sender.cancelSend()
                showMessage(translate("transfer_timeout"))
            end)
        end
        if progress then
            local onCloseWidget = progress.onCloseWidget
            progress.onCloseWidget = function(self, ...)
                clearTimeout()
                if onCloseWidget then return onCloseWidget(self, ...) end
            end
        end
        UIManager:scheduleIn(SEND_TIMEOUT_SECONDS, timeout)
    end
    guarded_sender = sender
end

local function startNativeSend(instance, path, closeProgress)
    if not screenshotExists(path) then return end

    local entry = instance.showFileSendFlow
    local sender = userpatch.getUpValue(entry, "lssender")
    local flow = sender and sender.showFileSendFlow
    local nativeScan, scan_index
    if type(flow) == "function" then
        nativeScan, scan_index = userpatch.getUpValue(flow, "scanAndSelectDevice")
    end
    local state_module = type(flow) == "function" and userpatch.getUpValue(flow, "state")
    local state = state_module and state_module.ServerState
    local discovery = type(nativeScan) == "function" and userpatch.getUpValue(nativeScan, "discovery")
        or package.loaded.localsend_discovery
    local constants = discovery and type(discovery.scanDevices) == "function"
        and userpatch.getUpValue(discovery.scanDevices, "constants") or package.loaded.localsend_constants
    local use_fallback = false
    if constants and constants.CONTROL_SOCKET_FILE == SHARED_CONTROL_SOCKET then
        local ok, ready = pcall(prepareSharedControlDirectory)
        if (not ok or not ready) and discovery and type(discovery.scanDevices) == "function" then
            logger.warn("Screenshot LocalSend: control directory unavailable, using LocalSend's private default", not ok and ready or nil)
            use_fallback = true
        end
    end

    local function invokeNativeFlow()
        local previous = starting_scan
        if discovery and type(discovery.scanDevices) == "function" then
            guardScreenshotDiscovery(discovery, constants)
            starting_scan = { discovery = discovery, use_fallback = use_fallback, close_progress = closeProgress }
        end
        local ok, err = pcall(entry, instance, path)
        starting_scan = previous
        return ok, err
    end

    if type(nativeScan) ~= "function" or not state or type(sender.sendFile) ~= "function" then
        -- The plugin's public entry point also works on versions with different internals.
        local ok, err = invokeNativeFlow()
        if not ok then reportError(err) end
        return
    end

    guardScreenshotSends(sender, state)
    local previous_op_id = state.scan_op_id
    local previous_widget = UIManager:getTopmostVisibleWidget()
    -- Tag the options in the native device-selection callback, including after a rescan.
    -- Discovery, device selection and PIN handling are all still owned by LocalSend.
    userpatch.replaceUpValue(flow, scan_index, function(owner, onSelect)
        return nativeScan(owner, function(device, options, ...)
            if type(options) == "table" then options.screenshot_send = screenshot_send end
            safely(onSelect, device, options, ...)
        end)
    end)
    local ok, err = invokeNativeFlow()
    userpatch.replaceUpValue(flow, scan_index, nativeScan)

    local scan_id = state.scan_op_id
    if state.scan_in_progress and scan_id ~= previous_op_id then
        local widget = UIManager:getTopmostVisibleWidget()
        if not ok then
            if discovery and discovery.stopActiveScanSync then safely(discovery.stopActiveScanSync) end
            if widget and widget ~= previous_widget then UIManager:close(widget) end
        elseif discovery and discovery.cancelScan and widget and widget ~= previous_widget and widget.buttons then
            -- The native Cancel button already cancels scanning. Do the same on Back or an outside tap.
            local dismiss = widget.tap_close_callback
            widget.tap_close_callback = function()
                if state.scan_in_progress and state.scan_op_id == scan_id then safely(discovery.cancelScan) end
                if dismiss then safely(dismiss) end
            end
        end
    end
    if not ok then reportError(err) end
end

local function openSendFlow(dialog, path)
    local loader = require("pluginloader")
    local disabled = G_reader_settings:readSetting("plugins_disabled")
    if type(disabled) == "table" and (disabled.localsend or disabled.LocalSend) then
        showMessage(translate("disabled"))
        return
    end
    local instance = loader:getPluginInstance("LocalSend") or loader:getPluginInstance("localsend")
    if not instance then
        showMessage(translate("not_installed"))
        return
    end
    if instance.recovery_mode or instance.reinstall_required or type(instance.showFileSendFlow) ~= "function" then
        showMessage(translate("unavailable"))
        return
    end
    if not screenshotExists(path) then return end

    local NetworkMgr = require("ui/network/manager")
    local function startDiscovery()
        local progress = InfoMessage:new{
            text = translate("searching"),
            dismissable = false,
            reader_wifi_keep_on = true,
        }
        local function closeProgress()
            if UIManager:isWidgetShown(progress) then UIManager:close(progress) end
        end
        UIManager:show(progress)
        UIManager:tickAfterNext(function()
            safely(startNativeSend, instance, path, closeProgress)
            closeProgress()
        end)
    end
    dialog:onClose()
    if NetworkMgr:isConnected() then
        safely(startDiscovery)
    else
        -- This tap explicitly requests Wi-Fi. Wait for the connection before scanning.
        if NetworkMgr:turnOnWifiAndWaitForConnection(function()
            safely(startDiscovery)
        end) == false then
            showMessage(translate("wifi_error"))
        end
    end
end

-- Scope the constructor to Screenshoter. All three native gesture/key aliases
-- share this same function, and the original buttons and image capture stay in KOReader.
local capture = Screenshoter.onScreenshot
if type(capture) ~= "function" then return end
local ButtonDialog, constructor_index = userpatch.getUpValue(capture, "ButtonDialog")
if ButtonDialog ~= require("ui/widget/buttondialog") then return end

userpatch.replaceUpValue(capture, constructor_index, {
    new = function(_, spec)
        -- Read the saved path from a native callback, independent of the title's translation and bidi formatting.
        local row = type(spec) == "table" and type(spec.buttons) == "table" and spec.buttons[1]
        local delete = type(row) == "table" and row[1]
        local path = type(delete) == "table" and type(delete.callback) == "function"
            and userpatch.getUpValue(delete.callback, "screenshot_name")
        if type(path) ~= "string" or path == "" then return ButtonDialog:new(spec) end

        local dialog
        table.insert(spec.buttons, {{
            text = translate("send"),
            callback = function() safely(openSendFlow, dialog, path) end,
        }})
        dialog = ButtonDialog:new(spec)
        return dialog
    end,
})
