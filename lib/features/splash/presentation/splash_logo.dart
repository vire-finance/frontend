import 'dart:async';

import 'package:flutter/material.dart';

/// The PNG wordmark has a 19px transparent top margin. Its V occupies
/// x=0..50, y=19..60 in the 118x84 image; align the moving icon to that box.
class SplashLogo extends StatefulWidget {
  const SplashLogo({super.key});

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 870),
  );
  Timer? _hold;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    await precacheImage(
        const AssetImage('assets/images/Regular Images/Logo - V.png'), context);
    if (!mounted) return;
    await precacheImage(
        const AssetImage('assets/images/Regular Images/Logo - VIRE.png'),
        context);
    if (!mounted) return;
    _hold = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 118,
        height: 41,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            const arrival = 650 / 870;
            final slide =
                const Interval(0, arrival, curve: Curves.easeInOutCubic)
                    .transform(_controller.value);
            final reveal = const Interval(arrival, 1, curve: Curves.easeInOut)
                .transform(_controller.value);
            return Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: Opacity(
                  key: const ValueKey('splash-wordmark'),
                  opacity: reveal,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 118,
                      maxWidth: 118,
                      minHeight: 84,
                      maxHeight: 84,
                      child: Transform.translate(
                        offset: const Offset(0, -19),
                        child: Image.asset(
                          'assets/images/Regular Images/Logo - VIRE.png',
                          width: 118,
                          height: 84,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('splash-moving-v'),
                left: 34 * (1 - slide),
                top: 0,
                width: 50,
                height: 41,
                child: Opacity(
                  opacity: 1 - reveal,
                  child: Image.asset(
                    'assets/images/Regular Images/Logo - V.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ]);
          },
        ),
      );
}
