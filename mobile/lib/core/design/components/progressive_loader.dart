import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';

/// A spinner that sits there for ten seconds tells the user nothing (spec 65).
/// This walks through the real stages of the pipeline instead: Reading,
/// Understanding, Finding dates. Stages advance on a timer but stop at the last
/// one, so a slow analysis reads as "still working", never as "finished".
class ProgressiveLoader extends StatefulWidget {
  const ProgressiveLoader({
    super.key,
    required this.stages,
    this.stageDuration = const Duration(milliseconds: 1400),
  });

  final List<String> stages;
  final Duration stageDuration;

  @override
  State<ProgressiveLoader> createState() => _ProgressiveLoaderState();
}

class _ProgressiveLoaderState extends State<ProgressiveLoader> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.stageDuration, (_) {
      if (!mounted) return;
      if (_index >= widget.stages.length - 1) return;
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.stages.isEmpty ? '' : widget.stages[_index];

    return Semantics(
      liveRegion: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            switchInCurve: AppDurations.curve,
            child: Text(
              label,
              key: ValueKey(label),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
