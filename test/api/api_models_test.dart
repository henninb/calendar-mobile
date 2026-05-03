import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/api/api_models.dart';

void main() {
  // ── ApiCategory ─────────────────────────────────────────────────────────────

  group('ApiCategory.fromJson', () {
    test('parses required fields', () {
      final c = ApiCategory.fromJson({
        'id': 1,
        'name': 'Work',
        'color': '#3b82f6',
        'icon': '💼',
      });
      expect(c.id, 1);
      expect(c.name, 'Work');
      expect(c.color, '#3b82f6');
      expect(c.icon, '💼');
      expect(c.description, isNull);
    });

    test('parses optional description', () {
      final c = ApiCategory.fromJson({
        'id': 2,
        'name': 'Health',
        'color': '#22c55e',
        'icon': '🏋️',
        'description': 'Gym and wellness',
      });
      expect(c.description, 'Gym and wellness');
    });

    test('applies default color when missing', () {
      final c = ApiCategory.fromJson({'id': 3, 'name': 'X'});
      expect(c.color, '#3b82f6');
    });

    test('applies default icon when missing', () {
      final c = ApiCategory.fromJson({'id': 3, 'name': 'X'});
      expect(c.icon, '📅');
    });

    test('accepts numeric id as double', () {
      final c = ApiCategory.fromJson({'id': 4.0, 'name': 'Y', 'color': '#fff', 'icon': '!'});
      expect(c.id, 4);
    });
  });

  // ── ApiPerson ───────────────────────────────────────────────────────────────

  group('ApiPerson.fromJson', () {
    test('parses id and name', () {
      final p = ApiPerson.fromJson({'id': 10, 'name': 'Alice'});
      expect(p.id, 10);
      expect(p.name, 'Alice');
      expect(p.email, isNull);
    });

    test('parses optional email', () {
      final p = ApiPerson.fromJson({'id': 11, 'name': 'Bob', 'email': 'bob@example.com'});
      expect(p.email, 'bob@example.com');
    });
  });

  // ── ApiEvent ─────────────────────────────────────────────────────────────────

  group('ApiEvent.fromJson', () {
    final categoryJson = {'id': 1, 'name': 'Work', 'color': '#3b82f6', 'icon': '💼'};

    Map<String, dynamic> baseEvent() => {
          'id': 100,
          'title': 'Team meeting',
          'category_id': 1,
          'dtstart': '2026-05-01',
          'is_active': true,
          'category': categoryJson,
        };

    test('parses required fields with defaults', () {
      final e = ApiEvent.fromJson(baseEvent());
      expect(e.id, 100);
      expect(e.title, 'Team meeting');
      expect(e.categoryId, 1);
      expect(e.dtstart, '2026-05-01');
      expect(e.priority, 'medium');
      expect(e.isActive, true);
      expect(e.durationDays, 1);
      expect(e.rrule, isNull);
      expect(e.description, isNull);
      expect(e.amount, isNull);
      expect(e.location, isNull);
    });

    test('parses optional fields when present', () {
      final json = baseEvent()
        ..addAll({
          'rrule': 'FREQ=WEEKLY',
          'priority': 'high',
          'description': 'Stand-up',
          'amount': '50.00',
          'location': 'Office',
          'duration_days': 2,
        });
      final e = ApiEvent.fromJson(json);
      expect(e.rrule, 'FREQ=WEEKLY');
      expect(e.priority, 'high');
      expect(e.description, 'Stand-up');
      expect(e.amount, '50.00');
      expect(e.location, 'Office');
      expect(e.durationDays, 2);
    });

    test('amount as num is converted to string', () {
      final json = baseEvent()..['amount'] = 99;
      final e = ApiEvent.fromJson(json);
      expect(e.amount, '99');
    });

    test('is_active defaults to true when missing', () {
      final json = baseEvent()..remove('is_active');
      final e = ApiEvent.fromJson(json);
      expect(e.isActive, true);
    });

    test('nested category is parsed', () {
      final e = ApiEvent.fromJson(baseEvent());
      expect(e.category.name, 'Work');
    });
  });

  // ── ApiOccurrence ────────────────────────────────────────────────────────────

  group('ApiOccurrence.fromJson', () {
    test('parses without event', () {
      final o = ApiOccurrence.fromJson({
        'id': 200,
        'event_id': 100,
        'occurrence_date': '2026-05-10',
        'status': 'upcoming',
      });
      expect(o.id, 200);
      expect(o.eventId, 100);
      expect(o.occurrenceDate, '2026-05-10');
      expect(o.status, 'upcoming');
      expect(o.notes, isNull);
      expect(o.event, isNull);
    });

    test('status defaults to upcoming when missing', () {
      final o = ApiOccurrence.fromJson({
        'id': 201,
        'event_id': 100,
        'occurrence_date': '2026-05-11',
      });
      expect(o.status, 'upcoming');
    });

    test('parses optional notes', () {
      final o = ApiOccurrence.fromJson({
        'id': 202,
        'event_id': 100,
        'occurrence_date': '2026-05-12',
        'notes': 'Important day',
      });
      expect(o.notes, 'Important day');
    });

    test('parses nested event when present', () {
      final o = ApiOccurrence.fromJson({
        'id': 203,
        'event_id': 100,
        'occurrence_date': '2026-05-13',
        'event': {
          'id': 100,
          'title': 'Sprint review',
          'category_id': 1,
          'dtstart': '2026-05-01',
          'is_active': true,
          'category': {'id': 1, 'name': 'Work', 'color': '#3b82f6', 'icon': '💼'},
        },
      });
      expect(o.event, isNotNull);
      expect(o.event!.title, 'Sprint review');
    });
  });

  // ── ApiSubtask ───────────────────────────────────────────────────────────────

  group('ApiSubtask.fromJson', () {
    test('parses required fields', () {
      final s = ApiSubtask.fromJson({
        'id': 1,
        'task_id': 10,
        'title': 'Write docs',
        'status': 'todo',
        'order': 0,
      });
      expect(s.id, 1);
      expect(s.taskId, 10);
      expect(s.title, 'Write docs');
      expect(s.status, 'todo');
      expect(s.order, 0);
      expect(s.dueDate, isNull);
      expect(s.completedAt, isNull);
    });

    test('status defaults to todo when missing', () {
      final s = ApiSubtask.fromJson({'id': 2, 'task_id': 10, 'title': 'X'});
      expect(s.status, 'todo');
    });

    test('order defaults to 0 when missing', () {
      final s = ApiSubtask.fromJson({'id': 3, 'task_id': 10, 'title': 'X', 'status': 'todo'});
      expect(s.order, 0);
    });

    test('parses optional completedAt', () {
      final s = ApiSubtask.fromJson({
        'id': 4,
        'task_id': 10,
        'title': 'Done task',
        'status': 'done',
        'order': 1,
        'completed_at': '2026-05-01T10:00:00Z',
      });
      expect(s.completedAt, '2026-05-01T10:00:00Z');
    });
  });

  // ── ApiTask ──────────────────────────────────────────────────────────────────

  group('ApiTask.fromJson', () {
    Map<String, dynamic> baseTask() => {
          'id': 500,
          'title': 'Implement feature',
          'status': 'todo',
          'priority': 'medium',
          'recurrence': 'none',
          'order': 0,
          'subtasks': [],
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-02T00:00:00Z',
        };

    test('parses minimal task', () {
      final t = ApiTask.fromJson(baseTask());
      expect(t.id, 500);
      expect(t.title, 'Implement feature');
      expect(t.status, 'todo');
      expect(t.priority, 'medium');
      expect(t.recurrence, 'none');
      expect(t.subtasks, isEmpty);
      expect(t.assignee, isNull);
      expect(t.category, isNull);
      expect(t.description, isNull);
    });

    test('status defaults to todo when missing', () {
      final json = baseTask()..remove('status');
      expect(ApiTask.fromJson(json).status, 'todo');
    });

    test('priority defaults to medium when missing', () {
      final json = baseTask()..remove('priority');
      expect(ApiTask.fromJson(json).priority, 'medium');
    });

    test('recurrence defaults to none when missing', () {
      final json = baseTask()..remove('recurrence');
      expect(ApiTask.fromJson(json).recurrence, 'none');
    });

    test('order defaults to 0 when missing', () {
      final json = baseTask()..remove('order');
      expect(ApiTask.fromJson(json).order, 0);
    });

    test('parses subtasks list', () {
      final json = baseTask()
        ..['subtasks'] = [
          {'id': 1, 'task_id': 500, 'title': 'Sub1', 'status': 'todo', 'order': 0},
          {'id': 2, 'task_id': 500, 'title': 'Sub2', 'status': 'done', 'order': 1},
        ];
      final t = ApiTask.fromJson(json);
      expect(t.subtasks.length, 2);
      expect(t.subtasks[0].title, 'Sub1');
    });

    test('parses nested assignee', () {
      final json = baseTask()
        ..['assignee'] = {'id': 7, 'name': 'Charlie'};
      final t = ApiTask.fromJson(json);
      expect(t.assignee!.name, 'Charlie');
    });

    test('parses optional numeric fields from doubles', () {
      final json = baseTask()
        ..['assignee_id'] = 7.0
        ..['category_id'] = 2.0
        ..['estimated_minutes'] = 45.0
        ..['occurrence_id'] = 9.0
        ..['order'] = 3.0;
      final t = ApiTask.fromJson(json);
      expect(t.assigneeId, 7);
      expect(t.categoryId, 2);
      expect(t.estimatedMinutes, 45);
      expect(t.occurrenceId, 9);
      expect(t.order, 3);
    });

    test('parses nested category', () {
      final json = baseTask()
        ..['category'] = {'id': 1, 'name': 'Work', 'color': '#3b82f6', 'icon': '💼'};
      final t = ApiTask.fromJson(json);
      expect(t.category!.name, 'Work');
    });

    test('subtasks default to empty list when missing', () {
      final json = baseTask()..remove('subtasks');
      expect(ApiTask.fromJson(json).subtasks, isEmpty);
    });
  });

  // ── ApiCreditCard ────────────────────────────────────────────────────────────

  group('ApiCreditCard.fromJson', () {
    test('parses minimal credit card', () {
      final c = ApiCreditCard.fromJson({'id': 1, 'name': 'Visa', 'is_active': true});
      expect(c.id, 1);
      expect(c.name, 'Visa');
      expect(c.isActive, true);
      expect(c.issuer, isNull);
      expect(c.lastFour, isNull);
    });

    test('is_active defaults to true when missing', () {
      final c = ApiCreditCard.fromJson({'id': 2, 'name': 'MC'});
      expect(c.isActive, true);
    });

    test('parses all optional fields', () {
      final c = ApiCreditCard.fromJson({
        'id': 3,
        'name': 'Amex',
        'is_active': true,
        'issuer': 'American Express',
        'last_four': '1234',
        'statement_close_day': 15,
        'grace_period_days': 25,
        'weekend_shift': 'before',
        'cycle_days': 30,
        'cycle_reference_date': '2026-01-01',
        'due_day_same_month': 0,
        'due_day_next_month': 20,
        'annual_fee_month': 3,
      });
      expect(c.issuer, 'American Express');
      expect(c.lastFour, '1234');
      expect(c.statementCloseDay, 15);
      expect(c.gracePeriodDays, 25);
      expect(c.weekendShift, 'before');
      expect(c.cycleDays, 30);
      expect(c.cycleReferenceDate, '2026-01-01');
      expect(c.dueDaySameMonth, 0);
      expect(c.dueDayNextMonth, 20);
      expect(c.annualFeeMonth, 3);
    });
  });

  // ── ApiStore ─────────────────────────────────────────────────────────────────

  group('ApiStore.fromJson', () {
    test('parses required fields', () {
      final s = ApiStore.fromJson({'id': 1, 'name': 'Walmart', 'is_active': true});
      expect(s.id, 1);
      expect(s.name, 'Walmart');
      expect(s.isActive, true);
      expect(s.location, isNull);
    });

    test('parses optional location', () {
      final s = ApiStore.fromJson({
        'id': 2,
        'name': 'Target',
        'is_active': true,
        'location': '123 Main St',
      });
      expect(s.location, '123 Main St');
    });

    test('is_active defaults to true when missing', () {
      final s = ApiStore.fromJson({'id': 3, 'name': 'Costco'});
      expect(s.isActive, true);
    });
  });

  // ── ApiGroceryItem ───────────────────────────────────────────────────────────

  group('ApiGroceryItem.fromJson', () {
    test('parses required fields', () {
      final item = ApiGroceryItem.fromJson({
        'id': 10,
        'name': 'Apples',
        'default_unit': 'lb',
      });
      expect(item.id, 10);
      expect(item.name, 'Apples');
      expect(item.defaultUnit, 'lb');
      expect(item.defaultStoreId, isNull);
    });

    test('default_unit defaults to each when missing', () {
      final item = ApiGroceryItem.fromJson({'id': 11, 'name': 'Eggs'});
      expect(item.defaultUnit, 'each');
    });

    test('parses optional defaultStoreId', () {
      final item = ApiGroceryItem.fromJson({
        'id': 12,
        'name': 'Milk',
        'default_unit': 'liter',
        'default_store_id': 5,
      });
      expect(item.defaultStoreId, 5);
    });
  });

  // ── ApiOnHand ────────────────────────────────────────────────────────────────

  group('ApiOnHand.fromJson', () {
    test('parses quantity as num', () {
      final o = ApiOnHand.fromJson({'id': 1, 'item_id': 10, 'quantity': 2.5, 'unit': 'lb'});
      expect(o.quantity, closeTo(2.5, 0.001));
    });

    test('parses quantity as decimal string', () {
      final o = ApiOnHand.fromJson({'id': 2, 'item_id': 10, 'quantity': '1.750', 'unit': 'each'});
      expect(o.quantity, closeTo(1.75, 0.001));
    });

    test('quantity defaults to 0.0 when missing', () {
      final o = ApiOnHand.fromJson({'id': 3, 'item_id': 10, 'unit': 'each'});
      expect(o.quantity, closeTo(0.0, 0.001));
    });

    test('invalid quantity string falls back to 0.0', () {
      final o = ApiOnHand.fromJson({
        'id': 30,
        'item_id': 10,
        'quantity': 'not-a-number',
        'unit': 'each',
      });
      expect(o.quantity, closeTo(0.0, 0.001));
    });

    test('unit defaults to each when missing', () {
      final o = ApiOnHand.fromJson({'id': 4, 'item_id': 10, 'quantity': 1});
      expect(o.unit, 'each');
    });

    test('parses nested item when present', () {
      final o = ApiOnHand.fromJson({
        'id': 5,
        'item_id': 10,
        'quantity': 3,
        'unit': 'lb',
        'item': {'id': 10, 'name': 'Apples', 'default_unit': 'lb'},
      });
      expect(o.item!.name, 'Apples');
    });

    test('item is null when absent', () {
      final o = ApiOnHand.fromJson({'id': 6, 'item_id': 10, 'quantity': 1, 'unit': 'each'});
      expect(o.item, isNull);
    });
  });

  // ── ApiGroceryListItem ───────────────────────────────────────────────────────

  group('ApiGroceryListItem.fromJson', () {
    test('parses required fields with defaults', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 1,
        'list_id': 20,
        'item_id': 10,
        'quantity': 2,
        'unit': 'each',
        'status': 'needed',
      });
      expect(i.id, 1);
      expect(i.listId, 20);
      expect(i.itemId, 10);
      expect(i.quantity, closeTo(2.0, 0.001));
      expect(i.unit, 'each');
      expect(i.status, 'needed');
      expect(i.price, isNull);
      expect(i.notes, isNull);
    });

    test('price as num', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 2, 'list_id': 20, 'item_id': 10, 'quantity': 1, 'unit': 'each',
        'status': 'needed', 'price': 3.99,
      });
      expect(i.price, closeTo(3.99, 0.001));
    });

    test('price as string', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 3, 'list_id': 20, 'item_id': 10, 'quantity': 1, 'unit': 'each',
        'status': 'needed', 'price': '4.500',
      });
      expect(i.price, closeTo(4.5, 0.001));
    });

    test('price null when absent', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 4, 'list_id': 20, 'item_id': 10, 'quantity': 1, 'unit': 'each', 'status': 'needed',
      });
      expect(i.price, isNull);
    });

    test('invalid price string parses as null', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 40,
        'list_id': 20,
        'item_id': 10,
        'quantity': 1,
        'unit': 'each',
        'status': 'needed',
        'price': 'oops',
      });
      expect(i.price, isNull);
    });

    test('quantity defaults to 1.0 when missing', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 5, 'list_id': 20, 'item_id': 10, 'unit': 'each', 'status': 'needed',
      });
      expect(i.quantity, closeTo(1.0, 0.001));
    });

    test('status defaults to needed when missing', () {
      final i = ApiGroceryListItem.fromJson({
        'id': 6, 'list_id': 20, 'item_id': 10, 'quantity': 1, 'unit': 'each',
      });
      expect(i.status, 'needed');
    });
  });

  // ── ApiGroceryList ───────────────────────────────────────────────────────────

  group('ApiGroceryList.fromJson', () {
    test('parses minimal list with no items', () {
      final list = ApiGroceryList.fromJson({
        'id': 1,
        'name': 'Weekly shop',
        'status': 'draft',
        'items': [],
      });
      expect(list.id, 1);
      expect(list.name, 'Weekly shop');
      expect(list.status, 'draft');
      expect(list.items, isEmpty);
      expect(list.store, isNull);
      expect(list.storeId, isNull);
      expect(list.shoppingDate, isNull);
    });

    test('status defaults to draft when missing', () {
      final list = ApiGroceryList.fromJson({'id': 2, 'name': 'X'});
      expect(list.status, 'draft');
    });

    test('items default to empty when missing', () {
      final list = ApiGroceryList.fromJson({'id': 3, 'name': 'X', 'status': 'draft'});
      expect(list.items, isEmpty);
    });

    test('parses nested store', () {
      final list = ApiGroceryList.fromJson({
        'id': 4,
        'name': 'Costco run',
        'status': 'active',
        'items': [],
        'store': {'id': 5, 'name': 'Costco', 'is_active': true},
      });
      expect(list.store!.name, 'Costco');
    });

    test('parses items list', () {
      final list = ApiGroceryList.fromJson({
        'id': 5,
        'name': 'Snacks',
        'status': 'active',
        'items': [
          {'id': 1, 'list_id': 5, 'item_id': 10, 'quantity': 2, 'unit': 'each', 'status': 'needed'},
        ],
      });
      expect(list.items.length, 1);
      expect(list.items.first.quantity, closeTo(2.0, 0.001));
    });
  });

  // ── ApiTrackerRow ────────────────────────────────────────────────────────────

  group('ApiTrackerRow.fromJson', () {
    test('parses required fields', () {
      final r = ApiTrackerRow.fromJson({
        'id': 1,
        'name': 'Chase Freedom',
        'grace': '25d',
        'prev_close': '2026-04-15',
        'prev_due': '2026-05-10',
        'next_close': '2026-05-15',
        'next_close_days': 12,
        'next_due': '2026-06-10',
        'next_due_days': 38,
        'prev_due_overdue': false,
      });
      expect(r.id, 1);
      expect(r.name, 'Chase Freedom');
      expect(r.grace, '25d');
      expect(r.nextCloseDays, 12);
      expect(r.nextDueDays, 38);
      expect(r.prevDueOverdue, false);
      expect(r.issuer, isNull);
      expect(r.lastFour, isNull);
      expect(r.annualFeeDate, isNull);
      expect(r.annualFeeDays, isNull);
    });

    test('string fields default to empty string when missing', () {
      final r = ApiTrackerRow.fromJson({
        'id': 2,
        'name': 'X',
        'prev_due_overdue': false,
      });
      expect(r.grace, '');
      expect(r.prevClose, '');
      expect(r.prevDue, '');
      expect(r.nextClose, '');
      expect(r.nextDue, '');
    });

    test('day counts default to 0 when missing', () {
      final r = ApiTrackerRow.fromJson({'id': 3, 'name': 'Y', 'prev_due_overdue': false});
      expect(r.nextCloseDays, 0);
      expect(r.nextDueDays, 0);
    });

    test('prevDueOverdue defaults to false when missing', () {
      final r = ApiTrackerRow.fromJson({'id': 4, 'name': 'Z'});
      expect(r.prevDueOverdue, false);
    });

    test('parses optional issuer, lastFour, annualFeeDate, annualFeeDays', () {
      final r = ApiTrackerRow.fromJson({
        'id': 5,
        'name': 'Sapphire',
        'prev_due_overdue': true,
        'issuer': 'Chase',
        'last_four': '4321',
        'annual_fee_date': '2026-03-01',
        'annual_fee_days': 300,
        'grace': '21d',
        'prev_close': '2026-04-01',
        'prev_due': '2026-04-25',
        'next_close': '2026-05-01',
        'next_close_days': 28,
        'next_due': '2026-05-25',
        'next_due_days': 52,
      });
      expect(r.issuer, 'Chase');
      expect(r.lastFour, '4321');
      expect(r.annualFeeDate, '2026-03-01');
      expect(r.annualFeeDays, 300);
      expect(r.prevDueOverdue, true);
    });
  });
}
