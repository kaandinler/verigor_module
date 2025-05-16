# verigor_module_flutter

VeriGor Flutter Modülü, dosya seçici ve WebView tabanlı cevap gösterimi ile hızlı ve kaliteli bir soru-cevap deneyimi sunar.

---

## Kurulum

`pubspec.yaml` dosyanıza ekleyin:

```yaml
dependencies:
  verigor_module_flutter:
    git:
      url: https://github.com/kaandinler/verigor_module.git
      ref: main
```

veya kendi projenize kopyalayın.

---

## Kullanım

### 1. Token Sağlayıcı Fonksiyonunuzu Oluşturun

```dart
String _getToken() {
  return 'TOKENINIZ';
}
```

### 2. VeriGorModule Widget'ını Kullanın

```dart
import 'package:verigor_module_flutter/verigor_module.dart';

VeriGorModule(
  tokenProvider: _getToken,
  // İsteğe bağlı: örnek sorular
  exampleQuestions: [
    "Örnek soru 1",
    "Örnek soru 2",
    "Örnek soru 3",
  ],
)
```

### 3. Örnek Tam Entegrasyon

```dart
MaterialApp(
  home: Scaffold(
    appBar: AppBar(title: Text('Demo')),
    body: VeriGorModule(tokenProvider: _getToken),
  ),
);
```

---

## Özellikler

- **Dosya Seçimi:** Sunucudan dosya listesini çeker ve seçim yapılmasını sağlar.
- **Soru-Cevap:** Kullanıcıdan soru alır, API'ye gönderir ve cevabı WebView ile gösterir.
- **Örnek Sorular:** Alt sekmede örnek sorular gösterir.
- **Mesajlaşma:** Soru ve cevaplar balon şeklinde listelenir.
- **WebView ile Cevap:** Cevaplar dinamik yükseklikte WebView ile gösterilir.

---

## Bileşenler

### QAScreen

Ana widget. Parametreler:
- `tokenProvider`: Zorunlu. String döndüren bir fonksiyon.
- `exampleQuestions`: Opsiyonel. List<String>.

### ExampleQuestionsWidget

Sadece örnek soruları alt alta listeler. (Kendi başına da kullanılabilir.)

---

## Gelişmiş

### ViewModel Ayrımı

İş mantığı (API çağrıları) `VeriGorViewModel` içinde tutulur. UI katmanı sadece bu ViewModel’i kullanır.

---

## Servis Adreslerini Özelleştirme

Modülü implemente edecek kullanıcılar, kendi servis adreslerini `lib/data/service/query_service.dart` dosyasındaki `url` sabitini düzenleyerek değiştirebilirler.  
Aynı şekilde, dosya servis adresi için de ilgili servis dosyasındaki URL'yi güncelleyebilirsiniz.

---

## Servisler ve Repository'ler

### FileService

- **fetchFiles(String xToken):**
  - **Payload:**  
    - Header: `x-token` (String)
  - **Return:**  
    - `BaseResponse<List<FileData>>`  
    - Başarılıysa: `data` alanı List<FileData> içerir.

### QueryService

- **sendQuery({required String xToken, required String query, required String threadId, required String fileName}):**
  - **Payload:**  
    - Header: `x-token` (String)
    - Body (JSON):  
      - `query` (String)  
      - `thread_id` (String)  
      - `file_name` (String)
  - **Return:**  
    - `BaseResponse<QueryData>`  
    - Başarılıysa: `data` alanı QueryData içerir (`requestId`).

---

### FileRepository

- **getFiles(String xToken):**
  - **Payload:**  
    - `xToken` parametresi doğrudan FileService'e iletilir.
  - **Return:**  
    - Başarılıysa: `List<FileEntity>`  
    - Hata durumunda: Exception fırlatır.

### QueryRepository

- **createQuery({required String xToken, required String query, required String threadId, required String fileName}):**
  - **Payload:**  
    - Parametreler doğrudan QueryService'e iletilir.
  - **Return:**  
    - Başarılıysa: `QueryEntity` (`requestId` içerir)
    - Hata durumunda: Exception fırlatır.

---

## Dosya Yapısı

- `src/verigor_screen.dart`: Ana ekran.
- `src/widgets/example_question_widget.dart`: Örnek sorular listesi.
- `src/widgets/resizable_answer_widget.dart`: WebView ile cevap gösterimi.
- `src/verigor_view_model.dart`: ViewModel (iş mantığı).
- `models/`: Veri modelleri ve repository katmanı.
- `data/service/`: API servisleri.

---

## Sıkça Sorulan Sorular

**S: Kendi örnek sorularımı nasıl eklerim?**  
C: `exampleQuestions` parametresine bir liste verin. En fazla 3 örnek soru eklenebilir.

**S: Token nasıl güncellenir?**  
C: `tokenProvider` fonksiyonunuzda güncel token’ı döndürün.

**S: Token Nedir?**  
C: `tokenProvider` fonksiyonunuzda güncel token’ı döndürdüğünüz Token; VeriGor servislerini kullanabilmeniz için proje yöneticinizin sizin kullanıcı hesabınıza tanımlaması gereken bir kimlik bilgisidir. Bu Token bilgisi sayesinde VeriGor servislerini kullanabilme imkanı sağlanmaktadır.

**S: Token Bilgisi Alacağım Servisi Nasıl Değiştirebilirim?**  
C: Modülü implemente edecek kullanıcılar, kendi servis adreslerini `lib/data/service/query_service.dart` dosyasındaki `url` sabitini ve diğer alanları düzenleyerek değiştirebilirler.  
Aynı şekilde, dosya servis adresi için de ilgili servis dosyasındaki URL'yi güncelleyebilirsiniz.

---

## Lisans

GPL v3

---
