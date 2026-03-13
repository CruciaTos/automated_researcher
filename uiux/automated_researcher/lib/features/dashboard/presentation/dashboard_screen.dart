import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/widgets/primary_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _topicController = TextEditingController();
  int _selectedDepth = 25;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(jobCreationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Dashboard'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'What topic do you want researched?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'e.g. AI safety regulation in 2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Research depth',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [5, 25, 40].map((depth) {
                final isSelected = _selectedDepth == depth;
                return ChoiceChip(
                  label: Text('$depth min'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDepth = depth),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Start Research',
              isLoading: creationState.isLoading,
              onPressed: () async {
                final topic = _topicController.text.trim();
                if (topic.isEmpty) return;
                await ref.read(jobCreationProvider.notifier).createJob(
                      topic,
                      _selectedDepth,
                    );
                final job = ref.read(jobCreationProvider).value;
                if (job != null && context.mounted) {
                  context.go('/jobs/${job.id}/progress');
                }
              },
            ),
            if (creationState.hasError) ...[
              const SizedBox(height: 12),
              Text(
                'Failed to create job. Please try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}