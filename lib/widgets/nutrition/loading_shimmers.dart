// lib/widgets/nutrition/loading_shimmers.dart
// Shimmer loading skeletons for nutrition screens

import 'package:flutter/material.dart';

/// A simple shimmer placeholder that pulses
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
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
            color: Colors.grey.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Full shimmer placeholder for dashboard
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _shimmerCard(height: 150),
          const SizedBox(height: 16),
          _shimmerCard(height: 120),
          const SizedBox(height: 16),
          _shimmerCard(height: 80),
          const SizedBox(height: 16),
          _shimmerCard(height: 200),
        ],
      ),
    );
  }

  Widget _shimmerCard({double height = 100}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

/// Shimmer placeholder for add meal screen
class AddMealShimmer extends StatelessWidget {
  const AddMealShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Meal type chips
          SizedBox(
            height: 40,
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ShimmerPlaceholder(width: 60, height: 36, borderRadius: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Health warning skeleton
          ShimmerPlaceholder(height: 50, borderRadius: 12),
          const SizedBox(height: 16),
          // Selected foods card skeleton
          ShimmerPlaceholder(height: 120, borderRadius: 20),
          const SizedBox(height: 16),
          // Target nutrients card skeleton
          ShimmerPlaceholder(height: 150, borderRadius: 20),
          const SizedBox(height: 16),
          // Search section skeleton
          ShimmerPlaceholder(height: 50, borderRadius: 12),
          const SizedBox(height: 12),
          // Food items skeleton
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerPlaceholder(height: 60, borderRadius: 14),
          )),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for meal suggestions screen
class SuggestionsShimmer extends StatelessWidget {
  const SuggestionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerPlaceholder(height: 60, borderRadius: 12),
          const SizedBox(height: 16),
          ShimmerPlaceholder(height: 150, borderRadius: 20),
          const SizedBox(height: 16),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerPlaceholder(height: 80, borderRadius: 16),
          )),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for history screen
class HistoryShimmer extends StatelessWidget {
  const HistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerPlaceholder(height: 50, borderRadius: 16),
          const SizedBox(height: 16),
          ShimmerPlaceholder(height: 120, borderRadius: 20),
          const SizedBox(height: 16),
          ShimmerPlaceholder(height: 200, borderRadius: 16),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for analysis screen
class AnalysisShimmer extends StatelessWidget {
  const AnalysisShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerPlaceholder(height: 120, borderRadius: 20),
          const SizedBox(height: 16),
          ShimmerPlaceholder(height: 150, borderRadius: 16),
          const SizedBox(height: 16),
          ShimmerPlaceholder(height: 200, borderRadius: 16),
        ],
      ),
    );
  }
}