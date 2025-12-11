import 'package:flutter/material.dart';
import '../../core/email_repository.dart';
import '../../core/priority_classifier.dart';
import '../../core/priority_store.dart';
import '../../core/summarizer.dart';

class ImportantScreen extends StatefulWidget {
  final List<EmailWithPriority> prioritizedEmails;
  final VoidCallback? onRecompute;

  const ImportantScreen({
    super.key,
    required this.prioritizedEmails,
    this.onRecompute,
  });

  @override
  State<ImportantScreen> createState() => _ImportantScreenState();
}

class _ImportantScreenState extends State<ImportantScreen> {
  late List<EmailWithPriority> _sortedEmails;
  final bool _isRecomputing = false;
  final Set<String> _selectedEmails = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _sortedEmails = List.from(widget.prioritizedEmails);
    _sortByPriority();
  }

  @override
  void didUpdateWidget(ImportantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortedEmails = List.from(widget.prioritizedEmails);
    _sortByPriority();
  }

  void _sortByPriority() {
    _sortedEmails.sort((a, b) {
      // Sort by priority score descending
      final scoreCompare = b.displayScore.compareTo(a.displayScore);
      if (scoreCompare != 0) return scoreCompare;
      // Then by date descending
      if (a.email.date == null || b.email.date == null) return 0;
      return b.email.date!.compareTo(a.email.date!);
    });
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedEmails.contains(messageId)) {
        _selectedEmails.remove(messageId);
      } else {
        _selectedEmails.add(messageId);
      }
      if (_selectedEmails.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedEmails.add(messageId);
    });
  }

  Future<void> _bulkSetPriority(String priority) async {
    try {
      final priorityStore = PriorityStore();
      await priorityStore.init();

      for (final messageId in _selectedEmails) {
        await priorityStore.updateManualOverride(messageId, priority);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated ${_selectedEmails.length} email(s) to $priority priority',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _selectedEmails.clear();
        _isSelectionMode = false;
      });

      // Recompute priorities
      if (widget.onRecompute != null) {
        widget.onRecompute!();
      }
    } catch (e) {
      debugPrint('Error in bulk set priority: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating priorities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPriorityModal(EmailWithPriority emailWithPriority) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return PrioritySelectionModal(emailWithPriority: emailWithPriority);
      },
    );

    if (result != null && mounted) {
      try {
        final label = result['label'] as String?;
        final score = result['score'] as int?;

        if (label != null && score != null) {
          // Extract domain from the email
          final domain = _extractDomain(emailWithPriority.email.from);

          // Save domain-level override
          final priorityStore = PriorityStore();
          await priorityStore.init();
          await priorityStore.saveDomainPriority(
            emailWithPriority.email.from,
            label,
          );

          // Update all emails from this domain in local state
          setState(() {
            for (int i = 0; i < _sortedEmails.length; i++) {
              final email = _sortedEmails[i];
              if (_extractDomain(email.email.from) == domain) {
                _sortedEmails[i] = EmailWithPriority(
                  email: email.email,
                  score: score,
                  label: email.label,
                  manualOverride: true,
                  manualLabel: label,
                  storedAt: DateTime.now(),
                );
              }
            }
            _sortByPriority();
          });

          // Show confirmation with affected count
          final affectedCount = _sortedEmails
              .where((e) => _extractDomain(e.email.from) == domain)
              .length;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Set $label priority for $domain ($affectedCount email${affectedCount != 1 ? 's' : ''})',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error updating priority: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating priority: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _extractDomain(String email) {
    try {
      if (email.contains('@')) {
        return email.split('@')[1].split('>')[0].toLowerCase();
      }
      return email.toLowerCase();
    } catch (e) {
      return email.toLowerCase();
    }
  }

  void _showExplanationDialog(EmailWithPriority emailWithPriority) {
    final classifier = PriorityClassifier();
    final explanation = classifier.explainPrediction(emailWithPriority.email);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Priority Explanation'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Score: ${explanation['score']}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(explanation['label'] as String),
                        backgroundColor: _getPriorityColor(
                          explanation['label'] as String,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Reasons:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                ...((explanation['reasons'] as List<dynamic>).map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('• ${reason as String}'),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEmailDetail(EmailWithPriority emailWithPriority) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EmailDetailModal(emailWithPriority: emailWithPriority);
      },
    );
  }

  Color _getPriorityColor(String label) {
    switch (label.toUpperCase()) {
      case 'HIGH':
        return Colors.red[100]!;
      case 'MEDIUM':
        return Colors.orange[100]!;
      case 'LOW':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isRecomputing) const LinearProgressIndicator(),
        // Bulk action toolbar
        if (_selectedEmails.isNotEmpty)
          Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedEmails.length} selected',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _bulkSetPriority('High'),
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      label: const Text('High'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[100],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _bulkSetPriority('Medium'),
                      icon: const Icon(Icons.unfold_more, size: 18),
                      label: const Text('Med'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[100],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _bulkSetPriority('Low'),
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      label: const Text('Low'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _selectedEmails.clear();
                        _isSelectionMode = false;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: _sortedEmails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No important emails',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'High-priority emails will appear here',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _sortedEmails.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (BuildContext context, int index) {
                    final emailWithPriority = _sortedEmails[index];
                    return _buildPrioritizedEmailCard(
                      context,
                      emailWithPriority,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPrioritizedEmailCard(
    BuildContext context,
    EmailWithPriority emailWithPriority,
  ) {
    final isSelected = _selectedEmails.contains(emailWithPriority.email.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(emailWithPriority.email.id),
              )
            : CircleAvatar(
                child: Text(_getInitials(emailWithPriority.email.from)),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                emailWithPriority.email.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Priority score chip
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: _getPriorityColor(emailWithPriority.displayLabel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emailWithPriority.displayLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                emailWithPriority.email.from,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(
                emailWithPriority.email.snippet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Wrap(
              spacing: 8.0,
              children: [
                Chip(
                  label: const Text('Email'),
                  avatar: const Icon(Icons.mail, size: 18),
                  backgroundColor: Colors.blue[100],
                ),
                if (emailWithPriority.manualOverride)
                  Chip(
                    label: const Text('Manual'),
                    backgroundColor: Colors.purple[100],
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.star, color: Colors.amber[700]),
                onPressed: () => _showPriorityModal(emailWithPriority),
                tooltip: 'Set priority',
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showExplanationDialog(emailWithPriority),
                tooltip: 'Explain priority',
              ),
            ],
          ),
        ),
        onTap: _isSelectionMode
            ? () => _toggleSelection(emailWithPriority.email.id)
            : () => _showEmailDetail(emailWithPriority),
        onLongPress: () => _enterSelectionMode(emailWithPriority.email.id),
      ),
    );
  }

  String _getInitials(String from) {
    if (from.isEmpty) return '?';
    final parts = from.split(' ');
    if (parts[0].contains('@')) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return from.substring(0, 1).toUpperCase();
  }
}

class PrioritySelectionModal extends StatefulWidget {
  final EmailWithPriority emailWithPriority;

  const PrioritySelectionModal({super.key, required this.emailWithPriority});

  @override
  State<PrioritySelectionModal> createState() => _PrioritySelectionModalState();
}

class _PrioritySelectionModalState extends State<PrioritySelectionModal> {
  late String _selectedPriority;
  late PriorityStore _priorityStore;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.emailWithPriority.displayLabel;
    _priorityStore = PriorityStore();
    _initStore();
  }

  Future<void> _initStore() async {
    await _priorityStore.init();
  }

  Future<void> _savePriority() async {
    try {
      final scoreMap = {'High': 90, 'Medium': 60, 'Low': 30};
      final score = scoreMap[_selectedPriority] ?? 50;

      await _priorityStore.updateManualOverride(
        widget.emailWithPriority.email.id,
        _selectedPriority,
      );
      if (mounted) {
        Navigator.pop(context, {'label': _selectedPriority, 'score': score});
      }
    } catch (e) {
      debugPrint('Error saving priority: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving priority: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set Priority',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            for (final priority in ['High', 'Medium', 'Low'])
              RadioListTile<String>(
                title: Text(priority),
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _savePriority,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmailDetailModal extends StatelessWidget {
  final EmailWithPriority emailWithPriority;

  const EmailDetailModal({super.key, required this.emailWithPriority});

  @override
  Widget build(BuildContext context) {
    final classifier = PriorityClassifier();
    final explanation = classifier.explainPrediction(emailWithPriority.email);
    final summary = Summarizer.summarize(
      '${emailWithPriority.email.subject} ${emailWithPriority.email.snippet}',
      maxSentences: 2,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            emailWithPriority.email.subject,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                child: Text(
                  emailWithPriority.email.from.isNotEmpty
                      ? emailWithPriority.email.from
                            .substring(0, 1)
                            .toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emailWithPriority.email.from,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (emailWithPriority.email.date != null)
                      Text(
                        emailWithPriority.email.date!.toString().split('.')[0],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Priority: ${emailWithPriority.displayLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text('(Score: ${emailWithPriority.displayScore})'),
                    if (emailWithPriority.manualOverride)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: const Text('Manual Override'),
                          backgroundColor: Colors.orange[100],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Reasons:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                ...((explanation['reasons'] as List<dynamic>).map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '• ${reason as String}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(summary, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
