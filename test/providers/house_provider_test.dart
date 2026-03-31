import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:macoloc/src/providers/house_provider.dart';
import 'house_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult<Map<String, dynamic>>>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
])
void main() {
  late MockFirebaseFunctions mockFunctions;
  late ProviderContainer container;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    container = ProviderContainer(
      overrides: [
        firebaseFunctionsProvider.overrideWithValue(mockFunctions),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('createHouse', () {
    test('calls createHouse callable and returns houseId', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(mockFunctions.httpsCallable('createHouse'))
          .thenReturn(mockCallable);
      when(mockCallable.call<Map<String, dynamic>>({
        'name': 'Test House',
        'displayName': 'Mamy',
        'timezone': 'Europe/Paris',
        'rooms': ['Kitchen', 'Bathroom'],
      })).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'houseId': 'house123'});

      final notifier = container.read(houseActionsProvider.notifier);
      final houseId = await notifier.createHouse(
        name: 'Test House',
        displayName: 'Mamy',
        timezone: 'Europe/Paris',
        rooms: ['Kitchen', 'Bathroom'],
      );

      expect(houseId, 'house123');
    });
  });

  group('joinHouse', () {
    test('calls joinHouse callable with invite code', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(mockFunctions.httpsCallable('joinHouse'))
          .thenReturn(mockCallable);
      when(mockCallable.call<Map<String, dynamic>>({
        'inviteCode': 'ABC123',
        'displayName': 'Mamy',
        'avatarUrl': null,
      })).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'houseId': 'house456'});

      final notifier = container.read(houseActionsProvider.notifier);
      final houseId = await notifier.joinHouse(
        inviteCode: 'ABC123',
        displayName: 'Mamy',
      );

      expect(houseId, 'house456');
    });
  });
}
