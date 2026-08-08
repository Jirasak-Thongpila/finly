import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// First screen for unauthenticated users.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              _Logo(),
              const SizedBox(height: 36),
              _Illustration(),
              const SizedBox(height: 32),
              Text(
                'Manage Your Money',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Track your income and expenses, understand your '
                'spending, and stay on top of your personal finances.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/register'),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 10),
        const Text(
          'Finly',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Coin(icon: Icons.attach_money_rounded, rotation: -0.12, size: 54),
        SizedBox(
          width: 8,
        ),
        _Coin(icon: Icons.trending_up_rounded, rotation: 0.08, size: 74),
        SizedBox(
          width: 8,
        ),
        _Coin(icon: Icons.savings_rounded, rotation: -0.05, size: 62),
      ],
    );
  }
}

class _Coin extends StatelessWidget {
  final IconData icon;
  final double rotation;
  final double size;

  const _Coin({required this.icon, required this.rotation, required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: size * 0.45),
      ),
    );
  }
}