import 'package:flutter/material.dart';
import '../../widgets/email_card.dart';
import '../../core/email_metadata.dart';

class InboxScreen extends StatelessWidget {
  final List<EmailMetadata> emails;
  final bool isSyncing;
  final String? errorMessage;

  const InboxScreen({
    super.key,
    required this.emails,
    this.isSyncing = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isSyncing) const LinearProgressIndicator(),
        if (errorMessage != null)
          Container(
            color: Colors.red[100],
            padding: const EdgeInsets.all(12),
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: emails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No emails found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try signing in or refreshing',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: emails.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (BuildContext context, int index) {
                    return EmailCard(email: emails[index]);
                  },
                ),
        ),
      ],
    );
  }
}
