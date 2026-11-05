import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String message = 'Ready to test the backend.';
  bool loading = false;

  Future<void> checkConnection() async {
    setState(() {
      loading = true;
      message = 'Connecting to FastAPI...';
    });

    final connected = await ApiService.testConnection();

    if (!mounted) return;

    setState(() {
      loading = false;
      message = connected
          ? 'Connected to FastAPI successfully!'
          : 'Connection failed. Check the backend and browser console.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Connection Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : checkConnection,
                child: Text(loading ? 'Testing...' : 'Test Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
