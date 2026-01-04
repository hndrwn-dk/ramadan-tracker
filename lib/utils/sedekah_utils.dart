import 'dart:math';
import 'package:intl/intl.dart';

class SedekahUtils {
  /// Generate quick-add chip amounts based on currency, daily goal, and remaining amount
  /// 
  /// Rules:
  /// - Default global chips base: [2,5,10,20,50,100]
  /// - If dailyGoalAmount < 10 → chips: [1,2,5,dailyGoalAmount] (unique, <=goal)
  /// - If dailyGoalAmount between 10..50 → [2,5,10,20, dailyGoalAmount] (unique, <=goal)
  /// - If dailyGoalAmount > 50 → [5,10,20,50, min(100,goal), goal] (unique)
  /// - Never generate chips > remainingToday (if provided)
  /// - Remove duplicates, round to 2 decimals max
  /// 
  /// Currency handling:
  /// - For SGD/MYR/USD: use denominations 1/2/5/10/20/50/100
  /// - For IDR: use 1000/2000/5000/10000/20000/50000 (multiply by goal factor)
  static List<double> generateQuickAddChips({
    required String currency,
    required double dailyGoalAmount,
    double? remainingToday,
  }) {
    // Normalize currency - handle symbols like S$, $, RM, Rp
    String normalizedCurrency = currency.trim();
    final symbolToCode = {
      'S\$': 'SGD',
      '\$': 'USD',
      'RM': 'MYR',
      'Rp': 'IDR',
      'RP': 'IDR',
    };
    if (symbolToCode.containsKey(normalizedCurrency)) {
      normalizedCurrency = symbolToCode[normalizedCurrency]!;
    } else {
      normalizedCurrency = normalizedCurrency.toUpperCase();
    }
    
    final isMajorCurrency = ['SGD', 'MYR', 'USD', 'EUR', 'GBP'].contains(normalizedCurrency);
    final isIDR = normalizedCurrency == 'IDR' || normalizedCurrency == 'RP';
    
    List<double> baseChips;
    
    if (isIDR) {
      // For IDR, use larger denominations
      baseChips = [1000, 2000, 5000, 10000, 20000, 50000];
    } else if (isMajorCurrency) {
      // For major currencies, use standard denominations
      baseChips = [1, 2, 5, 10, 20, 50, 100];
    } else {
      // Default: use standard denominations
      baseChips = [2, 5, 10, 20, 50, 100];
    }
    
    List<double> chips = [];
    
    if (dailyGoalAmount <= 0) {
      // No goal set, use default chips based on currency
      if (isIDR) {
        chips = [5000, 10000, 20000];
      } else if (isMajorCurrency) {
        chips = [5, 10, 20, 50];
      } else {
        chips = [5000, 10000, 20000];
      }
    } else if (dailyGoalAmount < 10) {
      // Small amounts: [1,2,5,goal] (unique, <=goal)
      chips = [1.0, 2.0, 5.0].where((c) => c <= dailyGoalAmount).toList();
      if (dailyGoalAmount > 0 && !chips.contains(dailyGoalAmount)) {
        chips.add(dailyGoalAmount);
      }
    } else if (dailyGoalAmount >= 10 && dailyGoalAmount <= 50) {
      // Medium amounts: [2,5,10,20,goal] (unique, <=goal)
      chips = [2.0, 5.0, 10.0, 20.0].where((c) => c <= dailyGoalAmount).toList();
      if (dailyGoalAmount > 0 && !chips.contains(dailyGoalAmount)) {
        chips.add(dailyGoalAmount);
      }
    } else {
      // Large amounts: [5,10,20,50,min(100,goal),goal] (unique)
      chips = [5.0, 10.0, 20.0, 50.0].where((c) => c <= dailyGoalAmount).toList();
      final cappedGoal = min(100.0, dailyGoalAmount);
      if (cappedGoal > 0 && !chips.contains(cappedGoal)) {
        chips.add(cappedGoal);
      }
      if (dailyGoalAmount > 100 && !chips.contains(dailyGoalAmount)) {
        chips.add(dailyGoalAmount);
      }
    }
    
    // Filter out chips that exceed remaining amount (if provided)
    if (remainingToday != null && remainingToday > 0) {
      chips = chips.where((chip) => chip <= remainingToday).toList();
    }
    
    // Remove duplicates and sort
    chips = chips.toSet().toList()..sort();
    
    // Round to 2 decimals max, but for SGD/USD show integers if whole number
    chips = chips.map((chip) {
      if (isMajorCurrency && chip == chip.roundToDouble()) {
        return chip.roundToDouble();
      }
      return double.parse(chip.toStringAsFixed(2));
    }).toList();
    
    // Limit to max 4 chips for UI
    if (chips.length > 4) {
      // Keep goal and a few strategic values
      final goalIndex = chips.indexWhere((c) => (c - dailyGoalAmount).abs() < 0.01);
      if (goalIndex >= 0) {
        final goal = chips[goalIndex];
        chips.removeAt(goalIndex);
        chips = chips.take(3).toList()..add(goal)..sort();
      } else {
        chips = chips.take(4).toList();
      }
    }
    
    // Ensure at least 2 chips
    if (chips.isEmpty) {
      chips = isIDR ? [5000.0, 10000.0] : [5.0, 10.0];
    }
    
    return chips;
  }
  
  /// Format currency amount for display
  /// Returns formatted string like "S$ 100" or "SGD 100" or "Rp 10.000"
  static String formatCurrency(double amount, String currency) {
    // Handle currency symbols that might be passed directly (S$, $, RM, Rp)
    String normalizedCurrency = currency.trim();
    
    // Map symbols to currency codes for processing
    final symbolToCode = {
      'S\$': 'SGD',
      '\$': 'USD',
      'RM': 'MYR',
      'Rp': 'IDR',
      'RP': 'IDR',
    };
    
    // Check if it's a symbol, convert to code
    if (symbolToCode.containsKey(normalizedCurrency)) {
      normalizedCurrency = symbolToCode[normalizedCurrency]!;
    } else {
      normalizedCurrency = normalizedCurrency.toUpperCase();
    }
    
    // Currency symbols mapping for display
    final currencySymbols = {
      'SGD': 'S\$',
      'MYR': 'RM',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'IDR': 'Rp',
      'RP': 'Rp',
    };
    
    final symbol = currencySymbols[normalizedCurrency] ?? normalizedCurrency;
    
    // For major currencies, show as integer if whole number
    final isMajorCurrency = ['SGD', 'MYR', 'USD', 'EUR', 'GBP'].contains(normalizedCurrency);
    final isIDR = normalizedCurrency == 'IDR' || normalizedCurrency == 'RP';
    
    if (isMajorCurrency && amount == amount.roundToDouble()) {
      return '$symbol ${amount.toInt()}';
    }
    
    if (isIDR) {
      // Format IDR with thousand separators
      final formatter = NumberFormat('#,###', 'id_ID');
      return '$symbol ${formatter.format(amount.toInt())}';
    }
    
    // Default: show 2 decimals max
    final formatted = amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return '$symbol $formatted';
  }
}

