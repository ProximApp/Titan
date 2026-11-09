import 'package:flutter/material.dart';

class CheckBoxEntry extends StatelessWidget {
  final String title;
  final ValueNotifier<bool> valueNotifier;
  final VoidCallback? onChanged;
  const CheckBoxEntry({
    super.key,
    required this.title,
    required this.valueNotifier,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        valueNotifier.value = !valueNotifier.value;
        // The row and the box are one control to a user, so they run the same
        // callback. The row used to flip only, which meant the booking form's
        // date-clearing callback (start/end/recurrence end) never ran when the
        // mode was toggled by its label.
        onChanged?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
          Checkbox(
            checkColor: Colors.white,
            activeColor: Colors.black,
            value: valueNotifier.value,
            onChanged: (value) {
              valueNotifier.value = value!;
              onChanged?.call();
            },
          ),
        ],
      ),
    );
  }
}
