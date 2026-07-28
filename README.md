# Elmosis RackSense

RackSense, soğutma kabinini Raspberry Pi üzerinden izlemek ve yönetmek için geliştirilen Flutter/Linux uygulamasıdır. Uygulama; iki AC ünitesi, kabin alarm girişleri, sıcaklık izleme, yerel telemetri kaydı, kamera akışı ve gelecekteki sunucu eşitlemesini içerir.

## İçerik

- `RackSense/`: Flutter uygulaması
- `scripts/`: Derleme, dağıtım, test kamerası ve Raspberry Pi yardımcı komutları
- `docs/`: Proje ve seri haberleşme notları
- `artifacts/`: Oluşturulan Linux dağıtım paketleri

## Gereksinimler

- macOS geliştirme makinesi
- Flutter SDK, `RackSense/pubspec.yaml` içindeki Dart SDK aralığıyla uyumlu
- Derleme için ARM64 Raspberry Pi build sunucusu
- Hedef cihaz olarak Raspberry Pi OS/Linux
- Hedef Pi'de uygulama için `pi` kullanıcısı, SSH ve `sudo` erişimi

## Yerel geliştirme

```bash
cd RackSense
flutter pub get
flutter analyze
flutter run -d linux
```

Uygulama bağlantısız çalışacak şekilde tasarlanmıştır. İnternet, kamera akışı, GPIO, SPI veya seri uzatma kartı yokken arayüz açılır; cihazlar bağlantısız durumda gösterilir.

## Derleme

Kök dizinden çalıştırın:

```bash
./scripts/build.sh [branch] [build-sunucusu-ip]
```

Örnek:

```bash
./scripts/build.sh main 192.168.0.70
```

Bu komut yerel değişiklikleri stage eder, gerekiyorsa commit oluşturur, belirtilen branch'e push eder, build sunucusunda ARM64 Linux release üretir ve paketi `artifacts/` dizinine indirir.

Sürüm, `RackSense/pubspec.yaml` içindeki `version` alanından okunur. Dağıtımdan önce sürüm kodunu artırın.

## Dağıtım

Önce `artifacts/` altında oluşturulan paketi doğrulayın. Ardından kök dizinden:

```bash
./scripts/deploy.sh <sürüm|paket-yolu> <hedef-pi-ip>
```

Örnek:

```bash
./scripts/deploy.sh 0.1.0+1 192.168.0.66
```

Dağıtım komutu hedefte çalışan `rack_sense` sürecini durdurur, `/opt/rack_sense` dizinini yeniler, paketi açar ve gerekirse masaüstü kısayolunu oluşturur.

## Kamera

Kamera ekranı MJPEG akışlarını kullanır. Varsayılan akış adresi:

```text
http://localhost:8080/video_feed
```

Bu adresi uygulamadaki **Ayarlar > Kamera > Video akış adresi** alanından değiştirebilirsiniz. Akış bulunamazsa uygulama çalışmaya devam eder ve kamera panelinde hata durumu gösterilir.

### Test kamerası

`mock_cam.py`, fiziksel kamera olmadan MJPEG test akışı üretir. Hedef Pi'de gerekli paketleri bir kez yükleyin:

```bash
sudo apt update
sudo apt install -y python3-opencv python3-numpy python3-flask
```

Script'i hedef Pi'ye kopyalayın ve çalıştırın:

```bash
python3 /home/pi/mock_cam.py
```

Akış `http://<pi-ip>:8080/video_feed` adresinde kullanılabilir. Uygulama ve mock kamera aynı Pi'de çalışıyorsa varsayılan `localhost` adresi kullanılabilir.

## GPIO 4'ü 1-Wire kullanımından serbest bırakma

GPIO 4, Raspberry Pi'de 1-Wire için yapılandırılmış olabilir. RackSense bu pini çıkış olarak kullanır. Hedef Pi üzerinde önce aşağıdaki script'i çalıştırın:

```bash
sudo ./free_gpio4_before_reboot.sh
sudo reboot
```

Pi yeniden başladıktan sonra doğrulayın:

```bash
./verify_gpio4_after_reboot.sh
```

Scriptler `scripts/` dizinindedir. Doğrulama için `gpioinfo` gerekli olabilir:

```bash
sudo apt install gpiod
```

İlk script, `/boot/firmware/config.txt` veya `/boot/config.txt` içindeki `w1-gpio` overlay satırını kaldırır ve yapılandırma dosyasının yedeğini `.rack_sense_backup` uzantısıyla oluşturur.

## Senkronizasyon

Telemetri ve çalışma olayları hedef Pi'nin yerel SQLite veritabanında tutulur. Senkronizasyon ekranı; son eşitleme zamanı, gönderilmemiş kayıt sayısı, hatalı kayıt sayısı ve sonraki eşitleme için geri sayımı gösterir.

Sunucu endpoint'i henüz tanımlı değildir. Endpoint hazır olduğunda istemci isteği, kimlik doğrulama ve başarılı/başarısız kayıt durumlarının güncellenmesi eklenecektir.

## Kontroller

```bash
cd RackSense
flutter analyze
flutter test
```

## Sorun giderme

- **Uygulama açılıyor fakat cihazlar bağlı görünmüyor:** Seri kart, UART/RS-485 bağlantısı ve GPIO/SPI kablolamasını doğrulayın.
- **Kamera bağlanamıyor:** Ayarlardaki MJPEG URL'sini, mock kamera sürecini ve ağ erişimini kontrol edin.
- **GPIO 4 kullanılamıyor:** `gpioinfo` çıktısındaki consumer bilgisini kontrol edin; 1-Wire overlay'i kaldırıp yeniden başlatın.
- **Dağıtım başarısız:** Hedef Pi'ye SSH erişimini, `pi` kullanıcısının `sudo` yetkisini ve paket sürümünü kontrol edin.
