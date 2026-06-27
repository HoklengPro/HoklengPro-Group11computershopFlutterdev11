import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/view_state.dart';
import '../state/nexus_controller.dart';
import '../services/nexus_api_service.dart';
import '../theme/nexus_palette.dart';
import '../widgets/ui_kit.dart';

/// Full-screen auth backdrop.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF07080D) : const Color(0xFFF1F5F9);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: base,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? NexusPalette.cyan.withValues(alpha: 0.14)
                  : NexusPalette.cyan.withValues(alpha: 0.08),
              base,
              isDark
                  ? NexusPalette.violet.withValues(alpha: 0.12)
                  : NexusPalette.violet.withValues(alpha: 0.05),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Fills the device frame — SafeArea + min-height scroll.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.child,
    this.onBack,
    this.centerContent = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: centerContent
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: onBack,
                          tooltip: 'Back',
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 26,
                          ),
                        ),
                      ),
                    child,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12121A).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NexusPalette.borderSubtle(context)),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        child: child,
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = NexusPalette.textMuted(context);
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                NexusPalette.cyan,
                NexusPalette.magenta,
                NexusPalette.violet,
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                color: NexusPalette.cyan.withValues(alpha: 0.28),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.5),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: const Icon(Icons.memory_rounded, color: NexusPalette.cyan, size: 30),
          ),
        ),
        const SizedBox(height: 20),
        GradientTitle(
          title,
          style: const TextStyle(fontSize: 28, letterSpacing: 1.2),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.4,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = NexusPalette.textMuted(context);
    final fieldFill = isDark
        ? const Color(0xFF1A1A24)
        : const Color(0xFFF8FAFC);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 15, color: muted),
            filled: true,
            fillColor: fieldFill,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: NexusPalette.borderSubtle(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NexusPalette.cyan, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthDemoHint extends StatelessWidget {
  const _AuthDemoHint();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? NexusPalette.cyan.withValues(alpha: 0.1)
            : NexusPalette.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NexusPalette.cyan.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 20, color: NexusPalette.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo account: demo@school.dev / demo1234',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key, required this.controller});

  final NexusController controller;

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _SlideSpec {
  _SlideSpec({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final steps = [
    _SlideSpec(
      title: 'BUILD WITHOUT LIMITS',
      body:
          'Configure your dream PC with our real-time compatibility checker.',
      color: NexusPalette.cyan,
      icon: Icons.memory_rounded,
    ),
    _SlideSpec(
      title: 'SHOP THE LATEST',
      body: 'RTX 4090s, mechanical decks, and pro audio gear in stock.',
      color: NexusPalette.magenta,
      icon: Icons.tv_rounded,
    ),
    _SlideSpec(
      title: 'WE FIX. WE UPGRADE.',
      body: 'Book repairs and track them in real time from your phone.',
      color: NexusPalette.violet,
      icon: Icons.build_rounded,
    ),
  ];

  int step = 0;

  @override
  Widget build(BuildContext context) {
    final slide = steps[step];
    return AuthBackground(
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 8,
              child: TextButton(
                onPressed: () =>
                    unawaited(widget.controller.skipOnboarding()),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: Text(
                  'SKIP',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Column(
                            key: ValueKey(step),
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: slide.color.withValues(alpha: .45),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 28,
                                      color:
                                          slide.color.withValues(alpha: .28),
                                    ),
                                  ],
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.85),
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 52,
                                  color: slide.color,
                                ),
                              ),
                              const SizedBox(height: 28),
                              GradientTitle(
                                slide.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                slide.body,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: NexusPalette.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final active = step == i;
                            return AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 260),
                              width: active ? 24 : 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: active
                                    ? slide.color
                                    : Theme.of(context).dividerColor,
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          blurRadius: 14,
                                          color: slide.color
                                              .withValues(alpha: .36),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 36),
                        GradientRgbButton(
                          onPressed: () async {
                            if (step == 2) {
                              await widget.controller.finishOnboarding();
                            } else {
                              setState(() => step += 1);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(step == 2 ? 'GET STARTED' : 'NEXT'),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool obscure = true;
  bool loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    return AuthPageShell(
      centerContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrandHeader(
            title: 'NEXUS',
            subtitle: 'Welcome back — sign in to sync orders & favorites',
          ),
          const SizedBox(height: 28),
          _AuthDemoHint(),
          const SizedBox(height: 16),
          AuthFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _password,
                  obscureText: obscure,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: NexusPalette.iconMuted(context),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => store.navigate(ViewState.forgotPassword),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NexusPalette.cyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GradientRgbButton(
                  onPressed: loading
                      ? () {}
                      : () async {
                          final email = _email.text.trim();
                          final password = _password.text;
                          if (email.isEmpty || password.isEmpty) {
                            showNexusToast(context, 'ENTER EMAIL AND PASSWORD');
                            return;
                          }
                          setState(() => loading = true);
                          try {
                            await store.login(email: email, password: password);
                            if (!mounted) return;
                            showNexusToast(context, 'SIGNED IN');
                            store.navigate(ViewState.account);
                          } on NexusApiException catch (e) {
                            if (!mounted) return;
                            showNexusToast(context, e.message.toUpperCase());
                          } catch (_) {
                            if (!mounted) return;
                            showNexusToast(
                                context, 'LOGIN FAILED — CHECK BACKEND');
                          } finally {
                            if (mounted) setState(() => loading = false);
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SIGN IN'),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: NexusPalette.borderSubtle(context))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: GoogleFonts.inter(fontSize: 12, color: muted),
                      ),
                    ),
                    Expanded(child: Divider(color: NexusPalette.borderSubtle(context))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            showNexusToast(context, 'GOOGLE SSO — DEMO BUILD'),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                        label: Text(
                          'Google',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            showNexusToast(context, 'APPLE SSO — DEMO BUILD'),
                        icon: const Icon(Icons.apple, size: 20),
                        label: Text(
                          'Apple',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New here? ',
                style: GoogleFonts.inter(fontSize: 14, color: muted),
              ),
              TextButton(
                onPressed: () => store.navigate(ViewState.signup),
                child: Text(
                  'Create account',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NexusPalette.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool obscure = true;
  bool loading = false;

  int get strength {
    final p = _password.text;
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    if (p.length < 10) return 2;
    return 3;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    return AuthPageShell(
      onBack: () => store.navigate(ViewState.login),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const AuthBrandHeader(
            title: 'CREATE ACCOUNT',
            subtitle: 'Join Nexus — sync orders, favorites & builds',
          ),
          const SizedBox(height: 28),
          AuthFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'Full name',
                  hint: 'Jane Doe',
                  controller: _name,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Password (min 6 characters)',
                  hint: 'Create a secure password',
                  controller: _password,
                  obscureText: obscure,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: NexusPalette.iconMuted(context),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: strength > i
                              ? (strength >= 3 && i == 2
                                  ? NexusPalette.magenta
                                  : NexusPalette.cyan)
                              : NexusPalette.borderSubtle(context),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strength == 0
                      ? 'Enter a password'
                      : strength == 1
                          ? 'Weak — use at least 6 characters'
                          : strength == 2
                              ? 'Good strength'
                              : 'Strong password',
                  style: GoogleFonts.inter(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 20),
                GradientRgbButton(
                  onPressed: loading
                      ? () {}
                      : () async {
                          final name = _name.text.trim();
                          final email = _email.text.trim();
                          final password = _password.text;
                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.length < 6) {
                            showNexusToast(
                              context,
                              'NAME, EMAIL, AND 6+ CHAR PASSWORD REQUIRED',
                            );
                            return;
                          }
                          setState(() => loading = true);
                          try {
                            await store.signup(
                              name: name,
                              email: email,
                              password: password,
                            );
                            if (!mounted) return;
                            showNexusToast(context, 'WELCOME TO NEXUS');
                            store.navigate(ViewState.account);
                          } on NexusApiException catch (e) {
                            if (!mounted) return;
                            showNexusToast(context, e.message.toUpperCase());
                          } catch (_) {
                            if (!mounted) return;
                            showNexusToast(
                                context, 'SIGN UP FAILED — CHECK BACKEND');
                          } finally {
                            if (mounted) setState(() => loading = false);
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SIGN UP'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.inter(fontSize: 14, color: muted),
              ),
              TextButton(
                onPressed: () => store.navigate(ViewState.login),
                child: Text(
                  'Sign in',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NexusPalette.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    return AuthPageShell(
      onBack: () => store.navigate(ViewState.login),
      centerContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBrandHeader(
            title: 'RESET ACCESS',
            subtitle: 'Enter your email and we will send reset instructions',
          ),
          const SizedBox(height: 28),
          AuthFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo mode — link is simulated for school project',
                  style: GoogleFonts.inter(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 20),
                GradientRgbButton(
                  onPressed: () {
                    showNexusToast(context, 'RESET LINK — CHECK INBOX');
                    store.navigate(ViewState.login);
                  },
                  child: const Text('SEND RESET LINK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
