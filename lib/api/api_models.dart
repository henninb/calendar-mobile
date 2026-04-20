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
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        color: j['color'] as String? ?? '#3b82f6',
        icon: j['icon'] as String? ?? '📅',
        description: j['description'] as String?,
      );
}

class ApiPerson {
  final int id;
  final String name;
  final String? email;

  const ApiPerson({required this.id, required this.name, this.email});

  factory ApiPerson.fromJson(Map<String, dynamic> j) => ApiPerson(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        email: j['email'] as String?,
      );
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
  final String? amount;
  final String? location;
  final int durationDays;

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
    this.amount,
    this.location,
    this.durationDays = 1,
  });

  factory ApiEvent.fromJson(Map<String, dynamic> j) => ApiEvent(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String,
        categoryId: (j['category_id'] as num).toInt(),
        rrule: j['rrule'] as String?,
        dtstart: j['dtstart'] as String,
        priority: j['priority'] as String? ?? 'medium',
        description: j['description'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        category: ApiCategory.fromJson(j['category'] as Map<String, dynamic>),
        amount: j['amount']?.toString(),
        location: j['location'] as String?,
        durationDays: (j['duration_days'] as num?)?.toInt() ?? 1,
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
        id: (j['id'] as num).toInt(),
        eventId: (j['event_id'] as num).toInt(),
        occurrenceDate: j['occurrence_date'] as String,
        status: j['status'] as String? ?? 'upcoming',
        notes: j['notes'] as String?,
        event: j['event'] != null ? ApiEvent.fromJson(j['event'] as Map<String, dynamic>) : null,
      );
}

class ApiSubtask {
  final int id;
  final int taskId;
  final String title;
  final String status;
  final String? dueDate;
  final int order;
  final String? completedAt;

  const ApiSubtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    this.dueDate,
    required this.order,
    this.completedAt,
  });

  factory ApiSubtask.fromJson(Map<String, dynamic> j) => ApiSubtask(
        id: (j['id'] as num).toInt(),
        taskId: (j['task_id'] as num).toInt(),
        title: j['title'] as String,
        status: j['status'] as String? ?? 'todo',
        dueDate: j['due_date'] as String?,
        order: (j['order'] as num?)?.toInt() ?? 0,
        completedAt: j['completed_at'] as String?,
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
  final int order;
  final ApiPerson? assignee;
  final ApiCategory? category;
  final List<ApiSubtask> subtasks;
  final String? completedAt;
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
    this.order = 0,
    this.assignee,
    this.category,
    required this.subtasks,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiTask.fromJson(Map<String, dynamic> j) => ApiTask(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String,
        description: j['description'] as String?,
        status: j['status'] as String? ?? 'todo',
        priority: j['priority'] as String? ?? 'medium',
        assigneeId: (j['assignee_id'] as num?)?.toInt(),
        categoryId: (j['category_id'] as num?)?.toInt(),
        dueDate: j['due_date'] as String?,
        estimatedMinutes: (j['estimated_minutes'] as num?)?.toInt(),
        recurrence: j['recurrence'] as String? ?? 'none',
        occurrenceId: (j['occurrence_id'] as num?)?.toInt(),
        order: (j['order'] as num?)?.toInt() ?? 0,
        assignee: j['assignee'] != null ? ApiPerson.fromJson(j['assignee'] as Map<String, dynamic>) : null,
        category: j['category'] != null ? ApiCategory.fromJson(j['category'] as Map<String, dynamic>) : null,
        subtasks: (j['subtasks'] as List? ?? [])
            .map((s) => ApiSubtask.fromJson(s as Map<String, dynamic>))
            .toList(),
        completedAt: j['completed_at'] as String?,
        createdAt: j['created_at'] as String,
        updatedAt: j['updated_at'] as String,
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
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        issuer: j['issuer'] as String?,
        lastFour: j['last_four'] as String?,
        statementCloseDay: (j['statement_close_day'] as num?)?.toInt(),
        gracePeriodDays: (j['grace_period_days'] as num?)?.toInt(),
        weekendShift: j['weekend_shift'] as String?,
        cycleDays: (j['cycle_days'] as num?)?.toInt(),
        cycleReferenceDate: j['cycle_reference_date'] as String?,
        dueDaySameMonth: (j['due_day_same_month'] as num?)?.toInt(),
        dueDayNextMonth: (j['due_day_next_month'] as num?)?.toInt(),
        annualFeeMonth: (j['annual_fee_month'] as num?)?.toInt(),
        isActive: j['is_active'] as bool? ?? true,
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
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        issuer: j['issuer'] as String?,
        lastFour: j['last_four'] as String?,
        grace: j['grace'] as String? ?? '',
        prevClose: j['prev_close'] as String? ?? '',
        prevDue: j['prev_due'] as String? ?? '',
        nextClose: j['next_close'] as String? ?? '',
        nextCloseDays: (j['next_close_days'] as num?)?.toInt() ?? 0,
        nextDue: j['next_due'] as String? ?? '',
        nextDueDays: (j['next_due_days'] as num?)?.toInt() ?? 0,
        annualFeeDate: j['annual_fee_date'] as String?,
        annualFeeDays: (j['annual_fee_days'] as num?)?.toInt(),
        prevDueOverdue: j['prev_due_overdue'] as bool? ?? false,
      );
}
