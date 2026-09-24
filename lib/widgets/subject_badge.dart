import 'package:flutter/material.dart';
import '../models/subject.dart';

class SubjectBadge extends StatelessWidget {
  final Subject? subject;
  final bool isSmall;

  const SubjectBadge({
    super.key,
    required this.subject,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (subject == null) {
      return const SizedBox.shrink();
    }

    final color = Color(subject!.colorValue);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 6 : 8,
            height: isSmall ? 6 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            subject!.name,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
