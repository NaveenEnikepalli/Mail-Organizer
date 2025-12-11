import 'package:flutter/material.dart';

class RoleSelectionSheet extends StatelessWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionSheet({super.key, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your role',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Student'),
            subtitle: const Text('Prioritize exams, assignments, and notices'),
            onTap: () {
              onRoleSelected('Student');
            },
          ),
          ListTile(
            title: const Text('Job Seeker'),
            subtitle: const Text(
              'Highlight offers, interviews, and test links',
            ),
            onTap: () {
              onRoleSelected('Job Seeker');
            },
          ),
          ListTile(
            title: const Text('Professional'),
            subtitle: const Text(
              'Focus on meetings, clients, and project deadlines',
            ),
            onTap: () {
              onRoleSelected('Professional');
            },
          ),
        ],
      ),
    );
  }
}
