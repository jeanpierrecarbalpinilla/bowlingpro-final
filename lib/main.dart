import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BowlingProApp());
}

class BowlingProApp extends StatelessWidget {
  const BowlingProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BowlingPro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGate(), // AuthGate decide Login o Home según la sesión
    );
  }
}