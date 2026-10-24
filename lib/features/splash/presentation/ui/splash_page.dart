import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;
  late final Animation<double> _ringScale;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.32, curve: Curves.easeOut),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.85, curve: Curves.easeOut),
    );
    _contentOffset =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.42, 0.85, curve: Curves.easeOutCubic),
          ),
        );
    _ringScale = Tween<double>(begin: 0.75, end: 1.35).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.82, curve: Curves.easeOut),
      ),
    );
    _loadVersion();
    _start();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (_) {
      if (mounted) setState(() => _version = 'v1.0.0');
    }
  }

  Future<void> _start() async {
    _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    if (!mounted) return;

    final isSignedIn =
        Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
    Modular.to.navigate(isSignedIn ? '/home/' : '/auth/');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF075A91), Color(0xFF0874B9), Color(0xFF22B2E2)],
              stops: [0, 0.58, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _BackgroundDecoration(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 4),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _ringScale.value,
                              child: Opacity(
                                opacity: (1 - _controller.value).clamp(0, 0.42),
                                child: Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _logoOpacity,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: const _FinanceLogo(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeTransition(
                        opacity: _contentOpacity,
                        child: SlideTransition(
                          position: _contentOffset,
                          child: Column(
                            children: [
                              Text(
                                context.tr(LanguageKeys.appName),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                context.tr(LanguageKeys.brandTagline),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xDFFFFFFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 5),
                      FadeTransition(
                        opacity: _contentOpacity,
                        child: const _LoadingIndicator(),
                      ),
                      const SizedBox(height: 14),
                      FadeTransition(
                        opacity: _contentOpacity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _version,
                            key: ValueKey(_version),
                            style: const TextStyle(
                              color: Color(0xBFFFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceLogo extends StatelessWidget {
  const _FinanceLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35003D66),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Color(0xFF0874B9),
            size: 52,
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xFF22B2E2),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: Color(0x35FFFFFF),
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x12FFFFFF),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x16FFFFFF), width: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
