import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const Color primaryBlue = Color(0xFF5963A5);
const Color backgroundColor = Color(0xFFF6F7FC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    runApp(const SRStudiesApp());
  } catch (e) {
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

// ============================================================
// APP
// ============================================================

class SRStudiesApp extends StatelessWidget {
  const SRStudiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SR STUDIES',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// FIREBASE ERROR
// ============================================================

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  const FirebaseErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SR STUDIES',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Firebase Error',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email और Password दोनों भरें');
      return;
    }

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        showMessage('Login failed');
        return;
      }

      await user.reload();

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && !currentUser.emailVerified) {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          showMessage(
            'पहले Email verification पूरा करें।',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      showMessage(authError(e.code));
    } catch (_) {
      showMessage('Login में समस्या हुई');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String authError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email सही नहीं है';
      case 'user-not-found':
        return 'यह Email registered नहीं है';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email या Password गलत है';
      case 'user-disabled':
        return 'यह account बंद कर दिया गया है';
      case 'too-many-requests':
        return 'बहुत ज्यादा attempts हुए हैं';
      case 'network-request-failed':
        return 'Internet connection check करें';
      default:
        return 'Login failed: $code';
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          child: Column(
            children: [
              const Icon(
                Icons.school,
                size: 90,
                color: primaryBlue,
              ),
              const SizedBox(height: 18),
              const Text(
                'SR STUDIES',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn • Practice • Succeed',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 45),
              AppTextField(
                controller: emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Create New Account',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP
// ============================================================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage('Name, Email और Password भरें');
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password कम से कम 6 characters का होना चाहिए',
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Account Created'),
          content: const Text(
            'आपके Email पर verification link भेजा गया है। '
            'Email verify करने के बाद Login करें।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      showMessage(signupError(e.code));
    } catch (_) {
      showMessage('Account बनाने में समस्या हुई');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String signupError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'यह Email पहले से registered है';
      case 'invalid-email':
        return 'Email सही नहीं है';
      case 'weak-password':
        return 'Password बहुत कमजोर है';
      case 'operation-not-allowed':
        return 'Firebase में Email/Password enable करें';
      case 'network-request-failed':
        return 'Internet connection check करें';
      default:
        return 'Signup failed: $code';
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.school,
              size: 75,
              color: primaryBlue,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: nameController,
              hint: 'Student Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: emailController,
              hint: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: passwordController,
              hint: 'Password',
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              suffix: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: loading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FORGOT PASSWORD
// ============================================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Registered Email डालें');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        showMessage(
          'Password reset link Email पर भेज दिया गया है।',
        );
      }
    } on FirebaseAuthException catch (e) {
      showMessage('Password reset failed: ${e.code}');
    } catch (_) {
      showMessage('Password reset में समस्या हुई');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: primaryBlue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            AppTextField(
              controller: emailController,
              hint: 'Registered Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: loading ? null : resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'SEND RESET LINK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAIN NAVIGATION
// ============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    SubjectsPage(),
    PracticePage(),
    NotesPage(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SR STUDIES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to SR STUDIES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'अपने subjects चुनें और अपनी preparation शुरू करें।',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Subjects',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            const SubjectSection(
              title: 'ARTS & SOCIAL SCIENCE',
              icon: Icons.menu_book_outlined,
              subjects: [
                ['History', Icons.history_edu],
                ['Economics', Icons.currency_rupee],
                ['Geography', Icons.public],
                ['Polity', Icons.account_balance],
              ],
            ),
            const SubjectSection(
              title: 'SCIENCE',
              icon: Icons.science_outlined,
              subjects: [
                ['Biology', Icons.biotech_outlined],
                ['Chemistry', Icons.science],
                ['Physics', Icons.bolt_outlined],
              ],
            ),
            const SubjectSection(
              title: 'MAPS',
              icon: Icons.map_outlined,
              subjects: [
                ['World Map', Icons.public],
                ['Indian Map', Icons.map],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUBJECTS
// ============================================================

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          SubjectSection(
            title: 'ARTS & SOCIAL SCIENCE',
            icon: Icons.menu_book_outlined,
            subjects: [
              ['History', Icons.history_edu],
              ['Economics', Icons.currency_rupee],
              ['Geography', Icons.public],
              ['Polity', Icons.account_balance],
            ],
          ),
          SubjectSection(
            title: 'SCIENCE',
            icon: Icons.science_outlined,
            subjects: [
              ['Biology', Icons.biotech_outlined],
              ['Chemistry', Icons.science],
              ['Physics', Icons.bolt_outlined],
            ],
          ),
          SubjectSection(
            title: 'MAPS',
            icon: Icons.map_outlined,
            subjects: [
              ['World Map', Icons.public],
              ['Indian Map', Icons.map],
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUBJECT SECTION
// ============================================================

class SubjectSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<List<dynamic>> subjects;

  const SubjectSection({
    super.key,
    required this.title,
    required this.icon,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupTitle(
          icon: icon,
          title: title,
        ),
        ...subjects.map(
          (item) => SubjectCard(
            title: item[0] as String,
            icon: item[1] as IconData,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

// ============================================================
// SUBJECT CARD
// ============================================================

class SubjectCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const SubjectCard({
    super.key,
    required this.title,
    required this.icon,
  });

  String get firestoreSubjectName {
    return title.toLowerCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 65,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectVideosPage(
                subjectName: title,
                firestoreName: firestoreSubjectName,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUBJECT VIDEOS
// ============================================================

class SubjectVideosPage extends StatelessWidget {
  final String subjectName;
  final String firestoreName;

  const SubjectVideosPage({
    super.key,
    required this.subjectName,
    required this.firestoreName,
  });

  @override
  Widget build(BuildContext context) {
    final videosStream = FirebaseFirestore.instance
        .collection('subjects')
        .doc(firestoreName)
        .collection('videos')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subjectName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: videosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  'Videos load नहीं हो सके।\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 75,
                      color: primaryBlue,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'अभी कोई video उपलब्ध नहीं है',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return VideoCard(
                title: (data['title'] ?? 'Study Video').toString(),
                description:
                    (data['description'] ?? '').toString(),
                videoUrl: (data['videoUrl'] ?? '').toString(),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// VIDEO CARD
// VIDEO NOW PLAYS INSIDE THE APP
// ============================================================

class VideoCard extends StatefulWidget {
  final String title;
  final String description;
  final String videoUrl;

  const VideoCard({
    super.key,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  YoutubePlayerController? controller;
  String? videoId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final id = YoutubePlayer.convertUrlToId(
      widget.videoUrl.trim(),
    );

    if (id == null || id.isEmpty) {
      errorMessage = 'Video link गलत है';
      return;
    }

    videoId = id;

    controller = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        hideControls: false,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller != null && videoId != null)
            YoutubePlayer(
              controller: controller!,

              // ==================================================
              // CUSTOM CONTROLS
              // Share / Watch Later / YouTube button removed.
              // ==================================================

              topActions: const [],

              bottomActions: const [
                PlayPauseButton(),
                CurrentPosition(),
                SizedBox(width: 8),
                ProgressBar(
                  isExpanded: true,
                ),
                SizedBox(width: 8),
                RemainingDuration(),
              ],

              showVideoProgressIndicator: false,
              aspectRatio: 16 / 9,
            )
          else
            Container(
              width: double.infinity,
              height: 210,
              color: Colors.black12,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    errorMessage ?? 'Video load नहीं हुआ',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              15,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRACTICE
// ============================================================

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Practice',
      message: 'Practice questions जल्द उपलब्ध होंगे।',
      icon: Icons.quiz_outlined,
    );
  }
}

// ============================================================
// NOTES
// ============================================================

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Notes',
      message: 'Study notes जल्द उपलब्ध होंगे।',
      icon: Icons.folder_outlined,
    );
  }
}

// ============================================================
// SIMPLE PAGE
// ============================================================

class SimplePage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const SimplePage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 75,
                color: primaryBlue,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();

    nameController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> changeName() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage('Name खाली नहीं हो सकता');
      return;
    }

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMessage('User login नहीं है');
        return;
      }

      await user.updateDisplayName(name);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': name,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.reload();

      if (mounted) {
        showMessage('Name successfully updated');
      }
    } catch (_) {
      showMessage('Name update नहीं हो पाया');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 52,
              backgroundColor: primaryBlue,
              child: Icon(
                Icons.person,
                size: 55,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Student Profile',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            AppTextField(
              controller: nameController,
              hint: 'Student Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saving ? null : changeName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('CHANGE NAME'),
              ),
            ),
            const SizedBox(height: 35),

            // ==================================================
            // SOCIAL MEDIA
            // ==================================================

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Admin Social Media',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),

            SocialButton(
              icon: Icons.play_circle_fill,
              title: 'YouTube',
              url: 'https://youtube.com/@rceditor999',
            ),

            SocialButton(
              icon: Icons.camera_alt,
              title: 'Instagram',
              url: 'https://www.instagram.com/rceditor999/',
            ),

            SocialButton(
              icon: Icons.send,
              title: 'Telegram',
              url: 'https://t.me/RCEDITOR999',
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SOCIAL BUTTON
// ============================================================

class SocialButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  const SocialButton({
    super.key,
    required this.icon,
    required this.title,
    required this.url,
  });

  Future<void> openLink(BuildContext context) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      showMessage(context, '$title link गलत है');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        showMessage(
          context,
          '$title खोलने में समस्या हुई',
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          '$title खोलने में समस्या हुई',
        );
      }
    }
  }

  void showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openLink(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: primaryBlue,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.open_in_new),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GROUP TITLE
// ============================================================

class GroupTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const GroupTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEXT FIELD
// ============================================================

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
      ),
    );
  }
}
