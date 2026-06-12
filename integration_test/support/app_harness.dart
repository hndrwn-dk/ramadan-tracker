import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared helpers for emulator regression tests.
class AppHarness {
  AppHarness._();

  static const settleTimeout = Duration(seconds: 8);
  static const pumpStep = Duration(milliseconds: 500);

  static Future<void> settle(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        settleTimeout,
      );
    } catch (_) {
      // Charts, async providers, or platform callbacks may never fully settle.
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Bottom nav index: 0 Hari Ini, 1 Bulan, 2 Rencana, 3 Sunnah, 4 Wawasan, 5 Atur.
  static Future<void> tapNavIndex(WidgetTester tester, int index) async {
    final destinations = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(NavigationDestination),
    );
    expect(destinations, findsWidgets);
    expect(destinations.evaluate().length, greaterThan(index));
    await tester.tap(destinations.at(index));
    await settle(tester);
  }

  /// Dismiss language picker, permission dialogs, and onboarding skip if shown.
  static Future<void> completeStartup(WidgetTester tester) async {
    // Notification rescheduling on cold start can take 60–90s on emulator.
    for (var attempt = 0; attempt < 120; attempt++) {
      await tester.pump(const Duration(seconds: 1));

      if (find.textContaining('Initialization Error').evaluate().isNotEmpty) {
        throw TestFailure('App failed to initialize on device.');
      }

      if (find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.byIcon(Icons.today_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.today).evaluate().isNotEmpty ||
          find.byIcon(Icons.nightlight_outlined).evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 500));
        return;
      }

      for (final label in ['Allow', 'ALLOW', 'Izinkan', 'OK', 'While using the app']) {
        final button = find.text(label);
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button.first);
          await settle(tester);
          break;
        }
      }

      final bahasa = find.text('Bahasa Indonesia');
      if (bahasa.evaluate().isNotEmpty) {
        await tester.tap(bahasa);
        await settle(tester);
        continue;
      }

      for (final skipLabel in ['Lewati dulu', 'Skip for now']) {
        final skip = find.text(skipLabel);
        if (skip.evaluate().isNotEmpty) {
          await tester.tap(skip);
          await settle(tester);
          break;
        }
      }
    }

    throw TestFailure(
      'Main screen did not appear (NavigationBar not found after startup).',
    );
  }

  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    double delta = -300,
    int maxScrolls = 12,
  }) async {
    for (var i = 0; i < maxScrolls; i++) {
      if (finder.evaluate().isNotEmpty) return;
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) return;
      await tester.drag(scrollable.first, Offset(0, delta));
      await settle(tester);
    }
  }

  static bool isRamadanFocusMode(WidgetTester tester) {
    return find.text('Ramadan sedang berlangsung').evaluate().isNotEmpty;
  }

  static bool hasNoSeason(WidgetTester tester) {
    return find.text('Tidak ada musim ditemukan').evaluate().isNotEmpty ||
        find.text('No season found').evaluate().isNotEmpty;
  }

  /// Wawasan tab (index 4); waits for season analytics cards.
  static Future<void> openWawasanSeasonView(WidgetTester tester) async {
    await tapNavIndex(tester, 4);

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.textContaining('Zakat & Fidyah').evaluate().isNotEmpty ||
          find.textContaining('Puasa Sunnah').evaluate().isNotEmpty ||
          find.textContaining('Sedekah').evaluate().isNotEmpty) {
        break;
      }
      if (find.text('Ramadan').evaluate().isNotEmpty &&
          find.text('Hari Ini').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ramadan'));
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    await settle(tester);

    for (var i = 0; i < 8; i++) {
      if (find.textContaining('Puasa Sunnah').evaluate().isNotEmpty) break;
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable.first, const Offset(0, -400));
      await settle(tester);
    }
  }
}
