import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_shell.dart';
import 'state/nexus_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final controller = NexusController(prefs);
  try {
    await controller.loadCatalog();
  } catch (_) {
    // App still launches; app_shell shows backend connection error UI.
  }
  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const NexusFlutterApp(),
    ),
  );
}
