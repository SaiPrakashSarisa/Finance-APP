import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Purpose: Reusable Skeleton Loader Components for Data Fetching States
/// Author: Antigravity AI
/// Design System: Stitch Finance Hub Enterprise (Luminous Ledger)
///
/// Provides layout-matching skeleton placeholders that replace generic
/// CircularProgressIndicator spinners with smooth shimmer animations.

// ─────────────────────────────────────────────────────────────────────────────
// CORE: Shimmer Animation Container
// ─────────────────────────────────────────────────────────────────────────────

/// A single skeleton bone with shimmer sweep animation.
/// All skeleton loaders are composed from this primitive.
class SkeletonBone extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const SkeletonBone({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<SkeletonBone> createState() => _SkeletonBoneState();
}

class _SkeletonBoneState extends State<SkeletonBone> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                AppColors.surfaceContainer,
                AppColors.surfaceContainerHigh,
                AppColors.surfaceContainerHighest,
                AppColors.surfaceContainerHigh,
                AppColors.surfaceContainer,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSITE: Skeleton Row (icon + text lines)
// ─────────────────────────────────────────────────────────────────────────────

/// A generic list-item skeleton: leading circle + two text lines + trailing block.
/// Used for transaction rows, category rows, credit rows.
class SkeletonListTile extends StatelessWidget {
  final bool hasTrailing;
  final double leadingSize;

  const SkeletonListTile({
    super.key,
    this.hasTrailing = true,
    this.leadingSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Leading circle (icon placeholder)
          SkeletonBone(
            width: leadingSize,
            height: leadingSize,
            borderRadius: leadingSize / 2,
          ),
          const SizedBox(width: 14),
          // Title + subtitle lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(
                  width: 120 + (hashCode % 40).toDouble(),
                  height: 14,
                  borderRadius: 6,
                ),
                const SizedBox(height: 8),
                SkeletonBone(
                  width: 80 + (hashCode % 30).toDouble(),
                  height: 10,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          if (hasTrailing)
            const SkeletonBone(width: 60, height: 16, borderRadius: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Dashboard Skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Matches the dashboard layout: balance card + account carousel + recent transactions.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance / Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: 100, height: 12, borderRadius: 4),
                SizedBox(height: 12),
                SkeletonBone(width: 180, height: 32, borderRadius: 8),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: SkeletonBone(width: double.infinity, height: 48, borderRadius: 12)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBone(width: double.infinity, height: 48, borderRadius: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section header
          const SkeletonBone(width: 130, height: 16, borderRadius: 6),
          const SizedBox(height: 12),

          // Account cards carousel
          SizedBox(
            height: 135,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBone(width: 32, height: 32, borderRadius: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(width: 80, height: 10, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBone(width: 100, height: 18, borderRadius: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // "Recent Transactions" header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBone(width: 160, height: 16, borderRadius: 6),
              SkeletonBone(width: 50, height: 12, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 12),

          // Transaction row skeletons
          ...List.generate(5, (_) => const SkeletonListTile()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Dashboard Account Cards Skeleton (horizontal carousel only)
// ─────────────────────────────────────────────────────────────────────────────

class AccountCardsSkeleton extends StatelessWidget {
  const AccountCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBone(width: 32, height: 32, borderRadius: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: 80, height: 10, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBone(width: 100, height: 18, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Dashboard Transactions Skeleton (list only)
// ─────────────────────────────────────────────────────────────────────────────

class TransactionListSkeleton extends StatelessWidget {
  final int count;
  const TransactionListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const SkeletonListTile()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Transactions Screen Full Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class TransactionsScreenSkeleton extends StatelessWidget {
  const TransactionsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonBone(
            width: MediaQuery.of(context).size.width - 32,
            height: 44,
            borderRadius: 12,
          ),
        ),
        const SizedBox(height: 4),
        // Filter chips skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SkeletonBone(
                  width: 65 + (i * 10).toDouble(),
                  height: 32,
                  borderRadius: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Transaction rows
        const Expanded(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: TransactionListSkeleton(count: 8),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Accounts Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class AccountsScreenSkeleton extends StatelessWidget {
  const AccountsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Net worth header card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: 80, height: 12, borderRadius: 4),
                SizedBox(height: 10),
                SkeletonBone(width: 160, height: 28, borderRadius: 8),
              ],
            ),
          ),
          // Account list items
          ...List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Row(
                children: [
                  SkeletonBone(width: 44, height: 44, borderRadius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(width: 120, height: 14, borderRadius: 6),
                        SizedBox(height: 8),
                        SkeletonBone(width: 70, height: 10, borderRadius: 4),
                      ],
                    ),
                  ),
                  SkeletonBone(width: 80, height: 18, borderRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Analytics Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsScreenSkeleton extends StatelessWidget {
  const AnalyticsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: SkeletonBone(width: double.infinity, height: 56, borderRadius: 12)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBone(width: double.infinity, height: 56, borderRadius: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chart placeholder
          const SkeletonBone(width: 120, height: 14, borderRadius: 6),
          const SizedBox(height: 12),
          SkeletonBone(width: width - 32, height: 200, borderRadius: 16),
          const SizedBox(height: 24),

          // Category breakdown rows
          const SkeletonBone(width: 150, height: 14, borderRadius: 6),
          const SizedBox(height: 12),
          ...List.generate(4, (_) => const SkeletonListTile()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Budgets Tab Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class BudgetsTabSkeleton extends StatelessWidget {
  const BudgetsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBone(width: 100, height: 12, borderRadius: 4),
                    SkeletonBone(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonBone(width: double.infinity, height: 8, borderRadius: 4),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: SkeletonBone(width: double.infinity, height: 48, borderRadius: 12)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBone(width: double.infinity, height: 48, borderRadius: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Budget category rows
          const SkeletonBone(width: 130, height: 14, borderRadius: 6),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBone(width: 36, height: 36, borderRadius: 10),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBone(width: 100, height: 12, borderRadius: 4),
                            SizedBox(height: 6),
                            SkeletonBone(width: 70, height: 10, borderRadius: 4),
                          ],
                        ),
                      ),
                      SkeletonBone(width: 60, height: 14, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 10),
                  SkeletonBone(width: double.infinity, height: 6, borderRadius: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Credits Tab Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class CreditsTabSkeleton extends StatelessWidget {
  const CreditsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SkeletonBone(
                  width: 60 + (i * 12).toDouble(),
                  height: 30,
                  borderRadius: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Credit cards
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBone(width: 40, height: 40, borderRadius: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBone(width: 110, height: 14, borderRadius: 6),
                            SizedBox(height: 6),
                            SkeletonBone(width: 80, height: 10, borderRadius: 4),
                          ],
                        ),
                      ),
                      SkeletonBone(width: 70, height: 18, borderRadius: 6),
                    ],
                  ),
                  SizedBox(height: 12),
                  SkeletonBone(width: double.infinity, height: 6, borderRadius: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN-SPECIFIC: Categories Screen Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class CategoriesScreenSkeleton extends StatelessWidget {
  const CategoriesScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkeletonBone(width: 40, height: 40, borderRadius: 12),
            SizedBox(height: 10),
            SkeletonBone(width: 60, height: 10, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
