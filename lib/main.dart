import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const Color primaryBlue = Color(0xFF5963A5);
const Color backgroundColor = Color(0xFFF6F7FC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  try {
    await Firebase.initializeApp();
    runApp(const SRStudiesApp());
  } catch (e) {
    runApp(
      FirebaseErrorApp(
        error: e.toString(),
      ),
    );
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
          surfaceTintColor: Colors.transparent,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
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
  State<LoginScreen> createState() =>
      _LoginScreenState();
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
      showMessage(
        'Email और Password दोनों भरें',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        showMessage('Login failed');
        return;
      }

      await user.reload();

      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser != null &&
          !currentUser.emailVerified) {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          showMessage(
            'पहले Email verification पूरा करें।',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      showMessage(
        authError(e.code),
      );
    } catch (_) {
      showMessage(
        'Login में समस्या हुई',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            30,
            50,
            30,
            30,
          ),
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
                keyboardType:
                    TextInputType.emailAddress,
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
                      obscurePassword =
                          !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons
                            .visibility_off_outlined
                        : Icons
                            .visibility_outlined,
                  ),
                ),
              ),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ForgotPasswordScreen(),
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
                  onPressed:
                      loading ? null : login,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryBlue,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
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
                            fontWeight:
                                FontWeight.bold,
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
                      builder: (_) =>
                          const SignupScreen(),
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
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {
  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

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
    final name =
        nameController.text.trim();

    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      showMessage(
        'Name, Email और Password भरें',
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password कम से कम 6 characters का होना चाहिए',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(
          name,
        );

        await user.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      await FirebaseAuth.instance
          .signOut();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text(
              'Account Created',
            ),
            content: const Text(
              'आपके Email पर verification link भेजा गया है। '
              'Email verify करने के बाद Login करें।',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      showMessage(
        signupError(e.code),
      );
    } catch (_) {
      showMessage(
        'Account बनाने में समस्या हुई',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
        ),
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
              textCapitalization:
                  TextCapitalization.words,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: emailController,
              hint: 'Email',
              icon: Icons.email_outlined,
              keyboardType:
                  TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller:
                  passwordController,
              hint: 'Password',
              icon: Icons.lock_outline,
              obscureText:
                  obscurePassword,
              suffix: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword =
                        !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons
                          .visibility_off_outlined
                      : Icons
                          .visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed:
                    loading ? null : signup,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryBlue,
                  foregroundColor:
                      Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
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

class ForgotPasswordScreen
    extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController =
      TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email =
        emailController.text.trim();

    if (email.isEmpty) {
      showMessage(
        'Registered Email डालें',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        showMessage(
          'Password reset link Email पर भेज दिया गया है।',
        );
      }
    } on FirebaseAuthException catch (e) {
      showMessage(
        passwordResetError(e.code),
      );
    } catch (_) {
      showMessage(
        'Password reset में समस्या हुई',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String passwordResetError(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return 'Email सही नहीं है';

      case 'user-not-found':
        return 'यह Email registered नहीं है';

      case 'network-request-failed':
        return 'Internet connection check करें';

      case 'too-many-requests':
        return 'बहुत ज्यादा attempts हुए हैं, थोड़ी देर बाद try करें';

      default:
        return 'Password reset failed: $code';
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
        ),
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
              keyboardType:
                  TextInputType.emailAddress,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed:
                    loading
                        ? null
                        : resetPassword,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryBlue,
                  foregroundColor:
                      Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'SEND RESET LINK',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
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

class MainNavigation
    extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
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
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            selectedIcon: Icon(
              Icons.menu_book,
            ),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.quiz_outlined,
            ),
            selectedIcon: Icon(
              Icons.quiz,
            ),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.folder_outlined,
            ),
            selectedIcon: Icon(
              Icons.folder,
            ),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius:
                    BorderRadius.circular(26),
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to SR STUDIES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
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
              title:
                  'ARTS & SOCIAL SCIENCE',
              icon:
                  Icons.menu_book_outlined,
              subjects: [
                [
                  'History',
                  Icons.history_edu,
                ],
                [
                  'Economics',
                  Icons.currency_rupee,
                ],
                [
                  'Geography',
                  Icons.public,
                ],
                [
                  'Polity',
                  Icons.account_balance,
                ],
              ],
            ),
            const SubjectSection(
              title: 'SCIENCE',
              icon:
                  Icons.science_outlined,
              subjects: [
                [
                  'Biology',
                  Icons.biotech_outlined,
                ],
                [
                  'Chemistry',
                  Icons.science,
                ],
                [
                  'Physics',
                  Icons.bolt_outlined,
                ],
              ],
            ),
            const SubjectSection(
              title: 'MAPS',
              icon: Icons.map_outlined,
              subjects: [
                [
                  'World Map',
                  Icons.public,
                ],
                [
                  'Indian Map',
                  Icons.map,
                ],
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

class SubjectsPage
    extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subjects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          SubjectSection(
            title:
                'ARTS & SOCIAL SCIENCE',
            icon:
                Icons.menu_book_outlined,
            subjects: [
              [
                'History',
                Icons.history_edu,
              ],
              [
                'Economics',
                Icons.currency_rupee,
              ],
              [
                'Geography',
                Icons.public,
              ],
              [
                'Polity',
                Icons.account_balance,
              ],
            ],
          ),
          SubjectSection(
            title: 'SCIENCE',
            icon:
                Icons.science_outlined,
            subjects: [
              [
                'Biology',
                Icons.biotech_outlined,
              ],
              [
                'Chemistry',
                Icons.science,
              ],
              [
                'Physics',
                Icons.bolt_outlined,
              ],
            ],
          ),
          SubjectSection(
            title: 'MAPS',
            icon: Icons.map_outlined,
            subjects: [
              [
                'World Map',
                Icons.public,
              ],
              [
                'Indian Map',
                Icons.map,
              ],
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

class SubjectSection
    extends StatelessWidget {
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
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

class SubjectCard
    extends StatelessWidget {
  final String title;
  final IconData icon;

  const SubjectCard({
    super.key,
    required this.title,
    required this.icon,
  });

  String get firestoreSubjectName {
    switch (title) {
      case 'History':
        return 'history';

      case 'Economics':
        return 'economics';

      case 'Geography':
        return 'geography';

      case 'Polity':
        return 'polity';

      case 'Biology':
        return 'biology';

      case 'Chemistry':
        return 'chemistry';

      case 'Physics':
        return 'physics';

      case 'World Map':
        return 'world_map';

      case 'Indian Map':
        return 'indian_map';

      default:
        return title
            .toLowerCase()
            .replaceAll(' ', '_');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 65,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SubjectVideosPage(
                subjectName: title,
                firestoreName:
                    firestoreSubjectName,
              ),
            ),
          );
        },
        style:
            ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor:
              Colors.black87,
          elevation: 1,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: primaryBlue
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
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
                  fontWeight:
                      FontWeight.w600,
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
// SUBJECT VIDEOS PAGE
// ============================================================

class SubjectVideosPage
    extends StatefulWidget {
  final String subjectName;
  final String firestoreName;

  const SubjectVideosPage({
    super.key,
    required this.subjectName,
    required this.firestoreName,
  });

  @override
  State<SubjectVideosPage> createState() =>
      _SubjectVideosPageState();
}

class _SubjectVideosPageState
    extends State<SubjectVideosPage> {
  @override
  void initState() {
    super.initState();

    lockPortrait();
  }

  Future<void> lockPortrait() async {
    await SystemChrome
        .setPreferredOrientations(
      const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );

    await SystemChrome
        .setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    SystemChrome
        .setPreferredOrientations(
      const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );

    SystemChrome
        .setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  Stream<
      QuerySnapshot<
          Map<String, dynamic>>> videoStream() {
    return FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.firestoreName)
        .collection('videos')
        .snapshots();
  }

  List<
      QueryDocumentSnapshot<
          Map<String, dynamic>>> sortVideos(
    List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        docs,
  ) {
    final videos = [...docs];

    videos.sort(
      (a, b) {
        final aData = a.data();
        final bData = b.data();

        final aTime =
            aData['createdAt'];

        final bTime =
            bData['createdAt'];

        if (aTime is Timestamp &&
            bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        if (aTime is Timestamp) {
          return -1;
        }

        if (bTime is Timestamp) {
          return 1;
        }

        return b.id.compareTo(a.id);
      },
    );

    return videos;
  }

  String getVideoValue(
    Map<String, dynamic> data,
  ) {
    const fields = [
      'videoUrl',
      'videoURL',
      'youtubeUrl',
      'youtubeURL',
      'url',
      'link',
      'videoId',
      'youtubeId',
      'youtubeVideoId',
      'video_id',
    ];

    for (final field in fields) {
      final value = data[field];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return '';
  }

  bool getIsLive(
    Map<String, dynamic> data) {
    final type =
        (data['type'] ?? '')
            .toString()
            .toLowerCase();

    return data['isLive'] == true ||
        type == 'live' ||
        type == 'livestream';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar हटाया गया है।
      // इसलिए ऊपर Subject वाला white bar नहीं आएगा।
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: videoStream(),
        builder:
            (context, snapshot) {
          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          if (snapshot.hasError) {
            return _EmptyOrErrorView(
              icon:
                  Icons.error_outline,
              title:
                  'Videos load नहीं हो सके',
              message:
                  '${snapshot.error}',
              error: true,
            );
          }

          final docs = sortVideos(
            snapshot.data?.docs ?? [],
          );

          if (docs.isEmpty) {
            return _EmptyOrErrorView(
              icon: Icons
                  .video_library_outlined,
              title:
                  'अभी ${widget.subjectName} का कोई video उपलब्ध नहीं है',
              message:
                  'Firestore में subjects/${widget.firestoreName}/videos में video add करें।',
            );
          }

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(
                  milliseconds: 300,
                ),
              );
            },
            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(
                parent:
                    BouncingScrollPhysics(),
              ),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,

              // AppBar हटने के बाद video सबसे ऊपर से शुरू होगा।
              padding:
                  const EdgeInsets.fromLTRB(
                0,
                0,
                0,
                40,
              ),

              itemCount: docs.length,
              itemBuilder:
                  (context, index) {
                final data =
                    docs[index].data();

                final title =
                    (data['title'] ??
                            data['name'] ??
                            'Study Video')
                        .toString()
                        .trim();

                final description =
                    (data['description'] ??
                            '')
                        .toString()
                        .trim();

                final videoUrl =
                    getVideoValue(data);

                return VideoCard(
                  key: ValueKey(
                    '${widget.firestoreName}_${docs[index].id}',
                  ),
                  title: title.isEmpty
                      ? 'Study Video'
                      : title,
                  description:
                      description,
                  videoUrl: videoUrl,
                  isLive:
                      getIsLive(data),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// EMPTY / ERROR
// ============================================================

class _EmptyOrErrorView
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool error;

  const _EmptyOrErrorView({
    required this.icon,
    required this.title,
    required this.message,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 75,
              color: error
                  ? Colors.red
                  : primaryBlue,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// VIDEO CARD
// ============================================================

class VideoCard
    extends StatefulWidget {
  final String title;
  final String description;
  final String videoUrl;
  final bool isLive;

  const VideoCard({
    super.key,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.isLive = false,
  });

  @override
  State<VideoCard> createState() =>
      _VideoCardState();
}

class _VideoCardState
    extends State<VideoCard> {
  YoutubePlayerController? controller;

  String? videoId;
  String? errorMessage;

  bool isFullscreen = false;
  bool muted = false;

  double playbackSpeed = 1.0;

  // ==========================================================
  // ALL SPEEDS
  // ==========================================================

  static const List<double> speeds = [
    0.25,
    0.50,
    0.75,
    1.0,
    1.25,
    1.50,
    1.75,
    2.0,
  ];

  @override
  void initState() {
    super.initState();

    initializePlayer();
  }

  // ==========================================================
  // YOUTUBE ID
  // ==========================================================

  String? extractYoutubeId(
    String input,
  ) {
    var value = input
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();

    if (value.isEmpty) {
      return null;
    }

    final directId =
        RegExp(
      r'^[A-Za-z0-9_-]{11}$',
    );

    if (directId.hasMatch(value)) {
      return value;
    }

    Uri? uri =
        Uri.tryParse(value);

    if (uri == null ||
        uri.host.isEmpty) {
      uri = Uri.tryParse(
        'https://$value',
      );
    }

    if (uri == null) {
      return null;
    }

    final host =
        uri.host.toLowerCase();

    const youtubeHosts = {
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'music.youtube.com',
    };

    if (youtubeHosts.contains(host)) {
      final queryId =
          uri.queryParameters['v'];

      if (queryId != null &&
          directId.hasMatch(
            queryId,
          )) {
        return queryId;
      }

      for (final pathName in [
        'shorts',
        'embed',
        'live',
      ]) {
        if (uri.pathSegments.length >=
                2 &&
            uri.pathSegments
                    .first
                    .toLowerCase() ==
                pathName) {
          final id =
              uri.pathSegments[1];

          if (directId.hasMatch(id)) {
            return id;
          }
        }
      }
    }

    if (host == 'youtu.be' ||
        host == 'www.youtu.be') {
      if (uri.pathSegments
          .isNotEmpty) {
        final id =
            uri.pathSegments.first;

        if (directId.hasMatch(id)) {
          return id;
        }
      }
    }

    final fallback =
        RegExp(
      r'(?:v=|youtu\.be/|/shorts/|/embed/|/live/)'
      r'([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );

    return fallback
        .firstMatch(value)
        ?.group(1);
  }

  // ==========================================================
  // INITIALIZE PLAYER
  // ==========================================================

  void initializePlayer() {
    final input =
        widget.videoUrl.trim();

    if (input.isEmpty) {
      errorMessage =
          'Video link Firestore में नहीं मिला';
      return;
    }

    final id =
        extractYoutubeId(input);

    if (id == null ||
        id.isEmpty) {
      errorMessage =
          'YouTube video link गलत है\n\n$linkPreview';
      return;
    }

    videoId = id;

    controller =
        YoutubePlayerController(
      initialVideoId: id,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart:
            true,
        hideControls: false,
        loop: false,
        forceHD: false,
        isLive: widget.isLive,
        useHybridComposition:
            true,
      ),
    );

    controller!.addListener(
      playerListener,
    );
  }

  String get linkPreview {
    if (widget.videoUrl.length <=
        100) {
      return widget.videoUrl;
    }

    return '${widget.videoUrl.substring(0, 100)}...';
  }

  // ==========================================================
  // PLAYER LISTENER
  // ==========================================================

  void playerListener() {
    if (!mounted ||
        controller == null) {
      return;
    }

    final fullscreen =
        controller!
            .value
            .isFullScreen;

    if (fullscreen !=
        isFullscreen) {
      setState(() {
        isFullscreen =
            fullscreen;
      });
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    controller?.removeListener(
      playerListener,
    );

    controller?.dispose();

    super.dispose();
  }

  // ==========================================================
  // ENTER FULLSCREEN
  // ==========================================================

  Future<void>
      enterFullscreen() async {
    if (controller == null) {
      return;
    }

    await SystemChrome
        .setPreferredOrientations(
      const [
        DeviceOrientation
            .landscapeLeft,
        DeviceOrientation
            .landscapeRight,
      ],
    );

    await SystemChrome
        .setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    controller!
        .toggleFullScreenMode();

    if (mounted) {
      setState(() {
        isFullscreen = true;
      });
    }
  }

  // ==========================================================
  // EXIT FULLSCREEN
  // ==========================================================

  Future<void>
      exitFullscreen() async {
    if (controller == null) {
      return;
    }

    if (controller!
        .value
        .isFullScreen) {
      controller!
          .toggleFullScreenMode();
    }

    await SystemChrome
        .setPreferredOrientations(
      const [
        DeviceOrientation
            .portraitUp,
        DeviceOrientation
            .portraitDown,
      ],
    );

    await SystemChrome
        .setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    if (mounted) {
      setState(() {
        isFullscreen = false;
      });
    }
  }

  // ==========================================================
  // FULLSCREEN TOGGLE
  // ==========================================================

  Future<void>
      toggleFullscreen() async {
    if (isFullscreen) {
      await exitFullscreen();
    } else {
      await enterFullscreen();
    }
  }

  // ==========================================================
  // SPEED LABEL
  // ==========================================================

  String speedLabel(
    double speed,
  ) {
    if (speed ==
        speed.roundToDouble()) {
      return '${speed.toInt()}x';
    }

    return '${speed.toStringAsFixed(2)}x';
  }

  // ==========================================================
  // CHANGE SPEED
  // ==========================================================

  void changeSpeed(
    double speed,
  ) {
    if (controller == null) {
      return;
    }

    controller!.setPlaybackRate(
      speed,
    );

    if (mounted) {
      setState(() {
        playbackSpeed = speed;
      });
    }
  }

  // ==========================================================
  // SPEED MENU
  // ==========================================================

  void showSpeedMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const Padding(
                  padding:
                      EdgeInsets.fromLTRB(
                    20,
                    6,
                    20,
                    8,
                  ),
                  child: Text(
                    'Playback Speed',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child:
                      ListView.separated(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      20,
                    ),
                    itemCount:
                        speeds.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (_, index) {
                      final speed =
                          speeds[index];

                      final selected =
                          speed ==
                              playbackSpeed;

                      return ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                        ),
                        leading: Icon(
                          selected
                              ? Icons
                                  .radio_button_checked
                              : Icons
                                  .radio_button_off,
                          color:
                              primaryBlue,
                        ),
                        title: Text(
                          speedLabel(
                            speed,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        trailing:
                            selected
                                ? const Icon(
                                    Icons.check,
                                    color:
                                        primaryBlue,
                                  )
                                : null,
                        onTap: () {
                          changeSpeed(
                            speed,
                          );

                          Navigator.of(
                            sheetContext,
                          ).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // MUTE
  // ==========================================================

  void toggleMute() {
    if (controller == null) {
      return;
    }

    if (muted) {
      controller!.unMute();
    } else {
      controller!.mute();
    }

    if (mounted) {
      setState(() {
        muted = !muted;
      });
    }
  }

  // ==========================================================
  // QUALITY
  // ==========================================================

  void showQualityInfo() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          const SafeArea(
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(
            24,
            15,
            24,
            30,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.high_quality,
                size: 55,
                color: primaryBlue,
              ),
              SizedBox(height: 15),
              Text(
                'Video Quality',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'YouTube video की quality internet speed और YouTube player के अनुसार automatically adjust होती है।',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // OPEN YOUTUBE
  // ==========================================================

  Future<void> openYoutube() async {
    if (videoId == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.youtube.com/watch?v=$videoId',
    );

    try {
      final opened =
          await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'YouTube खोलने में समस्या हुई',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'YouTube खोलने में समस्या हुई',
            ),
          ),
        );
      }
    }
  }

  // ==========================================================
  // PLAYER
  // ==========================================================

  Widget buildPlayer() {
    if (controller == null ||
        videoId == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black12,
          alignment:
              Alignment.center,
          padding:
              const EdgeInsets.all(
            20,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                errorMessage ??
                    'Video load नहीं हुआ',
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 14,
              ),
              if (widget.videoUrl
                  .trim()
                  .isNotEmpty)
                OutlinedButton.icon(
                  onPressed:
                      openYoutube,
                  icon: const Icon(
                    Icons.open_in_new,
                  ),
                  label: const Text(
                    'YouTube पर खोलें',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: YoutubePlayer(
        controller: controller!,
        aspectRatio: 16 / 9,
        showVideoProgressIndicator:
            !widget.isLive,
        progressIndicatorColor:
            primaryBlue,
        progressColors:
            const ProgressBarColors(
          playedColor:
              primaryBlue,
          handleColor:
              primaryBlue,
          bufferedColor:
              Colors.grey,
          backgroundColor:
              Colors.white30,
        ),

        // ======================================================
        // TOP ACTIONS
        // ======================================================

        topActions: [
          if (widget.isLive)
            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.red,
                borderRadius:
                    BorderRadius
                        .circular(
                  5,
                ),
              ),
              child: const Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color:
                        Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight
                              .bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap:
                showQualityInfo,
            child:
                const Padding(
              padding:
                  EdgeInsets.all(
                8,
              ),
              child: Icon(
                Icons.high_quality,
                color:
                    Colors.white,
              ),
            ),
          ),
        ],

        // ======================================================
        // BOTTOM ACTIONS
        // ======================================================

        bottomActions: [
          const PlayPauseButton(),

          if (!widget.isLive) ...[
            const SizedBox(width: 5),

            const CurrentPosition(),

            const SizedBox(width: 5),

            const Expanded(
              child:
                  ProgressBar(
                isExpanded: true,
              ),
            ),

            const SizedBox(width: 4),

            const RemainingDuration(),

            const SizedBox(width: 5),

            GestureDetector(
              onTap:
                  showSpeedMenu,
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  speedLabel(
                    playbackSpeed,
                  ),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 5),

            GestureDetector(
              onTap:
                  toggleFullscreen,
              child: Icon(
                isFullscreen
                    ? Icons
                        .fullscreen_exit
                    : Icons.fullscreen,
                color:
                    Colors.white,
                size: 21,
              ),
            ),
          ] else ...[
            const SizedBox(
              width: 10,
            ),

            const Expanded(
              child: Text(
                'LIVE',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            GestureDetector(
              onTap:
                  showSpeedMenu,
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  speedLabel(
                    playbackSpeed,
                  ),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 5),

            GestureDetector(
              onTap:
                  toggleFullscreen,
              child: Icon(
                isFullscreen
                    ? Icons
                        .fullscreen_exit
                    : Icons.fullscreen,
                color:
                    Colors.white,
                size: 21,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),
      elevation: 2,
      clipBehavior:
          Clip.antiAlias,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          buildPlayer(),

          if (widget.isLive)
            Container(
              width: double.infinity,
              color: Colors.red
                  .withValues(
                alpha: 0.08,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 9,
                    color: Colors.red,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'LIVE CLASS',
                    style:
                        TextStyle(
                      color:
                          Colors.red,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              15,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  widget.title,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                if (widget
                    .description
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 9,
                  ),
                  Text(
                    widget.description,
                    style:
                        const TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 12,
                ),

                widget.isLive
                    ? const Chip(
                        avatar: Icon(
                          Icons.live_tv,
                          size: 17,
                        ),
                        label:
                            Text(
                          'Live',
                        ),
                      )
                    : const Chip(
                        avatar:
                            Icon(
                          Icons
                              .video_library,
                          size: 17,
                        ),
                        label:
                            Text(
                          'Recorded',
                        ),
                      ),
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

class PracticePage
    extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Practice',
      message:
          'Practice questions जल्द उपलब्ध होंगे।',
      icon: Icons.quiz_outlined,
    );
  }
}

// ============================================================
// NOTES
// ============================================================

class NotesPage
    extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Notes',
      message:
          'Study notes जल्द उपलब्ध होंगे।',
      icon: Icons.folder_outlined,
    );
  }
}

// ============================================================
// SIMPLE PAGE
// ============================================================

class SimplePage
    extends StatelessWidget {
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
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            25,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 75,
                color: primaryBlue,
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 18,
                  color:
                      Colors.grey,
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

class ProfileScreen
    extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final nameController =
      TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();

    nameController.text =
        FirebaseAuth.instance
                .currentUser
                ?.displayName ??
            '';
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> changeName() async {
    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'Name खाली नहीं हो सकता',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final user =
          FirebaseAuth.instance
              .currentUser;

      if (user == null) {
        showMessage(
          'User login नहीं है',
        );
        return;
      }

      await user.updateDisplayName(
        name,
      );

      await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name': name,
          'email': user.email,
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      await user.reload();

      if (mounted) {
        showMessage(
          'Name successfully updated',
        );
      }
    } catch (_) {
      showMessage(
        'Name update नहीं हो पाया',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance
        .signOut();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance
            .currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          25,
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 52,
              backgroundColor:
                  primaryBlue,
              child: Icon(
                Icons.person,
                size: 55,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Student Profile',
              style: TextStyle(
                fontSize: 27,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            AppTextField(
              controller:
                  nameController,
              hint: 'Student Name',
              icon:
                  Icons.person_outline,
              textCapitalization:
                  TextCapitalization
                      .words,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              user?.email ?? '',
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child:
                  ElevatedButton(
                onPressed:
                    saving
                        ? null
                        : changeName,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      primaryBlue,
                  foregroundColor:
                      Colors.white,
                ),
                child: saving
                    ? const CircularProgressIndicator(
                        color:
                            Colors.white,
                      )
                    : const Text(
                        'CHANGE NAME',
                      ),
              ),
            ),
            const SizedBox(
              height: 35,
            ),
            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Admin Social Media',
                style:
                    TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            SocialButton(
              icon:
                  Icons.play_circle_fill,
              title: 'YouTube',
              url:
                  'https://youtube.com/@rceditor999',
            ),
            SocialButton(
              icon:
                  Icons.camera_alt,
              title: 'Instagram',
              url:
                  'https://www.instagram.com/rceditor999/',
            ),
            SocialButton(
              icon: Icons.send,
              title: 'Telegram',
              url:
                  'https://t.me/RCEDITOR999',
            ),
            const SizedBox(
              height: 25,
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child:
                  OutlinedButton.icon(
                onPressed: logout,
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'LOGOUT',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
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

class SocialButton
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  const SocialButton({
    super.key,
    required this.icon,
    required this.title,
    required this.url,
  });

  Future<void> openLink(
    BuildContext context,
  ) async {
    final uri =
        Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      showMessage(
        context,
        '$title link गलत है',
      );
      return;
    }

    try {
      final opened =
          await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication,
      );

      if (!opened &&
          context.mounted) {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          onTap: () =>
              openLink(context),
          child: Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: primaryBlue,
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                ),
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

class GroupTitle
    extends StatelessWidget {
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
      padding:
          const EdgeInsets.only(
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
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
                color:
                    primaryBlue,
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

class AppTextField
    extends StatelessWidget {
  final TextEditingController
      controller;

  final String hint;
  final IconData icon;

  final bool obscureText;
  final Widget? suffix;

  final TextInputType?
      keyboardType;

  final TextCapitalization
      textCapitalization;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization =
        TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization:
          textCapitalization,
      decoration:
          InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(icon),
        suffixIcon:
            suffix,
        filled: true,
        fillColor:
            Colors.white,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide(
            color:
                Colors.grey.shade300,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                primaryBlue,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets
                .symmetric(
          vertical: 18,
          horizontal: 18,
        ),
      ),
    );
  }
}
