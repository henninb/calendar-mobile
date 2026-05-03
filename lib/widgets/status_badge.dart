import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      OccurrenceStatus.upcoming  => (AppColors.upcomingBg,  AppColors.upcomingFg,  'UPCOMING'),
      OccurrenceStatus.overdue   => (AppColors.overdueBg,   AppColors.overdueFg,   'OVERDUE'),
      OccurrenceStatus.completed => (AppColors.completedBg, AppColors.completedFg, 'DONE'),
      OccurrenceStatus.skipped   => (AppColors.skippedBg,   AppColors.skippedFg,   'SKIPPED'),
      _                          => (AppColors.skippedBg,   AppColors.skippedFg,   status.toUpperCase()),
    };
    return _BadgeChip(bg: bg, fg: fg, label: label);
  }
}

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      TaskStatus.todo       => (AppColors.upcomingBg,          AppColors.upcomingFg,          'TODO'),
      TaskStatus.inProgress => (const Color(0xFFFEF3C7),       const Color(0xFF92400E),        'IN PROGRESS'),
      TaskStatus.done       => (AppColors.completedBg,         AppColors.completedFg,          'DONE'),
      TaskStatus.cancelled  => (AppColors.skippedBg,           AppColors.skippedFg,            'CANCELLED'),
      _                     => (AppColors.skippedBg,           AppColors.skippedFg,            status.toUpperCase()),
    };
    return _BadgeChip(bg: bg, fg: fg, label: label);
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

// Shared filled-chip renderer used by StatusBadge and TaskStatusBadge.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.bg,
    required this.fg,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final String label;

  @override
  Widget build(BuildContext context) {
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
