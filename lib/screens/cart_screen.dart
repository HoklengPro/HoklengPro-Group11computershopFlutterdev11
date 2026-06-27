import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/view_state.dart';
import '../state/nexus_controller.dart';
import '../widgets/cart_item_tile.dart';
import '../theme/nexus_palette.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  static String cents(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);

    Widget header(String txt) => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(color: NexusPalette.borderSubtle(context)),
            ),
          ),
          child: Text(
            txt,
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
          ),
        );

    if (controller.cart.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header('CART (0)'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 48, color: muted),
                    const SizedBox(height: 16),
                    Text(
                      'YOUR CART IS EMPTY',
                      style: GoogleFonts.jetBrainsMono(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add some gear to get started.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final subtotal = controller.cartSubtotal;
    final tax = subtotal * 0.08;
    final total = subtotal + tax;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header('CART (${controller.cart.length})'),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 240),
                itemCount: controller.cart.length + 1,
                itemBuilder: (context, i) {
                  if (i == controller.cart.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TotalsRow(label: 'Subtotal', amount: subtotal, muted: muted),
                          const SizedBox(height: 8),
                          _TotalsRow(label: 'Estimated Tax', amount: tax, muted: muted),
                          const Divider(height: 24),
                          _TotalsRow(
                            label: 'Total',
                            amount: total,
                            muted: muted,
                            emphasized: NexusPalette.cyan,
                            emphasizeStyle: FontWeight.bold,
                          ),
                        ],
                      ),
                    );
                  }
                  final item = controller.cart[i];
                  final prod = controller.productById(item.productId);
                  return CartItemTile(
                    item: item,
                    product: prod,
                    onIncrease: () =>
                        controller.updateCartQty(item.id, item.qty + 1),
                    onDecrease: () =>
                        controller.updateCartQty(item.id, item.qty - 1),
                    onDelete: () => controller.removeFromCart(item.id),
                  );
                },
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
            child: GradientPrimaryButton(
              label: 'PROCEED TO CHECKOUT',
              onTap: () => controller.navigate(ViewState.checkout),
            ),
          ),
        ),
      ],
    );
  }
}

class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NexusPalette.cyan,
                NexusPalette.magenta,
                NexusPalette.violet,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              style:
                  GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.amount,
    required this.muted,
    this.emphasized,
    this.emphasizeStyle,
  });

  final String label;
  final double amount;
  final Color muted;
  final Color? emphasized;
  final FontWeight? emphasizeStyle;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(color: muted.withValues(alpha: .9));

    final amountStyle = GoogleFonts.jetBrainsMono(
      fontWeight: emphasizeStyle ?? FontWeight.w500,
      color: emphasized ?? muted,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text('\$ ${CartSheet.cents(amount)}', style: amountStyle),
      ],
    );
  }
}


