class DemoMail {
  final String subject;
  final String sender;
  final String preview;
  final bool hasDeadline;
  final bool isImportant;

  const DemoMail({
    required this.subject,
    required this.sender,
    required this.preview,
    required this.hasDeadline,
    required this.isImportant,
  });

  static List<DemoMail> getDemoEmails() {
    return [
      DemoMail(
        subject: 'Welcome to MailMind',
        sender: 'support@mailmind.app',
        preview: 'Get started with intelligent email prioritization...',
        hasDeadline: false,
        isImportant: true,
      ),
      DemoMail(
        subject: 'Project Deadline: Q1 Report Due',
        sender: 'manager@company.com',
        preview: 'Please submit the quarterly report by Friday EOD...',
        hasDeadline: true,
        isImportant: true,
      ),
      DemoMail(
        subject: 'Meeting Confirmation: Monday 2 PM',
        sender: 'john.doe@company.com',
        preview: 'Confirming our meeting to discuss the new strategy...',
        hasDeadline: false,
        isImportant: false,
      ),
      DemoMail(
        subject: 'Newsletter: Flutter 3.16 Released',
        sender: 'news@flutter.dev',
        preview: 'Discover what\'s new in Flutter 3.16 with improved...',
        hasDeadline: false,
        isImportant: false,
      ),
      DemoMail(
        subject: 'Action Required: Please Review',
        sender: 'colleague@company.com',
        preview: 'Your feedback is requested on the design proposal...',
        hasDeadline: true,
        isImportant: true,
      ),
      DemoMail(
        subject: 'Weekly Team Sync',
        sender: 'team@company.com',
        preview: 'Summary of this week\'s accomplishments and next steps...',
        hasDeadline: false,
        isImportant: false,
      ),
    ];
  }
}
