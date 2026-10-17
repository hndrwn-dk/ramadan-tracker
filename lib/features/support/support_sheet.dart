import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/support_provider.dart';
import 'package:ramadan_tracker/domain/support/support_products.dart';
import 'package:ramadan_tracker/domain/support/support_purchase_quantity.dart';
import 'package:ramadan_tracker/domain/support/support_purchase_service.dart';
import 'package:ramadan_tracker/features/support/support_thanks_heart.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

Future<void> showSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const SupportSheet(),
  );
}

String supportTierLabel(AppLocalizations l10n, String productId) {
  switch (productId) {
    case SupportProducts.coffee:
      return l10n.supportTierCoffee;
    case SupportProducts.full:
      return l10n.supportTierFull;
    case SupportProducts.lunch:
    default:
      return l10n.supportTierLunch;
  }
}

class SupportSheet extends ConsumerStatefulWidget {
  const SupportSheet({super.key});

  @override
  ConsumerState<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends ConsumerState<SupportSheet> {
  late final SupportPurchaseService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(supportPurchaseProvider);
    _service.consumeSignals();
    _service.sheetOpen = true;
    _service.start();
    _service.addListener(_onService);
    _service.prepare();
  }

  @override
  void dispose() {
    _service.sheetOpen = false;
    _service.removeListener(_onService);
    super.dispose();
  }

  void _onService() {
    if (!mounted) return;
    final service = _service;
    if (service.closeRequested) {
      final failed = service.errorRequested;
      service.consumeSignals();
      final messenger = ScaffoldMessenger.of(context);
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();
      if (failed) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.supportPurchaseError)),
        );
      }
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supportPurchaseProvider);
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: service.phase == SupportUiPhase.thanks
              ? _Thanks(
                  key: const ValueKey('support_thanks'),
                  l10n: l10n,
                  productId: service.purchasedProductId,
                  quantity: service.purchasedQuantity,
                )
              : _Catalog(
                  key: const ValueKey('support_catalog'),
                  l10n: l10n,
                  service: service,
                ),
        ),
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({
    super.key,
    required this.l10n,
    required this.service,
  });

  final AppLocalizations l10n;
  final SupportPurchaseService service;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loading = service.phase == SupportUiPhase.loading;
    final tiles = loading
        ? [
            for (final id in SupportProducts.ordered)
              (id: id, price: null as String?),
          ]
        : [
            for (final offer in service.offers)
              (id: offer.id, price: offer.price),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.supportSheetTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.supportSheetBody),
        const SizedBox(height: 16),
        if (service.phase == SupportUiPhase.unavailable)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.supportUnavailable,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          )
        else ...[
          Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TierTile(
                    price: tiles[i].price,
                    label: supportTierLabel(l10n, tiles[i].id),
                    selected: tiles[i].id == service.selectedId,
                    onTap: loading ? null : () => service.select(tiles[i].id),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supportQuantityHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (service.phase == SupportUiPhase.pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.supportPaymentPending,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          FilledButton(
            onPressed: service.phase == SupportUiPhase.catalog
                ? service.buySelected
                : null,
            child: Text(l10n.supportContinuePlay),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.supportFootnote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.price,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String? price;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priceStyle = Theme.of(context).textTheme.titleSmall;
    final fontSize = priceStyle?.fontSize ?? 14;
    final lineHeight = fontSize * (priceStyle?.height ?? 1.43);
    final fill = selected
        ? Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.16),
            colorScheme.surface,
          )
        : colorScheme.surface;
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              SizedBox(
                height: lineHeight,
                child: price == null
                    ? Center(
                        child: DecoratedBox(
                          key: const Key('support_price_placeholder'),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SizedBox(width: 64, height: fontSize * 0.7),
                        ),
                      )
                    : Text(
                        price!,
                        textAlign: TextAlign.center,
                        style: priceStyle,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks({
    super.key,
    required this.l10n,
    required this.productId,
    required this.quantity,
  });

  final AppLocalizations l10n;
  final String? productId;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final label = productId == null ? null : supportTierLabel(l10n, productId!);
    final quantityLine = supportThanksQuantityLine(
      tierLabel: label,
      quantity: quantity,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const SupportThanksHeart(),
        const SizedBox(height: 12),
        Text(
          l10n.supportThanksTitle,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.supportThanksBody,
          textAlign: TextAlign.center,
        ),
        if (quantityLine != null) ...[
          const SizedBox(height: 8),
          Text(
            quantityLine,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.supportClose),
          ),
        ),
      ],
    );
  }
}
