import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Countries offered at launch. The country sets currency, emergency number
/// and local rules; the dial code is used for mobile numbers.
enum Country {
  singapore(
    'SG',
    'Singapore',
    '+65',
    '<rect width="28" height="19" fill="#FFFFFF"/><rect width="28" height="9.5" fill="#E03C31"/><circle cx="7" cy="5" r="3" fill="#FFFFFF"/><circle cx="8.3" cy="5" r="2.7" fill="#E03C31"/><circle cx="11.5" cy="3" r=".8" fill="#FFFFFF"/><circle cx="13.5" cy="4.8" r=".8" fill="#FFFFFF"/><circle cx="12.7" cy="7" r=".8" fill="#FFFFFF"/><circle cx="10.3" cy="7" r=".8" fill="#FFFFFF"/><circle cx="9.5" cy="4.8" r=".8" fill="#FFFFFF"/>',
  ),
  malaysia(
    'MY',
    'Malaysia',
    '+60',
    '<rect y="0.00" width="28" height="2.81" fill="#CC0001"/><rect y="2.71" width="28" height="2.81" fill="#FFFFFF"/><rect y="5.43" width="28" height="2.81" fill="#CC0001"/><rect y="8.14" width="28" height="2.81" fill="#FFFFFF"/><rect y="10.86" width="28" height="2.81" fill="#CC0001"/><rect y="13.57" width="28" height="2.81" fill="#FFFFFF"/><rect y="16.29" width="28" height="2.81" fill="#CC0001"/><rect width="14" height="10.8" fill="#010066"/><circle cx="7" cy="5.4" r="2.8" fill="#FFCC00"/>',
  ),
  indonesia(
    'ID',
    'Indonesia',
    '+62',
    '<rect width="28" height="19" fill="#FFFFFF"/><rect width="28" height="9.5" fill="#CE1126"/>',
  ),
  thailand(
    'TH',
    'Thailand',
    '+66',
    '<rect y="0" width="28" height="3.17" fill="#A51931"/><rect y="3.17" width="28" height="3.17" fill="#F4F5F8"/><rect y="6.34" width="28" height="6.33" fill="#2D2A4A"/><rect y="12.67" width="28" height="3.17" fill="#F4F5F8"/><rect y="15.84" width="28" height="3.17" fill="#A51931"/>',
  );

  const Country(this.code, this.name, this.dialCode, this._flag);

  final String code;
  final String name;
  final String dialCode;
  final String _flag;

  static Country fromCode(String? code) =>
      values.firstWhere((c) => c.code == code, orElse: () => singapore);

  Widget flag() => ExcludeSemantics(
    child: Container(
      width: 28,
      height: 19,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Color(0xFFD9D9D2), spreadRadius: 1)],
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 19">$_flag</svg>',
        width: 28,
        height: 19,
      ),
    ),
  );
}
