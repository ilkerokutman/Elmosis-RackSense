# RackSense SNMPv3 Entegrasyonu — Müşteri Bilgi Talebi

RackSense uygulamasına SNMPv3 desteği eklenmesi planlanmaktadır.
Bu doküman, entegrasyonu tamamlayabilmemiz için müşteriden beklenen
teknik bilgileri özetler.

## Genel Mimari

- RackSense uygulaması Raspberry Pi üzerinde çalışır.
- Pi üzerinde Linux `net-snmp` (`snmpd`) servisi çalıştırılacaktır.
- SNMPv3 kimlik doğrulama/şifreleme `snmpd` tarafından halledilir;
  RackSense doğrudan SNMP paketi işlemez.
- `snmpd`, istenen OID'lere yapılan GET/SET isteklerini yerel bir
  Python köprü script'i üzerinden RackSense uygulamasına yönlendirir.
- RackSense uygulaması içinde küçük bir HTTP sunucu çalışır;
  bu sunucu mevcut AC ünitesi verilerini sunar ve yazılabilir OID'lere
  gelen SET değerlerini seri haberleşme üzerinden ilgili AC ünitesine
  gönderir.

## Müşteriden İstenen Bilgiler

### 1. Özel Kurumsal OID (Private Enterprise Number)

SNMP OID ağacımız şu şekilde planlanmıştır:

```text
1.3.6.1.4.1.<KURUMSAL_NUMARA>.1.<unit_id>.<field_id>
```

- `<KURUMSAL_NUMARA>`: IANA'dan tahsis edilmiş özel kurumsal numara.
- `<unit_id>`: `1` = AC Ünitesi 1, `2` = AC Ünitesi 2.
- `<field_id>`: Aşağıdaki tabloda listelenen veri alanları.

**Örnek**: Kurumsal numaranız `54321` ise, AC Ünitesi 1'in NTC 1 değeri
`1.3.6.1.4.1.54321.1.1.2` OID'siyle okunur.

> Geliştirme aşamasında geçici olarak `99999` kullanılabilir; üretim
> ortamına geçmeden önce gerçek kurumsal numara ile değiştirilmelidir.

**Müşteri tarafından sağlanmalı:**

- Özel kurumsal OID numarası (e.g. `1.3.6.1.4.1.54321`).

### 2. Sunulması İstenen OID'ler ve Erişim Türleri

Aşağıdaki tablo önerilen OID haritasıdır. Müşteri bu yapıyı
onaylamalı veya istediği değişiklikleri belirtmelidir.

| OID Uç Noktası | Açıklama | Tip | Erişim |
|---|---|---|---|
| `...1.1.1` | AC Ünitesi 1 — NTC 0 | Integer | read-only |
| `...1.1.2` | AC Ünitesi 1 — NTC 1 | Integer | read-only |
| `...1.1.3` | AC Ünitesi 1 — NTC 2 | Integer | read-only |
| `...1.1.4` | AC Ünitesi 1 — NTC 3 | Integer | read-only |
| `...1.1.5` | AC Ünitesi 1 — Fan Seviyesi | Integer | read-only |
| `...1.1.6` | AC Ünitesi 1 — Aç/Kapa Durumu (`0` = kapalı, `1` = açık) | Integer | read-only |
| `...1.1.7` | AC Ünitesi 1 — Hata Kodu (`0` = hata yok) | Integer | read-only |
| `...1.1.8` | AC Ünitesi 1 — Set Değeri (hedef sıcaklık, °C) | Integer | read-write |
| `...1.2.1` | AC Ünitesi 2 — NTC 0 | Integer | read-only |
| `...1.2.2` | AC Ünitesi 2 — NTC 1 | Integer | read-only |
| `...1.2.3` | AC Ünitesi 2 — NTC 2 | Integer | read-only |
| `...1.2.4` | AC Ünitesi 2 — NTC 3 | Integer | read-only |
| `...1.2.5` | AC Ünitesi 2 — Fan Seviyesi | Integer | read-only |
| `...1.2.6` | AC Ünitesi 2 — Aç/Kapa Durumu | Integer | read-only |
| `...1.2.7` | AC Ünitesi 2 — Hata Kodu | Integer | read-only |
| `...1.2.8` | AC Ünitesi 2 — Set Değeri | Integer | read-write |

**Notlar:**

- NTC değerleri tam sayı (°C) olarak iletilir.
- Hata kodu `0` dışında bir değer aldığında ilgili AC ünitesinde iletişim
  veya donanım hatası olduğunu gösterir.
- Set değeri SNMP üzerinden yazılabilirdir. Yazılan değer ilgili AC
  ünitesine hedef sıcaklık olarak gönderilir.

**Müşteri tarafından sağlanmalı:**

- Tablodaki OID yapısı onaylanmalı veya istenen değişiklikler
  belirtilmeli.
- İlave veri alanları isteniyorsa (örneğin otomatik/mod durumu,
  dolap sıcaklığı, alarm girişleri, cihaz bağlantı durumu) liste
  halinde verilmeli.

### 3. SNMPv3 Güvenlik Ayarları

SNMPv3 kullanıcı kimlik doğrulaması `snmpd` üzerinde yapılandırılacaktır.
Aşağıdaki bilgiler gereklidir:

| Parametre | Açıklama | Müşteri Girdisi |
|---|---|---|
| Kullanıcı adı | SNMPv3 kullanıcı adı | |
| Güvenlik seviyesi | `noAuthNoPriv` / `authNoPriv` / `authPriv` | |
| Kimlik doğrulama protokolü | `MD5` veya `SHA` (gerekirse) | |
| Kimlik doğrulama parolası | Auth password (gerekirse) | |
| Gizlilik protokolü | `DES` veya `AES` (gerekirse) | |
| Gizlilik parolası | Priv password (gerekirse) | |
| İzinler | Sadece GET mi, SET de yapılabilir mi? | |

**Müşteri tarafından sağlanmalı:**

- SNMPv3 kullanıcı adı, güvenlik seviyesi ve protokol/parola bilgileri.
- SET işlemine izin verilip verilmeyeceği (Set Değeri OID'si için
  gerekli).

### 4. Ağ ve Erişim Bilgileri

| Parametre | Açıklama | Müşteri Girdisi |
|---|---|---|
| SNMP portu | Standart `161` mi, farklı bir port mu? | |
| Erişim kaynağı | SNMP yöneticisi hangi IP/IP aralığından ulaşacak? | |
| Güvenlik duvarı | Pi üzerinde `ufw`/`iptables` var mı? Port açılması gerekir mi? | |

**Müşteri tarafından sağlanmalı:**

- Kullanılacak port ve erişime izin verilecek kaynak IP adres(ler)i.

### 5. Polling ve Beklentiler

| Parametre | Açıklama | Müşteri Girdisi |
|---|---|---|
| Get sıklığı | SNMP yöneticisi ne sıklıkla GET çekecek? | |
| Maksimum gecikme | Bir SET komutunun AC ünitesine ulaşması için kabul edilebilir üst süre | |
| Trap/Notify | Cihaz durumu değişikliklerinde SNMP TRAP/INFORM gönderilmeli mi? | |

**Müşteri tarafından sağlanmalı:**

- Beklenen polling sıklığı ve gecikme beklentisi.
- Trap/Notify gereksinimi varsa, trap hedef IP'si ve portu.

## Sonraki Adımlar

Müşteri yukarıdaki bilgileri sağladıktan sonra:

1. OID tablosu ve kurumsal numara kesinleştirilecek.
2. `feature/snmp` dalında HTTP SNMP köprüsü, `SnmpDataProvider`,
   Python `pass-persist` scripti ve `snmpd` yapılandırması
   geliştirilecek.
3. Geliştirme tamamlandıktan sonra test Pi (müsait olduğunda) veya
   müşteri ortamında doğrulanacak.

## Ek Not

- Bu entegrasyon, mevcut RackSense ekranlarına ve donanım düğmelerine
  dokunmadan, paralel bir servis olarak çalışacaktır.
- SNMPv3 paket işleme `net-snmp` tarafından yapılacağı için, saf Dart
  SNMP kütüphanesi kullanılmasına gerek kalmayacaktır.
