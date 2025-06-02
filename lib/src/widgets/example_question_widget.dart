import 'package:flutter/material.dart';

class ExampleQuestionsWidget extends StatelessWidget {
  /// Soruların listesi
  final List<String> questions;

  /// Şu anda seçili olan sorunun indeksi (veya null)
  final int? selectedIndex;

  /// Seçim değiştiğinde çağrılacak callback
  final ValueChanged<String?> onChanged;

  const ExampleQuestionsWidget({
    super.key,
    required this.questions,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<String> _defaultExampleQuestions = [
    "Tüm zamanların en yüksel gelir elde edilen satışı hangisi?",
    "2025 Yılına ait en yüksek gelir elde edilen satış hangisi?",
    "2025 Yılına ait en düşük gelir elde edilen satış hangisi?",
  ];

  @override
  Widget build(BuildContext context) {
    List<String> effectiveQuestionList = questions.isEmpty ? _defaultExampleQuestions : questions;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: effectiveQuestionList.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            if (selectedIndex == index) {
              onChanged(null);
            } else {
              onChanged(effectiveQuestionList[index]);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
              effectiveQuestionList[index],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
