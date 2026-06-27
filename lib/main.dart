import 'package:flutter/material.dart';

/// Project entry placeholder for Member 2 repo structure.
/// Member 1 will replace this with NexusController + app_shell integration.
void main() {
  runApp(const CsfMember2Shell());
}

class CsfMember2Shell extends StatelessWidget {
  const CsfMember2Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSF Member 2',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: Center(
          child: Text(
            'Member 2 shopping UI files are in lib/screens and lib/widgets.\n'
            'Member 1 will connect main.dart + Provider.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
