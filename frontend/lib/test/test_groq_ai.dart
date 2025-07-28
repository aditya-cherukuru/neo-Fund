import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart'; // Import to access environmentVariables
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env file
  // For web, the .env file needs to be in assets
  if (kIsWeb) {
    await dotenv.load(fileName: ".env");
  } else {
    await dotenv.load(fileName: ".env");
  }
  
  // Populate environment variables map (same as main.dart)
  environmentVariables.addAll({
    'GROQ_API_KEY': dotenv.env['GROQ_API_KEY'] ?? '',
    'GROQ_MODEL': dotenv.env['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct',
    'BACKEND_URL': dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api',
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groq AI Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GroqTestScreen(),
    );
  }
}

class GroqTestScreen extends StatefulWidget {
  const GroqTestScreen({super.key});

  @override
  State<GroqTestScreen> createState() => _GroqTestScreenState();
}

class _GroqTestScreenState extends State<GroqTestScreen> {
  String _response = '';
  bool _isLoading = false;

  Future<void> _testGroqAPI() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final apiKey = environmentVariables['GROQ_API_KEY'] ?? '';
      final model = environmentVariables['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct';
      
      if (apiKey.isEmpty) {
        setState(() {
          _response = 'Error: GROQ_API_KEY not found in environment variables';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': 'Hello! Can you give me a quick financial tip?',
            }
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content is String) {
          setState(() {
            _response = content;
            _isLoading = false;
          });
        } else {
          setState(() {
            _response = 'Error: Invalid response format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groq AI Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testGroqAPI,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test Groq API'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response.isEmpty ? 'Click the button to test the API' : _response,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 