import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Bottom sheet to set the sunnah fasting status for [date].
/// Writes to SunnahFasts and (optionally) the qadha ledger.
Future<void> showSunnahStatusSheet(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
) async {
  final s = SunnahStrings.of(context);
  final db = ref.read(databaseProvider);
  final existing = await db.sunnahFastsDao.getByDate(date);
  final types = SunnahFastingRules.typesFor(date);
  final defaultType = types.isNotEmpty ? types.first.key : 'custom';
  bool isQadha = existing?.isQadha ?? false;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> apply(int status) async {
            if (status == FastingStatus.notDone && existing == null) {
              Navigator.pop(ctx);
              return;
            }
            await db.sunnahFastsDao.upsert(
              date,
              status: status,
              type: existing?.type ?? defaultType,
              isQadha: isQadha,
            );
            // When a fast is logged as qadha, add a make-up credit.
            if (status == FastingStatus.fasted &&
                isQadha &&
                !(existing?.isQadha ?? false)) {
              await db.qadhaLedgerDao.addEntry(
                kind: 'qadha',
                direction: 'paid',
                days: 1,
                dateYmd: SunnahFastsDao.dateKey(date),
                note: 'Auto from sunnah log',
              );
              ref.read(qadhaRefreshProvider.notifier).state++;
            }
            ref.read(sunnahRefreshProvider.notifier).state++;
            await HomeWidgetService.update(db);
            if (ctx.mounted) Navigator.pop(ctx);
          }

          Widget option(int status, IconData icon, String label, Color color) {
            return ListTile(
              leading: Icon(icon, color: color),
              title: Text(label),
              onTap: () => apply(status),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      s.setStatus,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  option(FastingStatus.fasted, Icons.check_circle,
                      s.statusFasted, Colors.green),
                  SwitchListTile(
                    secondary: const Icon(Icons.event_repeat),
                    title: Text(s.markAsQadha),
                    value: isQadha,
                    onChanged: (v) => setState(() => isQadha = v),
                  ),
                  const Divider(height: 1),
                  option(FastingStatus.excusedSick, Icons.healing,
                      s.statusSick, Colors.orange),
                  option(FastingStatus.excusedHaid, Icons.water_drop,
                      s.statusHaid, Colors.pink),
                  option(FastingStatus.excusedNifas, Icons.child_friendly,
                      s.statusNifas, Colors.purple),
                  option(FastingStatus.excusedOther, Icons.more_horiz,
                      s.statusOther, Colors.blueGrey),
                  const Divider(height: 1),
                  option(FastingStatus.notDone, Icons.cancel_outlined,
                      existing == null ? s.cancel : s.clear,
                      Theme.of(ctx).colorScheme.outline),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
