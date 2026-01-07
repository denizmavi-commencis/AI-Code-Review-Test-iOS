# Android Module Dependency Demo

Bu proje, Android uygulamalarında modüller arası bağımlılıkları göstermek için oluşturulmuştur.

## Modül Yapısı

### 1. Login API Module (`login-api`)
- **Amaç**: Login işlemleri için interface'ler içerir
- **İçerik**: 
  - `ILoginService`: Login işlemleri için interface
  - `ILoginNavigation`: Login navigasyonu için interface
- **Bağımlılıklar**: Yok

### 2. Login Module (`login`)
- **Amaç**: Login API'nin implementasyonlarını içerir
- **İçerik**:
  - `LoginServiceImpl`: ILoginService implementasyonu
  - `LoginNavigationImpl`: ILoginNavigation implementasyonu
- **Bağımlılıklar**: `login-api`

### 3. Home Module (`home`)
- **Amaç**: Ana sayfa işlemleri, login API'ye erişir
- **İçerik**:
  - `HomeManager`: Login servislerini kullanan ana sayfa yöneticisi
- **Bağımlılıklar**: `login-api`

### 4. Passenger Module (`passenger`)
- **Amaç**: Yolcu işlemleri ve navigasyon servisleri
- **İçerik**:
  - `PassengerManager`: Yolcu yönetimi
  - `PassengerNavigationService`: Yolcu navigasyon servisleri
- **Bağımlılıklar**: Yok

### 5. FlightList Module (`flightlist`)
- **Amaç**: Uçuş listesi işlemleri, passenger module'e erişir
- **İçerik**:
  - `FlightListManager`: Passenger navigasyon servislerini kullanan uçuş listesi yöneticisi
- **Bağımlılıklar**: `passenger`

### 6. Baggage Module (`baggage`)
- **Amaç**: Bagaj işlemleri
- **İçerik**:
  - `BaggageService`: Bagaj yönetim servisleri
- **Bağımlılıklar**: Yok

### 7. Seat Module (`seat`)
- **Amaç**: Koltuk seçimi işlemleri, app module vasıtası ile baggage'a erişir
- **İçerik**:
  - `SeatManager`: Koltuk yönetimi
  - `IBaggageServiceProvider`: Baggage servisine erişim için interface
- **Bağımlılıklar**: Yok (dolaylı olarak app module üzerinden baggage'a erişir)

### 8. App Module (`app`)
- **Amaç**: Ana uygulama modülü, tüm bağımlılıkları yönetir
- **İçerik**:
  - `MainActivity`: Tüm modül bağımlılıklarını gösteren ana aktivite
  - `BaggageServiceProvider`: Seat module için baggage service provider implementasyonu
- **Bağımlılıklar**: Tüm modüller

## Bağımlılık Diyagramı

```
App Module
├── Login API Module
├── Login Module → Login API Module
├── Home Module → Login API Module
├── Passenger Module
├── FlightList Module → Passenger Module
├── Baggage Module
└── Seat Module → (App Module aracılığıyla) → Baggage Module
```

## Çalıştırma

1. Android Studio'da projeyi açın
2. Gradle sync yapın
3. Uygulamayı çalıştırın
4. Logcat'te modül bağımlılıklarının nasıl çalıştığını görebilirsiniz

## Önemli Notlar

- Tüm methodlar boş implementasyonlardır, sadece bağımlılık gösterimi amaçlıdır
- Her modül bağımsız olarak derlenebilir
- Seat module, app module vasıtası ile baggage module'e erişir (dolaylı bağımlılık)
- Home ve Login modülleri aynı Login API'yi kullanır
