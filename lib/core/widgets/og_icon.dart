import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The stroke icons drawn in the OlympusGO artboards, kept as the same SVG
/// geometry so they render identically. Each value is the inner markup of a
/// 24×24 viewBox.
abstract final class OgIcons {
  static const back = '<path d="M15 5l-7 7 7 7"/>';
  static const chevronRight = '<path d="M9 5l7 7-7 7"/>';
  static const chevronDown = '<path d="M6 9l6 6 6-6"/>';
  static const check = '<path d="M5 12.5l4.5 4.5L19 7"/>';
  static const home = '<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/>';
  static const discover =
      '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>';
  static const torch =
      '<path d="M8 3h8l-1.5 6h-5zM9.5 9v9a2.5 2.5 0 0 0 5 0V9"/>';
  static const scan =
      '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M8 12h8"/>';
  static const inbox =
      '<rect x="3.5" y="5.5" width="17" height="13" rx="3"/><path d="M4.5 7.5L12 13l7.5-5.5"/>';
  static const person =
      '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-6.5 8-6.5s8 2.5 8 6.5"/>';
  static const faceId =
      '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M9 10v1.5M15 10v1.5M12 10v3.5h-1M9 16c1.7 1.4 4.3 1.4 6 0"/>';
  static const phone =
      '<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M11 18.5h2"/>';
  static const mail =
      '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M4 7l8 6 8-6"/>';
  static const mailRound =
      '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M4 7l8 6 8-6"/>';
  static const shield =
      '<path d="M12 3l7 3v5c0 4.6-3 8.3-7 10-4-1.7-7-5.4-7-10V6z"/><path d="M9 12l2.2 2.2L15.5 10"/>';
  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>';
  static const people =
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6M16 5a3.5 3.5 0 0 1 0 6.5M18 14c2.3.7 3.5 2.6 3.5 5"/>';
  static const bag = '<path d="M5 8h14l-1 12H6zM9 8V6a3 3 0 0 1 6 0v2"/>';
  static const academy =
      '<path d="M2 9l10-5 10 5-10 5z"/><path d="M6 11v5c3 2 9 2 12 0v-5"/>';
  static const pin =
      '<path d="M12 21s-7-6-7-11a7 7 0 0 1 14 0c0 5-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>';
  static const idCard =
      '<rect x="3" y="5" width="18" height="14" rx="3"/><circle cx="9" cy="11" r="2.2"/><path d="M5.5 16c.6-1.8 2-2.5 3.5-2.5s2.9.7 3.5 2.5M14.5 10h4M14.5 13h3"/>';
  static const gear =
      '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>';
  static const share =
      '<path d="M12 15V4M8 8l4-4 4 4"/><path d="M5 12v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/>';

  static const bell =
      '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 21h4"/>';
  static const wallet =
      '<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18M16 14.5h2"/>';
  static const bookmark = '<path d="M6 4h12v17l-6-4-6 4z"/>';
  static const block =
      '<circle cx="12" cy="12" r="9"/><path d="M5.6 5.6l12.8 12.8"/>';
  static const help =
      '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7M12 17h.01"/>';
  static const logOut =
      '<path d="M9 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h3M16 8l4 4-4 4M20 12H9"/>';
  static const send = '<path d="M4 12l16-8-6 16-2-7z"/>';
  static const more =
      '<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>';
  static const clock = '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>';
  static const location =
      '<path d="M12 21s7-6.2 7-11.5A7 7 0 0 0 5 9.5C5 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const cart =
      '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M3 4h2.5l2.2 11h10.3l2-8H6.5"/>';
  static const lock =
      '<rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';

  static const calendar =
      '<rect x="3.5" y="5" width="17" height="15" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>';
  static const filters = '<path d="M4 6h16M7 12h10M10 18h4"/>';
  static const trophy =
      '<path d="M7 4h10v5a5 5 0 0 1-10 0zM7 6H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3M12 14v4M8 20h8"/>';
  static const pinSmall =
      '<path d="M12 21s7-6.2 7-11a7 7 0 0 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>';

  // Sports.
  static const badminton =
      '<path d="M12 20L6 4M12 20l6-16M12 20V4"/><path d="M5 4h14"/><circle cx="12" cy="20.5" r="1.5"/>';
  static const pickleball =
      '<rect x="4" y="3" width="11" height="12" rx="5"/><path d="M9.5 15v6"/><circle cx="18" cy="18" r="3"/>';
  static const tennis =
      '<circle cx="12" cy="12" r="9"/><path d="M5 5.5c4 3 4 10 0 13M19 5.5c-4 3-4 10 0 13"/>';
  static const padel =
      '<rect x="6" y="2.5" width="12" height="13" rx="6"/><path d="M12 15.5V21"/><path d="M10 7h.01M14 7h.01M12 10h.01"/>';
  static const tableTennis =
      '<circle cx="10" cy="10" r="7"/><path d="M15 15l5 5"/><circle cx="19" cy="6" r="1.5"/>';
  static const basketball =
      '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3v18M5.5 5.5c3 3 3 10 0 13M18.5 5.5c-3 3-3 10 0 13"/>';
  static const football =
      '<circle cx="12" cy="12" r="9"/><path d="M12 8l3.5 2.5-1.3 4H9.8l-1.3-4z"/><path d="M12 8V3M15.5 10.5l4.5-1.5M14.2 14.5l3 3.5M9.8 14.5l-3 3.5M8.5 10.5L4 9"/>';
  static const running =
      '<circle cx="14" cy="4.5" r="2"/><path d="M11 20l2-6-3-3 2-4 4 2 3 1M9 13l-3 1M12 14l4 6"/>';
  static const swimming =
      '<circle cx="16" cy="6" r="2"/><path d="M4 14l5-4 4 2 3-2"/><path d="M3 18c1.5 1 3 1 4.5 0s3-1 4.5 0 3 1 4.5 0 3-1 4.5 0"/>';
  static const cycling =
      '<circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M6 16l4-8h5l3 8M10 8l3 8M9 5h3"/>';

  // Club, team and shop artboards (phase 3).
  static const arrowBack = '<path d="M19 12H5M11 6l-6 6 6 6"/>';
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const closeSmall = '<path d="M7 7l10 10M17 7L7 17"/>';
  static const tick = '<path d="M5 12.5l4.5 4.5L19 7.5"/>';
  static const chevronUp = '<path d="M6 15l6-6 6 6"/>';
  static const sliders =
      '<path d="M4 7h10M18 7h2M4 17h2M10 17h10"/><circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/>';
  static const group =
      '<circle cx="9" cy="8" r="3.2"/><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><path d="M16 5.2a3 3 0 0 1 0 5.6M18 14.5c1.8.8 3 2.7 3 5"/>';
  static const shareUp =
      '<path d="M12 3v12M7 8l5-5 5 5"/><path d="M5 13v6a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-6"/>';
  static const shareTray = '<path d="M12 15V4M8 8l4-4 4 4M5 13v6h14v-6"/>';
  static const mapPin =
      '<path d="M12 21s-6-5.5-6-11a6 6 0 0 1 12 0c0 5.5-6 11-6 11z"/><circle cx="12" cy="10" r="2.2"/>';
  static const padlock =
      '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';
  static const cog =
      '<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>';
  static const settings =
      '<path d="M10.3 3.2h3.4l.5 2.4c.6.2 1.2.6 1.7 1l2.3-.8 1.7 2.9-1.8 1.6c.1.6.1 1.2 0 1.8l1.8 1.6-1.7 2.9-2.3-.8c-.5.4-1.1.8-1.7 1l-.5 2.4h-3.4l-.5-2.4c-.6-.2-1.2-.6-1.7-1l-2.3.8-1.7-2.9 1.8-1.6a6 6 0 0 1 0-1.8L4.1 8.7l1.7-2.9 2.3.8c.5-.4 1.1-.8 1.7-1z"/><circle cx="12" cy="12" r="3"/>';
  static const personRequest =
      '<circle cx="12" cy="8" r="3.6"/><path d="M4.5 20c0-4 3.4-6.5 7.5-6.5s7.5 2.5 7.5 6.5"/>';
  static const megaphone =
      '<path d="M4 10v4a1 1 0 0 0 1 1h2l5 4V5L7 9H5a1 1 0 0 0-1 1z"/><path d="M16 9a4 4 0 0 1 0 6M19 6.5a8 8 0 0 1 0 11"/>';
  static const racquet =
      '<ellipse cx="14.5" cy="9.5" rx="5.5" ry="6.5" transform="rotate(35 14.5 9.5)"/><path d="M10.6 14.6L4 21.2"/>';
  static const racquetStrings =
      '<ellipse cx="14.5" cy="9.5" rx="5.5" ry="6.5" transform="rotate(35 14.5 9.5)"/><path d="M10.6 14.6L4 21.2"/><path d="M11.5 6.5l6 6M13.5 4.2l5.7 5.7"/>';
  static const male =
      '<circle cx="10" cy="14" r="5.5"/><path d="M14 10l6-6M15 4h5v5"/>';
  static const female =
      '<circle cx="12" cy="9" r="5.5"/><path d="M12 14.5V22M8.5 18.5h7"/>';
  static const bookmarkTall = '<path d="M6 3.5h12v17l-6-4.2-6 4.2z"/>';
  static const calendarBox =
      '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M9 3v4M15 3v4"/>';
  static const trophyCup =
      '<path d="M7 4h10v4a5 5 0 0 1-10 0z"/><path d="M7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4M12 13v4M8 20h8"/>';
  static const trophyTeam =
      '<path d="M8 4h8v5a4 4 0 0 1-8 0zM8 6H5a3 3 0 0 0 3 3M16 6h3a3 3 0 0 1-3 3M12 13v4M8.5 20h7"/>';
  static const dotsVertical =
      '<circle cx="12" cy="5.5" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="12" cy="18.5" r="1.8"/>';
  static const thumbtack =
      '<path d="M9 3h6l-1 6 4 3v2H6v-2l4-3z"/><path d="M12 14v7"/>';
  static const flag = '<path d="M5 21V4M5 4h12l-2.5 4 2.5 4H5"/>';
  static const flagClub =
      '<path d="M4 20V5.5A1.5 1.5 0 0 1 5.5 4H15l-2 4 2 4H6"/>';
  static const paperPlane = '<path d="M4 12l16-8-6 16-2.5-6.5z"/>';
  static const chatSquare = '<path d="M4 5h16v11H9l-5 4z"/>';
  static const chatRound =
      '<path d="M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v9a1.5 1.5 0 0 1-1.5 1.5H10l-4.5 4v-4A1.5 1.5 0 0 1 4 14.5z"/>';
  static const chatLines =
      '<path d="M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v9a1.5 1.5 0 0 1-1.5 1.5H10l-4.5 4v-4A1.5 1.5 0 0 1 4 14.5z"/><path d="M8 9h8M8 12h5"/>';
  static const leave = '<path d="M14 4h5v16h-5M10 8l-4 4 4 4M6 12h9"/>';
  static const exitDoor =
      '<path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4M10 16l-4-4 4-4M6 12h10"/>';
  static const warning =
      '<path d="M12 4l9 16H3z"/><path d="M12 10v4.5M12 17.5h.01"/>';
  static const reorder =
      '<path d="M7 20V4M3 8l4-4 4 4M17 4v16M13 16l4 4 4-4"/>';
  static const roleShield =
      '<path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/><circle cx="12" cy="10" r="2.2"/><path d="M8.5 16c.8-1.6 2-2.4 3.5-2.4s2.7.8 3.5 2.4"/>';
  static const shieldDot =
      '<path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/><circle cx="12" cy="10" r="2.2"/>';
  static const shieldTick =
      '<path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/><path d="M9 11.5l2 2 4-4"/>';
  static const shieldPlain =
      '<path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/>';
  static const link =
      '<path d="M10 14a4 4 0 0 0 5.7 0l3.5-3.5a4 4 0 0 0-5.7-5.7L12 6.3"/><path d="M14 10a4 4 0 0 0-5.7 0l-3.5 3.5a4 4 0 0 0 5.7 5.7l1.5-1.5"/>';
  static const rosterCard =
      '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3h6v1"/><circle cx="12" cy="10" r="2.3"/><path d="M8.5 16.5c.7-1.6 2-2.4 3.5-2.4s2.8.8 3.5 2.4"/>';
  static const clipboardList =
      '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3h6v1"/><path d="M8.5 10h7M8.5 13.5h7M8.5 17h4"/>';
  static const clipboardAudit =
      '<rect x="5" y="4.5" width="14" height="17" rx="2.5"/><rect x="9" y="2.5" width="6" height="4" rx="1.2"/><path d="M8.5 11h7M8.5 14.5h7M8.5 18h4"/>';
  static const ticket =
      '<rect x="3" y="7" width="18" height="11" rx="2"/><path d="M8 7V5h8v2"/><rect x="7" y="11" width="10" height="3" rx="1"/>';
  static const info =
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5"/><circle cx="12" cy="7.8" r=".6" fill="currentColor"/>';
  static const gift =
      '<rect x="4" y="10" width="16" height="10" rx="2"/><path d="M4 14h16M12 10v10M12 10c-3 0-5-1.2-5-3a2.2 2.2 0 0 1 4-1.2L12 10zM12 10c3 0 5-1.2 5-3a2.2 2.2 0 0 0-4-1.2L12 10z"/>';
  static const giftBox =
      '<rect x="4" y="9" width="16" height="11" rx="1.5"/><path d="M3 9h18M12 9v11M12 9c-2-4-6-3-5-1s5 1 5 1zm0 0c2-4 6-3 5-1s-5 1-5 1z"/>';
  static const personTick =
      '<circle cx="10" cy="8" r="3.4"/><path d="M3.5 20c0-3.6 2.9-6.5 6.5-6.5 1.6 0 3 .5 4.2 1.4"/><path d="M15.5 17.5l2 2 4-4"/>';
  static const ban = '<circle cx="12" cy="12" r="8.5"/><path d="M6 6l12 12"/>';
  static const clockFace =
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>';
  static const pencil =
      '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>';
  static const trash = '<path d="M5 7h14M10 7V4.5h4V7M7 7l1 13h8l1-13"/>';
  static const searchCircle =
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>';

  // Home (design v2).
  static const heart =
      '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>';
  static const mortarboard =
      '<path d="M2 9l10-5 10 5-10 5z"/><path d="M6 11.5V16c0 1.5 2.7 3 6 3s6-1.5 6-3v-4.5"/>';
  static const dots = '<path d="M5 12h.01M12 12h.01M19 12h.01"/>';
  static const walletCard =
      '<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18M16 14.5h2"/>';
  static const pointsStar =
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5l1.4 2.9 3.1.4-2.3 2.2.6 3.1L12 14.6 9.2 16.1l.6-3.1-2.3-2.2 3.1-.4z"/>';

  // Sport marks drawn on club and team screens.
  static const sportBadminton =
      '<path d="M9 14l6-10 5 5-10 6z"/><path d="M9 14l1 1-3.5 3.5a1.5 1.5 0 0 1-2-2z"/><path d="M12.5 9l3 3"/>';
  static const sportTennis =
      '<circle cx="12" cy="12" r="8.5"/><path d="M5 6.5c3 2 3 9 0 11M19 6.5c-3 2-3 9 0 11"/>';
  static const sportPickleball =
      '<circle cx="12" cy="12" r="8.5"/><path d="M9 9h.01M15 9h.01M12 12h.01M9 15h.01M15 15h.01"/>';
  static const sportTableTennis =
      '<circle cx="10" cy="10" r="6.5"/><path d="M14.5 14.5l5 5"/><circle cx="19" cy="6" r="1.5"/>';
  static const sportSquash =
      '<ellipse cx="13" cy="9" rx="5" ry="6.5" transform="rotate(30 13 9)"/><path d="M9.5 14.5L5 20"/><circle cx="18.5" cy="18.5" r="1.5"/>';
  static const sportPadel =
      '<rect x="7" y="3" width="10" height="13" rx="5"/><path d="M12 16v5M10.5 8h.01M13.5 8h.01M12 11h.01"/>';
  static const sportRunning =
      '<path d="M3 17h13.5a4 4 0 0 0 4-3.5l-6-2.5-2.5-4H9l-1 4-5 2z"/><path d="M3 20h18"/>';
  static const sportHyrox =
      '<path d="M6 8v8M3.5 10v4M18 8v8M20.5 10v4M6 12h12"/>';
}

/// Draws one of [OgIcons] as a stroked line icon, like the artboards do.
class OgIcon extends StatelessWidget {
  const OgIcon(
    this.markup, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
    this.semanticLabel,
    this.fill = false,
  });

  final String markup;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  /// Fills closed shapes too, for "on" states like a saved bookmark.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color!;
    final hex =
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="${fill ? hex : 'none'}" stroke="$hex" stroke-opacity="${c.a}" '
        'stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round">${markup.replaceAll('currentColor', hex)}</svg>';
    final icon = SvgPicture.string(svg, width: size, height: size);
    if (semanticLabel == null) return ExcludeSemantics(child: icon);
    return Semantics(label: semanticLabel, image: true, child: icon);
  }
}
