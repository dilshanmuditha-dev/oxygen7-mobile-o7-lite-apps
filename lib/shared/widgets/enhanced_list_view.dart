// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/device_performance_detector.dart';

/// Enhanced ListView with automatic performance optimizations
///
/// Features:
/// - Automatic itemExtent calculation for uniform items
/// - Device-adaptive cache extent
/// - Optimized scroll physics
/// - Memory-efficient rendering
/// - RepaintBoundary for complex items
class EnhancedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final double? itemExtent;
  final bool addRepaintBoundary;
  final String? semanticLabel;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addSemanticIndexes;

  const EnhancedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.itemExtent,
    this.addRepaintBoundary = true,
    this.semanticLabel,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addSemanticIndexes = true,
  }) : super(key: key);

  /// Factory for transaction list with optimized settings
  factory EnhancedListView.transactions({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return EnhancedListView(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      padding: padding,
      itemExtent: 120.0, // Fixed height for transaction items
      addRepaintBoundary: true,
      semanticLabel: 'Transaction List',
      addAutomaticKeepAlives: false, // Disable for better memory usage
    );
  }

  /// Factory for simple lists with minimal overhead
  factory EnhancedListView.simple({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
    double? itemHeight,
  }) {
    return EnhancedListView(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      padding: padding,
      itemExtent: itemHeight,
      addRepaintBoundary: false, // Skip for simple items
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemExtent: itemExtent,
      // Use optimal physics based on device capability
      physics: physics ?? _getOptimalPhysics(detector),
      // Use optimal cache extent
      cacheExtent: _getOptimalCacheExtent(detector),
      // Optimize for memory usage on low-spec devices
      addAutomaticKeepAlives:
          detector.isInitialized && detector.shouldUseSimplifiedUI()
              ? false
              : addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundary,
      addSemanticIndexes: addSemanticIndexes,
      semanticChildCount: semanticLabel != null ? itemCount : null,
      itemBuilder: (context, index) {
        Widget child = itemBuilder(context, index);

        // Add RepaintBoundary for complex items on capable devices
        if (addRepaintBoundary &&
            (!detector.isInitialized || !detector.shouldUseSimplifiedUI())) {
          child = RepaintBoundary(
            key: ValueKey('enhanced_list_item_$index'),
            child: child,
          );
        }

        return child;
      },
    );
  }

  /// Get optimal scroll physics based on device capability
  ScrollPhysics _getOptimalPhysics(DevicePerformanceDetector detector) {
    if (!detector.isInitialized) {
      return const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics());
    }

    return detector.getOptimalScrollPhysics();
  }

  /// Get optimal cache extent based on device capability
  double _getOptimalCacheExtent(DevicePerformanceDetector detector) {
    if (!detector.isInitialized) {
      return 250.0; // Conservative default
    }

    return detector.getOptimalCacheExtent();
  }
}

/// Enhanced SliverList for use in CustomScrollView
class EnhancedSliverList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double? itemExtent;
  final bool addRepaintBoundary;

  const EnhancedSliverList({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.addRepaintBoundary = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    if (itemExtent != null) {
      // Use SliverFixedExtentList for better performance when item height is known
      return SliverFixedExtentList(
        itemExtent: itemExtent!,
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildItem(context, index, detector),
          childCount: itemCount,
          addAutomaticKeepAlives:
              detector.isInitialized && detector.shouldUseSimplifiedUI()
                  ? false
                  : true,
          addRepaintBoundaries: addRepaintBoundary,
        ),
      );
    } else {
      // Use regular SliverList for variable height items
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildItem(context, index, detector),
          childCount: itemCount,
          addAutomaticKeepAlives:
              detector.isInitialized && detector.shouldUseSimplifiedUI()
                  ? false
                  : true,
          addRepaintBoundaries: addRepaintBoundary,
        ),
      );
    }
  }

  Widget _buildItem(
      BuildContext context, int index, DevicePerformanceDetector detector) {
    Widget child = itemBuilder(context, index);

    // Add RepaintBoundary for complex items on capable devices
    if (addRepaintBoundary &&
        (!detector.isInitialized || !detector.shouldUseSimplifiedUI())) {
      child = RepaintBoundary(
        key: ValueKey('enhanced_sliver_item_$index'),
        child: child,
      );
    }

    return child;
  }
}

/// Memory-efficient GridView alternative
class EnhancedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final bool addRepaintBoundary;

  const EnhancedGridView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.addRepaintBoundary = true,
  }) : super(key: key);

  /// Factory for fixed cross axis count with performance optimizations
  factory EnhancedGridView.count({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return EnhancedGridView(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      // Use optimal physics and cache
      physics: detector.isInitialized
          ? detector.getOptimalScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
      cacheExtent:
          detector.isInitialized ? detector.getOptimalCacheExtent() : 250.0,
      itemBuilder: (context, index) {
        Widget child = itemBuilder(context, index);

        // Add RepaintBoundary for complex items
        if (addRepaintBoundary &&
            (!detector.isInitialized || !detector.shouldUseSimplifiedUI())) {
          child = RepaintBoundary(
            key: ValueKey('enhanced_grid_item_$index'),
            child: child,
          );
        }

        return child;
      },
    );
  }
}

/// Optimized PageView for smooth page transitions
class EnhancedPageView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final PageController? controller;
  final Axis scrollDirection;
  final bool pageSnapping;
  final ValueChanged<int>? onPageChanged;

  const EnhancedPageView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.pageSnapping = true,
    this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    return PageView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      pageSnapping: pageSnapping,
      onPageChanged: onPageChanged,
      itemCount: itemCount,
      // Optimize physics for device capability
      physics: detector.isInitialized && detector.shouldUseSimplifiedUI()
          ? const ClampingScrollPhysics()
          : const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        Widget child = itemBuilder(context, index);

        // Add RepaintBoundary for smooth page transitions
        return RepaintBoundary(
          key: ValueKey('enhanced_page_$index'),
          child: child,
        );
      },
    );
  }
}

/// Performance monitoring for lists
class ListPerformanceMonitor {
  static final Map<String, DateTime> _scrollStartTimes = {};
  static final Map<String, int> _frameDropCounts = {};

  /// Start monitoring scroll performance
  static void startScrollMonitoring(String listId) {
    _scrollStartTimes[listId] = DateTime.now();
    _frameDropCounts[listId] = 0;
  }

  /// Record frame drop
  static void recordFrameDrop(String listId) {
    _frameDropCounts[listId] = (_frameDropCounts[listId] ?? 0) + 1;
  }

  /// End monitoring and get performance metrics
  static Map<String, dynamic> endScrollMonitoring(String listId) {
    final startTime = _scrollStartTimes[listId];
    final frameDrops = _frameDropCounts[listId] ?? 0;

    if (startTime == null) {
      return {'error': 'Monitoring not started for $listId'};
    }

    final duration = DateTime.now().difference(startTime);

    // Clean up
    _scrollStartTimes.remove(listId);
    _frameDropCounts.remove(listId);

    return {
      'listId': listId,
      'duration': duration.inMilliseconds,
      'frameDrops': frameDrops,
      'fps': frameDrops > 0 ? 60 - (frameDrops * 2) : 60, // Estimate FPS
    };
  }

  /// Get current performance stats
  static Map<String, dynamic> getCurrentStats() {
    return {
      'activeMonitors': _scrollStartTimes.length,
      'totalFrameDrops':
          _frameDropCounts.values.fold<int>(0, (sum, value) => sum + value),
    };
  }
}
