import 'package:flutter/material.dart';

import '../tokens/app_durations.dart';

/// A short fade-and-rise, staggered down a list.
///
/// Motion here is doing one job: telling the eye the order to read things in.
/// It is capped at a few items and a few hundred milliseconds, because an
/// animation the user has to wait for is worse than no animation at all.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final bool enabled;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _controller.value = 1;
      return;
    }
    // Stagger caps out quickly: the eighth row should not wait a second.
    final delayMs = (widget.index.clamp(0, 7)) * 45;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respects the system setting: someone who gets motion sick has asked for
    // no movement, and that is not a preference to override for polish.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppDurations.emphasised,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
