import 'package:flutter/material.dart';

class ExampleQuestionsWidget extends StatelessWidget {
  /// Soruların listesi
  final List<String> questions;

  /// Şu anda seçili olan sorunun indeksi (veya null)
  final int? selectedIndex;

  /// Seçim değiştiğinde çağrılacak callback
  final ValueChanged<int?> onChanged;

  const ExampleQuestionsWidget({
    Key? key,
    required this.questions,
    required this.selectedIndex,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: questions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            if (selectedIndex == index) {
              onChanged(null);
            } else {
              onChanged(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
              questions[index],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
