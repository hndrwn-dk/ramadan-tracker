import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Helpers for Zakat / Fidyah ledger entries (currency stored in [note]).
class ObligationsUtils {
  static const currencyNotePrefix = 'cur:';

  static String encodeCurrencyNote(String currency, {String? userNote}) {
    final cur = currency.trim().toUpperCase();
    if (userNote == null || userNote.isEmpty) {
      return '$currencyNotePrefix$cur';
    }
    return '$currencyNotePrefix$cur|$userNote';
  }

  static String parseCurrencyFromNote(String? note, {String fallback = 'IDR'}) {
    if (note == null || !note.startsWith(currencyNotePrefix)) {
      return fallback;
    }
    final payload = note.substring(currencyNotePrefix.length);
    final cur = payload.split('|').first.trim();
    return cur.isEmpty ? fallback : cur.toUpperCase();
  }

  static String? parseUserNote(String? note) {
    if (note == null || !note.startsWith(currencyNotePrefix)) {
      return note;
    }
    final payload = note.substring(currencyNotePrefix.length);
    final parts = payload.split('|');
    if (parts.length < 2) return null;
    return parts.sublist(1).join('|');
  }

  static int parseAmountInput(String text, String currency) {
    if (currency == 'IDR') {
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(digits) ?? 0;
    }
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  static String formatAmountInput(int amount, String currency) {
    if (amount <= 0) return '';
    if (currency == 'IDR') {
      return NumberFormat('#,###', 'id_ID').format(amount);
    }
    return amount.toString();
  }

  static String formatEntryDate(int createdAtMs, bool idLocale) {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final pattern = idLocale ? 'd MMM yyyy' : 'MMM d, yyyy';
    return DateFormat(pattern, idLocale ? 'id_ID' : 'en_US').format(date);
  }

  static bool isInSeason({
    required int createdAtMs,
    String? dateYmd,
    int? sourceSeasonId,
    required int seasonId,
    required DateTime seasonStart,
    required int seasonDays,
  }) {
    if (sourceSeasonId == seasonId) return true;
    if (dateYmd != null && dateYmd.isNotEmpty) {
      try {
        final d = DateTime.parse(dateYmd);
        final normalized = DateTime(d.year, d.month, d.day);
        final start = DateTime(
          seasonStart.year,
          seasonStart.month,
          seasonStart.day,
        );
        final end = start.add(Duration(days: seasonDays - 1));
        return !normalized.isBefore(start) && !normalized.isAfter(end);
      } catch (_) {}
    }
    final created = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final start = DateTime(
      seasonStart.year,
      seasonStart.month,
      seasonStart.day,
    );
    final end = start.add(Duration(days: seasonDays));
    return !created.isBefore(start) && created.isBefore(end);
  }

  static int? dayIndexInSeason({
    String? dateYmd,
    int? createdAtMs,
    required DateTime seasonStart,
    required int seasonDays,
  }) {
    DateTime? day;
    if (dateYmd != null && dateYmd.isNotEmpty) {
      try {
        day = DateTime.parse(dateYmd);
      } catch (_) {}
    }
    day ??= createdAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
        : null;
    if (day == null) return null;
    final normalized = DateTime(day.year, day.month, day.day);
    final start = DateTime(
      seasonStart.year,
      seasonStart.month,
      seasonStart.day,
    );
    final diff = normalized.difference(start).inDays;
    if (diff < 0 || diff >= seasonDays) return null;
    return diff + 1;
  }
}

class IdrAmountInputFormatter extends TextInputFormatter {
  static final _idrFormat = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount == 0) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final formatted = _idrFormat.format(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
