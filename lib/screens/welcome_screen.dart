import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:optica_sana/flutter_services/customer_service.dart';
import 'package:optica_sana/screens/customer_search_screen.dart';
import 'package:optica_sana/themes/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final CustomerService customerService;

  const WelcomeScreen({super.key, required this.customerService});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            CustomerSearchScreen(customerService: widget.customerService),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1024),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 180,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Optica Sana',
                      style: TextStyle(
                        color: AppColors.primaryDeep,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'welcome_tagline'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 260,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _getStarted,
                        child: Text(
                          'welcome_get_started'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          ),
        ),
      ),
    ),
  );
  }
}
