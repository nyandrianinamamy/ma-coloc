import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/member.dart';

void main() {
  group('Presence enum', () {
    test('has home and away values', () {
      expect(Presence.values, containsAll([Presence.home, Presence.away]));
      expect(Presence.values.length, 2);
    });

    test('name returns correct string', () {
      expect(Presence.home.name, 'home');
      expect(Presence.away.name, 'away');
    });
  });

  group('MemberRole enum', () {
    test('has admin and member values', () {
      expect(MemberRole.values, containsAll([MemberRole.admin, MemberRole.member]));
      expect(MemberRole.values.length, 2);
    });
  });
}
