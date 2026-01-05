import 'package:flutter/material.dart';

class RegisterDotsIndicator extends StatelessWidget {
  const RegisterDotsIndicator({
    super.key,
    required this.activeIndex,
  });

  final int activeIndex;

  static const Color _activeColor = Color(0xFFE67E22);
  static const Color _inactiveColor = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _Dot(index: 0),
        SizedBox(width: 8),
        _Dot(index: 1),
        SizedBox(width: 8),
        _Dot(index: 2),
      ],
    );
  }

  static Color colorForIndex(int index, int activeIndex) {
    return index == activeIndex ? _activeColor : _inactiveColor;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final parent =
    context.findAncestorWidgetOfExactType<RegisterDotsIndicator>()!;
    final isActive = index == parent.activeIndex;

    if (isActive) {
      return const _ActiveDot();
    }
    return const _InactiveDot();
  }
}

class _InactiveDot extends StatelessWidget {
  const _InactiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: RegisterDotsIndicator._inactiveColor,
      ),
    );
  }
}

class _ActiveDot extends StatefulWidget {
  const _ActiveDot();

  @override
  State<_ActiveDot> createState() => _ActiveDotState();
}

class _ActiveDotState extends State<_ActiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: RegisterDotsIndicator._activeColor,
        ),
      ),
    );
  }
}
