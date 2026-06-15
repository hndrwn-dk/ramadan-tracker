import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/qadha/widgets/obligations_history_section.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_back_button.dart';
import 'package:ramadan_tracker/utils/obligations_utils.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

class QadhaScreen extends ConsumerStatefulWidget {
  const QadhaScreen({super.key});

  @override
  ConsumerState<QadhaScreen> createState() => _QadhaScreenState();
}

class _QadhaScreenState extends ConsumerState<QadhaScreen> {
  int _zakatPeople = 0;
  int _fidyahDays = 0;
  int _zakatRate = 0;
  int _fidyahRate = 0;
  String _currency = 'IDR';

  final _zakatPeopleController = TextEditingController();
  final _fidyahDaysController = TextEditingController();
  final _zakatRateController = TextEditingController();
  final _fidyahRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final db = ref.read(databaseProvider);
    final currency =
        await db.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    if (mounted) {
      setState(() => _currency = currency);
    }
  }

  @override
  void dispose() {
    _zakatPeopleController.dispose();
    _fidyahDaysController.dispose();
    _zakatRateController.dispose();
    _fidyahRateController.dispose();
    super.dispose();
  }

  List<TextInputFormatter> _amountFormatters() {
    if (_currency == 'IDR') {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        IdrAmountInputFormatter(),
      ];
    }
    return [FilteringTextInputFormatter.digitsOnly];
  }

  Future<void> _setCurrency(String? value) async {
    if (value == null || value == _currency) return;
    final db = ref.read(databaseProvider);
    await db.kvSettingsDao.setValue('sedekah_currency', value);
    setState(() {
      _currency = value;
      _zakatRate = 0;
      _fidyahRate = 0;
      _zakatRateController.clear();
      _fidyahRateController.clear();
    });
  }

  String _todayYmd() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(qadhaBalanceProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(s.obligationsTitle),
      ),
      body: balanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (balance) {
          final season = seasonAsync.valueOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCurrencySelector(context, s, l10n),
              const SizedBox(height: 16),
              _buildZakatCalculator(context, s),
              const SizedBox(height: 16),
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
              ObligationsHistorySection(
                entries: balance.entries,
                zakatByCurrency: balance.zakatPaidByCurrency,
                fidyahByCurrency: balance.fidyahPaidByCurrency,
                currency: _currency,
                season: season,
                onDelete: (e) async {
                  final db = ref.read(databaseProvider);
                  await db.qadhaLedgerDao.deleteEntry(e.id);
                  ref.read(qadhaRefreshProvider.notifier).state++;
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrencySelector(
      BuildContext context, SunnahStrings s, AppLocalizations l10n) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.currencyLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'IDR', child: Text(l10n.idrRp)),
              DropdownMenuItem(value: 'SGD', child: Text(l10n.sgdSdollar)),
              DropdownMenuItem(value: 'USD', child: Text(l10n.usdDollar)),
              DropdownMenuItem(value: 'MYR', child: Text(l10n.myrRm)),
            ],
            onChanged: _setCurrency,
          ),
          const SizedBox(height: 8),
          Text(
            s.rateHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
        ],
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
    final canPay = _zakatPeople > 0 && _zakatRate > 0;

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
                    controller: _zakatPeopleController,
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
                    controller: _zakatRateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: _amountFormatters(),
                    decoration: InputDecoration(
                      labelText: s.zakatRate,
                      hintText: s.enterRateFirst,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _zakatRate =
                        ObligationsUtils.parseAmountInput(v, _currency)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${s.zakatTotal}: ${total > 0 ? SedekahUtils.formatCurrency(total.toDouble(), _currency) : '-'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: canPay ? () => _markPaid('zakat', total) : null,
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
    final canPay = _fidyahDays > 0 && _fidyahRate > 0;

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
                    controller: _fidyahDaysController,
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
                    controller: _fidyahRateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: _amountFormatters(),
                    decoration: InputDecoration(
                      labelText: s.fidyahRate,
                      hintText: s.enterRateFirst,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _fidyahRate =
                        ObligationsUtils.parseAmountInput(v, _currency)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${s.fidyahTotal}: ${total > 0 ? SedekahUtils.formatCurrency(total.toDouble(), _currency) : '-'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: canPay ? () => _markPaid('fidyah', total) : null,
                child: Text(s.markFidyahPaid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(String kind, int total) async {
    final days = kind == 'zakat' ? _zakatPeople : _fidyahDays;
    final db = ref.read(databaseProvider);
    final season = await ref.read(currentSeasonProvider.future);

    await db.qadhaLedgerDao.addEntry(
      kind: kind,
      direction: 'paid',
      days: days,
      amount: total,
      dateYmd: _todayYmd(),
      sourceSeasonId: season?.id,
      note: ObligationsUtils.encodeCurrencyNote(_currency),
    );
    ref.read(qadhaRefreshProvider.notifier).state++;

    setState(() {
      if (kind == 'zakat') {
        _zakatPeople = 0;
        _zakatPeopleController.clear();
      } else {
        _fidyahDays = 0;
        _fidyahDaysController.clear();
      }
    });
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
