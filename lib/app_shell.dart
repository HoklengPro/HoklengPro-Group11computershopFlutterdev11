import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/view_state.dart';
import 'screens/admin_screens.dart';
import 'screens/auth_screens.dart';
import 'screens/builder_flow.dart';
import 'screens/catalog_flow.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/social_hub.dart';
import 'screens/supporting_screens.dart';
import 'state/nexus_controller.dart';
import 'config/api_config.dart';
import 'theme/nexus_palette.dart';
import 'theme/nexus_theme.dart';
import 'widgets/nexus_profile_avatar.dart';
import 'widgets/nexus_scroll_behavior.dart';

class NexusFlutterApp extends StatelessWidget {
  const NexusFlutterApp({super.key});

  static bool _hidesChrome(ViewState view) =>
      view == ViewState.onboarding ||
      view == ViewState.login ||
      view == ViewState.signup ||
      view == ViewState.forgotPassword;

  static bool _moreTabActive(ViewState view) =>
      view == ViewState.more ||
      view == ViewState.map ||
      view == ViewState.nearby ||
      view == ViewState.promotions ||
      view == ViewState.booking ||
      view == ViewState.chat ||
      view == ViewState.reviews ||
      view == ViewState.media ||
      view == ViewState.repairTracker;

  @override
  Widget build(BuildContext context) {
    return Consumer<NexusController>(
      builder: (context, controller, _) {
        Widget route(ViewState view) => switch (view) {
              ViewState.onboarding =>
                OnboardingCarousel(controller: controller),
              ViewState.login => const LoginScreen(),
              ViewState.signup => const SignupScreen(),
              ViewState.forgotPassword => const ForgotScreen(),
              ViewState.home => const NexusHomeScreen(),
              ViewState.builder => const BuilderLaboratory(),
              ViewState.compare => const CompareScreen(),
              ViewState.favorites => const SavedHubScreen(),
              ViewState.more => const ExploreMoreScreen(),
              ViewState.cart => const CartSheet(),
              ViewState.checkout => const CheckoutScreen(),
              ViewState.product => const ProductDetailRoute(),
              ViewState.category => const CategoryBrowseScreen(),
              ViewState.buildSummary => const BuildSummarySheet(),
              ViewState.search => const NexusSearchScreen(),
              ViewState.notifications => const NotificationsFeedScreen(),
              ViewState.account => const AccountOverviewScreen(),
              ViewState.orders => const OrdersListScreen(),
              ViewState.orderDetail => const OrderReceiptScreen(),
              ViewState.settings => const AppSettingsScreen(),
              ViewState.addresses => const SavedAddressesScreen(),
              ViewState.paymentMethods => const PaymentWalletScreen(),
              ViewState.writeReview => const WriteReviewSheet(),
              ViewState.map => const BranchLocatorScreen(),
              ViewState.nearby => const NearbyAvailabilityScreen(),
              ViewState.promotions => const PromotionsHubScreen(),
              ViewState.booking => const RepairBookingScreen(),
              ViewState.chat => const TechChatScreen(),
              ViewState.reviews => const CommunityReviewsScreen(),
              ViewState.media => const ShowcaseMediaScreen(),
              ViewState.repairTracker => const RepairTimelineScreen(),
              ViewState.loyalty => const LoyaltyHubScreen(),
              ViewState.help => const HelpDeskScreen(),
              ViewState.adminDashboard => const AdminDashboardScreen(),
              ViewState.adminProducts => const AdminProductsScreen(),
              ViewState.adminProductForm => const AdminProductFormScreen(),
              ViewState.adminOrders => const AdminOrdersScreen(),
            };

        final v = controller.currentView;

        if (!controller.isCatalogReady) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _CatalogBootstrapScreen(controller: controller),
          );
        }

        return MaterialApp(
          scrollBehavior: const NexusScrollBehavior(),
          debugShowCheckedModeBanner: false,
          themeMode:
              controller.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          theme: NexusTheme.light(),
          darkTheme: NexusTheme.dark(),
          home: AnimatedTheme(
            duration: const Duration(milliseconds: 260),
            data: controller.isDarkTheme
                ? NexusTheme.dark()
                : NexusTheme.light(),
            child: Builder(
              builder: (shellCtx) {
                return Scaffold(
                  backgroundColor:
                      Theme.of(shellCtx).scaffoldBackgroundColor,
                  resizeToAvoidBottomInset: true,
                  body: _hidesChrome(v)
                      ? KeyedSubtree(
                          key: ValueKey<ViewState>(v),
                          child: route(v),
                        )
                      : SafeArea(
                          child: Column(
                            children: [
                              _Header(controller),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 260),
                                  child: KeyedSubtree(
                                    key: ValueKey<ViewState>(v),
                                    child: route(v),
                                  ),
                                ),
                              ),
                              BottomNavRail(
                                controller: controller,
                                moreActive:
                                    NexusFlutterApp._moreTabActive(v),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CatalogBootstrapScreen extends StatelessWidget {
  const _CatalogBootstrapScreen({required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingCatalog) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                'Cannot reach Nexus backend',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                controller.catalogError ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Expected API: ${ApiConfig.baseUrl}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  try {
                    await controller.loadCatalog();
                  } catch (_) {}
                },
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.controller);

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final muted = NexusPalette.textMuted(context);
    final surface = Theme.of(context).colorScheme.surface;
    final v = controller.currentView;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: .45),
              ),
            ),
            color: surface.withValues(alpha: 0.82),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => controller.navigate(
                  controller.isSignedIn ? ViewState.account : ViewState.login,
                ),
                child: NexusProfileAvatar(
                  radius: 16,
                  initials: controller.isSignedIn
                      ? controller.accountProfile.initials
                      : 'G',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.navigate(ViewState.home),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          gradient: LinearGradient(
                            colors: [
                              NexusPalette.cyan,
                              NexusPalette.magenta,
                              NexusPalette.violet,
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(1),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: const Icon(
                            Icons.memory,
                            color: NexusPalette.cyan,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) =>
                              NexusPalette.textGradientHorizontal
                                  .createShader(bounds),
                          child: Text(
                            'NEXUS',
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _HeaderIconButton(
                tooltip: 'Search',
                icon: Icons.search_rounded,
                muted: muted,
                active: v == ViewState.search,
                activeColor: NexusPalette.cyan,
                onPressed: () => controller.navigate(ViewState.search),
              ),
              const SizedBox(width: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderIconButton(
                    tooltip: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    muted: muted,
                    active: v == ViewState.notifications,
                    activeColor: NexusPalette.cyan,
                    onPressed: () =>
                        controller.navigate(ViewState.notifications),
                  ),
                  if (controller.unreadNotificationsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: NexusPalette.magenta,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: NexusPalette.magenta.withValues(alpha: .45),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderIconButton(
                    tooltip: 'Cart',
                    icon: Icons.shopping_cart_outlined,
                    muted: muted,
                    active: v == ViewState.cart,
                    activeColor: NexusPalette.magenta,
                    onPressed: () => controller.navigate(ViewState.cart),
                  ),
                  if (controller.cartCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: NexusPalette.magenta,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 11,
                              color: NexusPalette.magenta.withValues(alpha: .45),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${controller.cartCount}',
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.muted,
    required this.onPressed,
    this.tooltip,
    this.active = false,
    this.activeColor = NexusPalette.cyan,
  });

  final IconData icon;
  final Color muted;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : NexusPalette.iconMuted(context);

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: activeColor.withValues(alpha: .12),
          highlightColor: activeColor.withValues(alpha: .08),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 24, color: color),
          ),
        ),
      ),
    );
  }
}
// footer button
class BottomNavRail extends StatelessWidget {
  const BottomNavRail({
    super.key,
    required this.controller,
    required this.moreActive,
  });

  final NexusController controller;
  final bool moreActive;

  @override
  Widget build(BuildContext context) {
    final muted = NexusPalette.textMuted(context);
    final v = controller.currentView;

    EdgeInsets padIcon(bool accent, bool active) =>
        EdgeInsets.all(accent && active ? 10 : 10);

    final surface = Theme.of(context).colorScheme.surface;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 94,
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.72),
            border: Border(top: BorderSide(color: NexusPalette.borderSubtle(context))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          _NavIcon(
            label: 'HOME',
            icon: Icons.home_rounded,
            muted: muted,
            active: v == ViewState.home,
            onTap: () => controller.navigate(ViewState.home),
          ),
          _NavIcon(
            label: 'BUILD',
            icon: Icons.memory,
            muted: muted,
            accent: true,
            pad: padIcon(true, v == ViewState.builder),
            active: v == ViewState.builder,
            glow: NexusPalette.cyan,
            onTap: () =>
                controller.navigate(ViewState.builder),
          ),
          _NavIcon(
            label: 'COMPARE',
            icon: Icons.compare_rounded,
            muted: muted,
            active: v == ViewState.compare,
            onTap: () =>
                controller.navigate(ViewState.compare),
          ),
          _NavIcon(
            label: 'SAVED',
            icon: Icons.favorite_border_rounded,
            muted: muted,
            active: v == ViewState.favorites,
            onTap: () =>
                controller.navigate(ViewState.favorites),
          ),
          _NavIcon(
            label: 'MORE',
            icon: Icons.menu_rounded,
            muted: muted,
            active: moreActive,
            onTap: () => controller.navigate(ViewState.more),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.label,
    required this.icon,
    required this.muted,
    required this.active,
    required this.onTap,
    this.accent = false,
    this.glow,
    this.pad = const EdgeInsets.all(10),
  });

  final String label;
  final IconData icon;
  final Color muted;
  final bool active;
  final VoidCallback onTap;
  final bool accent;
  final EdgeInsetsGeometry pad;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color iconTone() => accent && active
        ? NexusPalette.cyan
        : (active ? scheme.onSurface : NexusPalette.iconMuted(context));

    Widget dot() => AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: active && !accent ? 6 : 0,
          height: active && !accent ? 6 : 0,
          margin: EdgeInsets.only(bottom: active && !accent ? 8 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                NexusPalette.magenta.withValues(alpha: active && !accent ? 1 : 0),
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active && !accent) dot() else SizedBox(height: active ? 0 : 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: pad,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: accent && active
                    ? NexusPalette.cyan.withValues(alpha: .1)
                    : active
                        ? scheme.onSurface.withValues(alpha: 0.08)
                        : Colors.transparent,
                boxShadow: accent && active && glow != null
                    ? [
                        BoxShadow(
                          blurRadius: 18,
                          color: glow!.withValues(alpha: .35),
                        )
                      ]
                    : null,
              ),
              child: Icon(icon, size: 24, color: iconTone()),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: active ? scheme.onSurface : NexusPalette.textMuted(context),
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily ?? 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
