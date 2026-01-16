import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/home_screen.dart';
import 'core/directory_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DirectoryProvider()),
      ],
      child: const ReNameryApp(),
    ),
  );
}

class ReNameryApp extends StatelessWidget {
  const ReNameryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReNamery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Windowsでのネイティブな外観
      ),
      home: const HomeScreen(),
    );
  }
}
