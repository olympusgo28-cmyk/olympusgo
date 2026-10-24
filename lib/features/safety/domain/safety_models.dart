import '../../../core/domain/country.dart';

/// Where a report stands.
enum ReportState {
  inReview('In review'),
  removed('Removed'),
  noAction('No action');

  const ReportState(this.label);
  final String label;
}

/// Something the player reported, and what happened to it.
class SafetyReport {
  const SafetyReport({
    required this.id,
    required this.what,
    required this.reason,
    required this.at,
    required this.state,
    required this.initials,
    required this.heading,
    required this.detail,
    this.steps = const [],
    this.decideBy,
    this.result,
    this.secondLook = false,
  });

  final String id;

  /// "Message · Tampines Smashers".
  final String what;

  /// "Personal details shared".
  final String reason;
  final DateTime at;
  final ReportState state;
  final String initials;

  /// "Message in Tampines Smashers chat".
  final String heading;

  /// "Kelvin Ho, 9:15 AM".
  final String detail;

  /// Title and line, oldest first.
  final List<(String, String)> steps;

  /// "By tomorrow, 9:24 AM at the latest", while in review.
  final String? decideBy;

  /// Why it was kept or removed, once decided.
  final String? result;

  /// Asked for a second look by a different reviewer.
  final bool secondLook;

  SafetyReport copyWith({bool? secondLook}) => SafetyReport(
    id: id,
    what: what,
    reason: reason,
    at: at,
    state: state,
    initials: initials,
    heading: heading,
    detail: detail,
    steps: steps,
    decideBy: decideBy,
    result: result,
    secondLook: secondLook ?? this.secondLook,
  );
}

/// We removed something the player posted.
class RemovalNotice {
  const RemovalNotice({
    required this.id,
    required this.what,
    required this.where,
    required this.rule,
    required this.decidedBy,
    required this.why,
    required this.next,
    this.reviewAsked = false,
  });

  final String id;

  /// "Your message of Thu 1 Oct, 8:02 PM".
  final String what;
  final String where;
  final String rule;
  final String decidedBy;
  final String why;
  final List<String> next;
  final bool reviewAsked;

  RemovalNotice asked() => RemovalNotice(
    id: id,
    what: what,
    where: where,
    rule: rule,
    decidedBy: decidedBy,
    why: why,
    next: next,
    reviewAsked: true,
  );
}

/// A legal notice from someone harmed by content, or acting for them.
class LegalNotice {
  const LegalNotice({
    required this.role,
    required this.name,
    required this.email,
    required this.country,
    required this.location,
    required this.reasons,
    required this.details,
  });

  /// "The person affected", "Parent or guardian", and so on.
  final String role;
  final String name;
  final String email;
  final Country country;

  /// A link, or the club, chat, video or shop name.
  final String location;
  final List<String> reasons;
  final String details;
}
