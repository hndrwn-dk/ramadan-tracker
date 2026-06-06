import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';

final qadhaRefreshProvider = StateProvider<int>((ref) => 0);

class QadhaBalance {
  final int qadhaOwed;
  final int qadhaPaid;
  final int fidyahDays;
  final int fidyahAmountPaid;
  final int zakatPeople;
  final int zakatAmountPaid;
  final List<QadhaLedgerData> entries;

  const QadhaBalance({
    required this.qadhaOwed,
    required this.qadhaPaid,
    required this.fidyahDays,
    required this.fidyahAmountPaid,
    required this.zakatPeople,
    required this.zakatAmountPaid,
    required this.entries,
  });

  int get qadhaRemaining => (qadhaOwed - qadhaPaid).clamp(0, 1 << 30);
}

final qadhaBalanceProvider = FutureProvider<QadhaBalance>((ref) async {
  ref.watch(qadhaRefreshProvider);
  final db = ref.watch(databaseProvider);
  final entries = await db.qadhaLedgerDao.getAll();

  int qadhaOwed = 0;
  int qadhaPaid = 0;
  int fidyahDays = 0;
  int fidyahAmountPaid = 0;
  int zakatPeople = 0;
  int zakatAmountPaid = 0;

  for (final e in entries) {
    if (e.kind == 'qadha') {
      if (e.direction == 'owed') {
        qadhaOwed += e.days;
      } else if (e.direction == 'paid') {
        qadhaPaid += e.days;
      }
    } else if (e.kind == 'fidyah' && e.direction == 'paid') {
      fidyahDays += e.days;
      fidyahAmountPaid += e.amount;
    } else if (e.kind == 'zakat' && e.direction == 'paid') {
      zakatPeople += e.days;
      zakatAmountPaid += e.amount;
    }
  }

  return QadhaBalance(
    qadhaOwed: qadhaOwed,
    qadhaPaid: qadhaPaid,
    fidyahDays: fidyahDays,
    fidyahAmountPaid: fidyahAmountPaid,
    zakatPeople: zakatPeople,
    zakatAmountPaid: zakatAmountPaid,
    entries: entries,
  );
});
