import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  final double speedPxPerSecond;

  final double minScrollExtent;

  final Duration minScrollDuration;

  final Duration pauseDuration;

  final Duration initialDelay;

  final int maxLines;
  final int maxLoops;

  const MarqueeText({
    Key? key,
    required this.text,
    required this.style,
    this.speedPxPerSecond = 80.0,
    this.minScrollExtent = 24.0,
    this.minScrollDuration = const Duration(milliseconds: 2500),
    this.pauseDuration = const Duration(milliseconds: 1000),
    this.initialDelay = const Duration(milliseconds: 2000),
    this.maxLines = 1,
    this.maxLoops = 2,
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _controller;

  double _maxScrollExtent = 0.0;
  bool _isOverflowing = false;
  int _completedLoops = 0;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _previousText = widget.text;
    _controller = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateForOverflow());
  }

  void _onTick() {
    if (!_scrollController.hasClients) return;
    final offset = (_controller.value * _maxScrollExtent).clamp(
      0.0,
      _maxScrollExtent,
    );
    _scrollController.jumpTo(offset);
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted || !_isOverflowing) return;

    if (status == AnimationStatus.completed) {
      Future.delayed(widget.pauseDuration, () {
        if (!mounted) return;

        final computedSlowMs =
            (_maxScrollExtent / widget.speedPxPerSecond * 1000).round();
        final slowMs = computedSlowMs < widget.minScrollDuration.inMilliseconds
            ? widget.minScrollDuration.inMilliseconds
            : computedSlowMs;
        final fastMs = (slowMs / 2.5).round().clamp(800, slowMs);

        _controller.duration = Duration(milliseconds: fastMs);
        _controller.reverse(from: 1.0);
      });
    } else if (status == AnimationStatus.dismissed) {
      _completedLoops += 1;
      if (_completedLoops >= widget.maxLoops) {
        _controller.stop();
        return;
      }

      Future.delayed(widget.pauseDuration, () {
        if (!mounted) return;

        final computedSlowMs =
            (_maxScrollExtent / widget.speedPxPerSecond * 1000).round();
        final slowMs = computedSlowMs < widget.minScrollDuration.inMilliseconds
            ? widget.minScrollDuration.inMilliseconds
            : computedSlowMs;

        _controller.duration = Duration(milliseconds: slowMs);
        _controller.forward(from: 0.0);
      });
    }
  }

  void _updateForOverflow() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;

    final overflowing = maxExtent > widget.minScrollExtent;

    if (overflowing && !_isOverflowing) {
      _isOverflowing = true;
      _completedLoops = 0;
      _maxScrollExtent = maxExtent;

      final computedSlowMs = (_maxScrollExtent / widget.speedPxPerSecond * 1000)
          .round();
      final slowMs = computedSlowMs < widget.minScrollDuration.inMilliseconds
          ? widget.minScrollDuration.inMilliseconds
          : computedSlowMs;

      _controller.duration = Duration(milliseconds: slowMs);
      Future.delayed(widget.initialDelay, () {
        if (!mounted || !_isOverflowing) return;
        _controller.forward(from: 0.0);
      });
      setState(() {});
    } else if (!overflowing && _isOverflowing) {
      _isOverflowing = false;
      _completedLoops = 0;
      _controller.stop();
      _scrollController.jumpTo(0);
      setState(() {});
    } else if (overflowing) {
      _maxScrollExtent = maxExtent;
    }
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _previousText || widget.style != oldWidget.style) {
      _previousText = widget.text;
      _completedLoops = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollController.jumpTo(0);
        _updateForOverflow();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateForOverflow());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: ClipRect(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: widget.style,
                maxLines: widget.maxLines,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        );
      },
    );
  }
}
