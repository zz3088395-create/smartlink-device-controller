import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/api_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/widgets/widgets.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillUsername();
  }

  Future<void> _prefillUsername() async {
    final last = await ref.read(appPrefsProvider).readLastUsername();
    if (!mounted || last == null || _username.text.isNotEmpty) return;
    _username.text = last;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(username: username, password: password);
      // The router observes the auth state and moves to the home screen.
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error, stackTrace) {
      // Anything outside the API layer (secure storage, platform channels)
      // must still surface instead of dying silently in the zone handler.
      debugPrint('Login failed outside the API layer: $error\n$stackTrace');
      if (mounted) {
        setState(() => _error = 'Sign in could not be completed on this device. '
            'Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useDemoAccount() {
    _username.text = AppConfig.demoUsername;
    _password.text = AppConfig.demoPassword;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 3),
                    const Center(child: SmartLinkLogo(size: 76)),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      AppConfig.appName,
                      style: AppTextStyles.display.copyWith(fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppConfig.appTagline,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl + AppSpacing.sm),
                    TextField(
                      controller: _username,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      keyboardType: TextInputType.name,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      enabled: !_loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: _error == null
                          ? const SizedBox(height: AppSpacing.xl)
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: InfoBanner(
                                title: _error!,
                                tone: StatusTone.danger,
                              ),
                            ),
                    ),
                    AppButton(
                      label: 'Sign In',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const Spacer(flex: 4),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          Text(
                            'Demo account available',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          TextButton(
                            onPressed: _loading ? null : _useDemoAccount,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Use demo account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
