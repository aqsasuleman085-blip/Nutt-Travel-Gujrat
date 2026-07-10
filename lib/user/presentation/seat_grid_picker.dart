import 'package:flutter/material.dart';

/// A visual grid of tappable seat chips, used instead of a plain dropdown
/// for picking extra seats. [selectedByOtherSlots] holds the seats already
/// chosen by OTHER seat slots (so a seat picked for slot 1 can't also be
/// picked for slot 2); [currentSlotValue] is this specific slot's own
/// selection, highlighted differently from other slots' picks.
class SeatGridPicker extends StatelessWidget {
  static const Color themeColor = Color(0xff10B981);

  final List<String> availableSeats;
  final Set<String> selectedByOtherSlots;
  final String? currentSlotValue;
  final ValueChanged<String> onSeatTap;

  const SeatGridPicker({
    super.key,
    required this.availableSeats,
    required this.selectedByOtherSlots,
    required this.currentSlotValue,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSeats.map((seat) {
        final isCurrent = seat == currentSlotValue;
        final isTakenByOtherSlot =
            selectedByOtherSlots.contains(seat) && !isCurrent;

        return _SeatChip(
          label: seat,
          state: isCurrent
              ? _SeatChipState.selected
              : isTakenByOtherSlot
              ? _SeatChipState.disabled
              : _SeatChipState.available,
          onTap: isTakenByOtherSlot ? null : () => onSeatTap(seat),
        );
      }).toList(),
    );
  }
}

enum _SeatChipState { available, selected, disabled }

class _SeatChip extends StatelessWidget {
  final String label;
  final _SeatChipState state;
  final VoidCallback? onTap;

  const _SeatChip({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    switch (state) {
      case _SeatChipState.selected:
        bgColor = SeatGridPicker.themeColor;
        borderColor = SeatGridPicker.themeColor;
        textColor = Colors.white;
        icon = Icons.event_seat;
        break;
      case _SeatChipState.disabled:
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade200;
        textColor = Colors.grey.shade400;
        icon = null;
        break;
      case _SeatChipState.available:
        bgColor = Colors.white;
        borderColor = SeatGridPicker.themeColor.withOpacity(0.35);
        textColor = Colors.black87;
        icon = null;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 12, color: textColor),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
