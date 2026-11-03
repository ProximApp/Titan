import 'package:flutter/material.dart';

class CheckBoxEntry extends StatelessWidget {
  final String title;
  final ValueNotifier<bool> valueNotifier;
  final VoidCallback onChanged;
  const CheckBoxEntry({
    super.key,
    required this.title,
    required this.valueNotifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        valueNotifier.value = !valueNotifier.value;
        // The row and the box are the same control to a user, so they must
        // have the same effect. Flipping alone skipped `onChanged`, and the
        // event form uses it to clear the dates a toggled mode invalidates
        // (an all-day event kept the hours it was created with).
        onChanged();
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
              // The box and the row share one contract: the widget owns the
              // value, the caller reacts to it. Callers used to flip the
              // notifier themselves, so the row (which flips) cancelled
              // their flip out while the box never switched mode at all.
              valueNotifier.value = value ?? !valueNotifier.value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
