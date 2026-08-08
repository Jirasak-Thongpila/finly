import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/drawer_actions.dart';

/// Navigation drawer: user header + menu + logout.
///
/// Navigation actions are emitted to the parent Home screen via
/// [onNavigate] / [onAddTransaction] / [onLogout], so the drawer stays
/// presentational and reusable.
class AppDrawer extends StatelessWidget {
  final User? user;
  final ValueChanged<DrawerAction> onNavigate;
  final ValueChanged<String> onAddTransaction;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.user,
    required this.onNavigate,
    required this.onAddTransaction,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: AppColors.textPrimary),
          title: Text(label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
        );

    final divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 1,
      color: AppColors.divider,
    );

    return Drawer(
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _Header(user: user),
            divider,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  tile(Icons.home_rounded, 'Home',
                      () => onNavigate(DrawerAction.home)),
                  tile(Icons.receipt_long_outlined, 'Transactions',
                      () => onNavigate(DrawerAction.transactions)),
                  tile(Icons.add_circle_outline, 'Add Income',
                      () => onAddTransaction('income')),
                  tile(Icons.remove_circle_outline, 'Add Expense',
                      () => onAddTransaction('expense')),
                  tile(Icons.pie_chart_outline_rounded, 'Statistics',
                      () => onNavigate(DrawerAction.statistics)),
                  tile(Icons.settings_outlined, 'Settings',
                      () => onNavigate(DrawerAction.settings)),
                  divider,
                  tile(
                    Icons.logout_rounded,
                    'Logout',
                    () {
                      Navigator.of(context).pop();
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;

  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Welcome';
    final email = user?.email ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              (user?.initials ?? 'U'),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}