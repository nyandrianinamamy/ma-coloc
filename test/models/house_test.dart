import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macoloc/src/models/house.dart';
import 'package:macoloc/src/models/house_settings.dart';

void main() {
  group('HouseSettings', () {
    test('creates with default values', () {
      const settings = HouseSettings();
      expect(settings.deepCleanDay, 1);
      expect(settings.volunteerWindowHours, 48);
      expect(settings.disputeWindowHours, 48);
    });

    test('serializes to and from JSON', () {
      const settings = HouseSettings(
        deepCleanDay: 15,
        volunteerWindowHours: 72,
        disputeWindowHours: 24,
      );
      final json = settings.toJson();
      final restored = HouseSettings.fromJson(json);
      expect(restored, settings);
    });
  });

  group('House', () {
    test('creates with required fields', () {
      final house = House(
        id: 'house1',
        name: 'Test House',
        createdBy: 'uid1',
        createdAt: Timestamp.now(),
        inviteCode: 'ABC123',
        members: const ['uid1'],
        rooms: const ['Kitchen', 'Bathroom'],
        timezone: 'Europe/Paris',
        settings: const HouseSettings(),
      );
      expect(house.name, 'Test House');
      expect(house.members, ['uid1']);
      expect(house.lastResetDate, isNull);
      expect(house.lastDeepCleanMonth, isNull);
    });

    test('serializes to and from JSON', () {
      final now = Timestamp.now();
      final house = House(
        id: 'house1',
        name: 'Test House',
        createdBy: 'uid1',
        createdAt: now,
        inviteCode: 'ABC123',
        members: const ['uid1', 'uid2'],
        rooms: const ['Kitchen'],
        timezone: 'Europe/Paris',
        lastResetDate: '2026-03-31',
        lastDeepCleanMonth: '2026-03',
        settings: const HouseSettings(deepCleanDay: 15),
      );
      final json = house.toJson();
      final restored = House.fromJson(json);
      expect(restored.name, house.name);
      expect(restored.members, house.members);
      expect(restored.lastResetDate, '2026-03-31');
      expect(restored.settings.deepCleanDay, 15);
    });
  });
}
