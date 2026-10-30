import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled policy is accessible offline; displaying it makes no network call.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final Future<String> _policy = rootBundle.loadString(
    'assets/legal/privacy_de.txt',
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Datenschutzerklärung')),
    body: SafeArea(
      child: FutureBuilder<String>(
        future: _policy,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: SelectableText(
                'Datenschutzerklärung konnte nicht geladen werden. '
                'Kontakt: info@geringdigital.de',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SelectableText(snapshot.data!),
          );
        },
      ),
    ),
  );
}
