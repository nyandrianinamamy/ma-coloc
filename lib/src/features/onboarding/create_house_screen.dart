import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/house_provider.dart';

class CreateHouseScreen extends ConsumerStatefulWidget {
  const CreateHouseScreen({super.key});

  @override
  ConsumerState<CreateHouseScreen> createState() => _CreateHouseScreenState();
}

class _CreateHouseScreenState extends ConsumerState<CreateHouseScreen> {
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _roomControllers = [TextEditingController(text: 'Kitchen')];
  final String _timezone = 'Europe/Paris';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    for (final c in _roomControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addRoom() {
    setState(() {
      _roomControllers.add(TextEditingController());
    });
  }

  void _removeRoom(int index) {
    if (_roomControllers.length <= 1) return;
    setState(() {
      _roomControllers[index].dispose();
      _roomControllers.removeAt(index);
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final rooms = _roomControllers
        .map((c) => c.text.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    if (name.isEmpty || displayName.isEmpty || rooms.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(houseActionsProvider.notifier).createHouse(
            name: name,
            displayName: displayName,
            timezone: _timezone,
            rooms: rooms,
          );
      if (mounted) context.go('/onboarding/created');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a House')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Your Display Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'House Name',
              border: OutlineInputBorder(),
              hintText: 'e.g. Appart Rue Exemple',
            ),
          ),
          const SizedBox(height: 24),
          Text('Rooms', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...List.generate(_roomControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _roomControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Room ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (_roomControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeRoom(i),
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addRoom,
            icon: const Icon(Icons.add),
            label: const Text('Add Room'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _create,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create House'),
          ),
        ],
      ),
    );
  }
}
