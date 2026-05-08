import 'package:calendar_mobile/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

// Exercises the generated data-class and companion methods (copyWith,
// copyWithCompanion, toCompanion, toJson, fromJson, toString, ==, hashCode)
// that live in app_database.g.dart.  No actual DB connection is needed for
// most of these because the generated types are plain Dart classes.

void main() {
  // ── Category ─────────────────────────────────────────────────────────────

  group('Category data class', () {
    const cat = Category(
      id: 1,
      serverId: 10,
      name: 'Work',
      color: '#ff0000',
      icon: '💼',
      description: 'Work stuff',
    );

    test('copyWith replaces specified fields', () {
      final copy = cat.copyWith(name: 'Personal', color: '#00ff00');
      expect(copy.name, 'Personal');
      expect(copy.color, '#00ff00');
      expect(copy.id, cat.id);
      expect(copy.serverId, cat.serverId);
    });

    test('copyWith with nullable Value.absent preserves original nullable', () {
      final copy = cat.copyWith();
      expect(copy.description, cat.description);
    });

    test('copyWith clears nullable field when Value(null) is passed', () {
      final copy = cat.copyWith(description: const Value(null));
      expect(copy.description, isNull);
    });

    test('copyWithCompanion applies companion changes', () {
      final companion = const CategoriesCompanion(name: Value('Updated'));
      final copy = cat.copyWithCompanion(companion);
      expect(copy.name, 'Updated');
      expect(copy.id, cat.id);
    });

    test('toCompanion preserves all fields', () {
      final companion = cat.toCompanion(false);
      expect(companion.id.value, cat.id);
      expect(companion.name.value, cat.name);
      expect(companion.color.value, cat.color);
    });

    test('toJson / fromJson round-trips', () {
      final json = cat.toJson();
      final restored = Category.fromJson(json);
      expect(restored, cat);
    });

    test('toString contains field values', () {
      final s = cat.toString();
      expect(s, contains('Work'));
      expect(s, contains('#ff0000'));
    });

    test('hashCode is stable', () {
      expect(cat.hashCode, cat.hashCode);
    });

    test('== returns true for identical field values', () {
      const other = Category(
        id: 1,
        serverId: 10,
        name: 'Work',
        color: '#ff0000',
        icon: '💼',
        description: 'Work stuff',
      );
      expect(cat, equals(other));
    });

    test('== returns false when a field differs', () {
      final other = cat.copyWith(name: 'Different');
      expect(cat, isNot(equals(other)));
    });
  });

  group('CategoriesCompanion', () {
    test('copyWith replaces specified fields', () {
      const c = CategoriesCompanion(
        serverId: Value(1),
        name: Value('Old'),
      );
      final copy = c.copyWith(name: const Value('New'));
      expect(copy.name.value, 'New');
      expect(copy.serverId, c.serverId);
    });

    test('insert constructor wraps required field', () {
      final c = CategoriesCompanion.insert(name: 'Test');
      expect(c.name.value, 'Test');
      expect(c.id.present, isFalse);
    });

    test('toString contains field info', () {
      const c = CategoriesCompanion(name: Value('Test'));
      expect(c.toString(), contains('Test'));
    });
  });

  // ── Person ───────────────────────────────────────────────────────────────

  group('Person data class', () {
    const person = Person(
      id: 2,
      serverId: 20,
      name: 'Alice',
      email: 'alice@example.com',
    );

    test('copyWith', () {
      final copy = person.copyWith(name: 'Bob');
      expect(copy.name, 'Bob');
      expect(copy.id, person.id);
    });

    test('toJson / fromJson round-trips', () {
      final json = person.toJson();
      expect(Person.fromJson(json), person);
    });

    test('toString and hashCode', () {
      expect(person.toString(), contains('Alice'));
      expect(person.hashCode, person.hashCode);
    });

    test('==', () {
      const other = Person(id: 2, serverId: 20, name: 'Alice', email: 'alice@example.com');
      expect(person, equals(other));
    });

    test('copyWithCompanion', () {
      final c = PersonsCompanion(name: const Value('Carol'));
      expect(person.copyWithCompanion(c).name, 'Carol');
    });

    test('toCompanion', () {
      final c = person.toCompanion(true);
      expect(c.name.value, 'Alice');
    });
  });

  group('PersonsCompanion', () {
    test('copyWith', () {
      final c = const PersonsCompanion(name: Value('Old'))
          .copyWith(name: const Value('New'));
      expect(c.name.value, 'New');
    });

    test('insert constructor', () {
      final c = PersonsCompanion.insert(name: 'Dave');
      expect(c.name.value, 'Dave');
    });
  });

  // ── Event ────────────────────────────────────────────────────────────────

  group('Event data class', () {
    const event = Event(
      id: 3,
      serverId: 30,
      title: 'Meeting',
      categoryServerId: 5,
      rrule: 'FREQ=WEEKLY',
      dtstart: '2026-05-01',
      priority: 'high',
      description: 'Weekly sync',
      isActive: true,
      amount: '50.00',
      location: 'Office',
      durationDays: 1,
    );

    test('copyWith', () {
      final copy = event.copyWith(title: 'Standup', priority: 'medium');
      expect(copy.title, 'Standup');
      expect(copy.priority, 'medium');
      expect(copy.id, event.id);
    });

    test('toJson / fromJson round-trips', () {
      final json = event.toJson();
      expect(Event.fromJson(json), event);
    });

    test('toString', () {
      expect(event.toString(), contains('Meeting'));
    });

    test('hashCode and ==', () {
      expect(event.hashCode, event.hashCode);
      const other = Event(
        id: 3,
        serverId: 30,
        title: 'Meeting',
        categoryServerId: 5,
        rrule: 'FREQ=WEEKLY',
        dtstart: '2026-05-01',
        priority: 'high',
        description: 'Weekly sync',
        isActive: true,
        amount: '50.00',
        location: 'Office',
        durationDays: 1,
      );
      expect(event, equals(other));
    });

    test('copyWithCompanion and toCompanion', () {
      final companion = const EventsCompanion(title: Value('New Title'));
      expect(event.copyWithCompanion(companion).title, 'New Title');
      expect(event.toCompanion(true).title.value, 'Meeting');
    });
  });

  group('EventsCompanion', () {
    test('copyWith', () {
      final c = const EventsCompanion(title: Value('Old'))
          .copyWith(title: const Value('New'));
      expect(c.title.value, 'New');
    });

    test('insert constructor', () {
      final c = EventsCompanion.insert(
        title: 'Event',
        categoryServerId: 5,
        dtstart: '2026-05-01',
      );
      expect(c.title.value, 'Event');
    });
  });

  // ── Occurrence ───────────────────────────────────────────────────────────

  group('Occurrence data class', () {
    const occ = Occurrence(
      id: 4,
      serverId: 40,
      eventServerId: 100,
      occurrenceDate: '2026-05-10',
      status: 'upcoming',
      notes: 'Bring laptop',
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = occ.copyWith(status: 'completed');
      expect(copy.status, 'completed');
      expect(copy.id, occ.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(Occurrence.fromJson(occ.toJson()), occ);
    });

    test('toString', () {
      expect(occ.toString(), contains('upcoming'));
    });

    test('hashCode and ==', () {
      expect(occ.hashCode, occ.hashCode);
      expect(occ, equals(occ.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const OccurrencesCompanion(status: Value('skipped'));
      expect(occ.copyWithCompanion(c).status, 'skipped');
      expect(occ.toCompanion(true).status.value, 'upcoming');
    });
  });

  group('OccurrencesCompanion', () {
    test('copyWith', () {
      final c = const OccurrencesCompanion(status: Value('upcoming'))
          .copyWith(status: const Value('skipped'));
      expect(c.status.value, 'skipped');
    });

    test('insert constructor', () {
      final c = OccurrencesCompanion.insert(
        eventServerId: 10,
        occurrenceDate: '2026-05-01',
      );
      expect(c.occurrenceDate.value, '2026-05-01');
    });
  });

  // ── Task ─────────────────────────────────────────────────────────────────

  group('Task data class', () {
    const task = Task(
      id: 5,
      serverId: 50,
      title: 'Fix bug',
      description: 'Critical',
      status: 'todo',
      priority: 'high',
      assigneeServerId: 2,
      categoryServerId: 3,
      dueDate: '2026-05-20',
      estimatedMinutes: 60,
      recurrence: 'none',
      occurrenceServerId: null,
      order: 1,
      syncStatus: 0,
      completedAt: null,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-02',
    );

    test('copyWith', () {
      final copy = task.copyWith(status: 'done', priority: 'low');
      expect(copy.status, 'done');
      expect(copy.priority, 'low');
      expect(copy.id, task.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(Task.fromJson(task.toJson()), task);
    });

    test('toString', () {
      expect(task.toString(), contains('Fix bug'));
    });

    test('hashCode and ==', () {
      expect(task.hashCode, task.hashCode);
      expect(task, equals(task.copyWith()));
    });

    test('copyWithCompanion', () {
      final c = const TasksCompanion(status: Value('in_progress'));
      expect(task.copyWithCompanion(c).status, 'in_progress');
    });

    test('toCompanion', () {
      expect(task.toCompanion(true).title.value, 'Fix bug');
    });
  });

  group('TasksCompanion', () {
    test('copyWith', () {
      final c = const TasksCompanion(title: Value('Old'))
          .copyWith(title: const Value('New'));
      expect(c.title.value, 'New');
    });

    test('insert constructor', () {
      final c = TasksCompanion.insert(
        title: 'Task',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      );
      expect(c.title.value, 'Task');
    });
  });

  // ── Subtask ──────────────────────────────────────────────────────────────

  group('Subtask data class', () {
    const sub = Subtask(
      id: 6,
      serverId: 60,
      taskLocalId: 5,
      taskServerId: 50,
      title: 'Write test',
      status: 'todo',
      dueDate: null,
      order: 0,
      completedAt: null,
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = sub.copyWith(status: 'done');
      expect(copy.status, 'done');
      expect(copy.id, sub.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(Subtask.fromJson(sub.toJson()), sub);
    });

    test('toString', () {
      expect(sub.toString(), contains('Write test'));
    });

    test('hashCode and ==', () {
      expect(sub.hashCode, sub.hashCode);
      expect(sub, equals(sub.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const SubtasksCompanion(status: Value('done'));
      expect(sub.copyWithCompanion(c).status, 'done');
      expect(sub.toCompanion(true).title.value, 'Write test');
    });
  });

  group('SubtasksCompanion', () {
    test('copyWith', () {
      final c = SubtasksCompanion(taskLocalId: const Value(1), title: const Value('Old'))
          .copyWith(title: const Value('New'));
      expect(c.title.value, 'New');
    });

    test('insert constructor', () {
      final c = SubtasksCompanion.insert(taskLocalId: 5, title: 'Sub');
      expect(c.title.value, 'Sub');
    });
  });

  // ── CreditCard ───────────────────────────────────────────────────────────

  group('CreditCard data class', () {
    const card = CreditCard(
      id: 7,
      serverId: 70,
      name: 'Visa Platinum',
      issuer: 'BigBank',
      lastFour: '4321',
      statementCloseDay: 15,
      gracePeriodDays: 25,
      weekendShift: 'before',
      cycleDays: null,
      cycleReferenceDate: null,
      dueDaySameMonth: null,
      dueDayNextMonth: 5,
      annualFeeMonth: 1,
      isActive: true,
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = card.copyWith(name: 'Mastercard');
      expect(copy.name, 'Mastercard');
      expect(copy.id, card.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(CreditCard.fromJson(card.toJson()), card);
    });

    test('toString', () {
      expect(card.toString(), contains('Visa Platinum'));
    });

    test('hashCode and ==', () {
      expect(card.hashCode, card.hashCode);
      expect(card, equals(card.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const CreditCardsCompanion(name: Value('New Name'));
      expect(card.copyWithCompanion(c).name, 'New Name');
      expect(card.toCompanion(true).name.value, 'Visa Platinum');
    });
  });

  group('CreditCardsCompanion', () {
    test('copyWith', () {
      final c = const CreditCardsCompanion(name: Value('Old'))
          .copyWith(name: const Value('New'));
      expect(c.name.value, 'New');
    });

    test('insert constructor', () {
      final c = CreditCardsCompanion.insert(name: 'Card');
      expect(c.name.value, 'Card');
    });
  });

  // ── CreditCardTrackerCacheData ────────────────────────────────────────────

  group('CreditCardTrackerCacheData data class', () {
    const row = CreditCardTrackerCacheData(
      id: 8,
      cardServerId: 80,
      name: 'My Card',
      issuer: 'Bank',
      lastFour: '1234',
      grace: '2026-05-15',
      prevClose: '2026-04-15',
      prevDue: '2026-05-05',
      nextClose: '2026-05-15',
      nextCloseDays: 7,
      nextDue: '2026-06-05',
      nextDueDays: 28,
      annualFeeDate: '2026-12-01',
      annualFeeDays: 207,
      prevDueOverdue: false,
    );

    test('copyWith', () {
      final copy = row.copyWith(nextDueDays: 30);
      expect(copy.nextDueDays, 30);
      expect(copy.id, row.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(CreditCardTrackerCacheData.fromJson(row.toJson()), row);
    });

    test('toString', () {
      expect(row.toString(), contains('My Card'));
    });

    test('hashCode and ==', () {
      expect(row.hashCode, row.hashCode);
      expect(row, equals(row.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = CreditCardTrackerCacheCompanion(nextDueDays: const Value(35));
      expect(row.copyWithCompanion(c).nextDueDays, 35);
      expect(row.toCompanion(true).name.value, 'My Card');
    });
  });

  group('CreditCardTrackerCacheCompanion', () {
    test('copyWith', () {
      final c = CreditCardTrackerCacheCompanion(
        cardServerId: const Value(1),
        name: const Value('Old'),
        grace: const Value('2026-05-15'),
        prevClose: const Value('2026-04-15'),
        prevDue: const Value('2026-05-05'),
        nextClose: const Value('2026-05-15'),
        nextCloseDays: const Value(7),
        nextDue: const Value('2026-06-05'),
        nextDueDays: const Value(28),
      ).copyWith(name: const Value('New'));
      expect(c.name.value, 'New');
    });
  });

  // ── GroceryStore ─────────────────────────────────────────────────────────

  group('GroceryStore data class', () {
    const store = GroceryStore(
      id: 9,
      serverId: 90,
      name: 'Whole Foods',
      location: 'Downtown',
      isActive: true,
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = store.copyWith(name: 'Trader Joes');
      expect(copy.name, "Trader Joes");
      expect(copy.id, store.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(GroceryStore.fromJson(store.toJson()), store);
    });

    test('toString', () {
      expect(store.toString(), contains('Whole Foods'));
    });

    test('hashCode and ==', () {
      expect(store.hashCode, store.hashCode);
      expect(store, equals(store.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const GroceryStoresCompanion(name: Value('Updated'));
      expect(store.copyWithCompanion(c).name, 'Updated');
      expect(store.toCompanion(true).name.value, 'Whole Foods');
    });
  });

  group('GroceryStoresCompanion', () {
    test('copyWith', () {
      final c = const GroceryStoresCompanion(name: Value('Old'))
          .copyWith(name: const Value('New'));
      expect(c.name.value, 'New');
    });

    test('insert constructor', () {
      final c = GroceryStoresCompanion.insert(name: 'Market');
      expect(c.name.value, 'Market');
    });
  });

  // ── GroceryItem ──────────────────────────────────────────────────────────

  group('GroceryItem data class', () {
    const item = GroceryItem(
      id: 10,
      serverId: 100,
      name: 'Milk',
      defaultUnit: 'gallon',
      defaultStoreServerId: 90,
    );

    test('copyWith', () {
      final copy = item.copyWith(name: 'Eggs');
      expect(copy.name, 'Eggs');
      expect(copy.id, item.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(GroceryItem.fromJson(item.toJson()), item);
    });

    test('toString', () {
      expect(item.toString(), contains('Milk'));
    });

    test('hashCode and ==', () {
      expect(item.hashCode, item.hashCode);
      expect(item, equals(item.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const GroceryItemsCompanion(name: Value('Bread'));
      expect(item.copyWithCompanion(c).name, 'Bread');
      expect(item.toCompanion(true).name.value, 'Milk');
    });
  });

  group('GroceryItemsCompanion', () {
    test('copyWith', () {
      final c = const GroceryItemsCompanion(name: Value('Old'))
          .copyWith(name: const Value('New'));
      expect(c.name.value, 'New');
    });

    test('insert constructor', () {
      final c = GroceryItemsCompanion.insert(name: 'Butter');
      expect(c.name.value, 'Butter');
    });
  });

  // ── GroceryOnHandData ────────────────────────────────────────────────────

  group('GroceryOnHandData data class', () {
    const oh = GroceryOnHandData(
      id: 11,
      itemServerId: 100,
      quantity: 2.5,
      unit: 'lb',
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = oh.copyWith(quantity: 5.0);
      expect(copy.quantity, 5.0);
      expect(copy.id, oh.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(GroceryOnHandData.fromJson(oh.toJson()), oh);
    });

    test('toString', () {
      expect(oh.toString(), contains('2.5'));
    });

    test('hashCode and ==', () {
      expect(oh.hashCode, oh.hashCode);
      expect(oh, equals(oh.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = GroceryOnHandCompanion(quantity: const Value(3.0));
      expect(oh.copyWithCompanion(c).quantity, 3.0);
      expect(oh.toCompanion(true).unit.value, 'lb');
    });
  });

  group('GroceryOnHandCompanion', () {
    test('copyWith', () {
      final c =
          GroceryOnHandCompanion(itemServerId: const Value(1), quantity: const Value(1.0))
              .copyWith(quantity: const Value(2.0));
      expect(c.quantity.value, 2.0);
    });

    test('insert constructor', () {
      final c = GroceryOnHandCompanion.insert(itemServerId: 5);
      expect(c.itemServerId.value, 5);
    });
  });

  // ── GroceryList ──────────────────────────────────────────────────────────

  group('GroceryList data class', () {
    const list = GroceryList(
      id: 12,
      serverId: 120,
      name: 'Weekly Shop',
      storeServerId: 90,
      status: 'draft',
      shoppingDate: '2026-05-10',
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = list.copyWith(status: 'active');
      expect(copy.status, 'active');
      expect(copy.id, list.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(GroceryList.fromJson(list.toJson()), list);
    });

    test('toString', () {
      expect(list.toString(), contains('Weekly Shop'));
    });

    test('hashCode and ==', () {
      expect(list.hashCode, list.hashCode);
      expect(list, equals(list.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const GroceryListsCompanion(status: Value('completed'));
      expect(list.copyWithCompanion(c).status, 'completed');
      expect(list.toCompanion(true).name.value, 'Weekly Shop');
    });
  });

  group('GroceryListsCompanion', () {
    test('copyWith', () {
      final c = const GroceryListsCompanion(name: Value('Old'))
          .copyWith(name: const Value('New'));
      expect(c.name.value, 'New');
    });

    test('insert constructor', () {
      final c = GroceryListsCompanion.insert(name: 'List');
      expect(c.name.value, 'List');
    });
  });

  // ── GroceryListItem ──────────────────────────────────────────────────────

  group('GroceryListItem data class', () {
    const item = GroceryListItem(
      id: 13,
      serverId: 130,
      listLocalId: 12,
      listServerId: 120,
      itemServerId: 100,
      quantity: 3.0,
      unit: 'each',
      price: 4.99,
      status: 'needed',
      notes: 'Organic preferred',
      syncStatus: 0,
    );

    test('copyWith', () {
      final copy = item.copyWith(quantity: 6.0, status: 'in_cart');
      expect(copy.quantity, 6.0);
      expect(copy.status, 'in_cart');
      expect(copy.id, item.id);
    });

    test('toJson / fromJson round-trips', () {
      expect(GroceryListItem.fromJson(item.toJson()), item);
    });

    test('toString', () {
      expect(item.toString(), contains('needed'));
    });

    test('hashCode and ==', () {
      expect(item.hashCode, item.hashCode);
      expect(item, equals(item.copyWith()));
    });

    test('copyWithCompanion and toCompanion', () {
      final c = const GroceryListItemsCompanion(status: Value('purchased'));
      expect(item.copyWithCompanion(c).status, 'purchased');
      expect(item.toCompanion(true).unit.value, 'each');
    });
  });

  group('GroceryListItemsCompanion', () {
    test('copyWith', () {
      final c = GroceryListItemsCompanion(
        listLocalId: const Value(1),
        itemServerId: const Value(5),
        status: const Value('needed'),
      ).copyWith(status: const Value('in_cart'));
      expect(c.status.value, 'in_cart');
    });

    test('insert constructor', () {
      final c = GroceryListItemsCompanion.insert(
        listLocalId: 12,
        itemServerId: 100,
      );
      expect(c.itemServerId.value, 100);
    });
  });
}
