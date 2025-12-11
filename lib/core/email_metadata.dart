class EmailMetadata {
  final String id;
  final String threadId;
  final String subject;
  final String from;
  final String snippet;
  final DateTime? date;
  final String gmailLink;
  final List<String> labels;

  const EmailMetadata({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.from,
    required this.snippet,
    this.date,
    required this.gmailLink,
    required this.labels,
  });

  factory EmailMetadata.fromGmailMessage(Map<String, dynamic> msg) {
    final id = msg['id'] ?? '';
    final threadId = msg['threadId'] ?? '';
    final snippet = msg['snippet'] ?? '';
    final labelIds = List<String>.from(msg['labelIds'] ?? []);

    String subject = '';
    String from = '';
    String dateHeader = '';

    final payload = msg['payload'];
    if (payload != null) {
      final headers = payload['headers'];
      if (headers is List) {
        for (var header in headers) {
          final name = header['name'];
          final value = header['value'];
          if (name == 'Subject') {
            subject = value ?? '';
          } else if (name == 'From') {
            from = value ?? '';
          } else if (name == 'Date') {
            dateHeader = value ?? '';
          }
        }
      }
    }

    DateTime? date;
    final internalDate = msg['internalDate'];
    if (internalDate != null) {
      try {
        final ms = int.parse(internalDate.toString());
        date = DateTime.fromMillisecondsSinceEpoch(ms);
      } catch (e) {
        date = null;
      }
    }

    if (dateHeader.isNotEmpty && date == null) {
      try {
        date = DateTime.parse(dateHeader);
      } catch (e) {
        date = null;
      }
    }

    final gmailLink = 'https://mail.google.com/mail/u/0/#inbox/$id';

    return EmailMetadata(
      id: id,
      threadId: threadId,
      subject: subject.isNotEmpty ? subject : '(No subject)',
      from: from,
      snippet: snippet,
      date: date,
      gmailLink: gmailLink,
      labels: labelIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'subject': subject,
      'from': from,
      'snippet': snippet,
      'date': date?.toIso8601String(),
      'gmailLink': gmailLink,
      'labels': labels,
    };
  }

  factory EmailMetadata.fromJson(Map<String, dynamic> json) {
    return EmailMetadata(
      id: json['id'] ?? '',
      threadId: json['threadId'] ?? '',
      subject: json['subject'] ?? '',
      from: json['from'] ?? '',
      snippet: json['snippet'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      gmailLink: json['gmailLink'] ?? '',
      labels: List<String>.from(json['labels'] ?? []),
    );
  }

  bool get isImportant =>
      labels.contains('IMPORTANT') || labels.contains('STARRED');

  @override
  String toString() {
    return 'EmailMetadata(id: $id, subject: $subject, from: $from)';
  }
}
