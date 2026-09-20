import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (bg, fg, label) = switch (status) {
      OccurrenceStatus.upcoming => (
        colors.upcomingBg,
        colors.upcomingFg,
        'UPCOMING',
      ),
      OccurrenceStatus.overdue => (
        colors.overdueBg,
        colors.overdueFg,
        'OVERDUE',
      ),
      OccurrenceStatus.completed => (
        colors.completedBg,
        colors.completedFg,
        'DONE',
      ),
      OccurrenceStatus.skipped => (
        colors.skippedBg,
        colors.skippedFg,
        'SKIPPED',
      ),
      _ => (colors.skippedBg, colors.skippedFg, status.toUpperCase()),
    };
    return _BadgeChip(bg: bg, fg: fg, label: label);
  }
}

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (bg, fg, label) = switch (status) {
      TaskStatus.todo => (colors.upcomingBg, colors.upcomingFg, 'TODO'),
      TaskStatus.inProgress => (
        colors.warningBg,
        colors.offlineFg,
        'IN PROGRESS',
      ),
      TaskStatus.done => (colors.completedBg, colors.completedFg, 'DONE'),
      TaskStatus.cancelled => (colors.skippedBg, colors.skippedFg, 'CANCELLED'),
      _ => (colors.skippedBg, colors.skippedFg, status.toUpperCase()),
    };
    return _BadgeChip(bg: bg, fg: fg, label: label);
  }
}

/// Covey quadrant for a task's importance × urgency.
enum Quadrant {
  doFirst('DO FIRST', AppColors.priorityHigh),
  schedule('SCHEDULE', AppColors.btnBlue),
  delegate('DELEGATE', AppColors.priorityMedium),
  eliminate('ELIMINATE', AppColors.priorityLow);

  const Quadrant(this.label, this.color);
  final String label;
  final Color color;

  static Quadrant of({required bool important, required bool urgent}) =>
      important
      ? (urgent ? Quadrant.doFirst : Quadrant.schedule)
      : (urgent ? Quadrant.delegate : Quadrant.eliminate);
}

class QuadrantBadge extends StatelessWidget {
  const QuadrantBadge({
    required this.important,
    required this.urgent,
    super.key,
  });

  final bool important;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final q = Quadrant.of(important: important, urgent: urgent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: q.color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: q.color.withAlpha(80)),
      ),
      child: Text(
        q.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: q.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Shared filled-chip renderer used by StatusBadge and TaskStatusBadge.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.bg, required this.fg, required this.label});

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
