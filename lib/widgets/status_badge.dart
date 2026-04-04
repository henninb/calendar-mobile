import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'upcoming'  => (AppColors.upcomingBg,  AppColors.upcomingFg,  'UPCOMING'),
      'overdue'   => (AppColors.overdueBg,   AppColors.overdueFg,   'OVERDUE'),
      'completed' => (AppColors.completedBg, AppColors.completedFg, 'DONE'),
      'skipped'   => (AppColors.skippedBg,   AppColors.skippedFg,   'SKIPPED'),
      _           => (AppColors.skippedBg,   AppColors.skippedFg,   status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'todo'        => (AppColors.upcomingBg,  AppColors.upcomingFg,  'TODO'),
      'in_progress' => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'IN PROGRESS'),
      'done'        => (AppColors.completedBg, AppColors.completedFg, 'DONE'),
      'cancelled'   => (AppColors.skippedBg,   AppColors.skippedFg,   'CANCELLED'),
      _             => (AppColors.skippedBg,   AppColors.skippedFg,   status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge(this.priority, {super.key});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (priority) {
      'high'   => (AppColors.priorityHigh,   'HIGH'),
      'medium' => (AppColors.priorityMedium, 'MED'),
      'low'    => (AppColors.priorityLow,    'LOW'),
      _        => (AppColors.textMuted,       priority.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
