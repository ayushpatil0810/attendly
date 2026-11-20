import 'package:flutter/material.dart';
import 'package:attendly/core/theme/app_motion.dart';

/// An [IndexedStack] replacement that smoothly animates transitions between children
/// with a refined fade-through motion while preserving the state, scroll position,
/// and lifecycle of all tabs.
class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _fadeOutAnimation;
  late final Animation<Offset> _slideInAnimation;
  late final Animation<Offset> _slideOutAnimation;
  late int _currentIndex;
  int? _previousIndex;

  static const _stoppedOpacity = AlwaysStoppedAnimation<double>(1.0);
  static const _stoppedOffset = AlwaysStoppedAnimation<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _fadeInAnimation = _animation;
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_animation);
    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.015),
      end: Offset.zero,
    ).animate(_animation);
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.012),
    ).animate(_animation);

    _controller.addStatusListener(_handleStatus);
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _previousIndex = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final reduced = AppMotion.reduced(context);
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;

      if (reduced) {
        _previousIndex = null;
        _controller.value = 1.0;
      } else {
        _controller.duration = AppMotion.duration(context, widget.duration);
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _buildChild(i),
      ],
    );
  }

  Widget _buildChild(int index) {
    final isCurrent = index == _currentIndex;
    final isPrevious = index == _previousIndex;
    final isVisible = isCurrent || isPrevious;

    final Animation<double> opacityAnim;
    final Animation<Offset> slideAnim;

    if (isCurrent && _previousIndex != null) {
      opacityAnim = _fadeInAnimation;
      slideAnim = _slideInAnimation;
    } else if (isPrevious) {
      opacityAnim = _fadeOutAnimation;
      slideAnim = _slideOutAnimation;
    } else {
      opacityAnim = _stoppedOpacity;
      slideAnim = _stoppedOffset;
    }

    return KeyedSubtree(
      key: ValueKey('animated_tab_$index'),
      child: IgnorePointer(
        ignoring: !isCurrent,
        child: Offstage(
          offstage: !isVisible,
          child: TickerMode(
            enabled: isCurrent,
            child: FadeTransition(
              opacity: opacityAnim,
              child: SlideTransition(
                position: slideAnim,
                child: widget.children[index],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
