import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GeneratingAnalysisText extends StatefulWidget {
  const GeneratingAnalysisText(
      {this.color = AppColors.red300, this.fontSize = 12, super.key});
  final Color color;
  final double fontSize;

  @override
  State<GeneratingAnalysisText> createState() => _GeneratingAnalysisTextState();
}

class _GeneratingAnalysisTextState extends State<GeneratingAnalysisText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Text('Generating Analysis…',
        style: TextStyle(
            color: AppColors.white, fontSize: widget.fontSize, height: 1.5));
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return Text('Generating Analysis…',
          style: TextStyle(
              color: widget.color, fontSize: widget.fontSize, height: 1.5));
    }
    return RepaintBoundary(
        child: AnimatedBuilder(
            animation: _controller,
            child: label,
            builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                        colors: [widget.color, AppColors.white, widget.color],
                        stops: const [0.15, 0.5, 0.85])
                    .createShader(Rect.fromLTWH(
                        bounds.left -
                            bounds.width +
                            _controller.value * bounds.width * 2,
                        bounds.top,
                        bounds.width,
                        bounds.height)),
                child: child)));
  }
}
