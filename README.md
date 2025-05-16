# verigor_module_flutter

VeriGor Q&A Flutter Modülü, dosya seçici ve WebView tabanlı cevap gösterimi ile hızlı ve kaliteli bir soru-cevap deneyimi sunar.

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

### 2. QAScreen Widget'ını Kullanın

```dart
import 'package:verigor_module_flutter/verigor_module.dart';

QAScreen(
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
    body: QAScreen(tokenProvider: _getToken),
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

İş mantığı (API çağrıları) `QAViewModel` içinde tutulur. UI katmanı sadece bu ViewModel’i kullanır.

---

## Dosya Yapısı

- `src/qa_screen.dart`: Ana ekran.
- `src/widgets/example_question_widget.dart`: Örnek sorular listesi.
- `src/widgets/resizable_answer_widget.dart`: WebView ile cevap gösterimi.
- `src/qu_view_model.dart`: ViewModel (iş mantığı).
- `models/`: Veri modelleri ve repository katmanı.
- `data/service/`: API servisleri.

---

## Sıkça Sorulan Sorular

**S: Kendi örnek sorularımı nasıl eklerim?**  
C: `exampleQuestions` parametresine bir liste verin.

**S: Token nasıl güncellenir?**  
C: `tokenProvider` fonksiyonunuzda güncel token’ı döndürün.

---

## Lisans

GPL v3

---