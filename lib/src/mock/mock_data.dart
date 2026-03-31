class MockUser {
  const MockUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.points,
    required this.presence,
    required this.streak,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final int points;
  final String presence; // 'home' | 'away'
  final int streak;
}

class MockIssue {
  const MockIssue({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.authorId,
    this.assigneeId,
    this.photoUrl,
    required this.createdAt,
    required this.description,
  });

  final String id;
  final String title;
  final String type;
  final String status;
  final String authorId;
  final String? assigneeId;
  final String? photoUrl;
  final DateTime createdAt;
  final String description;
}

class MockActivity {
  const MockActivity({
    required this.id,
    required this.type,
    required this.user,
    required this.issue,
    required this.time,
  });

  final String id;
  final String type;
  final MockUser user;
  final MockIssue issue;
  final String time;
}

class MockRoom {
  const MockRoom({
    required this.id,
    required this.name,
    required this.status,
    this.assigneeId,
  });

  final String id;
  final String name;
  final String status; // 'dirty' | 'clean' | 'assigned'
  final String? assigneeId;
}

class MockData {
  MockData._();

  static final List<MockUser> users = [
    const MockUser(
      id: 'u1',
      name: 'Alex M.',
      avatarUrl: 'https://i.pravatar.cc/150?u=u1',
      points: 420,
      presence: 'home',
      streak: 7,
    ),
    const MockUser(
      id: 'u2',
      name: 'Sam K.',
      avatarUrl: 'https://i.pravatar.cc/150?u=u2',
      points: 315,
      presence: 'away',
      streak: 3,
    ),
    const MockUser(
      id: 'u3',
      name: 'Jordan T.',
      avatarUrl: 'https://i.pravatar.cc/150?u=u3',
      points: 280,
      presence: 'home',
      streak: 5,
    ),
    const MockUser(
      id: 'u4',
      name: 'Casey R.',
      avatarUrl: 'https://i.pravatar.cc/150?u=u4',
      points: 195,
      presence: 'away',
      streak: 1,
    ),
    const MockUser(
      id: 'u5',
      name: 'Taylor B.',
      avatarUrl: 'https://i.pravatar.cc/150?u=u5',
      points: 150,
      presence: 'home',
      streak: 2,
    ),
    const MockUser(
      id: 'u6',
      name: 'Morgan L.',
      avatarUrl: 'https://i.pravatar.cc/150?u=u6',
      points: 90,
      presence: 'away',
      streak: 0,
    ),
  ];

  static final List<MockIssue> issues = [
    MockIssue(
      id: 'i1',
      title: 'Dish mountain in sink',
      type: 'Chore',
      status: 'open',
      authorId: 'u2',
      assigneeId: null,
      photoUrl: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      description: 'There\'s a huge pile of dishes in the sink. Someone needs to deal with this ASAP.',
    ),
    MockIssue(
      id: 'i2',
      title: 'Out of oat milk!',
      type: 'Grocery',
      status: 'in-progress',
      authorId: 'u3',
      assigneeId: 'u1',
      photoUrl: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      description: 'We ran out of oat milk. Please pick some up on the next grocery run.',
    ),
    MockIssue(
      id: 'i3',
      title: 'Bathroom handle loose',
      type: 'Repair',
      status: 'resolved',
      authorId: 'u1',
      assigneeId: 'u4',
      photoUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      description: 'The bathroom door handle is loose and wobbles. Needs tightening.',
    ),
    MockIssue(
      id: 'i4',
      title: 'Living room vacuum',
      type: 'Chore',
      status: 'disputed',
      authorId: 'u4',
      assigneeId: 'u5',
      photoUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      description: 'The living room carpet needs vacuuming — it hasn\'t been done in a week.',
    ),
  ];

  static List<MockActivity> get activities => [
        MockActivity(
          id: 'a1',
          type: 'created',
          user: userById('u2')!,
          issue: issues[0],
          time: '3h ago',
        ),
        MockActivity(
          id: 'a2',
          type: 'claimed',
          user: userById('u1')!,
          issue: issues[1],
          time: '8h ago',
        ),
        MockActivity(
          id: 'a3',
          type: 'resolved',
          user: userById('u4')!,
          issue: issues[2],
          time: '2d ago',
        ),
        MockActivity(
          id: 'a4',
          type: 'disputed',
          user: userById('u5')!,
          issue: issues[3],
          time: '1d ago',
        ),
      ];

  static final List<MockRoom> rooms = [
    const MockRoom(
      id: 'r1',
      name: 'Kitchen',
      status: 'dirty',
      assigneeId: null,
    ),
    const MockRoom(
      id: 'r2',
      name: 'Living Room',
      status: 'clean',
      assigneeId: null,
    ),
    const MockRoom(
      id: 'r3',
      name: 'Shared Bath 1',
      status: 'assigned',
      assigneeId: 'u1',
    ),
    const MockRoom(
      id: 'r4',
      name: 'Shared Bath 2',
      status: 'clean',
      assigneeId: null,
    ),
    const MockRoom(
      id: 'r5',
      name: 'Hallways',
      status: 'assigned',
      assigneeId: 'u3',
    ),
  ];

  static MockUser get currentUser => users[0];

  static MockUser? userById(String id) {
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
