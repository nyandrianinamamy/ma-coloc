import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/house_provider.dart';

class JoinHouseScreen extends ConsumerStatefulWidget {
  const JoinHouseScreen({super.key});

  @override
  ConsumerState<JoinHouseScreen> createState() => _JoinHouseScreenState();
}

class _JoinHouseScreenState extends ConsumerState<JoinHouseScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    if (code.isEmpty || name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(houseActionsProvider.notifier).joinHouse(
            inviteCode: code,
            displayName: name,
          );
      if (mounted) context.go('/home');
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
      appBar: AppBar(title: const Text('Join a House')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                border: OutlineInputBorder(),
                hintText: 'e.g. ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _join,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join House'),
            ),
          ],
        ),
      ),
    );
  }
}
