import 'package:qr_chat/components/custom_card.dart';
import 'package:qr_chat/services/crud_services.dart';
import 'package:qr_chat/screens/my_qr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();
  String? _userName;
  String? _userId; // persisted Firestore user id
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // Load saved name (and user id) and show dialog only if name missing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSavedName();
      if (_userName == null || _userName!.isEmpty) {
        await _showNameDialog();
      } else {
        await _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showNameDialog() async {
    _nameController.text = _userName ?? '';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false, // Prevent back button from closing dialog
          child: StatefulBuilder(
            builder: (context, setLocalState) => AlertDialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please enter your name to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _trySaveName(),
                onChanged: (_) => setLocalState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Saman Kumara ',
                  labelText: 'Your Name',
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isEmpty
                        ? null
                        : _trySaveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _trySaveName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _userName = name;
    });
    Navigator.of(context).pop();
    // Persist locally and remotely
    _persistName(name);
  }

  Future<void> _loadSavedName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');
      final savedId = prefs.getString('user_id');
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _userName = savedName;
          _userId = savedId;
        });
      }
    } catch (e) {
      // ignore prefs errors silently
      print('Error loading saved name: $e');
    }
  }

  Future<void> _persistName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      // If we don't already have a firestore user id, create one with auto id
      if (_userId == null || _userId!.isEmpty) {
        final crud = CrudServices();
        final generatedId = await crud.insertUserAuto(name: name);
        if (generatedId != null) {
          _userId = generatedId;
          await prefs.setString('user_id', generatedId);
          await _loadUnreadCount(); // Load unread count after user ID is set
        } else {
          print('Failed to create user in Firestore');
        }
      }
    } catch (e) {
      print('Error persisting name: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    if (_userId != null && _userId!.isNotEmpty) {
      try {
        final crud = CrudServices();
        final count = await crud.getTotalUnreadMessagesCount(_userId!);
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      } catch (e) {
        print('Error loading unread count: $e');
      }
    }
  }

  Future<void> testFirebaseConnection(BuildContext context) async {
    final crudServices = CrudServices();

    // Test inserting a user
    bool success = await crudServices.insertUser(
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User');

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Firebase connection successful! User inserted.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Firebase connection failed!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // StreamBuilder to listen for real-time unread count updates
          if (_userId != null && _userId!.isNotEmpty)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: CrudServices().getUserChatsStream(_userId!),
              builder: (context, snapshot) {
                // Calculate unread chats count from stream data (number of chats with unread messages)
                int currentUnreadCount = 0;
                if (snapshot.hasData) {
                  for (final chat in snapshot.data!) {
                    final unreadValue = chat['unread'] ?? 0;
                    final unreadCount = unreadValue is int
                        ? unreadValue
                        : int.tryParse(unreadValue.toString()) ?? 0;
                    if (unreadCount > 0) {
                      currentUnreadCount++;
                    }
                  }
                }

                // Update state if unread count changed
                if (currentUnreadCount != _unreadCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _unreadCount = currentUnreadCount;
                      });
                    }
                  });
                }

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.pushNamed(context, '/unread_messages');
                      },
                    ),
                    if (currentUnreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            currentUnreadCount > 99
                                ? '99+'
                                : '$currentUnreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          else
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.pushNamed(context, '/unread_messages');
                  },
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isSmall = width < 360;
          final hPad = width < 400 ? 16.0 : 24.0;

          return SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Welcome Header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmall ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName != null
                                            ? 'Welcome back, $_userName!'
                                            : 'QR Chat',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: isSmall ? 18 : 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Connect instantly with QR codes',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmall ? 32 : 40),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomCard(
                            icon: Icons.qr_code_outlined,
                            iconColor: theme.colorScheme.primary,
                            bgColor: theme.colorScheme.primary.withOpacity(0.1),
                            title: 'New Connection',
                            subtitle:
                                'Generate or scan a QR code to start a new chat',
                            buttonText: 'Connect Now',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MyQRPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomCard(
                            icon: Icons.message_outlined,
                            iconColor: theme.colorScheme.secondary,
                            bgColor:
                                theme.colorScheme.secondary.withOpacity(0.1),
                            title: 'Recent Chats',
                            subtitle:
                                'Continue your conversations with recent connections',
                            buttonText: 'View Chats',
                            onPressed: () {
                              Navigator.pushNamed(context, '/chats');
                            },
                          ),
                          const SizedBox(height: 32),
                          // Test Firebase Connection Button
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
