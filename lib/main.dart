import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_size/window_size.dart';
import 'dart:io';
import 'features/card_simulator/application/card_simulator_cubit.dart';
import 'features/card_simulator/presentation/pages/simulator_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set window size for Windows to simulate phone screen
  if (Platform.isWindows) {
    setWindowTitle(
      'Card Simulator',
    ); // iPhone X size
    setWindowMinSize(const Size(420, 600));
    setWindowMaxSize(const Size(420, 600));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) =>
            CardSimulatorCubit()..initialize(),
        child: const SimulatorPage(),
      ),
    );
  }
}
