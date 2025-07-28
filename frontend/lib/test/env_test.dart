import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  // For web, the .env file needs to be in assets
  if (kIsWeb) {
    await dotenv.load(fileName: ".env");
  } else {
    await dotenv.load(fileName: ".env");
  }
  
  // Populate environment variables map
  environmentVariables.addAll({
    'GROQ_API_KEY': dotenv.env['GROQ_API_KEY'] ?? '',
    'GROQ_MODEL': dotenv.env['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct',
    'BACKEND_URL': dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000',
  });
  
  runApp(const EnvTestApp());
}

class EnvTestApp extends StatelessWidget {
  const EnvTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Environment Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Environment Variables Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Environment Variables Status:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('GROQ_API_KEY loaded: ${environmentVariables['GROQ_API_KEY']?.isNotEmpty == true ? 'YES' : 'NO'}'),
              Text('GROQ_API_KEY length: ${environmentVariables['GROQ_API_KEY']?.length ?? 0}'),
              Text('GROQ_MODEL: ${environmentVariables['GROQ_MODEL']}'),
              Text('BACKEND_URL: ${environmentVariables['BACKEND_URL']}'),
              const SizedBox(height: 16),
              Text(
                'API Key Preview (first 10 chars):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(environmentVariables['GROQ_API_KEY']?.substring(0, 10) ?? 'Not loaded'),
            ],
          ),
        ),
      ),
    );
  }
} 