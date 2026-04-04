// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#3b82f6'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('📅'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    color,
    icon,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final int? serverId;
  final String name;
  final String color;
  final String icon;
  final String? description;
  const Category({
    required this.id,
    this.serverId,
    required this.name,
    required this.color,
    required this.icon,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['icon'] = Variable<String>(icon);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String>(json['icon']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String>(icon),
      'description': serializer.toJson<String?>(description),
    };
  }

  Category copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? name,
    String? color,
    String? icon,
    Value<String?> description = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    description: description.present ? description.value : this.description,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, name, color, icon, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.description == this.description);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String> color;
  final Value<String> icon;
  final Value<String?> description;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String>? color,
    Value<String>? icon,
    Value<String?>? description,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, serverId, name, email];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final int? serverId;
  final String name;
  final String? email;
  const Person({
    required this.id,
    this.serverId,
    required this.name,
    this.email,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
    };
  }

  Person copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? name,
    Value<String?> email = const Value.absent(),
  }) => Person(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    email: email.present ? email.value : this.email,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, name, email);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.email == this.email);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String?> email;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? email,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    });
  }

  PersonsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String?>? email,
  }) {
    return PersonsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryServerIdMeta = const VerificationMeta(
    'categoryServerId',
  );
  @override
  late final GeneratedColumn<int> categoryServerId = GeneratedColumn<int>(
    'category_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dtstartMeta = const VerificationMeta(
    'dtstart',
  );
  @override
  late final GeneratedColumn<String> dtstart = GeneratedColumn<String>(
    'dtstart',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    categoryServerId,
    rrule,
    dtstart,
    priority,
    description,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category_server_id')) {
      context.handle(
        _categoryServerIdMeta,
        categoryServerId.isAcceptableOrUnknown(
          data['category_server_id']!,
          _categoryServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryServerIdMeta);
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    }
    if (data.containsKey('dtstart')) {
      context.handle(
        _dtstartMeta,
        dtstart.isAcceptableOrUnknown(data['dtstart']!, _dtstartMeta),
      );
    } else if (isInserting) {
      context.missing(_dtstartMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      categoryServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_server_id'],
      )!,
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      dtstart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dtstart'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final int? serverId;
  final String title;
  final int categoryServerId;
  final String? rrule;
  final String dtstart;
  final String priority;
  final String? description;
  final bool isActive;
  const Event({
    required this.id,
    this.serverId,
    required this.title,
    required this.categoryServerId,
    this.rrule,
    required this.dtstart,
    required this.priority,
    this.description,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['title'] = Variable<String>(title);
    map['category_server_id'] = Variable<int>(categoryServerId);
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    map['dtstart'] = Variable<String>(dtstart);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      categoryServerId: Value(categoryServerId),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      dtstart: Value(dtstart),
      priority: Value(priority),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isActive: Value(isActive),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      categoryServerId: serializer.fromJson<int>(json['categoryServerId']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      dtstart: serializer.fromJson<String>(json['dtstart']),
      priority: serializer.fromJson<String>(json['priority']),
      description: serializer.fromJson<String?>(json['description']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'title': serializer.toJson<String>(title),
      'categoryServerId': serializer.toJson<int>(categoryServerId),
      'rrule': serializer.toJson<String?>(rrule),
      'dtstart': serializer.toJson<String>(dtstart),
      'priority': serializer.toJson<String>(priority),
      'description': serializer.toJson<String?>(description),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Event copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? title,
    int? categoryServerId,
    Value<String?> rrule = const Value.absent(),
    String? dtstart,
    String? priority,
    Value<String?> description = const Value.absent(),
    bool? isActive,
  }) => Event(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    categoryServerId: categoryServerId ?? this.categoryServerId,
    rrule: rrule.present ? rrule.value : this.rrule,
    dtstart: dtstart ?? this.dtstart,
    priority: priority ?? this.priority,
    description: description.present ? description.value : this.description,
    isActive: isActive ?? this.isActive,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      categoryServerId: data.categoryServerId.present
          ? data.categoryServerId.value
          : this.categoryServerId,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      dtstart: data.dtstart.present ? data.dtstart.value : this.dtstart,
      priority: data.priority.present ? data.priority.value : this.priority,
      description: data.description.present
          ? data.description.value
          : this.description,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('categoryServerId: $categoryServerId, ')
          ..write('rrule: $rrule, ')
          ..write('dtstart: $dtstart, ')
          ..write('priority: $priority, ')
          ..write('description: $description, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    title,
    categoryServerId,
    rrule,
    dtstart,
    priority,
    description,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.categoryServerId == this.categoryServerId &&
          other.rrule == this.rrule &&
          other.dtstart == this.dtstart &&
          other.priority == this.priority &&
          other.description == this.description &&
          other.isActive == this.isActive);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> title;
  final Value<int> categoryServerId;
  final Value<String?> rrule;
  final Value<String> dtstart;
  final Value<String> priority;
  final Value<String?> description;
  final Value<bool> isActive;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.categoryServerId = const Value.absent(),
    this.rrule = const Value.absent(),
    this.dtstart = const Value.absent(),
    this.priority = const Value.absent(),
    this.description = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String title,
    required int categoryServerId,
    this.rrule = const Value.absent(),
    required String dtstart,
    this.priority = const Value.absent(),
    this.description = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : title = Value(title),
       categoryServerId = Value(categoryServerId),
       dtstart = Value(dtstart);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? title,
    Expression<int>? categoryServerId,
    Expression<String>? rrule,
    Expression<String>? dtstart,
    Expression<String>? priority,
    Expression<String>? description,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (categoryServerId != null) 'category_server_id': categoryServerId,
      if (rrule != null) 'rrule': rrule,
      if (dtstart != null) 'dtstart': dtstart,
      if (priority != null) 'priority': priority,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? title,
    Value<int>? categoryServerId,
    Value<String?>? rrule,
    Value<String>? dtstart,
    Value<String>? priority,
    Value<String?>? description,
    Value<bool>? isActive,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      categoryServerId: categoryServerId ?? this.categoryServerId,
      rrule: rrule ?? this.rrule,
      dtstart: dtstart ?? this.dtstart,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (categoryServerId.present) {
      map['category_server_id'] = Variable<int>(categoryServerId.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (dtstart.present) {
      map['dtstart'] = Variable<String>(dtstart.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('categoryServerId: $categoryServerId, ')
          ..write('rrule: $rrule, ')
          ..write('dtstart: $dtstart, ')
          ..write('priority: $priority, ')
          ..write('description: $description, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $OccurrencesTable extends Occurrences
    with TableInfo<$OccurrencesTable, Occurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventServerIdMeta = const VerificationMeta(
    'eventServerId',
  );
  @override
  late final GeneratedColumn<int> eventServerId = GeneratedColumn<int>(
    'event_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<String> occurrenceDate = GeneratedColumn<String>(
    'occurrence_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('upcoming'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    eventServerId,
    occurrenceDate,
    status,
    notes,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Occurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('event_server_id')) {
      context.handle(
        _eventServerIdMeta,
        eventServerId.isAcceptableOrUnknown(
          data['event_server_id']!,
          _eventServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventServerIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Occurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Occurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      eventServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_server_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }
}

class Occurrence extends DataClass implements Insertable<Occurrence> {
  final int id;
  final int? serverId;
  final int eventServerId;
  final String occurrenceDate;
  final String status;
  final String? notes;
  final int syncStatus;
  const Occurrence({
    required this.id,
    this.serverId,
    required this.eventServerId,
    required this.occurrenceDate,
    required this.status,
    this.notes,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['event_server_id'] = Variable<int>(eventServerId);
    map['occurrence_date'] = Variable<String>(occurrenceDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      eventServerId: Value(eventServerId),
      occurrenceDate: Value(occurrenceDate),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
    );
  }

  factory Occurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Occurrence(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      eventServerId: serializer.fromJson<int>(json['eventServerId']),
      occurrenceDate: serializer.fromJson<String>(json['occurrenceDate']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'eventServerId': serializer.toJson<int>(eventServerId),
      'occurrenceDate': serializer.toJson<String>(occurrenceDate),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Occurrence copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? eventServerId,
    String? occurrenceDate,
    String? status,
    Value<String?> notes = const Value.absent(),
    int? syncStatus,
  }) => Occurrence(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    eventServerId: eventServerId ?? this.eventServerId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Occurrence copyWithCompanion(OccurrencesCompanion data) {
    return Occurrence(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      eventServerId: data.eventServerId.present
          ? data.eventServerId.value
          : this.eventServerId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Occurrence(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('eventServerId: $eventServerId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    eventServerId,
    occurrenceDate,
    status,
    notes,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Occurrence &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.eventServerId == this.eventServerId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus);
}

class OccurrencesCompanion extends UpdateCompanion<Occurrence> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> eventServerId;
  final Value<String> occurrenceDate;
  final Value<String> status;
  final Value<String?> notes;
  final Value<int> syncStatus;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.eventServerId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int eventServerId,
    required String occurrenceDate,
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
  }) : eventServerId = Value(eventServerId),
       occurrenceDate = Value(occurrenceDate);
  static Insertable<Occurrence> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? eventServerId,
    Expression<String>? occurrenceDate,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<int>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (eventServerId != null) 'event_server_id': eventServerId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  OccurrencesCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? eventServerId,
    Value<String>? occurrenceDate,
    Value<String>? status,
    Value<String?>? notes,
    Value<int>? syncStatus,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      eventServerId: eventServerId ?? this.eventServerId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (eventServerId.present) {
      map['event_server_id'] = Variable<int>(eventServerId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<String>(occurrenceDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('eventServerId: $eventServerId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _assigneeServerIdMeta = const VerificationMeta(
    'assigneeServerId',
  );
  @override
  late final GeneratedColumn<int> assigneeServerId = GeneratedColumn<int>(
    'assignee_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryServerIdMeta = const VerificationMeta(
    'categoryServerId',
  );
  @override
  late final GeneratedColumn<int> categoryServerId = GeneratedColumn<int>(
    'category_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedMinutesMeta = const VerificationMeta(
    'estimatedMinutes',
  );
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
    'estimated_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _occurrenceServerIdMeta =
      const VerificationMeta('occurrenceServerId');
  @override
  late final GeneratedColumn<int> occurrenceServerId = GeneratedColumn<int>(
    'occurrence_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    description,
    status,
    priority,
    assigneeServerId,
    categoryServerId,
    dueDate,
    estimatedMinutes,
    recurrence,
    occurrenceServerId,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('assignee_server_id')) {
      context.handle(
        _assigneeServerIdMeta,
        assigneeServerId.isAcceptableOrUnknown(
          data['assignee_server_id']!,
          _assigneeServerIdMeta,
        ),
      );
    }
    if (data.containsKey('category_server_id')) {
      context.handle(
        _categoryServerIdMeta,
        categoryServerId.isAcceptableOrUnknown(
          data['category_server_id']!,
          _categoryServerIdMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
        _estimatedMinutesMeta,
        estimatedMinutes.isAcceptableOrUnknown(
          data['estimated_minutes']!,
          _estimatedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('occurrence_server_id')) {
      context.handle(
        _occurrenceServerIdMeta,
        occurrenceServerId.isAcceptableOrUnknown(
          data['occurrence_server_id']!,
          _occurrenceServerIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      assigneeServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assignee_server_id'],
      ),
      categoryServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_server_id'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      estimatedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_minutes'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      )!,
      occurrenceServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_server_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final int? serverId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final int? assigneeServerId;
  final int? categoryServerId;
  final String? dueDate;
  final int? estimatedMinutes;
  final String recurrence;
  final int? occurrenceServerId;
  final int syncStatus;
  final String createdAt;
  final String updatedAt;
  const Task({
    required this.id,
    this.serverId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeServerId,
    this.categoryServerId,
    this.dueDate,
    this.estimatedMinutes,
    required this.recurrence,
    this.occurrenceServerId,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || assigneeServerId != null) {
      map['assignee_server_id'] = Variable<int>(assigneeServerId);
    }
    if (!nullToAbsent || categoryServerId != null) {
      map['category_server_id'] = Variable<int>(categoryServerId);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || estimatedMinutes != null) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    }
    map['recurrence'] = Variable<String>(recurrence);
    if (!nullToAbsent || occurrenceServerId != null) {
      map['occurrence_server_id'] = Variable<int>(occurrenceServerId);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      priority: Value(priority),
      assigneeServerId: assigneeServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeServerId),
      categoryServerId: categoryServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryServerId),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      estimatedMinutes: estimatedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedMinutes),
      recurrence: Value(recurrence),
      occurrenceServerId: occurrenceServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceServerId),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      assigneeServerId: serializer.fromJson<int?>(json['assigneeServerId']),
      categoryServerId: serializer.fromJson<int?>(json['categoryServerId']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      estimatedMinutes: serializer.fromJson<int?>(json['estimatedMinutes']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      occurrenceServerId: serializer.fromJson<int?>(json['occurrenceServerId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'assigneeServerId': serializer.toJson<int?>(assigneeServerId),
      'categoryServerId': serializer.toJson<int?>(categoryServerId),
      'dueDate': serializer.toJson<String?>(dueDate),
      'estimatedMinutes': serializer.toJson<int?>(estimatedMinutes),
      'recurrence': serializer.toJson<String>(recurrence),
      'occurrenceServerId': serializer.toJson<int?>(occurrenceServerId),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Task copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    String? priority,
    Value<int?> assigneeServerId = const Value.absent(),
    Value<int?> categoryServerId = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<int?> estimatedMinutes = const Value.absent(),
    String? recurrence,
    Value<int?> occurrenceServerId = const Value.absent(),
    int? syncStatus,
    String? createdAt,
    String? updatedAt,
  }) => Task(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assigneeServerId: assigneeServerId.present
        ? assigneeServerId.value
        : this.assigneeServerId,
    categoryServerId: categoryServerId.present
        ? categoryServerId.value
        : this.categoryServerId,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    estimatedMinutes: estimatedMinutes.present
        ? estimatedMinutes.value
        : this.estimatedMinutes,
    recurrence: recurrence ?? this.recurrence,
    occurrenceServerId: occurrenceServerId.present
        ? occurrenceServerId.value
        : this.occurrenceServerId,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      assigneeServerId: data.assigneeServerId.present
          ? data.assigneeServerId.value
          : this.assigneeServerId,
      categoryServerId: data.categoryServerId.present
          ? data.categoryServerId.value
          : this.categoryServerId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      occurrenceServerId: data.occurrenceServerId.present
          ? data.occurrenceServerId.value
          : this.occurrenceServerId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('assigneeServerId: $assigneeServerId, ')
          ..write('categoryServerId: $categoryServerId, ')
          ..write('dueDate: $dueDate, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('recurrence: $recurrence, ')
          ..write('occurrenceServerId: $occurrenceServerId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    title,
    description,
    status,
    priority,
    assigneeServerId,
    categoryServerId,
    dueDate,
    estimatedMinutes,
    recurrence,
    occurrenceServerId,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.assigneeServerId == this.assigneeServerId &&
          other.categoryServerId == this.categoryServerId &&
          other.dueDate == this.dueDate &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.recurrence == this.recurrence &&
          other.occurrenceServerId == this.occurrenceServerId &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<int?> assigneeServerId;
  final Value<int?> categoryServerId;
  final Value<String?> dueDate;
  final Value<int?> estimatedMinutes;
  final Value<String> recurrence;
  final Value<int?> occurrenceServerId;
  final Value<int> syncStatus;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.assigneeServerId = const Value.absent(),
    this.categoryServerId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.occurrenceServerId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.assigneeServerId = const Value.absent(),
    this.categoryServerId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.occurrenceServerId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<int>? assigneeServerId,
    Expression<int>? categoryServerId,
    Expression<String>? dueDate,
    Expression<int>? estimatedMinutes,
    Expression<String>? recurrence,
    Expression<int>? occurrenceServerId,
    Expression<int>? syncStatus,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (assigneeServerId != null) 'assignee_server_id': assigneeServerId,
      if (categoryServerId != null) 'category_server_id': categoryServerId,
      if (dueDate != null) 'due_date': dueDate,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (recurrence != null) 'recurrence': recurrence,
      if (occurrenceServerId != null)
        'occurrence_server_id': occurrenceServerId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<String>? priority,
    Value<int?>? assigneeServerId,
    Value<int?>? categoryServerId,
    Value<String?>? dueDate,
    Value<int?>? estimatedMinutes,
    Value<String>? recurrence,
    Value<int?>? occurrenceServerId,
    Value<int>? syncStatus,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeServerId: assigneeServerId ?? this.assigneeServerId,
      categoryServerId: categoryServerId ?? this.categoryServerId,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      recurrence: recurrence ?? this.recurrence,
      occurrenceServerId: occurrenceServerId ?? this.occurrenceServerId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (assigneeServerId.present) {
      map['assignee_server_id'] = Variable<int>(assigneeServerId.value);
    }
    if (categoryServerId.present) {
      map['category_server_id'] = Variable<int>(categoryServerId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (occurrenceServerId.present) {
      map['occurrence_server_id'] = Variable<int>(occurrenceServerId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('assigneeServerId: $assigneeServerId, ')
          ..write('categoryServerId: $categoryServerId, ')
          ..write('dueDate: $dueDate, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('recurrence: $recurrence, ')
          ..write('occurrenceServerId: $occurrenceServerId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskLocalIdMeta = const VerificationMeta(
    'taskLocalId',
  );
  @override
  late final GeneratedColumn<int> taskLocalId = GeneratedColumn<int>(
    'task_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskServerIdMeta = const VerificationMeta(
    'taskServerId',
  );
  @override
  late final GeneratedColumn<int> taskServerId = GeneratedColumn<int>(
    'task_server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    taskLocalId,
    taskServerId,
    title,
    status,
    dueDate,
    order,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subtask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('task_local_id')) {
      context.handle(
        _taskLocalIdMeta,
        taskLocalId.isAcceptableOrUnknown(
          data['task_local_id']!,
          _taskLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taskLocalIdMeta);
    }
    if (data.containsKey('task_server_id')) {
      context.handle(
        _taskServerIdMeta,
        taskServerId.isAcceptableOrUnknown(
          data['task_server_id']!,
          _taskServerIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      taskLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_local_id'],
      )!,
      taskServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final int id;
  final int? serverId;
  final int taskLocalId;
  final int? taskServerId;
  final String title;
  final String status;
  final String? dueDate;
  final int order;
  final int syncStatus;
  const Subtask({
    required this.id,
    this.serverId,
    required this.taskLocalId,
    this.taskServerId,
    required this.title,
    required this.status,
    this.dueDate,
    required this.order,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['task_local_id'] = Variable<int>(taskLocalId);
    if (!nullToAbsent || taskServerId != null) {
      map['task_server_id'] = Variable<int>(taskServerId);
    }
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    map['order'] = Variable<int>(order);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      taskLocalId: Value(taskLocalId),
      taskServerId: taskServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskServerId),
      title: Value(title),
      status: Value(status),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      order: Value(order),
      syncStatus: Value(syncStatus),
    );
  }

  factory Subtask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      taskLocalId: serializer.fromJson<int>(json['taskLocalId']),
      taskServerId: serializer.fromJson<int?>(json['taskServerId']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      order: serializer.fromJson<int>(json['order']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'taskLocalId': serializer.toJson<int>(taskLocalId),
      'taskServerId': serializer.toJson<int?>(taskServerId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'dueDate': serializer.toJson<String?>(dueDate),
      'order': serializer.toJson<int>(order),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Subtask copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? taskLocalId,
    Value<int?> taskServerId = const Value.absent(),
    String? title,
    String? status,
    Value<String?> dueDate = const Value.absent(),
    int? order,
    int? syncStatus,
  }) => Subtask(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    taskLocalId: taskLocalId ?? this.taskLocalId,
    taskServerId: taskServerId.present ? taskServerId.value : this.taskServerId,
    title: title ?? this.title,
    status: status ?? this.status,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    order: order ?? this.order,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      taskLocalId: data.taskLocalId.present
          ? data.taskLocalId.value
          : this.taskLocalId,
      taskServerId: data.taskServerId.present
          ? data.taskServerId.value
          : this.taskServerId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      order: data.order.present ? data.order.value : this.order,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('taskLocalId: $taskLocalId, ')
          ..write('taskServerId: $taskServerId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('order: $order, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    taskLocalId,
    taskServerId,
    title,
    status,
    dueDate,
    order,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.taskLocalId == this.taskLocalId &&
          other.taskServerId == this.taskServerId &&
          other.title == this.title &&
          other.status == this.status &&
          other.dueDate == this.dueDate &&
          other.order == this.order &&
          other.syncStatus == this.syncStatus);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> taskLocalId;
  final Value<int?> taskServerId;
  final Value<String> title;
  final Value<String> status;
  final Value<String?> dueDate;
  final Value<int> order;
  final Value<int> syncStatus;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.taskLocalId = const Value.absent(),
    this.taskServerId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.order = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  SubtasksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int taskLocalId,
    this.taskServerId = const Value.absent(),
    required String title,
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.order = const Value.absent(),
    this.syncStatus = const Value.absent(),
  }) : taskLocalId = Value(taskLocalId),
       title = Value(title);
  static Insertable<Subtask> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? taskLocalId,
    Expression<int>? taskServerId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? dueDate,
    Expression<int>? order,
    Expression<int>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (taskLocalId != null) 'task_local_id': taskLocalId,
      if (taskServerId != null) 'task_server_id': taskServerId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (order != null) 'order': order,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  SubtasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? taskLocalId,
    Value<int?>? taskServerId,
    Value<String>? title,
    Value<String>? status,
    Value<String?>? dueDate,
    Value<int>? order,
    Value<int>? syncStatus,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      taskLocalId: taskLocalId ?? this.taskLocalId,
      taskServerId: taskServerId ?? this.taskServerId,
      title: title ?? this.title,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      order: order ?? this.order,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (taskLocalId.present) {
      map['task_local_id'] = Variable<int>(taskLocalId.value);
    }
    if (taskServerId.present) {
      map['task_server_id'] = Variable<int>(taskServerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('taskLocalId: $taskLocalId, ')
          ..write('taskServerId: $taskServerId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('order: $order, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $CreditCardsTable extends CreditCards
    with TableInfo<$CreditCardsTable, CreditCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFourMeta = const VerificationMeta(
    'lastFour',
  );
  @override
  late final GeneratedColumn<String> lastFour = GeneratedColumn<String>(
    'last_four',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statementCloseDayMeta = const VerificationMeta(
    'statementCloseDay',
  );
  @override
  late final GeneratedColumn<int> statementCloseDay = GeneratedColumn<int>(
    'statement_close_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gracePeriodDaysMeta = const VerificationMeta(
    'gracePeriodDays',
  );
  @override
  late final GeneratedColumn<int> gracePeriodDays = GeneratedColumn<int>(
    'grace_period_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekendShiftMeta = const VerificationMeta(
    'weekendShift',
  );
  @override
  late final GeneratedColumn<String> weekendShift = GeneratedColumn<String>(
    'weekend_shift',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleDaysMeta = const VerificationMeta(
    'cycleDays',
  );
  @override
  late final GeneratedColumn<int> cycleDays = GeneratedColumn<int>(
    'cycle_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleReferenceDateMeta =
      const VerificationMeta('cycleReferenceDate');
  @override
  late final GeneratedColumn<String> cycleReferenceDate =
      GeneratedColumn<String>(
        'cycle_reference_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dueDaySameMonthMeta = const VerificationMeta(
    'dueDaySameMonth',
  );
  @override
  late final GeneratedColumn<int> dueDaySameMonth = GeneratedColumn<int>(
    'due_day_same_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayNextMonthMeta = const VerificationMeta(
    'dueDayNextMonth',
  );
  @override
  late final GeneratedColumn<int> dueDayNextMonth = GeneratedColumn<int>(
    'due_day_next_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _annualFeeMonthMeta = const VerificationMeta(
    'annualFeeMonth',
  );
  @override
  late final GeneratedColumn<int> annualFeeMonth = GeneratedColumn<int>(
    'annual_fee_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    issuer,
    lastFour,
    statementCloseDay,
    gracePeriodDays,
    weekendShift,
    cycleDays,
    cycleReferenceDate,
    dueDaySameMonth,
    dueDayNextMonth,
    annualFeeMonth,
    isActive,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    }
    if (data.containsKey('last_four')) {
      context.handle(
        _lastFourMeta,
        lastFour.isAcceptableOrUnknown(data['last_four']!, _lastFourMeta),
      );
    }
    if (data.containsKey('statement_close_day')) {
      context.handle(
        _statementCloseDayMeta,
        statementCloseDay.isAcceptableOrUnknown(
          data['statement_close_day']!,
          _statementCloseDayMeta,
        ),
      );
    }
    if (data.containsKey('grace_period_days')) {
      context.handle(
        _gracePeriodDaysMeta,
        gracePeriodDays.isAcceptableOrUnknown(
          data['grace_period_days']!,
          _gracePeriodDaysMeta,
        ),
      );
    }
    if (data.containsKey('weekend_shift')) {
      context.handle(
        _weekendShiftMeta,
        weekendShift.isAcceptableOrUnknown(
          data['weekend_shift']!,
          _weekendShiftMeta,
        ),
      );
    }
    if (data.containsKey('cycle_days')) {
      context.handle(
        _cycleDaysMeta,
        cycleDays.isAcceptableOrUnknown(data['cycle_days']!, _cycleDaysMeta),
      );
    }
    if (data.containsKey('cycle_reference_date')) {
      context.handle(
        _cycleReferenceDateMeta,
        cycleReferenceDate.isAcceptableOrUnknown(
          data['cycle_reference_date']!,
          _cycleReferenceDateMeta,
        ),
      );
    }
    if (data.containsKey('due_day_same_month')) {
      context.handle(
        _dueDaySameMonthMeta,
        dueDaySameMonth.isAcceptableOrUnknown(
          data['due_day_same_month']!,
          _dueDaySameMonthMeta,
        ),
      );
    }
    if (data.containsKey('due_day_next_month')) {
      context.handle(
        _dueDayNextMonthMeta,
        dueDayNextMonth.isAcceptableOrUnknown(
          data['due_day_next_month']!,
          _dueDayNextMonthMeta,
        ),
      );
    }
    if (data.containsKey('annual_fee_month')) {
      context.handle(
        _annualFeeMonthMeta,
        annualFeeMonth.isAcceptableOrUnknown(
          data['annual_fee_month']!,
          _annualFeeMonthMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      ),
      lastFour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_four'],
      ),
      statementCloseDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_close_day'],
      ),
      gracePeriodDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grace_period_days'],
      ),
      weekendShift: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekend_shift'],
      ),
      cycleDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_days'],
      ),
      cycleReferenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_reference_date'],
      ),
      dueDaySameMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day_same_month'],
      ),
      dueDayNextMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day_next_month'],
      ),
      annualFeeMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}annual_fee_month'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $CreditCardsTable createAlias(String alias) {
    return $CreditCardsTable(attachedDatabase, alias);
  }
}

class CreditCard extends DataClass implements Insertable<CreditCard> {
  final int id;
  final int? serverId;
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
  final int syncStatus;
  const CreditCard({
    required this.id,
    this.serverId,
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
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || issuer != null) {
      map['issuer'] = Variable<String>(issuer);
    }
    if (!nullToAbsent || lastFour != null) {
      map['last_four'] = Variable<String>(lastFour);
    }
    if (!nullToAbsent || statementCloseDay != null) {
      map['statement_close_day'] = Variable<int>(statementCloseDay);
    }
    if (!nullToAbsent || gracePeriodDays != null) {
      map['grace_period_days'] = Variable<int>(gracePeriodDays);
    }
    if (!nullToAbsent || weekendShift != null) {
      map['weekend_shift'] = Variable<String>(weekendShift);
    }
    if (!nullToAbsent || cycleDays != null) {
      map['cycle_days'] = Variable<int>(cycleDays);
    }
    if (!nullToAbsent || cycleReferenceDate != null) {
      map['cycle_reference_date'] = Variable<String>(cycleReferenceDate);
    }
    if (!nullToAbsent || dueDaySameMonth != null) {
      map['due_day_same_month'] = Variable<int>(dueDaySameMonth);
    }
    if (!nullToAbsent || dueDayNextMonth != null) {
      map['due_day_next_month'] = Variable<int>(dueDayNextMonth);
    }
    if (!nullToAbsent || annualFeeMonth != null) {
      map['annual_fee_month'] = Variable<int>(annualFeeMonth);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  CreditCardsCompanion toCompanion(bool nullToAbsent) {
    return CreditCardsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      issuer: issuer == null && nullToAbsent
          ? const Value.absent()
          : Value(issuer),
      lastFour: lastFour == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFour),
      statementCloseDay: statementCloseDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementCloseDay),
      gracePeriodDays: gracePeriodDays == null && nullToAbsent
          ? const Value.absent()
          : Value(gracePeriodDays),
      weekendShift: weekendShift == null && nullToAbsent
          ? const Value.absent()
          : Value(weekendShift),
      cycleDays: cycleDays == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleDays),
      cycleReferenceDate: cycleReferenceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleReferenceDate),
      dueDaySameMonth: dueDaySameMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDaySameMonth),
      dueDayNextMonth: dueDayNextMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDayNextMonth),
      annualFeeMonth: annualFeeMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(annualFeeMonth),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
    );
  }

  factory CreditCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCard(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      issuer: serializer.fromJson<String?>(json['issuer']),
      lastFour: serializer.fromJson<String?>(json['lastFour']),
      statementCloseDay: serializer.fromJson<int?>(json['statementCloseDay']),
      gracePeriodDays: serializer.fromJson<int?>(json['gracePeriodDays']),
      weekendShift: serializer.fromJson<String?>(json['weekendShift']),
      cycleDays: serializer.fromJson<int?>(json['cycleDays']),
      cycleReferenceDate: serializer.fromJson<String?>(
        json['cycleReferenceDate'],
      ),
      dueDaySameMonth: serializer.fromJson<int?>(json['dueDaySameMonth']),
      dueDayNextMonth: serializer.fromJson<int?>(json['dueDayNextMonth']),
      annualFeeMonth: serializer.fromJson<int?>(json['annualFeeMonth']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'issuer': serializer.toJson<String?>(issuer),
      'lastFour': serializer.toJson<String?>(lastFour),
      'statementCloseDay': serializer.toJson<int?>(statementCloseDay),
      'gracePeriodDays': serializer.toJson<int?>(gracePeriodDays),
      'weekendShift': serializer.toJson<String?>(weekendShift),
      'cycleDays': serializer.toJson<int?>(cycleDays),
      'cycleReferenceDate': serializer.toJson<String?>(cycleReferenceDate),
      'dueDaySameMonth': serializer.toJson<int?>(dueDaySameMonth),
      'dueDayNextMonth': serializer.toJson<int?>(dueDayNextMonth),
      'annualFeeMonth': serializer.toJson<int?>(annualFeeMonth),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  CreditCard copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? name,
    Value<String?> issuer = const Value.absent(),
    Value<String?> lastFour = const Value.absent(),
    Value<int?> statementCloseDay = const Value.absent(),
    Value<int?> gracePeriodDays = const Value.absent(),
    Value<String?> weekendShift = const Value.absent(),
    Value<int?> cycleDays = const Value.absent(),
    Value<String?> cycleReferenceDate = const Value.absent(),
    Value<int?> dueDaySameMonth = const Value.absent(),
    Value<int?> dueDayNextMonth = const Value.absent(),
    Value<int?> annualFeeMonth = const Value.absent(),
    bool? isActive,
    int? syncStatus,
  }) => CreditCard(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    issuer: issuer.present ? issuer.value : this.issuer,
    lastFour: lastFour.present ? lastFour.value : this.lastFour,
    statementCloseDay: statementCloseDay.present
        ? statementCloseDay.value
        : this.statementCloseDay,
    gracePeriodDays: gracePeriodDays.present
        ? gracePeriodDays.value
        : this.gracePeriodDays,
    weekendShift: weekendShift.present ? weekendShift.value : this.weekendShift,
    cycleDays: cycleDays.present ? cycleDays.value : this.cycleDays,
    cycleReferenceDate: cycleReferenceDate.present
        ? cycleReferenceDate.value
        : this.cycleReferenceDate,
    dueDaySameMonth: dueDaySameMonth.present
        ? dueDaySameMonth.value
        : this.dueDaySameMonth,
    dueDayNextMonth: dueDayNextMonth.present
        ? dueDayNextMonth.value
        : this.dueDayNextMonth,
    annualFeeMonth: annualFeeMonth.present
        ? annualFeeMonth.value
        : this.annualFeeMonth,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CreditCard copyWithCompanion(CreditCardsCompanion data) {
    return CreditCard(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      lastFour: data.lastFour.present ? data.lastFour.value : this.lastFour,
      statementCloseDay: data.statementCloseDay.present
          ? data.statementCloseDay.value
          : this.statementCloseDay,
      gracePeriodDays: data.gracePeriodDays.present
          ? data.gracePeriodDays.value
          : this.gracePeriodDays,
      weekendShift: data.weekendShift.present
          ? data.weekendShift.value
          : this.weekendShift,
      cycleDays: data.cycleDays.present ? data.cycleDays.value : this.cycleDays,
      cycleReferenceDate: data.cycleReferenceDate.present
          ? data.cycleReferenceDate.value
          : this.cycleReferenceDate,
      dueDaySameMonth: data.dueDaySameMonth.present
          ? data.dueDaySameMonth.value
          : this.dueDaySameMonth,
      dueDayNextMonth: data.dueDayNextMonth.present
          ? data.dueDayNextMonth.value
          : this.dueDayNextMonth,
      annualFeeMonth: data.annualFeeMonth.present
          ? data.annualFeeMonth.value
          : this.annualFeeMonth,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCard(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('issuer: $issuer, ')
          ..write('lastFour: $lastFour, ')
          ..write('statementCloseDay: $statementCloseDay, ')
          ..write('gracePeriodDays: $gracePeriodDays, ')
          ..write('weekendShift: $weekendShift, ')
          ..write('cycleDays: $cycleDays, ')
          ..write('cycleReferenceDate: $cycleReferenceDate, ')
          ..write('dueDaySameMonth: $dueDaySameMonth, ')
          ..write('dueDayNextMonth: $dueDayNextMonth, ')
          ..write('annualFeeMonth: $annualFeeMonth, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    issuer,
    lastFour,
    statementCloseDay,
    gracePeriodDays,
    weekendShift,
    cycleDays,
    cycleReferenceDate,
    dueDaySameMonth,
    dueDayNextMonth,
    annualFeeMonth,
    isActive,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCard &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.issuer == this.issuer &&
          other.lastFour == this.lastFour &&
          other.statementCloseDay == this.statementCloseDay &&
          other.gracePeriodDays == this.gracePeriodDays &&
          other.weekendShift == this.weekendShift &&
          other.cycleDays == this.cycleDays &&
          other.cycleReferenceDate == this.cycleReferenceDate &&
          other.dueDaySameMonth == this.dueDaySameMonth &&
          other.dueDayNextMonth == this.dueDayNextMonth &&
          other.annualFeeMonth == this.annualFeeMonth &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus);
}

class CreditCardsCompanion extends UpdateCompanion<CreditCard> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String?> issuer;
  final Value<String?> lastFour;
  final Value<int?> statementCloseDay;
  final Value<int?> gracePeriodDays;
  final Value<String?> weekendShift;
  final Value<int?> cycleDays;
  final Value<String?> cycleReferenceDate;
  final Value<int?> dueDaySameMonth;
  final Value<int?> dueDayNextMonth;
  final Value<int?> annualFeeMonth;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  const CreditCardsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.issuer = const Value.absent(),
    this.lastFour = const Value.absent(),
    this.statementCloseDay = const Value.absent(),
    this.gracePeriodDays = const Value.absent(),
    this.weekendShift = const Value.absent(),
    this.cycleDays = const Value.absent(),
    this.cycleReferenceDate = const Value.absent(),
    this.dueDaySameMonth = const Value.absent(),
    this.dueDayNextMonth = const Value.absent(),
    this.annualFeeMonth = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  CreditCardsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    this.issuer = const Value.absent(),
    this.lastFour = const Value.absent(),
    this.statementCloseDay = const Value.absent(),
    this.gracePeriodDays = const Value.absent(),
    this.weekendShift = const Value.absent(),
    this.cycleDays = const Value.absent(),
    this.cycleReferenceDate = const Value.absent(),
    this.dueDaySameMonth = const Value.absent(),
    this.dueDayNextMonth = const Value.absent(),
    this.annualFeeMonth = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CreditCard> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? issuer,
    Expression<String>? lastFour,
    Expression<int>? statementCloseDay,
    Expression<int>? gracePeriodDays,
    Expression<String>? weekendShift,
    Expression<int>? cycleDays,
    Expression<String>? cycleReferenceDate,
    Expression<int>? dueDaySameMonth,
    Expression<int>? dueDayNextMonth,
    Expression<int>? annualFeeMonth,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (issuer != null) 'issuer': issuer,
      if (lastFour != null) 'last_four': lastFour,
      if (statementCloseDay != null) 'statement_close_day': statementCloseDay,
      if (gracePeriodDays != null) 'grace_period_days': gracePeriodDays,
      if (weekendShift != null) 'weekend_shift': weekendShift,
      if (cycleDays != null) 'cycle_days': cycleDays,
      if (cycleReferenceDate != null)
        'cycle_reference_date': cycleReferenceDate,
      if (dueDaySameMonth != null) 'due_day_same_month': dueDaySameMonth,
      if (dueDayNextMonth != null) 'due_day_next_month': dueDayNextMonth,
      if (annualFeeMonth != null) 'annual_fee_month': annualFeeMonth,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  CreditCardsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String?>? issuer,
    Value<String?>? lastFour,
    Value<int?>? statementCloseDay,
    Value<int?>? gracePeriodDays,
    Value<String?>? weekendShift,
    Value<int?>? cycleDays,
    Value<String?>? cycleReferenceDate,
    Value<int?>? dueDaySameMonth,
    Value<int?>? dueDayNextMonth,
    Value<int?>? annualFeeMonth,
    Value<bool>? isActive,
    Value<int>? syncStatus,
  }) {
    return CreditCardsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      lastFour: lastFour ?? this.lastFour,
      statementCloseDay: statementCloseDay ?? this.statementCloseDay,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      weekendShift: weekendShift ?? this.weekendShift,
      cycleDays: cycleDays ?? this.cycleDays,
      cycleReferenceDate: cycleReferenceDate ?? this.cycleReferenceDate,
      dueDaySameMonth: dueDaySameMonth ?? this.dueDaySameMonth,
      dueDayNextMonth: dueDayNextMonth ?? this.dueDayNextMonth,
      annualFeeMonth: annualFeeMonth ?? this.annualFeeMonth,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (lastFour.present) {
      map['last_four'] = Variable<String>(lastFour.value);
    }
    if (statementCloseDay.present) {
      map['statement_close_day'] = Variable<int>(statementCloseDay.value);
    }
    if (gracePeriodDays.present) {
      map['grace_period_days'] = Variable<int>(gracePeriodDays.value);
    }
    if (weekendShift.present) {
      map['weekend_shift'] = Variable<String>(weekendShift.value);
    }
    if (cycleDays.present) {
      map['cycle_days'] = Variable<int>(cycleDays.value);
    }
    if (cycleReferenceDate.present) {
      map['cycle_reference_date'] = Variable<String>(cycleReferenceDate.value);
    }
    if (dueDaySameMonth.present) {
      map['due_day_same_month'] = Variable<int>(dueDaySameMonth.value);
    }
    if (dueDayNextMonth.present) {
      map['due_day_next_month'] = Variable<int>(dueDayNextMonth.value);
    }
    if (annualFeeMonth.present) {
      map['annual_fee_month'] = Variable<int>(annualFeeMonth.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('issuer: $issuer, ')
          ..write('lastFour: $lastFour, ')
          ..write('statementCloseDay: $statementCloseDay, ')
          ..write('gracePeriodDays: $gracePeriodDays, ')
          ..write('weekendShift: $weekendShift, ')
          ..write('cycleDays: $cycleDays, ')
          ..write('cycleReferenceDate: $cycleReferenceDate, ')
          ..write('dueDaySameMonth: $dueDaySameMonth, ')
          ..write('dueDayNextMonth: $dueDayNextMonth, ')
          ..write('annualFeeMonth: $annualFeeMonth, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $CreditCardTrackerCacheTable extends CreditCardTrackerCache
    with TableInfo<$CreditCardTrackerCacheTable, CreditCardTrackerCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardTrackerCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardServerIdMeta = const VerificationMeta(
    'cardServerId',
  );
  @override
  late final GeneratedColumn<int> cardServerId = GeneratedColumn<int>(
    'card_server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFourMeta = const VerificationMeta(
    'lastFour',
  );
  @override
  late final GeneratedColumn<String> lastFour = GeneratedColumn<String>(
    'last_four',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _graceMeta = const VerificationMeta('grace');
  @override
  late final GeneratedColumn<String> grace = GeneratedColumn<String>(
    'grace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevCloseMeta = const VerificationMeta(
    'prevClose',
  );
  @override
  late final GeneratedColumn<String> prevClose = GeneratedColumn<String>(
    'prev_close',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevDueMeta = const VerificationMeta(
    'prevDue',
  );
  @override
  late final GeneratedColumn<String> prevDue = GeneratedColumn<String>(
    'prev_due',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextCloseMeta = const VerificationMeta(
    'nextClose',
  );
  @override
  late final GeneratedColumn<String> nextClose = GeneratedColumn<String>(
    'next_close',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextCloseDaysMeta = const VerificationMeta(
    'nextCloseDays',
  );
  @override
  late final GeneratedColumn<int> nextCloseDays = GeneratedColumn<int>(
    'next_close_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextDueMeta = const VerificationMeta(
    'nextDue',
  );
  @override
  late final GeneratedColumn<String> nextDue = GeneratedColumn<String>(
    'next_due',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextDueDaysMeta = const VerificationMeta(
    'nextDueDays',
  );
  @override
  late final GeneratedColumn<int> nextDueDays = GeneratedColumn<int>(
    'next_due_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annualFeeDateMeta = const VerificationMeta(
    'annualFeeDate',
  );
  @override
  late final GeneratedColumn<String> annualFeeDate = GeneratedColumn<String>(
    'annual_fee_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _annualFeeDaysMeta = const VerificationMeta(
    'annualFeeDays',
  );
  @override
  late final GeneratedColumn<int> annualFeeDays = GeneratedColumn<int>(
    'annual_fee_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prevDueOverdueMeta = const VerificationMeta(
    'prevDueOverdue',
  );
  @override
  late final GeneratedColumn<bool> prevDueOverdue = GeneratedColumn<bool>(
    'prev_due_overdue',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("prev_due_overdue" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardServerId,
    name,
    issuer,
    lastFour,
    grace,
    prevClose,
    prevDue,
    nextClose,
    nextCloseDays,
    nextDue,
    nextDueDays,
    annualFeeDate,
    annualFeeDays,
    prevDueOverdue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_card_tracker_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditCardTrackerCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_server_id')) {
      context.handle(
        _cardServerIdMeta,
        cardServerId.isAcceptableOrUnknown(
          data['card_server_id']!,
          _cardServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cardServerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    }
    if (data.containsKey('last_four')) {
      context.handle(
        _lastFourMeta,
        lastFour.isAcceptableOrUnknown(data['last_four']!, _lastFourMeta),
      );
    }
    if (data.containsKey('grace')) {
      context.handle(
        _graceMeta,
        grace.isAcceptableOrUnknown(data['grace']!, _graceMeta),
      );
    } else if (isInserting) {
      context.missing(_graceMeta);
    }
    if (data.containsKey('prev_close')) {
      context.handle(
        _prevCloseMeta,
        prevClose.isAcceptableOrUnknown(data['prev_close']!, _prevCloseMeta),
      );
    } else if (isInserting) {
      context.missing(_prevCloseMeta);
    }
    if (data.containsKey('prev_due')) {
      context.handle(
        _prevDueMeta,
        prevDue.isAcceptableOrUnknown(data['prev_due']!, _prevDueMeta),
      );
    } else if (isInserting) {
      context.missing(_prevDueMeta);
    }
    if (data.containsKey('next_close')) {
      context.handle(
        _nextCloseMeta,
        nextClose.isAcceptableOrUnknown(data['next_close']!, _nextCloseMeta),
      );
    } else if (isInserting) {
      context.missing(_nextCloseMeta);
    }
    if (data.containsKey('next_close_days')) {
      context.handle(
        _nextCloseDaysMeta,
        nextCloseDays.isAcceptableOrUnknown(
          data['next_close_days']!,
          _nextCloseDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextCloseDaysMeta);
    }
    if (data.containsKey('next_due')) {
      context.handle(
        _nextDueMeta,
        nextDue.isAcceptableOrUnknown(data['next_due']!, _nextDueMeta),
      );
    } else if (isInserting) {
      context.missing(_nextDueMeta);
    }
    if (data.containsKey('next_due_days')) {
      context.handle(
        _nextDueDaysMeta,
        nextDueDays.isAcceptableOrUnknown(
          data['next_due_days']!,
          _nextDueDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextDueDaysMeta);
    }
    if (data.containsKey('annual_fee_date')) {
      context.handle(
        _annualFeeDateMeta,
        annualFeeDate.isAcceptableOrUnknown(
          data['annual_fee_date']!,
          _annualFeeDateMeta,
        ),
      );
    }
    if (data.containsKey('annual_fee_days')) {
      context.handle(
        _annualFeeDaysMeta,
        annualFeeDays.isAcceptableOrUnknown(
          data['annual_fee_days']!,
          _annualFeeDaysMeta,
        ),
      );
    }
    if (data.containsKey('prev_due_overdue')) {
      context.handle(
        _prevDueOverdueMeta,
        prevDueOverdue.isAcceptableOrUnknown(
          data['prev_due_overdue']!,
          _prevDueOverdueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCardTrackerCacheData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCardTrackerCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      ),
      lastFour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_four'],
      ),
      grace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grace'],
      )!,
      prevClose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_close'],
      )!,
      prevDue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_due'],
      )!,
      nextClose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_close'],
      )!,
      nextCloseDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_close_days'],
      )!,
      nextDue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_due'],
      )!,
      nextDueDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_due_days'],
      )!,
      annualFeeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annual_fee_date'],
      ),
      annualFeeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}annual_fee_days'],
      ),
      prevDueOverdue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prev_due_overdue'],
      )!,
    );
  }

  @override
  $CreditCardTrackerCacheTable createAlias(String alias) {
    return $CreditCardTrackerCacheTable(attachedDatabase, alias);
  }
}

class CreditCardTrackerCacheData extends DataClass
    implements Insertable<CreditCardTrackerCacheData> {
  final int id;
  final int cardServerId;
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
  const CreditCardTrackerCacheData({
    required this.id,
    required this.cardServerId,
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_server_id'] = Variable<int>(cardServerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || issuer != null) {
      map['issuer'] = Variable<String>(issuer);
    }
    if (!nullToAbsent || lastFour != null) {
      map['last_four'] = Variable<String>(lastFour);
    }
    map['grace'] = Variable<String>(grace);
    map['prev_close'] = Variable<String>(prevClose);
    map['prev_due'] = Variable<String>(prevDue);
    map['next_close'] = Variable<String>(nextClose);
    map['next_close_days'] = Variable<int>(nextCloseDays);
    map['next_due'] = Variable<String>(nextDue);
    map['next_due_days'] = Variable<int>(nextDueDays);
    if (!nullToAbsent || annualFeeDate != null) {
      map['annual_fee_date'] = Variable<String>(annualFeeDate);
    }
    if (!nullToAbsent || annualFeeDays != null) {
      map['annual_fee_days'] = Variable<int>(annualFeeDays);
    }
    map['prev_due_overdue'] = Variable<bool>(prevDueOverdue);
    return map;
  }

  CreditCardTrackerCacheCompanion toCompanion(bool nullToAbsent) {
    return CreditCardTrackerCacheCompanion(
      id: Value(id),
      cardServerId: Value(cardServerId),
      name: Value(name),
      issuer: issuer == null && nullToAbsent
          ? const Value.absent()
          : Value(issuer),
      lastFour: lastFour == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFour),
      grace: Value(grace),
      prevClose: Value(prevClose),
      prevDue: Value(prevDue),
      nextClose: Value(nextClose),
      nextCloseDays: Value(nextCloseDays),
      nextDue: Value(nextDue),
      nextDueDays: Value(nextDueDays),
      annualFeeDate: annualFeeDate == null && nullToAbsent
          ? const Value.absent()
          : Value(annualFeeDate),
      annualFeeDays: annualFeeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(annualFeeDays),
      prevDueOverdue: Value(prevDueOverdue),
    );
  }

  factory CreditCardTrackerCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCardTrackerCacheData(
      id: serializer.fromJson<int>(json['id']),
      cardServerId: serializer.fromJson<int>(json['cardServerId']),
      name: serializer.fromJson<String>(json['name']),
      issuer: serializer.fromJson<String?>(json['issuer']),
      lastFour: serializer.fromJson<String?>(json['lastFour']),
      grace: serializer.fromJson<String>(json['grace']),
      prevClose: serializer.fromJson<String>(json['prevClose']),
      prevDue: serializer.fromJson<String>(json['prevDue']),
      nextClose: serializer.fromJson<String>(json['nextClose']),
      nextCloseDays: serializer.fromJson<int>(json['nextCloseDays']),
      nextDue: serializer.fromJson<String>(json['nextDue']),
      nextDueDays: serializer.fromJson<int>(json['nextDueDays']),
      annualFeeDate: serializer.fromJson<String?>(json['annualFeeDate']),
      annualFeeDays: serializer.fromJson<int?>(json['annualFeeDays']),
      prevDueOverdue: serializer.fromJson<bool>(json['prevDueOverdue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardServerId': serializer.toJson<int>(cardServerId),
      'name': serializer.toJson<String>(name),
      'issuer': serializer.toJson<String?>(issuer),
      'lastFour': serializer.toJson<String?>(lastFour),
      'grace': serializer.toJson<String>(grace),
      'prevClose': serializer.toJson<String>(prevClose),
      'prevDue': serializer.toJson<String>(prevDue),
      'nextClose': serializer.toJson<String>(nextClose),
      'nextCloseDays': serializer.toJson<int>(nextCloseDays),
      'nextDue': serializer.toJson<String>(nextDue),
      'nextDueDays': serializer.toJson<int>(nextDueDays),
      'annualFeeDate': serializer.toJson<String?>(annualFeeDate),
      'annualFeeDays': serializer.toJson<int?>(annualFeeDays),
      'prevDueOverdue': serializer.toJson<bool>(prevDueOverdue),
    };
  }

  CreditCardTrackerCacheData copyWith({
    int? id,
    int? cardServerId,
    String? name,
    Value<String?> issuer = const Value.absent(),
    Value<String?> lastFour = const Value.absent(),
    String? grace,
    String? prevClose,
    String? prevDue,
    String? nextClose,
    int? nextCloseDays,
    String? nextDue,
    int? nextDueDays,
    Value<String?> annualFeeDate = const Value.absent(),
    Value<int?> annualFeeDays = const Value.absent(),
    bool? prevDueOverdue,
  }) => CreditCardTrackerCacheData(
    id: id ?? this.id,
    cardServerId: cardServerId ?? this.cardServerId,
    name: name ?? this.name,
    issuer: issuer.present ? issuer.value : this.issuer,
    lastFour: lastFour.present ? lastFour.value : this.lastFour,
    grace: grace ?? this.grace,
    prevClose: prevClose ?? this.prevClose,
    prevDue: prevDue ?? this.prevDue,
    nextClose: nextClose ?? this.nextClose,
    nextCloseDays: nextCloseDays ?? this.nextCloseDays,
    nextDue: nextDue ?? this.nextDue,
    nextDueDays: nextDueDays ?? this.nextDueDays,
    annualFeeDate: annualFeeDate.present
        ? annualFeeDate.value
        : this.annualFeeDate,
    annualFeeDays: annualFeeDays.present
        ? annualFeeDays.value
        : this.annualFeeDays,
    prevDueOverdue: prevDueOverdue ?? this.prevDueOverdue,
  );
  CreditCardTrackerCacheData copyWithCompanion(
    CreditCardTrackerCacheCompanion data,
  ) {
    return CreditCardTrackerCacheData(
      id: data.id.present ? data.id.value : this.id,
      cardServerId: data.cardServerId.present
          ? data.cardServerId.value
          : this.cardServerId,
      name: data.name.present ? data.name.value : this.name,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      lastFour: data.lastFour.present ? data.lastFour.value : this.lastFour,
      grace: data.grace.present ? data.grace.value : this.grace,
      prevClose: data.prevClose.present ? data.prevClose.value : this.prevClose,
      prevDue: data.prevDue.present ? data.prevDue.value : this.prevDue,
      nextClose: data.nextClose.present ? data.nextClose.value : this.nextClose,
      nextCloseDays: data.nextCloseDays.present
          ? data.nextCloseDays.value
          : this.nextCloseDays,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      nextDueDays: data.nextDueDays.present
          ? data.nextDueDays.value
          : this.nextDueDays,
      annualFeeDate: data.annualFeeDate.present
          ? data.annualFeeDate.value
          : this.annualFeeDate,
      annualFeeDays: data.annualFeeDays.present
          ? data.annualFeeDays.value
          : this.annualFeeDays,
      prevDueOverdue: data.prevDueOverdue.present
          ? data.prevDueOverdue.value
          : this.prevDueOverdue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardTrackerCacheData(')
          ..write('id: $id, ')
          ..write('cardServerId: $cardServerId, ')
          ..write('name: $name, ')
          ..write('issuer: $issuer, ')
          ..write('lastFour: $lastFour, ')
          ..write('grace: $grace, ')
          ..write('prevClose: $prevClose, ')
          ..write('prevDue: $prevDue, ')
          ..write('nextClose: $nextClose, ')
          ..write('nextCloseDays: $nextCloseDays, ')
          ..write('nextDue: $nextDue, ')
          ..write('nextDueDays: $nextDueDays, ')
          ..write('annualFeeDate: $annualFeeDate, ')
          ..write('annualFeeDays: $annualFeeDays, ')
          ..write('prevDueOverdue: $prevDueOverdue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardServerId,
    name,
    issuer,
    lastFour,
    grace,
    prevClose,
    prevDue,
    nextClose,
    nextCloseDays,
    nextDue,
    nextDueDays,
    annualFeeDate,
    annualFeeDays,
    prevDueOverdue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCardTrackerCacheData &&
          other.id == this.id &&
          other.cardServerId == this.cardServerId &&
          other.name == this.name &&
          other.issuer == this.issuer &&
          other.lastFour == this.lastFour &&
          other.grace == this.grace &&
          other.prevClose == this.prevClose &&
          other.prevDue == this.prevDue &&
          other.nextClose == this.nextClose &&
          other.nextCloseDays == this.nextCloseDays &&
          other.nextDue == this.nextDue &&
          other.nextDueDays == this.nextDueDays &&
          other.annualFeeDate == this.annualFeeDate &&
          other.annualFeeDays == this.annualFeeDays &&
          other.prevDueOverdue == this.prevDueOverdue);
}

class CreditCardTrackerCacheCompanion
    extends UpdateCompanion<CreditCardTrackerCacheData> {
  final Value<int> id;
  final Value<int> cardServerId;
  final Value<String> name;
  final Value<String?> issuer;
  final Value<String?> lastFour;
  final Value<String> grace;
  final Value<String> prevClose;
  final Value<String> prevDue;
  final Value<String> nextClose;
  final Value<int> nextCloseDays;
  final Value<String> nextDue;
  final Value<int> nextDueDays;
  final Value<String?> annualFeeDate;
  final Value<int?> annualFeeDays;
  final Value<bool> prevDueOverdue;
  const CreditCardTrackerCacheCompanion({
    this.id = const Value.absent(),
    this.cardServerId = const Value.absent(),
    this.name = const Value.absent(),
    this.issuer = const Value.absent(),
    this.lastFour = const Value.absent(),
    this.grace = const Value.absent(),
    this.prevClose = const Value.absent(),
    this.prevDue = const Value.absent(),
    this.nextClose = const Value.absent(),
    this.nextCloseDays = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.nextDueDays = const Value.absent(),
    this.annualFeeDate = const Value.absent(),
    this.annualFeeDays = const Value.absent(),
    this.prevDueOverdue = const Value.absent(),
  });
  CreditCardTrackerCacheCompanion.insert({
    this.id = const Value.absent(),
    required int cardServerId,
    required String name,
    this.issuer = const Value.absent(),
    this.lastFour = const Value.absent(),
    required String grace,
    required String prevClose,
    required String prevDue,
    required String nextClose,
    required int nextCloseDays,
    required String nextDue,
    required int nextDueDays,
    this.annualFeeDate = const Value.absent(),
    this.annualFeeDays = const Value.absent(),
    this.prevDueOverdue = const Value.absent(),
  }) : cardServerId = Value(cardServerId),
       name = Value(name),
       grace = Value(grace),
       prevClose = Value(prevClose),
       prevDue = Value(prevDue),
       nextClose = Value(nextClose),
       nextCloseDays = Value(nextCloseDays),
       nextDue = Value(nextDue),
       nextDueDays = Value(nextDueDays);
  static Insertable<CreditCardTrackerCacheData> custom({
    Expression<int>? id,
    Expression<int>? cardServerId,
    Expression<String>? name,
    Expression<String>? issuer,
    Expression<String>? lastFour,
    Expression<String>? grace,
    Expression<String>? prevClose,
    Expression<String>? prevDue,
    Expression<String>? nextClose,
    Expression<int>? nextCloseDays,
    Expression<String>? nextDue,
    Expression<int>? nextDueDays,
    Expression<String>? annualFeeDate,
    Expression<int>? annualFeeDays,
    Expression<bool>? prevDueOverdue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardServerId != null) 'card_server_id': cardServerId,
      if (name != null) 'name': name,
      if (issuer != null) 'issuer': issuer,
      if (lastFour != null) 'last_four': lastFour,
      if (grace != null) 'grace': grace,
      if (prevClose != null) 'prev_close': prevClose,
      if (prevDue != null) 'prev_due': prevDue,
      if (nextClose != null) 'next_close': nextClose,
      if (nextCloseDays != null) 'next_close_days': nextCloseDays,
      if (nextDue != null) 'next_due': nextDue,
      if (nextDueDays != null) 'next_due_days': nextDueDays,
      if (annualFeeDate != null) 'annual_fee_date': annualFeeDate,
      if (annualFeeDays != null) 'annual_fee_days': annualFeeDays,
      if (prevDueOverdue != null) 'prev_due_overdue': prevDueOverdue,
    });
  }

  CreditCardTrackerCacheCompanion copyWith({
    Value<int>? id,
    Value<int>? cardServerId,
    Value<String>? name,
    Value<String?>? issuer,
    Value<String?>? lastFour,
    Value<String>? grace,
    Value<String>? prevClose,
    Value<String>? prevDue,
    Value<String>? nextClose,
    Value<int>? nextCloseDays,
    Value<String>? nextDue,
    Value<int>? nextDueDays,
    Value<String?>? annualFeeDate,
    Value<int?>? annualFeeDays,
    Value<bool>? prevDueOverdue,
  }) {
    return CreditCardTrackerCacheCompanion(
      id: id ?? this.id,
      cardServerId: cardServerId ?? this.cardServerId,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      lastFour: lastFour ?? this.lastFour,
      grace: grace ?? this.grace,
      prevClose: prevClose ?? this.prevClose,
      prevDue: prevDue ?? this.prevDue,
      nextClose: nextClose ?? this.nextClose,
      nextCloseDays: nextCloseDays ?? this.nextCloseDays,
      nextDue: nextDue ?? this.nextDue,
      nextDueDays: nextDueDays ?? this.nextDueDays,
      annualFeeDate: annualFeeDate ?? this.annualFeeDate,
      annualFeeDays: annualFeeDays ?? this.annualFeeDays,
      prevDueOverdue: prevDueOverdue ?? this.prevDueOverdue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardServerId.present) {
      map['card_server_id'] = Variable<int>(cardServerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (lastFour.present) {
      map['last_four'] = Variable<String>(lastFour.value);
    }
    if (grace.present) {
      map['grace'] = Variable<String>(grace.value);
    }
    if (prevClose.present) {
      map['prev_close'] = Variable<String>(prevClose.value);
    }
    if (prevDue.present) {
      map['prev_due'] = Variable<String>(prevDue.value);
    }
    if (nextClose.present) {
      map['next_close'] = Variable<String>(nextClose.value);
    }
    if (nextCloseDays.present) {
      map['next_close_days'] = Variable<int>(nextCloseDays.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<String>(nextDue.value);
    }
    if (nextDueDays.present) {
      map['next_due_days'] = Variable<int>(nextDueDays.value);
    }
    if (annualFeeDate.present) {
      map['annual_fee_date'] = Variable<String>(annualFeeDate.value);
    }
    if (annualFeeDays.present) {
      map['annual_fee_days'] = Variable<int>(annualFeeDays.value);
    }
    if (prevDueOverdue.present) {
      map['prev_due_overdue'] = Variable<bool>(prevDueOverdue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardTrackerCacheCompanion(')
          ..write('id: $id, ')
          ..write('cardServerId: $cardServerId, ')
          ..write('name: $name, ')
          ..write('issuer: $issuer, ')
          ..write('lastFour: $lastFour, ')
          ..write('grace: $grace, ')
          ..write('prevClose: $prevClose, ')
          ..write('prevDue: $prevDue, ')
          ..write('nextClose: $nextClose, ')
          ..write('nextCloseDays: $nextCloseDays, ')
          ..write('nextDue: $nextDue, ')
          ..write('nextDueDays: $nextDueDays, ')
          ..write('annualFeeDate: $annualFeeDate, ')
          ..write('annualFeeDays: $annualFeeDays, ')
          ..write('prevDueOverdue: $prevDueOverdue')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $CreditCardsTable creditCards = $CreditCardsTable(this);
  late final $CreditCardTrackerCacheTable creditCardTrackerCache =
      $CreditCardTrackerCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    persons,
    events,
    occurrences,
    tasks,
    subtasks,
    creditCards,
    creditCardTrackerCache,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String name,
      Value<String> color,
      Value<String> icon,
      Value<String?> description,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> name,
      Value<String> color,
      Value<String> icon,
      Value<String?> description,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                serverId: serverId,
                name: name,
                color: color,
                icon: icon,
                description: description,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String name,
                Value<String> color = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                color: color,
                icon: icon,
                description: description,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String name,
      Value<String?> email,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> name,
      Value<String?> email,
    });

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
          Person,
          PrefetchHooks Function()
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
              }) => PersonsCompanion(
                id: id,
                serverId: serverId,
                name: name,
                email: email,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String name,
                Value<String?> email = const Value.absent(),
              }) => PersonsCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                email: email,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
      Person,
      PrefetchHooks Function()
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String title,
      required int categoryServerId,
      Value<String?> rrule,
      required String dtstart,
      Value<String> priority,
      Value<String?> description,
      Value<bool> isActive,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> title,
      Value<int> categoryServerId,
      Value<String?> rrule,
      Value<String> dtstart,
      Value<String> priority,
      Value<String?> description,
      Value<bool> isActive,
    });

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dtstart => $composableBuilder(
    column: $table.dtstart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dtstart => $composableBuilder(
    column: $table.dtstart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get dtstart =>
      $composableBuilder(column: $table.dtstart, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
          Event,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> categoryServerId = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String> dtstart = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                serverId: serverId,
                title: title,
                categoryServerId: categoryServerId,
                rrule: rrule,
                dtstart: dtstart,
                priority: priority,
                description: description,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String title,
                required int categoryServerId,
                Value<String?> rrule = const Value.absent(),
                required String dtstart,
                Value<String> priority = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                categoryServerId: categoryServerId,
                rrule: rrule,
                dtstart: dtstart,
                priority: priority,
                description: description,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
      Event,
      PrefetchHooks Function()
    >;
typedef $$OccurrencesTableCreateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int eventServerId,
      required String occurrenceDate,
      Value<String> status,
      Value<String?> notes,
      Value<int> syncStatus,
    });
typedef $$OccurrencesTableUpdateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> eventServerId,
      Value<String> occurrenceDate,
      Value<String> status,
      Value<String?> notes,
      Value<int> syncStatus,
    });

class $$OccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventServerId => $composableBuilder(
    column: $table.eventServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventServerId => $composableBuilder(
    column: $table.eventServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get eventServerId => $composableBuilder(
    column: $table.eventServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          Occurrence,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (
            Occurrence,
            BaseReferences<_$AppDatabase, $OccurrencesTable, Occurrence>,
          ),
          Occurrence,
          PrefetchHooks Function()
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> eventServerId = const Value.absent(),
                Value<String> occurrenceDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                serverId: serverId,
                eventServerId: eventServerId,
                occurrenceDate: occurrenceDate,
                status: status,
                notes: notes,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int eventServerId,
                required String occurrenceDate,
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                serverId: serverId,
                eventServerId: eventServerId,
                occurrenceDate: occurrenceDate,
                status: status,
                notes: notes,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      Occurrence,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (
        Occurrence,
        BaseReferences<_$AppDatabase, $OccurrencesTable, Occurrence>,
      ),
      Occurrence,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String title,
      Value<String?> description,
      Value<String> status,
      Value<String> priority,
      Value<int?> assigneeServerId,
      Value<int?> categoryServerId,
      Value<String?> dueDate,
      Value<int?> estimatedMinutes,
      Value<String> recurrence,
      Value<int?> occurrenceServerId,
      Value<int> syncStatus,
      required String createdAt,
      required String updatedAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<String> priority,
      Value<int?> assigneeServerId,
      Value<int?> categoryServerId,
      Value<String?> dueDate,
      Value<int?> estimatedMinutes,
      Value<String> recurrence,
      Value<int?> occurrenceServerId,
      Value<int> syncStatus,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assigneeServerId => $composableBuilder(
    column: $table.assigneeServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceServerId => $composableBuilder(
    column: $table.occurrenceServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assigneeServerId => $composableBuilder(
    column: $table.assigneeServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceServerId => $composableBuilder(
    column: $table.occurrenceServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get assigneeServerId => $composableBuilder(
    column: $table.assigneeServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryServerId => $composableBuilder(
    column: $table.categoryServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurrenceServerId => $composableBuilder(
    column: $table.occurrenceServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int?> assigneeServerId = const Value.absent(),
                Value<int?> categoryServerId = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<int?> occurrenceServerId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                assigneeServerId: assigneeServerId,
                categoryServerId: categoryServerId,
                dueDate: dueDate,
                estimatedMinutes: estimatedMinutes,
                recurrence: recurrence,
                occurrenceServerId: occurrenceServerId,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int?> assigneeServerId = const Value.absent(),
                Value<int?> categoryServerId = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<int?> occurrenceServerId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => TasksCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                assigneeServerId: assigneeServerId,
                categoryServerId: categoryServerId,
                dueDate: dueDate,
                estimatedMinutes: estimatedMinutes,
                recurrence: recurrence,
                occurrenceServerId: occurrenceServerId,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$SubtasksTableCreateCompanionBuilder =
    SubtasksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int taskLocalId,
      Value<int?> taskServerId,
      required String title,
      Value<String> status,
      Value<String?> dueDate,
      Value<int> order,
      Value<int> syncStatus,
    });
typedef $$SubtasksTableUpdateCompanionBuilder =
    SubtasksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> taskLocalId,
      Value<int?> taskServerId,
      Value<String> title,
      Value<String> status,
      Value<String?> dueDate,
      Value<int> order,
      Value<int> syncStatus,
    });

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taskLocalId => $composableBuilder(
    column: $table.taskLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taskServerId => $composableBuilder(
    column: $table.taskServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskLocalId => $composableBuilder(
    column: $table.taskLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskServerId => $composableBuilder(
    column: $table.taskServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get taskLocalId => $composableBuilder(
    column: $table.taskLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taskServerId => $composableBuilder(
    column: $table.taskServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          Subtask,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (Subtask, BaseReferences<_$AppDatabase, $SubtasksTable, Subtask>),
          Subtask,
          PrefetchHooks Function()
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> taskLocalId = const Value.absent(),
                Value<int?> taskServerId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                serverId: serverId,
                taskLocalId: taskLocalId,
                taskServerId: taskServerId,
                title: title,
                status: status,
                dueDate: dueDate,
                order: order,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int taskLocalId,
                Value<int?> taskServerId = const Value.absent(),
                required String title,
                Value<String> status = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => SubtasksCompanion.insert(
                id: id,
                serverId: serverId,
                taskLocalId: taskLocalId,
                taskServerId: taskServerId,
                title: title,
                status: status,
                dueDate: dueDate,
                order: order,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      Subtask,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (Subtask, BaseReferences<_$AppDatabase, $SubtasksTable, Subtask>),
      Subtask,
      PrefetchHooks Function()
    >;
typedef $$CreditCardsTableCreateCompanionBuilder =
    CreditCardsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String name,
      Value<String?> issuer,
      Value<String?> lastFour,
      Value<int?> statementCloseDay,
      Value<int?> gracePeriodDays,
      Value<String?> weekendShift,
      Value<int?> cycleDays,
      Value<String?> cycleReferenceDate,
      Value<int?> dueDaySameMonth,
      Value<int?> dueDayNextMonth,
      Value<int?> annualFeeMonth,
      Value<bool> isActive,
      Value<int> syncStatus,
    });
typedef $$CreditCardsTableUpdateCompanionBuilder =
    CreditCardsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> name,
      Value<String?> issuer,
      Value<String?> lastFour,
      Value<int?> statementCloseDay,
      Value<int?> gracePeriodDays,
      Value<String?> weekendShift,
      Value<int?> cycleDays,
      Value<String?> cycleReferenceDate,
      Value<int?> dueDaySameMonth,
      Value<int?> dueDayNextMonth,
      Value<int?> annualFeeMonth,
      Value<bool> isActive,
      Value<int> syncStatus,
    });

class $$CreditCardsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFour => $composableBuilder(
    column: $table.lastFour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statementCloseDay => $composableBuilder(
    column: $table.statementCloseDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gracePeriodDays => $composableBuilder(
    column: $table.gracePeriodDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekendShift => $composableBuilder(
    column: $table.weekendShift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleDays => $composableBuilder(
    column: $table.cycleDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleReferenceDate => $composableBuilder(
    column: $table.cycleReferenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDaySameMonth => $composableBuilder(
    column: $table.dueDaySameMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDayNextMonth => $composableBuilder(
    column: $table.dueDayNextMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get annualFeeMonth => $composableBuilder(
    column: $table.annualFeeMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreditCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFour => $composableBuilder(
    column: $table.lastFour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementCloseDay => $composableBuilder(
    column: $table.statementCloseDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gracePeriodDays => $composableBuilder(
    column: $table.gracePeriodDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekendShift => $composableBuilder(
    column: $table.weekendShift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleDays => $composableBuilder(
    column: $table.cycleDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleReferenceDate => $composableBuilder(
    column: $table.cycleReferenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDaySameMonth => $composableBuilder(
    column: $table.dueDaySameMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDayNextMonth => $composableBuilder(
    column: $table.dueDayNextMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get annualFeeMonth => $composableBuilder(
    column: $table.annualFeeMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get lastFour =>
      $composableBuilder(column: $table.lastFour, builder: (column) => column);

  GeneratedColumn<int> get statementCloseDay => $composableBuilder(
    column: $table.statementCloseDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gracePeriodDays => $composableBuilder(
    column: $table.gracePeriodDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weekendShift => $composableBuilder(
    column: $table.weekendShift,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleDays =>
      $composableBuilder(column: $table.cycleDays, builder: (column) => column);

  GeneratedColumn<String> get cycleReferenceDate => $composableBuilder(
    column: $table.cycleReferenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDaySameMonth => $composableBuilder(
    column: $table.dueDaySameMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDayNextMonth => $composableBuilder(
    column: $table.dueDayNextMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get annualFeeMonth => $composableBuilder(
    column: $table.annualFeeMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$CreditCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditCardsTable,
          CreditCard,
          $$CreditCardsTableFilterComposer,
          $$CreditCardsTableOrderingComposer,
          $$CreditCardsTableAnnotationComposer,
          $$CreditCardsTableCreateCompanionBuilder,
          $$CreditCardsTableUpdateCompanionBuilder,
          (
            CreditCard,
            BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard>,
          ),
          CreditCard,
          PrefetchHooks Function()
        > {
  $$CreditCardsTableTableManager(_$AppDatabase db, $CreditCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> issuer = const Value.absent(),
                Value<String?> lastFour = const Value.absent(),
                Value<int?> statementCloseDay = const Value.absent(),
                Value<int?> gracePeriodDays = const Value.absent(),
                Value<String?> weekendShift = const Value.absent(),
                Value<int?> cycleDays = const Value.absent(),
                Value<String?> cycleReferenceDate = const Value.absent(),
                Value<int?> dueDaySameMonth = const Value.absent(),
                Value<int?> dueDayNextMonth = const Value.absent(),
                Value<int?> annualFeeMonth = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => CreditCardsCompanion(
                id: id,
                serverId: serverId,
                name: name,
                issuer: issuer,
                lastFour: lastFour,
                statementCloseDay: statementCloseDay,
                gracePeriodDays: gracePeriodDays,
                weekendShift: weekendShift,
                cycleDays: cycleDays,
                cycleReferenceDate: cycleReferenceDate,
                dueDaySameMonth: dueDaySameMonth,
                dueDayNextMonth: dueDayNextMonth,
                annualFeeMonth: annualFeeMonth,
                isActive: isActive,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String name,
                Value<String?> issuer = const Value.absent(),
                Value<String?> lastFour = const Value.absent(),
                Value<int?> statementCloseDay = const Value.absent(),
                Value<int?> gracePeriodDays = const Value.absent(),
                Value<String?> weekendShift = const Value.absent(),
                Value<int?> cycleDays = const Value.absent(),
                Value<String?> cycleReferenceDate = const Value.absent(),
                Value<int?> dueDaySameMonth = const Value.absent(),
                Value<int?> dueDayNextMonth = const Value.absent(),
                Value<int?> annualFeeMonth = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
              }) => CreditCardsCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                issuer: issuer,
                lastFour: lastFour,
                statementCloseDay: statementCloseDay,
                gracePeriodDays: gracePeriodDays,
                weekendShift: weekendShift,
                cycleDays: cycleDays,
                cycleReferenceDate: cycleReferenceDate,
                dueDaySameMonth: dueDaySameMonth,
                dueDayNextMonth: dueDayNextMonth,
                annualFeeMonth: annualFeeMonth,
                isActive: isActive,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreditCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditCardsTable,
      CreditCard,
      $$CreditCardsTableFilterComposer,
      $$CreditCardsTableOrderingComposer,
      $$CreditCardsTableAnnotationComposer,
      $$CreditCardsTableCreateCompanionBuilder,
      $$CreditCardsTableUpdateCompanionBuilder,
      (
        CreditCard,
        BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard>,
      ),
      CreditCard,
      PrefetchHooks Function()
    >;
typedef $$CreditCardTrackerCacheTableCreateCompanionBuilder =
    CreditCardTrackerCacheCompanion Function({
      Value<int> id,
      required int cardServerId,
      required String name,
      Value<String?> issuer,
      Value<String?> lastFour,
      required String grace,
      required String prevClose,
      required String prevDue,
      required String nextClose,
      required int nextCloseDays,
      required String nextDue,
      required int nextDueDays,
      Value<String?> annualFeeDate,
      Value<int?> annualFeeDays,
      Value<bool> prevDueOverdue,
    });
typedef $$CreditCardTrackerCacheTableUpdateCompanionBuilder =
    CreditCardTrackerCacheCompanion Function({
      Value<int> id,
      Value<int> cardServerId,
      Value<String> name,
      Value<String?> issuer,
      Value<String?> lastFour,
      Value<String> grace,
      Value<String> prevClose,
      Value<String> prevDue,
      Value<String> nextClose,
      Value<int> nextCloseDays,
      Value<String> nextDue,
      Value<int> nextDueDays,
      Value<String?> annualFeeDate,
      Value<int?> annualFeeDays,
      Value<bool> prevDueOverdue,
    });

class $$CreditCardTrackerCacheTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardTrackerCacheTable> {
  $$CreditCardTrackerCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardServerId => $composableBuilder(
    column: $table.cardServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFour => $composableBuilder(
    column: $table.lastFour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grace => $composableBuilder(
    column: $table.grace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prevClose => $composableBuilder(
    column: $table.prevClose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prevDue => $composableBuilder(
    column: $table.prevDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextClose => $composableBuilder(
    column: $table.nextClose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextCloseDays => $composableBuilder(
    column: $table.nextCloseDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextDueDays => $composableBuilder(
    column: $table.nextDueDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annualFeeDate => $composableBuilder(
    column: $table.annualFeeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get annualFeeDays => $composableBuilder(
    column: $table.annualFeeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get prevDueOverdue => $composableBuilder(
    column: $table.prevDueOverdue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreditCardTrackerCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardTrackerCacheTable> {
  $$CreditCardTrackerCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardServerId => $composableBuilder(
    column: $table.cardServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFour => $composableBuilder(
    column: $table.lastFour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grace => $composableBuilder(
    column: $table.grace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prevClose => $composableBuilder(
    column: $table.prevClose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prevDue => $composableBuilder(
    column: $table.prevDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextClose => $composableBuilder(
    column: $table.nextClose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextCloseDays => $composableBuilder(
    column: $table.nextCloseDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextDueDays => $composableBuilder(
    column: $table.nextDueDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annualFeeDate => $composableBuilder(
    column: $table.annualFeeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get annualFeeDays => $composableBuilder(
    column: $table.annualFeeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get prevDueOverdue => $composableBuilder(
    column: $table.prevDueOverdue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditCardTrackerCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardTrackerCacheTable> {
  $$CreditCardTrackerCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cardServerId => $composableBuilder(
    column: $table.cardServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get lastFour =>
      $composableBuilder(column: $table.lastFour, builder: (column) => column);

  GeneratedColumn<String> get grace =>
      $composableBuilder(column: $table.grace, builder: (column) => column);

  GeneratedColumn<String> get prevClose =>
      $composableBuilder(column: $table.prevClose, builder: (column) => column);

  GeneratedColumn<String> get prevDue =>
      $composableBuilder(column: $table.prevDue, builder: (column) => column);

  GeneratedColumn<String> get nextClose =>
      $composableBuilder(column: $table.nextClose, builder: (column) => column);

  GeneratedColumn<int> get nextCloseDays => $composableBuilder(
    column: $table.nextCloseDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumn<int> get nextDueDays => $composableBuilder(
    column: $table.nextDueDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get annualFeeDate => $composableBuilder(
    column: $table.annualFeeDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get annualFeeDays => $composableBuilder(
    column: $table.annualFeeDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get prevDueOverdue => $composableBuilder(
    column: $table.prevDueOverdue,
    builder: (column) => column,
  );
}

class $$CreditCardTrackerCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditCardTrackerCacheTable,
          CreditCardTrackerCacheData,
          $$CreditCardTrackerCacheTableFilterComposer,
          $$CreditCardTrackerCacheTableOrderingComposer,
          $$CreditCardTrackerCacheTableAnnotationComposer,
          $$CreditCardTrackerCacheTableCreateCompanionBuilder,
          $$CreditCardTrackerCacheTableUpdateCompanionBuilder,
          (
            CreditCardTrackerCacheData,
            BaseReferences<
              _$AppDatabase,
              $CreditCardTrackerCacheTable,
              CreditCardTrackerCacheData
            >,
          ),
          CreditCardTrackerCacheData,
          PrefetchHooks Function()
        > {
  $$CreditCardTrackerCacheTableTableManager(
    _$AppDatabase db,
    $CreditCardTrackerCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardTrackerCacheTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CreditCardTrackerCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CreditCardTrackerCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardServerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> issuer = const Value.absent(),
                Value<String?> lastFour = const Value.absent(),
                Value<String> grace = const Value.absent(),
                Value<String> prevClose = const Value.absent(),
                Value<String> prevDue = const Value.absent(),
                Value<String> nextClose = const Value.absent(),
                Value<int> nextCloseDays = const Value.absent(),
                Value<String> nextDue = const Value.absent(),
                Value<int> nextDueDays = const Value.absent(),
                Value<String?> annualFeeDate = const Value.absent(),
                Value<int?> annualFeeDays = const Value.absent(),
                Value<bool> prevDueOverdue = const Value.absent(),
              }) => CreditCardTrackerCacheCompanion(
                id: id,
                cardServerId: cardServerId,
                name: name,
                issuer: issuer,
                lastFour: lastFour,
                grace: grace,
                prevClose: prevClose,
                prevDue: prevDue,
                nextClose: nextClose,
                nextCloseDays: nextCloseDays,
                nextDue: nextDue,
                nextDueDays: nextDueDays,
                annualFeeDate: annualFeeDate,
                annualFeeDays: annualFeeDays,
                prevDueOverdue: prevDueOverdue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardServerId,
                required String name,
                Value<String?> issuer = const Value.absent(),
                Value<String?> lastFour = const Value.absent(),
                required String grace,
                required String prevClose,
                required String prevDue,
                required String nextClose,
                required int nextCloseDays,
                required String nextDue,
                required int nextDueDays,
                Value<String?> annualFeeDate = const Value.absent(),
                Value<int?> annualFeeDays = const Value.absent(),
                Value<bool> prevDueOverdue = const Value.absent(),
              }) => CreditCardTrackerCacheCompanion.insert(
                id: id,
                cardServerId: cardServerId,
                name: name,
                issuer: issuer,
                lastFour: lastFour,
                grace: grace,
                prevClose: prevClose,
                prevDue: prevDue,
                nextClose: nextClose,
                nextCloseDays: nextCloseDays,
                nextDue: nextDue,
                nextDueDays: nextDueDays,
                annualFeeDate: annualFeeDate,
                annualFeeDays: annualFeeDays,
                prevDueOverdue: prevDueOverdue,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreditCardTrackerCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditCardTrackerCacheTable,
      CreditCardTrackerCacheData,
      $$CreditCardTrackerCacheTableFilterComposer,
      $$CreditCardTrackerCacheTableOrderingComposer,
      $$CreditCardTrackerCacheTableAnnotationComposer,
      $$CreditCardTrackerCacheTableCreateCompanionBuilder,
      $$CreditCardTrackerCacheTableUpdateCompanionBuilder,
      (
        CreditCardTrackerCacheData,
        BaseReferences<
          _$AppDatabase,
          $CreditCardTrackerCacheTable,
          CreditCardTrackerCacheData
        >,
      ),
      CreditCardTrackerCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$OccurrencesTableTableManager get occurrences =>
      $$OccurrencesTableTableManager(_db, _db.occurrences);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db, _db.creditCards);
  $$CreditCardTrackerCacheTableTableManager get creditCardTrackerCache =>
      $$CreditCardTrackerCacheTableTableManager(
        _db,
        _db.creditCardTrackerCache,
      );
}
