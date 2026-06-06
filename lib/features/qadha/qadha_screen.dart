import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';

class QadhaScreen extends ConsumerStatefulWidget {
  const QadhaScreen({super.key});

  @override
  ConsumerState<QadhaScreen> createState() => _QadhaScreenState();
}

class _QadhaScreenState extends ConsumerState<QadhaScreen> {
  int _fidyahDays = 0;
  int _fidyahRate = 30000; // default per-day rate (editable)
  int _zakatPeople = 0;
  int _zakatRate = 45000; // default per-person cash equivalent (editable)

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final balanceAsync = ref.watch(qadhaBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.obligationsTitle)),
      body: balanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (balance) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildZakatCalculator(context, s),
              const SizedBox(height: 24),
              _buildFidyahCalculator(context, s),
              const SizedBox(height: 24),
              Text(s.qadhaSection,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildBalanceCard(context, s, balance),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addEntry(s, 'qadha', 'owed'),
                      icon: const Icon(Icons.add),
                      label: Text(s.addOwed),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addEntry(s, 'qadha', 'paid'),
                      icon: const Icon(Icons.check),
                      label: Text(s.addPaid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(s.history,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (balance.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s.noHistory,
                      style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                ...balance.entries.map((e) => _buildHistoryTile(s, e)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, SunnahStrings s, QadhaBalance balance) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(s.qadhaRemaining,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '${balance.qadhaRemaining}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
            ),
            Text(s.daysUnit),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('${balance.qadhaOwed}', s.qadhaOwed),
                _miniStat('${balance.qadhaPaid}', s.qadhaPaid),
                _miniStat('${balance.fidyahDays}', s.fidyahTitle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildZakatCalculator(BuildContext context, SunnahStrings s) {
    final total = _zakatPeople * _zakatRate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.zakatTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: s.zakatPeopleLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _zakatPeople = int.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: TextEditingController(
                        text: _zakatRate.toString())
                      ..selection = TextSelection.collapsed(
                          offset: _zakatRate.toString().length),
                    decoration: InputDecoration(
                      labelText: s.zakatRate,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _zakatRate = int.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${s.zakatTotal}: $total',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _zakatPeople > 0
                    ? () async {
                        final db = ref.read(databaseProvider);
                        await db.qadhaLedgerDao.addEntry(
                          kind: 'zakat',
                          direction: 'paid',
                          days: _zakatPeople,
                          amount: total,
                        );
                        ref.read(qadhaRefreshProvider.notifier).state++;
                        setState(() => _zakatPeople = 0);
                      }
                    : null,
                child: Text(s.markZakatPaid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFidyahCalculator(BuildContext context, SunnahStrings s) {
    final total = _fidyahDays * _fidyahRate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.fidyahTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: s.fidyahDaysLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _fidyahDays = int.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: TextEditingController(
                        text: _fidyahRate.toString())
                      ..selection = TextSelection.collapsed(
                          offset: _fidyahRate.toString().length),
                    decoration: InputDecoration(
                      labelText: s.fidyahRate,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _fidyahRate = int.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${s.fidyahTotal}: $total',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _fidyahDays > 0
                    ? () async {
                        final db = ref.read(databaseProvider);
                        await db.qadhaLedgerDao.addEntry(
                          kind: 'fidyah',
                          direction: 'paid',
                          days: _fidyahDays,
                          amount: total,
                        );
                        ref.read(qadhaRefreshProvider.notifier).state++;
                        setState(() => _fidyahDays = 0);
                      }
                    : null,
                child: Text(s.markFidyahPaid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(SunnahStrings s, QadhaLedgerData e) {
    final isFidyah = e.kind == 'fidyah';
    final isZakat = e.kind == 'zakat';
    final isPaid = e.direction == 'paid';
    final String label;
    final String subtitle;
    if (isZakat) {
      label = '${s.zakatTitle}: ${e.days} ${s.peopleUnit}';
      subtitle = '${e.amount}';
    } else if (isFidyah) {
      label = '${s.fidyahTitle}: ${e.days} ${s.daysUnit}';
      subtitle = '${e.amount}';
    } else {
      label = isPaid ? s.qadhaPaid : s.qadhaOwed;
      subtitle = '${e.days} ${s.daysUnit}';
    }
    return Dismissible(
      key: ValueKey('qadha_${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final db = ref.read(databaseProvider);
        await db.qadhaLedgerDao.deleteEntry(e.id);
        ref.read(qadhaRefreshProvider.notifier).state++;
      },
      child: ListTile(
        leading: Icon(
          isPaid ? Icons.arrow_circle_down : Icons.arrow_circle_up,
          color: isPaid ? Colors.green : Colors.orange,
        ),
        title: Text(label),
        subtitle: Text(subtitle),
      ),
    );
  }

  Future<void> _addEntry(
      SunnahStrings s, String kind, String direction) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(direction == 'owed' ? s.addOwed : s.addPaid),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.amountHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(controller.text) ?? 0),
              child: Text(s.save),
            ),
          ],
        );
      },
    );
    if (result != null && result > 0) {
      final db = ref.read(databaseProvider);
      await db.qadhaLedgerDao.addEntry(
        kind: kind,
        direction: direction,
        days: result,
      );
      ref.read(qadhaRefreshProvider.notifier).state++;
    }
  }
}
