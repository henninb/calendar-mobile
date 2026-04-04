// API response models (mirrors backend Pydantic schemas)

class ApiCategory {
  final int id;
  final String name;
  final String color;
  final String icon;
  final String? description;

  const ApiCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.description,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> j) => ApiCategory(
        id: j['id'],
        name: j['name'],
        color: j['color'] ?? '#3b82f6',
        icon: j['icon'] ?? '📅',
        description: j['description'],
      );
}

class ApiPerson {
  final int id;
  final String name;
  final String? email;

  const ApiPerson({required this.id, required this.name, this.email});

  factory ApiPerson.fromJson(Map<String, dynamic> j) =>
      ApiPerson(id: j['id'], name: j['name'], email: j['email']);
}

class ApiEvent {
  final int id;
  final String title;
  final int categoryId;
  final String? rrule;
  final String dtstart;
  final String priority;
  final String? description;
  final bool isActive;
  final ApiCategory category;

  const ApiEvent({
    required this.id,
    required this.title,
    required this.categoryId,
    this.rrule,
    required this.dtstart,
    required this.priority,
    this.description,
    required this.isActive,
    required this.category,
  });

  factory ApiEvent.fromJson(Map<String, dynamic> j) => ApiEvent(
        id: j['id'],
        title: j['title'],
        categoryId: j['category_id'],
        rrule: j['rrule'],
        dtstart: j['dtstart'],
        priority: j['priority'] ?? 'medium',
        description: j['description'],
        isActive: j['is_active'] ?? true,
        category: ApiCategory.fromJson(j['category']),
      );
}

class ApiOccurrence {
  final int id;
  final int eventId;
  final String occurrenceDate;
  final String status;
  final String? notes;
  final ApiEvent? event;

  const ApiOccurrence({
    required this.id,
    required this.eventId,
    required this.occurrenceDate,
    required this.status,
    this.notes,
    this.event,
  });

  factory ApiOccurrence.fromJson(Map<String, dynamic> j) => ApiOccurrence(
        id: j['id'],
        eventId: j['event_id'],
        occurrenceDate: j['occurrence_date'],
        status: j['status'] ?? 'upcoming',
        notes: j['notes'],
        event: j['event'] != null ? ApiEvent.fromJson(j['event']) : null,
      );
}

class ApiSubtask {
  final int id;
  final int taskId;
  final String title;
  final String status;
  final String? dueDate;
  final int order;

  const ApiSubtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    this.dueDate,
    required this.order,
  });

  factory ApiSubtask.fromJson(Map<String, dynamic> j) => ApiSubtask(
        id: j['id'],
        taskId: j['task_id'],
        title: j['title'],
        status: j['status'] ?? 'todo',
        dueDate: j['due_date'],
        order: j['order'] ?? 0,
      );
}

class ApiTask {
  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final int? assigneeId;
  final int? categoryId;
  final String? dueDate;
  final int? estimatedMinutes;
  final String recurrence;
  final int? occurrenceId;
  final ApiPerson? assignee;
  final ApiCategory? category;
  final List<ApiSubtask> subtasks;
  final String createdAt;
  final String updatedAt;

  const ApiTask({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.categoryId,
    this.dueDate,
    this.estimatedMinutes,
    required this.recurrence,
    this.occurrenceId,
    this.assignee,
    this.category,
    required this.subtasks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiTask.fromJson(Map<String, dynamic> j) => ApiTask(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        status: j['status'] ?? 'todo',
        priority: j['priority'] ?? 'medium',
        assigneeId: j['assignee_id'],
        categoryId: j['category_id'],
        dueDate: j['due_date'],
        estimatedMinutes: j['estimated_minutes'],
        recurrence: j['recurrence'] ?? 'none',
        occurrenceId: j['occurrence_id'],
        assignee: j['assignee'] != null ? ApiPerson.fromJson(j['assignee']) : null,
        category: j['category'] != null ? ApiCategory.fromJson(j['category']) : null,
        subtasks: (j['subtasks'] as List? ?? [])
            .map((s) => ApiSubtask.fromJson(s))
            .toList(),
        createdAt: j['created_at'] ?? DateTime.now().toIso8601String(),
        updatedAt: j['updated_at'] ?? DateTime.now().toIso8601String(),
      );
}

class ApiCreditCard {
  final int id;
  final String name;
  final String? issuer;
  final String? lastFour;
  final int? statementCloseDay;
  final int? gracePeriodDays;
  final String? weekendShift;
  final int? cycleDays;
  final String? cycleReferenceDate;
  final int? dueDaySameMonth;
  final int? dueDayNextMonth;
  final int? annualFeeMonth;
  final bool isActive;

  const ApiCreditCard({
    required this.id,
    required this.name,
    this.issuer,
    this.lastFour,
    this.statementCloseDay,
    this.gracePeriodDays,
    this.weekendShift,
    this.cycleDays,
    this.cycleReferenceDate,
    this.dueDaySameMonth,
    this.dueDayNextMonth,
    this.annualFeeMonth,
    required this.isActive,
  });

  factory ApiCreditCard.fromJson(Map<String, dynamic> j) => ApiCreditCard(
        id: j['id'],
        name: j['name'],
        issuer: j['issuer'],
        lastFour: j['last_four'],
        statementCloseDay: j['statement_close_day'],
        gracePeriodDays: j['grace_period_days'],
        weekendShift: j['weekend_shift'],
        cycleDays: j['cycle_days'],
        cycleReferenceDate: j['cycle_reference_date'],
        dueDaySameMonth: j['due_day_same_month'],
        dueDayNextMonth: j['due_day_next_month'],
        annualFeeMonth: j['annual_fee_month'],
        isActive: j['is_active'] ?? true,
      );
}

class ApiTrackerRow {
  final int id;
  final String name;
  final String? issuer;
  final String? lastFour;
  final String grace;
  final String prevClose;
  final String prevDue;
  final String nextClose;
  final int nextCloseDays;
  final String nextDue;
  final int nextDueDays;
  final String? annualFeeDate;
  final int? annualFeeDays;
  final bool prevDueOverdue;

  const ApiTrackerRow({
    required this.id,
    required this.name,
    this.issuer,
    this.lastFour,
    required this.grace,
    required this.prevClose,
    required this.prevDue,
    required this.nextClose,
    required this.nextCloseDays,
    required this.nextDue,
    required this.nextDueDays,
    this.annualFeeDate,
    this.annualFeeDays,
    required this.prevDueOverdue,
  });

  factory ApiTrackerRow.fromJson(Map<String, dynamic> j) => ApiTrackerRow(
        id: j['id'],
        name: j['name'],
        issuer: j['issuer'],
        lastFour: j['last_four'],
        grace: j['grace'] ?? '',
        prevClose: j['prev_close'] ?? '',
        prevDue: j['prev_due'] ?? '',
        nextClose: j['next_close'] ?? '',
        nextCloseDays: j['next_close_days'] ?? 0,
        nextDue: j['next_due'] ?? '',
        nextDueDays: j['next_due_days'] ?? 0,
        annualFeeDate: j['annual_fee_date'],
        annualFeeDays: j['annual_fee_days'],
        prevDueOverdue: j['prev_due_overdue'] ?? false,
      );
}
