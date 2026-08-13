import 'package:flutter/material.dart';

void main() {
  runApp(const SRStudiesApp());
}

class SRStudiesApp extends StatelessWidget {
  const SRStudiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SR STUDIES',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const LoginPage(),
    );
  }
}

// ================= LOGIN =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;

  void login() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 15),
                const Text(
                  'SR STUDIES',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Learn • Practice • Succeed',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: login,
                    child: const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Real signup will be connected with Firebase next.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Create New Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final pages = const [
    HomeTab(),
    CoursesTab(),
    TestsTab(),
    NotesTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
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
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
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

// ================= HOME TAB =================

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to SR STUDIES 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your learning journey starts here.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3949AB),
                    Color(0xFF5C6BC0),
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 45,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Study Smarter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Courses • Classes • Notes • Tests',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: const [
                Expanded(
                  child: QuickCard(
                    icon: Icons.menu_book,
                    title: 'Courses',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: QuickCard(
                    icon: Icons.quiz,
                    title: 'Tests',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(
                  child: QuickCard(
                    icon: Icons.picture_as_pdf,
                    title: 'Notes',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: QuickCard(
                    icon: Icons.emoji_events,
                    title: 'Results',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const QuickCard({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            Icon(
              icon,
              size: 34,
              color: Colors.indigo,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= COURSES =================

class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 Courses',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Choose your foundation course',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            CourseCard(
              icon: Icons.biotech,
              title: 'Biology Foundation',
              subtitle: 'Build strong Biology fundamentals',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CourseDetailsPage(
                      title: 'Biology Foundation',
                      icon: Icons.biotech,
                      description:
                          'Learn the fundamental concepts of Biology.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            CourseCard(
              icon: Icons.trending_up,
              title: 'Economics Foundation',
              subtitle: 'Understand the basics of Economics',
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CourseDetailsPage(
                      title: 'Economics Foundation',
                      icon: Icons.trending_up,
                      description:
                          'Learn the basic concepts of Economics.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            CourseCard(
              icon: Icons.account_balance,
              title: 'History Foundation',
              subtitle: 'Build a strong foundation in History',
              iconColor: Colors.brown,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CourseDetailsPage(
                      title: 'History Foundation',
                      icon: Icons.account_balance,
                      description:
                          'Learn important historical concepts and events.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= COURSE DETAILS =================

class CourseDetailsPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const CourseDetailsPage({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              child: Icon(
                icon,
                size: 48,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            const CourseOption(
              icon: Icons.play_circle_outline,
              title: 'Video Classes',
              subtitle: 'Classes will be added here',
            ),

            const CourseOption(
              icon: Icons.picture_as_pdf,
              title: 'Notes / PDF',
              subtitle: 'Study material will be added here',
            ),

            const CourseOption(
              icon: Icons.quiz_outlined,
              title: 'Course Test',
              subtitle: 'Tests will be added here',
            ),
          ],
        ),
      ),
    );
  }
}

class CourseOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CourseOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

// ================= OTHER TABS =================

class TestsTab extends StatelessWidget {
  const TestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '📝 Tests\n\nTests will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '📄 Notes\n\nStudy notes will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 45,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
