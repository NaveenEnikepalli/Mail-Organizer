import 'package:flutter/material.dart';
import '../../core/email_metadata.dart';

class DeadlinesScreen extends StatefulWidget {
  final List<EmailMetadata> emails;
  final Map<String, Map<String, dynamic>> deadlineMetaById;
  final Future<void> Function()? onRefresh;

  const DeadlinesScreen({
    super.key,
    required this.emails,
    required this.deadlineMetaById,
    this.onRefresh,
  });

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen> {
  SortMode _sortMode = SortMode.leastDeadlines;

  List<EmailMetadata> _filterAndSortEmails() {
    final filtered = List<EmailMetadata>.from(widget.emails);

    // Sort based on selected mode
    if (_sortMode == SortMode.leastDeadlines) {
      filtered.sort((a, b) {
        final aCount =
            (widget.deadlineMetaById[a.id]?['deadlines'] as List?)?.length ?? 0;
        final bCount =
            (widget.deadlineMetaById[b.id]?['deadlines'] as List?)?.length ?? 0;
        return aCount.compareTo(bCount);
      });
    } else {
      // Latest emails first
      filtered.sort((a, b) {
        final aDate = a.date ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    }

    return filtered;
  }

  int _getDaysUntil(String messageId) {
    return (widget.deadlineMetaById[messageId]?['daysUntilPrimary'] as int?) ??
        9999;
  }

  Color _getDaysColor(int daysUntil) {
    if (daysUntil < 0) return Colors.red;
    if (daysUntil <= 2) return Colors.orange;
    return Colors.grey.shade700;
  }

  String _getDaysLabel(int daysUntil) {
    if (daysUntil < 0) return 'Overdue';
    if (daysUntil == 0) return 'Due today';
    if (daysUntil == 1) return '1d left';
    return '${daysUntil}d left';
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      try {
        await widget.onRefresh!();
        setState(() {});
      } catch (e) {
        debugPrint('Error refreshing deadlines: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().split(':').first}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showDeadlineDetail(EmailMetadata email) {
    final meta = widget.deadlineMetaById[email.id];
    if (meta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline details not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deadline Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subject
                Text(
                  email.subject,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // From & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            email.from,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            email.date?.toString().split(' ').first ??
                                'Unknown',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Primary deadline
                Text(
                  'Primary Deadline',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (meta['primaryDeadline'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateTime.tryParse(
                                meta['primaryDeadline'].toString(),
                              )?.toString().split('.').first ??
                              'Unknown date',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _getDaysColor(
                                  meta['daysUntilPrimary'] as int? ?? 0,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Time remaining: ${meta['remainingTime']?['days'] ?? 0}d ${meta['remainingTime']?['hours'] ?? 0}h ${meta['remainingTime']?['minutes'] ?? 0}m',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Urgency
                if (meta['urgencyScore'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urgency Score: ${meta['urgencyScore']}/10',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (meta['reminder'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              meta['reminder']['message'] ??
                                  'Deadline approaching',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterAndSortEmails();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        children: [
          // Sort controls
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text(
                  'Sort: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<SortMode>(
                  initialValue: _sortMode,
                  onSelected: (mode) {
                    setState(() => _sortMode = mode);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: SortMode.leastDeadlines,
                      child: Text('Least deadlines'),
                    ),
                    const PopupMenuItem(
                      value: SortMode.latestEmails,
                      child: Text('Latest emails'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _sortMode == SortMode.leastDeadlines
                              ? 'Least deadlines'
                              : 'Latest emails',
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Email list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No deadlines found. Pull to refresh.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (context, index) {
                          final email = filtered[index];
                          final daysUntil = _getDaysUntil(email.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            title: Text(
                              email.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              email.from,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDaysColor(
                                  daysUntil,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getDaysLabel(daysUntil),
                                style: TextStyle(
                                  color: _getDaysColor(daysUntil),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            onTap: () => _showDeadlineDetail(email),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

enum SortMode { leastDeadlines, latestEmails }
