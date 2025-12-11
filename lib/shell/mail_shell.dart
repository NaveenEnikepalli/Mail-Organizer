import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/email_repository.dart';
import '../core/gmail_api_service.dart';
import '../core/email_local_storage.dart';
import '../core/email_metadata.dart';
import '../core/priority_classifier.dart';
import '../core/priority_store.dart';
import '../core/deadline_detector.dart';
import '../core/deadline_store.dart';
import '../screens/inbox/inbox_screen.dart';
import '../screens/important/important_screen.dart';
import '../screens/deadlines/deadlines_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/signin/signin_screen.dart';
import '../screens/role_selection/role_selection_sheet.dart';
import '../screens/spam/spam_screen.dart';
import '../screens/groups/groups_screen.dart';

class MailShell extends StatefulWidget {
  const MailShell({super.key});

  @override
  State<MailShell> createState() => _MailShellState();
}

class _MailShellState extends State<MailShell> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'https://www.googleapis.com/auth/gmail.readonly'],
  );

  GoogleSignInAccount? _googleUser;
  bool _isImapLoggedIn = false;
  String? _imapEmailAddress;
  int _selectedIndex = 0;
  String? _selectedRole;

  late EmailRepository _emailRepository;
  List<EmailMetadata> _emails = [];
  bool _isSyncing = false;
  String? _errorMessage;
  List<EmailMetadata> _spamEmails = [];
  bool _isSyncingSpam = false;
  String? _spamError;
  late PriorityClassifier _priorityClassifier;
  late PriorityStore _priorityStore;
  List<EmailWithPriority> _prioritizedEmails = [];
  late DeadlineDetectorDart _deadlineDetector;
  late DeadlineStore _deadlineStore;
  final List<EmailMetadata> _emailsWithDeadlines = [];
  final Map<String, Map<String, dynamic>> _deadlineMetaById = {};
  String? _deadlineError;
  final List<EmailMetadata> _reminderEmails = [];
  Set<String> _dismissedReminderIds = {};
  int _remindersCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRepository()
        .then((_) {
          _loadLocalSpam();
          _loadLocalDeadlines();
        })
        .catchError((e) {
          debugPrint('Error during initialization: $e');
        });
    _setupGoogleSignInListener();
    _googleSignIn.signInSilently();
  }

  void _loadLocalDeadlines() {
    loadDeadlinesForLocalEmails()
        .then((_) {
          loadRemindersFromDeadlines();
        })
        .catchError((e) {
          debugPrint('Error loading local deadlines: $e');
        });
  }

  Future<void> _initializeRepository() async {
    _emailRepository = EmailRepository(
      gmailApiService: GmailApiService(),
      localStorage: EmailLocalStorage(),
    );
    // Initialize local storage
    try {
      await _emailRepository.localStorage.init();
      debugPrint('✓ EmailLocalStorage initialized');
    } catch (e) {
      debugPrint('Error initializing EmailLocalStorage: $e');
    }

    _priorityClassifier = PriorityClassifier(
      tfliteAssetPath: 'assets/models/priority_classifier.tflite',
    );
    _priorityStore = PriorityStore();
    _deadlineDetector = DeadlineDetectorDart();
    _deadlineStore = DeadlineStore();
    _initializePriorities();
    _initializeDeadlines();
  }

  Future<void> _initializePriorities() async {
    try {
      await _priorityClassifier.init();
      await _priorityStore.init();
    } catch (e) {
      debugPrint('Error initializing priorities: $e');
    }
  }

  Future<void> _initializeDeadlines() async {
    try {
      await _deadlineStore.init();
    } catch (e) {
      debugPrint('Error initializing deadline store: $e');
    }
  }

  Future<void> loadDeadlinesForLocalEmails() async {
    try {
      _emailsWithDeadlines.clear();
      _deadlineMetaById.clear();

      // Load all local emails
      final allEmails = await _emailRepository.loadEmailsFromLocal();
      debugPrint('📧 Loading deadlines for ${allEmails.length} local emails');

      // For each email, load deadline metadata
      for (final email in allEmails) {
        try {
          final meta = await _deadlineStore.loadDeadlineMetadata(email.id);
          if (meta != null) {
            final hasDeadline = meta['hasDeadline'] as bool? ?? false;
            debugPrint('  ${email.subject}: hasDeadline=$hasDeadline');
            if (hasDeadline) {
              _emailsWithDeadlines.add(email);
              _deadlineMetaById[email.id] = meta;
              debugPrint('    ✓ Added to deadline list');
            }
          }
        } catch (e) {
          debugPrint('Error loading deadline meta for ${email.id}: $e');
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error in loadDeadlinesForLocalEmails: $e');
      setState(() {
        _deadlineError =
            'Could not load deadlines: ${e.toString().split(':').first}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_deadlineError ?? 'Error loading deadlines'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> loadRemindersFromDeadlines() async {
    try {
      _reminderEmails.clear();
      _dismissedReminderIds.clear();

      final dismissedIds = await _deadlineStore.loadAllDismissedReminders();
      _dismissedReminderIds = dismissedIds.toSet();

      // Use existing emails (all, not just ones with deadlines)
      for (final email in _emails) {
        try {
          final meta = _deadlineMetaById[email.id];
          if (meta != null) {
            final daysUntil = meta['daysUntilPrimary'] as int? ?? 9999;
            if (daysUntil < 3 && !_dismissedReminderIds.contains(email.id)) {
              _reminderEmails.add(email);
            }
          }
        } catch (e) {
          debugPrint('Error processing reminder for ${email.id}: $e');
        }
      }

      _remindersCount = _reminderEmails.length;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error in loadRemindersFromDeadlines: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading reminders'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _setupGoogleSignInListener() {
    _googleSignIn.onCurrentUserChanged.listen((
      GoogleSignInAccount? account,
    ) async {
      setState(() {
        _googleUser = account;
      });
      if (account != null) {
        final authHeaders = await account.authHeaders;
        // Sync both inbox and spam in parallel
        await Future.wait([_syncInboxEmails(account), _syncSpam(authHeaders)]);
      }
    });
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google Sign-in error: $e')));
      }
    }
  }

  Future<void> _handleImapLogin(
    String email,
    String appPassword,
    String server,
    int port,
  ) async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });
    try {
      // TODO: Implement IMAP connection and email fetch
      // For now, just simulate a successful login
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isImapLoggedIn = true;
        _imapEmailAddress = email;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IMAP login successful for $email')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'IMAP login failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('IMAP login error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
    setState(() {
      _googleUser = null;
      _isImapLoggedIn = false;
      _imapEmailAddress = null;
      _selectedRole = null;
      _emails = [];
      _errorMessage = null;
    });
  }

  Future<void> _syncInboxEmails(GoogleSignInAccount account) async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });
    try {
      debugPrint('📥 Syncing emails from Gmail...');
      final authHeaders = await account.authHeaders;
      final emails = await _emailRepository.syncEmailsFromRemote(authHeaders);
      debugPrint('📥 Got ${emails.length} emails from Gmail');
      setState(() {
        _emails = emails;
      });
      // Compute priorities after sync (which calls _syncDeadlines internally)
      await _computePriorities();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sync emails: $e';
      });
      debugPrint('Email sync error: $e');
      // Still load cached emails if fetch fails
      try {
        final cachedEmails = await _emailRepository.loadEmailsFromLocal();
        setState(() {
          _emails = cachedEmails;
        });
        await _computePriorities();
      } catch (cacheError) {
        debugPrint('Cache load error: $cacheError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _computePriorities() async {
    try {
      debugPrint('⭐ Computing priorities for ${_emails.length} emails');
      final prioritized = await _emailRepository.computeAndStorePriorities(
        _emails,
        _priorityClassifier,
        _priorityStore,
      );
      setState(() {
        _prioritizedEmails = prioritized;
      });
      debugPrint('⭐ Got ${_prioritizedEmails.length} prioritized emails');
      // Also sync deadlines after computing priorities
      await _syncDeadlines();
    } catch (e) {
      debugPrint('Error computing priorities: $e');
    }
  }

  Future<void> _syncDeadlines() async {
    try {
      debugPrint('⏱️  Starting deadline sync with ${_emails.length} emails');
      await _emailRepository.analyzeAndStoreDeadlinesForEmails(
        _emails,
        _deadlineDetector,
        _deadlineStore,
      );

      // Load the deadline metadata and populate the UI
      await loadDeadlinesForLocalEmails();
      debugPrint(
        '⏱️  Loaded ${_emailsWithDeadlines.length} emails with deadlines',
      );
      await loadRemindersFromDeadlines();
      debugPrint('⏱️  Found ${_reminderEmails.length} reminder emails');
    } catch (e) {
      debugPrint('Error syncing deadlines: $e');
    }
  }

  Future<void> _manualRefreshEmails() async {
    if (_googleUser != null) {
      await _syncInboxEmails(_googleUser!);
    } else if (_isImapLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IMAP refresh not yet implemented')),
      );
    }
  }

  Future<void> _loadLocalSpam() async {
    try {
      final localSpam = await _emailRepository.loadSpamFromLocal();
      setState(() {
        _spamEmails = localSpam;
      });
    } catch (e) {
      debugPrint('Error loading local spam: $e');
    }
  }

  Future<void> _syncSpam(Map<String, String> authHeaders) async {
    setState(() {
      _isSyncingSpam = true;
      _spamError = null;
    });
    try {
      debugPrint('🚨 Syncing spam emails...');
      final spam = await _emailRepository.syncSpamFromRemote(authHeaders);
      debugPrint('🚨 Got ${spam.length} spam emails from Gmail');
      setState(() {
        _spamEmails = spam;
        _isSyncingSpam = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spam refreshed: ${spam.length} items'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _spamError = 'Failed to refresh spam: $e';
        _isSyncingSpam = false;
      });
      debugPrint('🚨 Error syncing spam: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spam refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoleSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return RoleSelectionSheet(
          onRoleSelected: (String role) {
            setState(() {
              _selectedRole = role;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return InboxScreen(
          emails: _emails,
          isSyncing: _isSyncing,
          errorMessage: _errorMessage,
        );
      case 1:
        return ImportantScreen(
          prioritizedEmails: _prioritizedEmails,
          onRecompute: _computePriorities,
        );
      case 2:
        return DeadlinesScreen(
          emails: _emailsWithDeadlines,
          deadlineMetaById: _deadlineMetaById,
          onRefresh: () async {
            await _syncInboxEmails(_googleUser!);
            await loadDeadlinesForLocalEmails();
            await loadRemindersFromDeadlines();
          },
        );
      case 3:
        return RemindersScreen(
          emails: _reminderEmails,
          reminderMetaById: _deadlineMetaById,
          onDismissReminder: (messageId) async {
            await _deadlineStore.saveReminderDismissed(messageId, true);
            await loadRemindersFromDeadlines();
            if (mounted) {
              setState(() {});
            }
          },
          onMoveToTrash: (messageId) async {
            // TODO: Implement move to trash functionality
            await _deadlineStore.saveReminderDismissed(messageId, true);
            await loadRemindersFromDeadlines();
            if (mounted) {
              setState(() {});
            }
          },
          onRefresh: () async {
            await _syncInboxEmails(_googleUser!);
            await loadDeadlinesForLocalEmails();
            await loadRemindersFromDeadlines();
          },
        );
      default:
        return InboxScreen(
          emails: _emails,
          isSyncing: _isSyncing,
          errorMessage: _errorMessage,
        );
    }
  }

  String _getDisplayName() {
    if (_googleUser?.displayName != null &&
        _googleUser!.displayName!.isNotEmpty) {
      return _googleUser!.displayName!;
    }
    if (_imapEmailAddress != null) {
      return _imapEmailAddress!.split('@')[0];
    }
    return 'User';
  }

  String _getDisplayEmail() {
    if (_googleUser?.email != null) {
      return _googleUser!.email;
    }
    if (_imapEmailAddress != null) {
      return _imapEmailAddress!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = _googleUser != null || _isImapLoggedIn;

    if (!isAuthenticated) {
      return SignInScreen(
        onGoogleSignIn: _handleGoogleSignIn,
        onImapLogin: _handleImapLogin,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mail Organizer'),
        centerTitle: false,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _manualRefreshEmails,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showRoleSelectionSheet,
              child: Center(
                child: _googleUser?.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(_googleUser!.photoUrl!),
                      )
                    : CircleAvatar(
                        child: Text(
                          _getDisplayName().substring(0, 1).toUpperCase(),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mail Organizer',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDisplayName(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      _getDisplayEmail(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    if (_isImapLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Chip(
                          label: const Text(
                            'IMAP',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.inbox),
                      title: const Text('Inbox'),
                      trailing: _emails.isNotEmpty
                          ? Badge(
                              label: Text(
                                _emails.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.blue,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text('Important'),
                      trailing: _prioritizedEmails.isNotEmpty
                          ? Badge(
                              label: Text(
                                _prioritizedEmails.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.orange,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Deadlines'),
                      trailing: _emailsWithDeadlines.isNotEmpty
                          ? Badge(
                              label: Text(
                                _emailsWithDeadlines.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.purple,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedIndex = 2);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.alarm),
                      title: const Text('Snoozed / Reminders'),
                      trailing: _remindersCount > 0
                          ? Badge(
                              label: Text(
                                _remindersCount.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedIndex = 3);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.report_gmailerrorred),
                      title: const Text('Spam'),
                      trailing: _spamEmails.isNotEmpty
                          ? Badge(
                              label: Text(
                                _spamEmails.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red.shade300,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpamScreen(
                              spamEmails: _spamEmails,
                              isSyncing: _isSyncingSpam,
                              errorMessage: _spamError,
                              onRefresh: _googleUser != null
                                  ? () async {
                                      final authHeaders =
                                          await _googleUser!.authHeaders;
                                      await _syncSpam(authHeaders);
                                    }
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.folder_open),
                      title: const Text('Groups'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupsScreen(emails: _emails),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.assignment_ind),
                      title: const Text('Role & Filters'),
                      subtitle: _selectedRole != null
                          ? Text(
                              _selectedRole!,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      onTap: () {
                        _showRoleSelectionSheet();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings page coming soon'),
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () {
                  _handleSignOut();
                  Navigator.pop(context);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Mail Organizer • Smart Email Prioritizer',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Important'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Deadlines'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
        ],
      ),
    );
  }
}
