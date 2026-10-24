import 'tab_widgets.dart';

/// Suggested players on Discover, from the design. Replace with a
/// suggestions query once there is enough play data to rank players.
abstract final class SampleContent {
  static const players = [
    (
      initials: 'SL',
      name: 'Sara Lim',
      detail: 'Badminton · Level 4.5',
      tone: AvatarTone.yellow,
    ),
    (
      initials: 'MT',
      name: 'Marcus Tan',
      detail: 'Pickleball · Level 3.5',
      tone: AvatarTone.green,
    ),
  ];
}
