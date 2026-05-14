import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/sheet_handle.dart';
import '../database/app_database.dart';
import '../providers/providers.dart';

class CreditCardScreen extends ConsumerWidget {
  const CreditCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerAsync = ref.watch(trackerCacheProvider);
    final bg = AppColors.of(context).background;

    return trackerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Failed to load credit cards — try refreshing')),
      data: (rows) {
        if (rows.isEmpty) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: Text('No credit cards cached.\nPull to refresh when online.', textAlign: TextAlign.center, style: AppText.small)),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showCardForm(context, ref, null),
              child: const Icon(Icons.add),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          body: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _TrackerCard(row: rows[i]),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCardForm(context, ref, null),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showCardForm(BuildContext context, WidgetRef ref, CreditCard? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CardForm(existing: existing),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.row});

  final CreditCardTrackerCacheData row;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final dueBgColor = row.nextDueDays <= 3
        ? colors.overdueBg
        : row.nextDueDays <= 7
            ? colors.warningBg
            : colors.surface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (row.issuer != null)
                        Text(row.issuer!, style: AppText.small),
                    ],
                  ),
                ),
                if (row.lastFour != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.tableHeader,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Text('••••${row.lastFour}', style: AppText.mono),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Date grid
            Table(
              children: [
                _tableRow('Grace', row.grace, 'Prev Close', row.prevClose),
                const TableRow(children: [SizedBox(height: 6), SizedBox(height: 6), SizedBox(height: 6), SizedBox(height: 6)]),
                _tableRow('Prev Due', row.prevDue, 'Next Close', row.nextClose),
                const TableRow(children: [SizedBox(height: 6), SizedBox(height: 6), SizedBox(height: 6), SizedBox(height: 6)]),
              ],
            ),
            // Next Due — highlighted
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: dueBgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: row.nextDueDays <= 3 ? colors.overdueFg : colors.divider,
                  width: row.nextDueDays <= 3 ? 1 : 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Next Due', style: AppText.label),
                  Row(
                    children: [
                      Text(
                        row.nextDue,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: row.nextDueDays <= 3
                              ? AppColors.ccOverdue
                              : row.nextDueDays <= 7
                                  ? AppColors.ccSoon
                                  : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _DaysChip(days: row.nextDueDays),
                    ],
                  ),
                ],
              ),
            ),
            if (row.annualFeeDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Annual Fee', style: AppText.label),
                  Text(
                    '${row.annualFeeDate}${row.annualFeeDays != null ? ' (${row.annualFeeDays}d)' : ''}',
                    style: AppText.small,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static TableRow _tableRow(String l1, String v1, String l2, String v2) {
    return TableRow(
      children: [
        Text(l1, style: AppText.label),
        Text(v1, style: AppText.small.copyWith(fontWeight: FontWeight.w500)),
        Text(l2, style: AppText.label),
        Text(v2, style: AppText.small.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (bg, fg) = days <= 3
        ? (colors.overdueBg, AppColors.ccOverdue)
        : days <= 7
            ? (colors.warningBg, AppColors.ccSoon)
            : (colors.upcomingBg, colors.upcomingFg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        '${days}d',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Card Create Form ─────────────────────────────────────────────────────────

class _CardForm extends ConsumerStatefulWidget {
  const _CardForm({this.existing});

  final CreditCard? existing;

  @override
  ConsumerState<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<_CardForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _issuer;
  late TextEditingController _lastFour;
  late TextEditingController _closeDay;
  late TextEditingController _graceDays;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name      = TextEditingController(text: e?.name ?? '');
    _issuer    = TextEditingController(text: e?.issuer ?? '');
    _lastFour  = TextEditingController(text: e?.lastFour ?? '');
    _closeDay  = TextEditingController(text: e?.statementCloseDay?.toString() ?? '');
    _graceDays = TextEditingController(text: e?.gracePeriodDays?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _lastFour.dispose();
    _closeDay.dispose();
    _graceDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Text(
              widget.existing == null ? 'Add Credit Card' : 'Edit Credit Card',
              style: AppText.heading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Card name *'),
              maxLength: 100,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: _issuer, decoration: const InputDecoration(labelText: 'Issuer'), maxLength: 100)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(
                controller: _lastFour,
                decoration: const InputDecoration(labelText: 'Last 4 digits'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) return 'Must be exactly 4 digits';
                  return null;
                },
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _closeDay,
                decoration: const InputDecoration(labelText: 'Statement close day'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1 || n > 31) return 'Must be 1–31';
                  return null;
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(
                controller: _graceDays,
                decoration: const InputDecoration(labelText: 'Grace period (days)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Must be 0 or more';
                  return null;
                },
              )),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(widget.existing == null ? 'Add Card' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(dbProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);
    try {
      if (widget.existing == null) {
        await db.insertCreditCard(CreditCardsCompanion(
          name: Value(_name.text.trim()),
          issuer: Value(_issuer.text.trim().isEmpty ? null : _issuer.text.trim()),
          lastFour: Value(_lastFour.text.trim().isEmpty ? null : _lastFour.text.trim()),
          statementCloseDay: Value(int.tryParse(_closeDay.text)),
          gracePeriodDays: Value(int.tryParse(_graceDays.text)),
          syncStatus: Value(SyncStatus.pendingCreate.value),
        ));
      } else {
        await db.updateCreditCard(
          widget.existing!.id,
          CreditCardsCompanion(
            name: Value(_name.text.trim()),
            issuer: Value(_issuer.text.trim().isEmpty ? null : _issuer.text.trim()),
            lastFour: Value(_lastFour.text.trim().isEmpty ? null : _lastFour.text.trim()),
            statementCloseDay: Value(int.tryParse(_closeDay.text)),
            gracePeriodDays: Value(int.tryParse(_graceDays.text)),
            syncStatus: Value(SyncStatus.pendingUpdate.value),
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      syncNotifier.syncIfOnline();
    } catch (e, st) {
      dev.log('_CardFormState._save: $e', name: 'credit_cards', level: 900, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save card. Please try again.')),
        );
      }
    }
  }
}
