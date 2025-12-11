import 'package:flutter/material.dart';
import '../../core/email_metadata.dart';
import '../../widgets/email_card.dart';

class GroupsScreen extends StatefulWidget {
  final List<EmailMetadata> emails;

  const GroupsScreen({super.key, required this.emails});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Map<String, List<EmailMetadata>> _groupedEmails;
  String _groupType = 'domain'; // 'domain' or 'category'

  static final Map<String, List<String>> _categoryKeywords = {
    'amazon': ['amazon', 'flipkart', 'ebay', 'shopping'],
    'social': [
      'linkedin',
      'facebook',
      'twitter',
      'instagram',
      'reddit',
      'whatsapp',
    ],
    'banking': [
      'bank',
      'banking',
      'icici',
      'hdfc',
      'sbi',
      'axis',
      'kotak',
      'wells fargo',
      'chase',
    ],
    'payment': [
      'paytm',
      'payment',
      'upi',
      'transfer',
      'gpay',
      'paypal',
      'stripe',
    ],
    'work': [
      'meeting',
      'project',
      'deadline',
      'task',
      'assignment',
      'conference',
      'presentation',
    ],
    'ecommerce': [
      'order',
      'shipment',
      'delivery',
      'tracking',
      'product',
      'purchase',
    ],
    'education': [
      'course',
      'exam',
      'grade',
      'class',
      'assignment',
      'school',
      'university',
      'certificate',
    ],
    'support': [
      'support',
      'ticket',
      'issue',
      'help',
      'resolve',
      'troubleshoot',
    ],
    'newsletter': [
      'newsletter',
      'subscribe',
      'unsubscribe',
      'weekly',
      'monthly',
      'digest',
    ],
    'notification': [
      'notification',
      'alert',
      'update',
      'status',
      'reminder',
      'confirmation',
    ],
  };

  @override
  void initState() {
    super.initState();
    _groupedEmails = _groupEmails();
  }

  Map<String, List<EmailMetadata>> _groupEmails() {
    final grouped = <String, List<EmailMetadata>>{};

    if (_groupType == 'domain') {
      for (final email in widget.emails) {
        final domain = _extractDomain(email.from);
        if (!grouped.containsKey(domain)) {
          grouped[domain] = [];
        }
        grouped[domain]!.add(email);
      }
    } else {
      // Category grouping
      for (final email in widget.emails) {
        String category = 'Other';
        final combinedText = '${email.subject} ${email.snippet} ${email.from}'
            .toLowerCase();

        for (final entry in _categoryKeywords.entries) {
          for (final keyword in entry.value) {
            if (combinedText.contains(keyword)) {
              category = _capitalizeFirst(entry.key);
              break;
            }
          }
          if (category != 'Other') break;
        }

        if (!grouped.containsKey(category)) {
          grouped[category] = [];
        }
        grouped[category]!.add(email);
      }
    }

    // Sort groups by name
    final sorted = <String, List<EmailMetadata>>{};
    for (final key in grouped.keys.toList()..sort()) {
      sorted[key] = grouped[key]!;
      // Sort emails within group by date descending
      sorted[key]!.sort((a, b) {
        if (a.date == null || b.date == null) return 0;
        return b.date!.compareTo(a.date!);
      });
    }

    return sorted;
  }

  String _extractDomain(String email) {
    try {
      if (email.contains('@')) {
        return email.split('@')[1].split('>')[0];
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _capitalizeFirst(String str) {
    return str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;
  }

  void _changeGroupType(String type) {
    setState(() {
      _groupType = type;
      _groupedEmails = _groupEmails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Group type selector
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'domain', label: Text('By Domain')),
                    ButtonSegment(
                      value: 'category',
                      label: Text('By Category'),
                    ),
                  ],
                  selected: {_groupType},
                  onSelectionChanged: (Set<String> newSelection) {
                    _changeGroupType(newSelection.first);
                  },
                ),
              ),
            ],
          ),
        ),
        // Groups list
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _groupedEmails.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No emails found',
                          style: Theme.of(context).textTheme.titleMedium,
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
                    child: ListView.builder(
                      itemCount: _groupedEmails.length,
                      padding: const EdgeInsets.all(12.0),
                      itemBuilder: (BuildContext context, int index) {
                        final groupName = _groupedEmails.keys.elementAt(index);
                        final groupEmails = _groupedEmails[groupName]!;
                        final latestEmail = groupEmails.first;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                groupName.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(
                              groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    latestEmail.snippet,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${groupEmails.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupDetailScreen(
                                    groupName: groupName,
                                    emails: groupEmails,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class GroupDetailScreen extends StatelessWidget {
  final String groupName;
  final List<EmailMetadata> emails;

  const GroupDetailScreen({
    super.key,
    required this.groupName,
    required this.emails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName), elevation: 0),
      body: ListView.builder(
        itemCount: emails.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (BuildContext context, int index) {
          return EmailCard(email: emails[index]);
        },
      ),
    );
  }
}
