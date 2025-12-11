import 'package:flutter/material.dart';
import '../../widgets/email_card.dart';
import '../../core/email_metadata.dart';

class SpamScreen extends StatelessWidget {
  final List<EmailMetadata> spamEmails;
  final bool isSyncing;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  const SpamScreen({
    super.key,
    required this.spamEmails,
    this.isSyncing = false,
    this.errorMessage,
    this.onRefresh,
  });

  void _handleTap(BuildContext context, EmailMetadata email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${email.subject}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

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
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: spamEmails.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_gmailerrorred,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No spam found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull to refresh',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        if (onRefresh != null) {
                          onRefresh!();
                        }
                      },
                      child: ListView.builder(
                        itemCount: spamEmails.length,
                        padding: const EdgeInsets.all(12.0),
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              _handleTap(context, spamEmails[index]);
                            },
                            child: EmailCard(email: spamEmails[index]),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
