import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/mascot.dart';

/// Splash: mascot, wordmark and three pulsing dots, then on to the app.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _continue();
  }

  Future<void> _continue() async {
    final minimum = Future<void>.delayed(const Duration(milliseconds: 1400));
    Object? profile;
    try {
      profile = await ref.read(sessionProfileProvider.future);
    } catch (_) {
      profile = null;
    }
    await minimum;
    if (!mounted) return;
    if (profile == null) {
      context.go(Routes.welcome);
    } else {
      // Signed in: the router sends unfinished accounts back to onboarding.
      context.go(Routes.home);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: OgColors.night,
        body: Semantics(
          label: 'OlympusGO is loading',
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(size: 200),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      text: 'Olympus',
                      children: const [
                        TextSpan(
                          text: 'GO',
                          style: TextStyle(color: OgColors.orange300),
                        ),
                      ],
                    ),
                    style: OgText.display(
                      48,
                      height: 1,
                      color: OgColors.offWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 52),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Opacity(
                          opacity: reduceMotion
                              ? [1.0, 0.5, 0.25][i]
                              : _dotOpacity(i),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: OgColors.orange300,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The design's 1 / 0.5 / 0.25 dots, rotating which one is brightest.
  double _dotOpacity(int i) {
    const levels = [1.0, 0.5, 0.25];
    final step = (_pulse.value * 3).floor() % 3;
    return levels[(i - step) % 3];
  }
}
