import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 32, child: Icon(Icons.person)),
            const SizedBox(height: 16),
            Text('User', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('user@crucio.com', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            const Text('Preferences'),
            const SizedBox(height: 8),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Email updates'),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}