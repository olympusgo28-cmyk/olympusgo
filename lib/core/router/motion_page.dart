import 'package:flutter/cupertino.dart';

import '../theme/og_layout.dart';

/// A page that slides in the iOS way, or cross-fades when the phone asks for
/// reduced motion. Edge swipe-back works either way; with reduced motion the
/// page fades with the finger instead of moving, and the page underneath
/// stays still.
class MotionPage<T> extends Page<T> {
  const MotionPage({super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _MotionRoute<T>(this);
}

class _MotionRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _MotionRoute(MotionPage<T> page) : super(settings: page);

  static bool get _still => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  @override
  Widget buildContent(BuildContext context) =>
      (settings as MotionPage<T>).child;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      _still ? OgMotion.fade : super.transitionDuration;

  // Flutter runs every animation 20 times faster with reduced motion on,
  // which would turn the fade into a cut. The fade moves nothing, so it
  // keeps its length.
  @override
  AnimationController createAnimationController() => AnimationController(
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    debugLabel: debugLabel,
    vsync: navigator!,
    animationBehavior: _still
        ? AnimationBehavior.preserve
        : AnimationBehavior.normal,
  );

  // Without this the page underneath would still slide a third of the way
  // out while this one fades in.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      !_still && super.canTransitionFrom(previousRoute);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!MediaQuery.disableAnimationsOf(context)) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    // The iOS transition held at rest keeps its back-swipe detector, which
    // drives [animation], so a swipe fades the page out under the finger.
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: OgMotion.ease)),
      child: super.buildTransitions(
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      ),
    );
  }
}
