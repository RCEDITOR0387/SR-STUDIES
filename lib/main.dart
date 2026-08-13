import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryBlue = Color(0xff5963A5);
const Color backgroundColor = Color(0xffF6F7FC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    runApp(const SRStudiesApp());
  } catch (e) {
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

// ======================================================
// APP
// ======================================================

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
      ),
      home: const AuthGate(),
    );
  }
}

// ======================================================
// FIREBASE ERROR
// ======================================================

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
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 85,
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
                  const SizedBox(height: 20),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'google-services.json और Firebase configuration check करें।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
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

// ======================================================
// AUTH GATE
// ======================================================

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

// ======================================================
// LOGIN
// ======================================================

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
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email और Password दोनों भरें');
      return;
    }

    setState(() {
      loading = true;
    });

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
            'पहले अपने Email को verify करें। Verification link आपके Email पर भेजा गया है।',
          );
        }

        return;
      }
    } on FirebaseAuthException catch (e) {
      showMessage(getAuthError(e.code));
    } catch (e) {
      showMessage('Login में समस्या हुई');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String getAuthError(String code) {
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
        return 'बहुत ज्यादा attempts हुए हैं। थोड़ी देर बाद कोशिश करें।';

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
            32,
            55,
            32,
            35,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.school,
                size: 95,
                color: primaryBlue,
              ),

              const SizedBox(height: 20),

              const Text(
                'SR STUDIES',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Learn • Practice • Succeed',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 55),

              AppTextField(
                controller: emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

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
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 62,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
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

// ======================================================
// SIGNUP
// ======================================================

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
    final password = passwordController.text.trim();

    if (name.isEmpty) {
      showMessage('Student Name भरें');
      return;
    }

    if (email.isEmpty) {
      showMessage('Email भरें');
      return;
    }

    if (password.isEmpty) {
      showMessage('Password भरें');
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
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        await user.sendEmailVerification();
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Account Created'),
            content: const Text(
              'आपका account बन गया है।\n\n'
              'आपके Email पर verification link भेजा गया है। '
              'Email खोलकर verification पूरा करें, फिर Login करें।',
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
      showMessage(getSignupError(e.code));
    } catch (e) {
      showMessage('Account बनाने में समस्या हुई');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String getSignupError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'यह Email पहले से registered है';

      case 'invalid-email':
        return 'Email सही नहीं है';

      case 'weak-password':
        return 'Password बहुत कमजोर है';

      case 'operation-not-allowed':
        return 'Firebase में Email/Password login enable करें';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            32,
            10,
            32,
            35,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.school,
                size: 80,
                color: primaryBlue,
              ),

              const SizedBox(height: 15),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

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
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: loading ? null : signup,
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
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Verification link आपके Email पर भेजा जाएगा।',
                textAlign: TextAlign.center,
                style: TextStyle(
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

// ======================================================
// FORGOT PASSWORD
// ======================================================

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

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Email Sent'),
            content: const Text(
              'Password reset link आपके Email पर भेज दिया गया है।',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      showMessage(
        getResetError(e.code),
      );
    } catch (e) {
      showMessage('Password reset में समस्या हुई');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String getResetError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email सही नहीं है';

      case 'user-not-found':
        return 'यह Email registered नहीं है';

      case 'too-many-requests':
        return 'बहुत ज्यादा requests हुई हैं। बाद में कोशिश करें।';

      case 'network-request-failed':
        return 'Internet connection check करें';

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
        title: const Text('Forgot Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 25),

            const Icon(
              Icons.lock_reset,
              size: 85,
              color: primaryBlue,
            ),

            const SizedBox(height: 25),

            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 35),

            AppTextField(
              controller: emailController,
              hint: 'Registered Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed:
                    loading ? null : resetPassword,
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

// ======================================================
// MAIN NAVIGATION
// ======================================================

class MainNavigation extends StatefulWidget {
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

// ======================================================
// HOME PAGE
// ======================================================

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
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          12,
          18,
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // WELCOME BOX
            // ------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 22,
              ),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(28),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'अपने subjects चुनें और अपनी preparation शुरू करें।',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Subjects',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            const GroupTitle(
              icon: Icons.menu_book_outlined,
              title: 'ARTS & SOCIAL SCIENCE',
            ),

            SubjectCard(
              title: 'History Foundation',
              icon: Icons.history_edu,
            ),

            SubjectCard(
              title: 'Economics Foundation',
              icon: Icons.currency_rupee,
            ),

            SubjectCard(
              title: 'Geography Foundation',
              icon: Icons.public,
            ),

            SubjectCard(
              title: 'Polity Foundation',
              icon: Icons.account_balance,
            ),

            const SizedBox(height: 20),

            const GroupTitle(
              icon: Icons.science_outlined,
              title: 'SCIENCE',
            ),

            SubjectCard(
              title: 'Biology Foundation',
              icon: Icons.biotech_outlined,
            ),

            SubjectCard(
              title: 'Chemistry Foundation',
              icon: Icons.science,
            ),

            SubjectCard(
              title: 'Physics Foundation',
              icon: Icons.bolt_outlined,
            ),

            const SizedBox(height: 20),

            const GroupTitle(
              icon: Icons.map_outlined,
              title: 'MAPS',
            ),

            SubjectCard(
              title: 'World Map',
              icon: Icons.public,
            ),

            SubjectCard(
              title: 'Indian Map',
              icon: Icons.map,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// SUBJECTS PAGE
// ======================================================

class SubjectsPage extends StatelessWidget {
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
        children: [
          const GroupTitle(
            icon: Icons.menu_book_outlined,
            title: 'ARTS & SOCIAL SCIENCE',
          ),

          SubjectCard(
            title: 'History Foundation',
            icon: Icons.history_edu,
          ),

          SubjectCard(
            title: 'Economics Foundation',
            icon: Icons.currency_rupee,
          ),

          SubjectCard(
            title: 'Geography Foundation',
            icon: Icons.public,
          ),

          SubjectCard(
            title: 'Polity Foundation',
            icon: Icons.account_balance,
          ),

          const SizedBox(height: 20),

          const GroupTitle(
            icon: Icons.science_outlined,
            title: 'SCIENCE',
          ),

          SubjectCard(
            title: 'Biology Foundation',
            icon: Icons.biotech_outlined,
          ),

          SubjectCard(
            title: 'Chemistry Foundation',
            icon: Icons.science,
          ),

          SubjectCard(
            title: 'Physics Foundation',
            icon: Icons.bolt_outlined,
          ),

          const SizedBox(height: 20),

          const GroupTitle(
            icon: Icons.map_outlined,
            title: 'MAPS',
          ),

          SubjectCard(
            title: 'World Map',
            icon: Icons.public,
          ),

          SubjectCard(
            title: 'Indian Map',
            icon: Icons.map,
          ),
        ],
      ),
    );
  }
}

// ======================================================
// PRACTICE PAGE
// ======================================================

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Practice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 80,
                color: primaryBlue,
              ),
              SizedBox(height: 20),
              Text(
                'Practice Section',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Practice questions जल्द उपलब्ध होंगे।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// NOTES PAGE
// ======================================================

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 80,
                color: primaryBlue,
              ),
              SizedBox(height: 20),
              Text(
                'Notes Section',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Study notes जल्द उपलब्ध होंगे।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// GROUP TITLE
// ======================================================

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

// ======================================================
// SUBJECT CARD
// ======================================================

class SubjectCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const SubjectCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 65,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$title अभी जल्द उपलब्ध होगा',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
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
                color: primaryBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 24,
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

// ======================================================
// PROFILE
// ======================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final nameController = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    nameController.text = user?.displayName ?? '';
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

    setState(() {
      saving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMessage('User login नहीं है');
        return;
      }

      await user.updateDisplayName(name);
      await user.reload();

      if (mounted) {
        showMessage('Name successfully updated');
        setState(() {});
      }
    } catch (e) {
      showMessage('Name update नहीं हो पाया');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              textCapitalization:
                  TextCapitalization.words,
            ),

            const SizedBox(height: 12),

            Text(
              user?.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    saving ? null : changeName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'CHANGE NAME',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 35),

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
              url:
                  'https://youtube.com/@rceditor999?si=4009XQKBUTsndL2u',
            ),

            SocialButton(
              icon: Icons.camera_alt,
              title: 'Instagram',
              url:
                  'https://www.instagram.com/rceditor999?igsh=NXJkdTg5dHBheG96',
            ),

            SocialButton(
              icon: Icons.send,
              title: 'Telegram',
              url:
                  'https://t.me/RCEDITOR999',
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

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// SOCIAL BUTTON
// ======================================================

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

  Future<void> openLink(
    BuildContext context,
  ) async {
    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title खोलने में समस्या हुई',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title खोलने में समस्या हुई',
            ),
          ),
        );
      }
    }
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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

                const Icon(
                  Icons.open_in_new,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// COMMON TEXT FIELD
// ======================================================

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
    this.textCapitalization =
        TextCapitalization.none,
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
