import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Single pulsing animated skeleton box placeholder.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 1. HOME SCREEN SKELETON LOADING VIEW
// ============================================================================
class HomeSkeletonView extends StatelessWidget {
  const HomeSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding, 12, AppConstants.pagePadding, 24,
      ),
      children: [
        // Top Header bar placeholder
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 42, height: 42, borderRadius: 21),
            SkeletonBox(width: 120, height: 20, borderRadius: 8),
            SkeletonBox(width: 42, height: 42, borderRadius: 21),
          ],
        ),
        const SizedBox(height: 24),

        // Balance section placeholder
        const Center(child: SkeletonBox(width: 100, height: 14, borderRadius: 6)),
        const SizedBox(height: 10),
        const Center(child: SkeletonBox(width: 220, height: 40, borderRadius: 12)),
        const SizedBox(height: 14),
        const Center(child: SkeletonBox(width: 240, height: 32, borderRadius: 16)),
        const SizedBox(height: 28),

        // 4 Action Buttons placeholder
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (_) => Column(
            children: const [
              SkeletonBox(width: 58, height: 58, borderRadius: 18),
              SizedBox(height: 8),
              SkeletonBox(width: 48, height: 12, borderRadius: 6),
            ],
          )),
        ),
        const SizedBox(height: 32),

        // Transaction Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 120, height: 18, borderRadius: 8),
            SkeletonBox(width: 60, height: 14, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 16),

        // 4 Transaction Card Skeletons
        ...List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _TransactionCardSkeleton(),
        )),
      ],
    );
  }
}

// ============================================================================
// 2. TRANSACTIONS SCREEN SKELETON LOADING VIEW
// ============================================================================
class TransactionsSkeletonView extends StatelessWidget {
  const TransactionsSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding, 8, AppConstants.pagePadding, 24,
      ),
      children: [
        // Segment filter bar placeholder
        const SkeletonBox(height: 48, borderRadius: 16),
        const SizedBox(height: 12),

        // Search field placeholder
        const SkeletonBox(height: 48, borderRadius: 16),
        const SizedBox(height: 20),

        // Date header placeholder
        const SkeletonBox(width: 80, height: 14, borderRadius: 6),
        const SizedBox(height: 12),

        // 5 Transaction Card Skeletons
        ...List.generate(5, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _TransactionCardSkeleton(),
        )),
      ],
    );
  }
}

// ============================================================================
// 3. STATISTICS SCREEN SKELETON LOADING VIEW
// ============================================================================
class StatisticsSkeletonView extends StatelessWidget {
  const StatisticsSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding, 8, AppConstants.pagePadding, 32,
      ),
      children: [
        // Month Selector Bar placeholder
        const SkeletonBox(height: 52, borderRadius: 16),
        const SizedBox(height: 16),

        // Balance Card placeholder
        const SkeletonBox(height: 140, borderRadius: 24),
        const SizedBox(height: 24),

        // Category Type Toggle Bar placeholder
        const SkeletonBox(height: 46, borderRadius: 16),
        const SizedBox(height: 20),

        // Category Overview Card placeholder
        const SkeletonBox(height: 110, borderRadius: 18),
        const SizedBox(height: 16),

        // 3 Category Item Card Skeletons
        ...List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _CategoryItemSkeleton(),
        )),
      ],
    );
  }
}

// ============================================================================
// 4. PROFILE SCREEN SKELETON LOADING VIEW
// ============================================================================
class ProfileSkeletonView extends StatelessWidget {
  const ProfileSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding, 8, AppConstants.pagePadding, 32,
      ),
      children: [
        // Hero Profile Card placeholder
        const SkeletonBox(height: 200, borderRadius: 24),
        const SizedBox(height: 16),

        // 2 Mini info cards placeholders
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 68, borderRadius: 18)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 68, borderRadius: 18)),
          ],
        ),
        const SizedBox(height: 24),

        // Section title
        const SkeletonBox(width: 120, height: 16, borderRadius: 6),
        const SizedBox(height: 12),

        // 3 Setting Tile placeholders
        ...List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: SkeletonBox(height: 60, borderRadius: 16),
        )),
      ],
    );
  }
}

// ============================================================================
// SUB-SKELETONS: การ์ดธุรกรรมย่อย และ การ์ดหมวดหมู่ย่อย
// ============================================================================
class _TransactionCardSkeleton extends StatelessWidget {
  const _TransactionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 130, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 11, borderRadius: 5),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonBox(width: 70, height: 14, borderRadius: 6),
              SizedBox(height: 6),
              SkeletonBox(width: 40, height: 11, borderRadius: 5),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItemSkeleton extends StatelessWidget {
  const _CategoryItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SkeletonBox(width: 44, height: 44, borderRadius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 110, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 60, height: 11, borderRadius: 5),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SkeletonBox(width: 70, height: 14, borderRadius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 36, height: 16, borderRadius: 8),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 6, borderRadius: 3),
        ],
      ),
    );
  }
}
