
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SR STUDIES'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.school, size: 80),
            SizedBox(height: 20),
            Text(
              'SR STUDIES',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text('By Kumar ranjan official'),
          ],
        ),
      ),
    );
  }
}
