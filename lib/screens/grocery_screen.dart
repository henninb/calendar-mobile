import 'dart:developer' as dev;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../database/app_database.dart';
import '../providers/providers.dart';

// ── Grocery Screen ────────────────────────────────────────────────────────────

/// Top-level grocery screen: Lists / Pantry / Stores tabs.
class GroceryScreen extends StatelessWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.shopping_cart_outlined),
                text: 'Lists',
              ),
              Tab(
                icon: Icon(Icons.kitchen_outlined),
                text: 'Pantry',
              ),
              Tab(
                icon: Icon(Icons.store_outlined),
                text: 'Stores',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ListsTab(),
                _OnHandTab(),
                _StoresTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lists Tab ─────────────────────────────────────────────────────────────────

class _ListsTab extends ConsumerStatefulWidget {
  const _ListsTab();

  @override
  ConsumerState<_ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends ConsumerState<_ListsTab> {
  int? _selectedListLocalId;

  @override
  Widget build(BuildContext context) {
    if (_selectedListLocalId != null) {
      return _ListDetailView(
        listLocalId: _selectedListLocalId!,
        onBack: () => setState(() => _selectedListLocalId = null),
      );
    }
    return _ListsOverview(
      onListSelected: (id) =>
          setState(() => _selectedListLocalId = id),
    );
  }
}

// ── Lists Overview ────────────────────────────────────────────────────────────

class _ListsOverview extends ConsumerWidget {
  const _ListsOverview({required this.onListSelected});

  final ValueChanged<int> onListSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(groceryListsProvider);
    final allItemsAsync = ref.watch(groceryListItemsProvider);

    return Scaffold(
      body: listsAsync.when(
        data: (lists) {
          final allItems = allItemsAsync.asData?.value ?? [];
          final counts = <int, (int, int)>{};
          for (final item in allItems) {
            final c = counts[item.listLocalId] ?? (0, 0);
            counts[item.listLocalId] = (
              c.$1 + 1,
              item.status == 'purchased' ? c.$2 + 1 : c.$2,
            );
          }
          if (lists.isEmpty) {
            return const Center(
              child: Text('No grocery lists yet'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lists.length,
            itemBuilder: (ctx, i) => _GroceryListCard(
              list: lists[i],
              counts: counts[lists[i].id],
              onTap: () => onListSelected(lists[i].id),
              onDelete: () => _deleteList(ref, lists[i]),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteList(WidgetRef ref, GroceryList list) async {
    await ref.read(dbProvider).markGroceryListDeleted(list.id);
    ref.read(syncStateProvider.notifier).syncIfOnline();
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateListSheet(),
    );
  }
}

// ── Grocery List Card ─────────────────────────────────────────────────────────

class _GroceryListCard extends StatelessWidget {
  const _GroceryListCard({
    required this.list,
    required this.counts,
    required this.onTap,
    required this.onDelete,
  });

  final GroceryList list;
  final (int, int)? counts;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _statusColor = <String, Color>{
    'draft': AppColors.skippedFg,
    'active': AppColors.warningFg,
    'completed': AppColors.completedFg,
  };

  @override
  Widget build(BuildContext context) {
    final (total, done) = counts ?? (0, 0);
    final color = _statusColor[list.status] ?? AppColors.skippedFg;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      list.status,
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                    ),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: done / total,
                        backgroundColor:
                            AppColors.textMuted.withValues(alpha: 0.2),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$done/$total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (list.shoppingDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      list.shoppingDate!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── List Detail View ──────────────────────────────────────────────────────────

class _ListDetailView extends ConsumerWidget {
  const _ListDetailView({
    required this.listLocalId,
    required this.onBack,
  });

  final int listLocalId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(groceryListsProvider).asData?.value ?? [];
    final list = lists.where((l) => l.id == listLocalId).firstOrNull;

    if (list == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = ref
            .watch(groceryListItemsForListProvider(listLocalId))
            .asData?.value ??
        [];
    final catalog = ref.watch(groceryItemsProvider).asData?.value ?? [];
    final catalogById = {
      for (final c in catalog)
        if (c.serverId != null) c.serverId!: c,
    };

    final needed =
        items.where((i) => i.status == 'needed').toList();
    final purchased =
        items.where((i) => i.status == 'purchased').toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DetailHeader(list: list, onBack: onBack)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ListItemRow(
                listItem: needed[i],
                catalogItem: catalogById[needed[i].itemServerId],
                onToggle: () => _toggle(ref, needed[i]),
                onDelete: () => _removeItem(ref, needed[i]),
              ),
              childCount: needed.length,
            ),
          ),
          if (purchased.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Purchased',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ListItemRow(
                listItem: purchased[i],
                catalogItem: catalogById[purchased[i].itemServerId],
                onToggle: () => _toggle(ref, purchased[i]),
                onDelete: () => _removeItem(ref, purchased[i]),
                faded: true,
              ),
              childCount: purchased.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: list.status != 'completed'
          ? FloatingActionButton(
              onPressed: () =>
                  _showAddItemSheet(context, ref, list, catalog),
              child: const Icon(Icons.add_shopping_cart_outlined),
            )
          : null,
    );
  }

  Future<void> _toggle(WidgetRef ref, GroceryListItem item) async {
    final next =
        item.status == 'needed' ? 'purchased' : 'needed';
    await ref.read(dbProvider).updateGroceryListItemStatus(item.id, next);
    ref.read(syncStateProvider.notifier).syncIfOnline();
  }

  Future<void> _removeItem(WidgetRef ref, GroceryListItem item) async {
    await ref.read(dbProvider).markGroceryListItemDeleted(item.id);
    ref.read(syncStateProvider.notifier).syncIfOnline();
  }

  void _showAddItemSheet(
    BuildContext context,
    WidgetRef ref,
    GroceryList list,
    List<GroceryItem> catalog,
  ) {
    final inList = ref
            .read(groceryListItemsForListProvider(listLocalId))
            .asData?.value ??

        [];
    final inListServerIds =
        inList.map((i) => i.itemServerId).toSet();
    final available = catalog
        .where(
          (c) =>
              c.serverId != null &&
              !inListServerIds.contains(c.serverId),
        )
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddItemSheet(list: list, items: available),
    );
  }
}

// ── Detail Header ─────────────────────────────────────────────────────────────

class _DetailHeader extends ConsumerWidget {
  const _DetailHeader({required this.list, required this.onBack});

  final GroceryList list;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdvance = list.status != 'completed';
    final advanceLabel =
        list.status == 'draft' ? 'Start' : 'Complete';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              list.name,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canAdvance)
            TextButton(
              onPressed: () => _advance(ref),
              child: Text(advanceLabel),
            ),
        ],
      ),
    );
  }

  Future<void> _advance(WidgetRef ref) async {
    final next =
        list.status == 'draft' ? 'active' : 'completed';
    await ref.read(dbProvider).updateGroceryListStatus(list.id, next);
    ref.read(syncStateProvider.notifier).syncIfOnline();
  }
}

// ── List Item Row ─────────────────────────────────────────────────────────────

class _ListItemRow extends StatelessWidget {
  const _ListItemRow({
    required this.listItem,
    required this.catalogItem,
    required this.onToggle,
    required this.onDelete,
    this.faded = false,
  });

  final GroceryListItem listItem;
  final GroceryItem? catalogItem;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final name = catalogItem?.name ?? 'Item #${listItem.itemServerId}';
    final qty = _fmtListQty(listItem.quantity, listItem.unit);

    return Opacity(
      opacity: faded ? 0.5 : 1.0,
      child: ListTile(
        leading: Checkbox(
          value: listItem.status == 'purchased',
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          name,
          style: faded
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                )
              : null,
        ),
        subtitle: qty.isNotEmpty ? Text(qty) : null,
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 18),
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
        ),
        dense: true,
      ),
    );
  }

}

// ── Create List Sheet ─────────────────────────────────────────────────────────

class _CreateListSheet extends ConsumerStatefulWidget {
  const _CreateListSheet();

  @override
  ConsumerState<_CreateListSheet> createState() =>
      _CreateListSheetState();
}

class _CreateListSheetState extends ConsumerState<_CreateListSheet> {
  final _nameCtrl = TextEditingController();
  int? _storeServerId;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stores =
        ref.watch(groceryStoresProvider).asData?.value ?? [];
    final canSave =
        _nameCtrl.text.trim().isNotEmpty && !_saving;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Shopping List',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'List name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            onSubmitted: canSave ? (_) => _save() : null,
          ),
          if (stores.isNotEmpty) ...[
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Store (optional)',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _storeServerId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— none —'),
                    ),
                    ...stores.map(
                      (s) => DropdownMenuItem(
                        value: s.serverId,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _storeServerId = v),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(dbProvider).insertGroceryList(
            GroceryListsCompanion(
              name: Value(name),
              status: const Value('draft'),
              storeServerId: Value(_storeServerId),
              syncStatus: Value(SyncStatus.pendingCreate.value),
            ),
          );
      ref.read(syncStateProvider.notifier).syncIfOnline();
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      dev.log('_CreateListSheet._save: $e', name: 'grocery', level: 900, stackTrace: st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create list. Please try again.')),
        );
      }
    }
  }
}

// ── Add Item Sheet ────────────────────────────────────────────────────────────

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({
    required this.list,
    required this.items,
  });

  final GroceryList list;
  final List<GroceryItem> items;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  GroceryItem? _selected;
  double _qty = 1.0;
  late String _unit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unit = widget.items.isNotEmpty
        ? widget.items.first.defaultUnit
        : 'each';
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selected != null && !_saving;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Item to "${widget.list.name}"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (widget.items.isEmpty)
            const Text(
              'No catalog items available. Add items via the web app.',
            )
          else ...[
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Item *',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GroceryItem>(
                  value: _selected,
                  isExpanded: true,
                  hint: const Text('Select item'),
                  items: widget.items
                      .map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(i.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selected = v;
                      if (v != null) _unit = v.defaultUnit;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _qty.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        setState(() => _qty = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                    value: _unit,
                    isExpanded: true,
                    items: GroceryConstants.units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(u),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _unit = v);
                    },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final item = _selected;
    if (item?.serverId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(dbProvider).insertGroceryListItem(
            GroceryListItemsCompanion(
              listLocalId: Value(widget.list.id),
              listServerId: Value(widget.list.serverId),
              itemServerId: Value(item!.serverId!),
              quantity: Value(_qty),
              unit: Value(_unit),
              status: const Value('needed'),
              syncStatus: Value(SyncStatus.pendingCreate.value),
            ),
          );
      ref.read(syncStateProvider.notifier).syncIfOnline();
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      dev.log('_AddItemSheet._save: $e', name: 'grocery', level: 900, stackTrace: st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item. Please try again.')),
        );
      }
    }
  }
}

// ── Quantity formatting helpers ───────────────────────────────────────────────

// Shopping-list style: '× N' for each quantities; '' for exactly 1.
String _fmtListQty(double qty, String unit) {
  if (unit == 'each') {
    if (qty == qty.roundToDouble()) return qty == 1.0 ? '' : '× ${qty.toInt()}';
    return '× $qty';
  }
  final n = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
  return '$n $unit';
}

// Pantry/on-hand style: always show the raw number.
String _fmtOnHandQty(double qty, String unit) {
  final n = qty == qty.roundToDouble()
      ? qty.toInt().toString()
      : qty.toStringAsFixed(2);
  return unit == 'each' ? n : '$n $unit';
}

// ── On Hand Tab ───────────────────────────────────────────────────────────────

class _OnHandTab extends ConsumerStatefulWidget {
  const _OnHandTab();

  @override
  ConsumerState<_OnHandTab> createState() => _OnHandTabState();
}

class _OnHandTabState extends ConsumerState<_OnHandTab> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(groceryItemsProvider).asData?.value ?? [];
    final onHand = ref.watch(groceryOnHandProvider).asData?.value ?? [];
    final onHandByItem = {
      for (final o in onHand) o.itemServerId: o,
    };

    final visible = _filter.isEmpty
        ? items
        : items
            .where(
              (i) => i.name.toLowerCase().contains(
                    _filter.toLowerCase(),
                  ),
            )
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search items…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No items'))
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (ctx, i) {
                    final item = visible[i];
                    final oh = item.serverId != null
                        ? onHandByItem[item.serverId]
                        : null;
                    return ListTile(
                      title: Text(item.name),
                      trailing: oh != null
                          ? Text(
                              _fmtOnHandQty(oh.quantity, oh.unit),
                              style: TextStyle(
                                color: oh.quantity > 0
                                    ? null
                                    : AppColors.overdueFg,
                              ),
                            )
                          : const Text(
                              '—',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                      dense: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

}

// ── Stores Tab ────────────────────────────────────────────────────────────────

class _StoresTab extends ConsumerWidget {
  const _StoresTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(groceryStoresProvider);

    return Scaffold(
      body: storesAsync.when(
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(child: Text('No stores yet'));
          }
          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (ctx, i) {
              final store = stores[i];
              return ListTile(
                leading: const Icon(Icons.store_outlined),
                title: Text(store.name),
                subtitle: store.location != null
                    ? Text(store.location!)
                    : null,
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateStoreSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateStoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateStoreSheet(),
    );
  }
}

// ── Create Store Sheet ────────────────────────────────────────────────────────

class _CreateStoreSheet extends ConsumerStatefulWidget {
  const _CreateStoreSheet();

  @override
  ConsumerState<_CreateStoreSheet> createState() =>
      _CreateStoreSheetState();
}

class _CreateStoreSheetState extends ConsumerState<_CreateStoreSheet> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _nameCtrl.text.trim().isNotEmpty && !_saving;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Store',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Store name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: canSave ? (_) => _save() : null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final location = _locationCtrl.text.trim();
    try {
      await ref.read(dbProvider).insertGroceryStore(
            GroceryStoresCompanion(
              name: Value(name),
              location: Value(location.isNotEmpty ? location : null),
              isActive: const Value(true),
              syncStatus: Value(SyncStatus.pendingCreate.value),
            ),
          );
      ref.read(syncStateProvider.notifier).syncIfOnline();
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      dev.log('_CreateStoreSheet._save: $e', name: 'grocery', level: 900, stackTrace: st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create store. Please try again.')),
        );
      }
    }
  }
}
