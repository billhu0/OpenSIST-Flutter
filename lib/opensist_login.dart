import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'opensist_api.dart' as api;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

Future<void> storeCookie(String cookie) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cookie', cookie);
}

Future<String> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie') ?? "";
}

Future<void> clearCookie() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cookie', "");
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _respBodyCtrl = TextEditingController();
  final _respHdrCtrl = TextEditingController();
  bool _loading = false;

  String selectedFetch = 'Fetch Programs';

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    setState(() => _loading = true);

    try {
      final http.Response res = await api.login(email, pass);

      // pretty-print response body JSON
      final bodyJson = json.decode(res.body);
      _respBodyCtrl.text = const JsonEncoder.withIndent('  ').convert(bodyJson);

      // format headers map into lines
      final hdrLines = res.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      _respHdrCtrl.text = hdrLines;
      if (res.headers['set-cookie'] != null) {
        String cookie = res.headers['set-cookie']!.split(';')[0];
        storeCookie(cookie);
        debugPrint("Setting cookie: $cookie");
      }
    } catch (err) {
      _respBodyCtrl.text = 'Error: $err';
      _respHdrCtrl.text = '';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchPrograms() async {
    setState(() => _loading = true);

    try {
      final res = await api.fetchPrograms(await getCookie());

      // pretty-print response body JSON
      final bodyJson = json.decode(res.body);
      _respBodyCtrl.text = const JsonEncoder.withIndent('  ').convert(bodyJson);

      // format headers map into lines
      final hdrLines = res.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      _respHdrCtrl.text = hdrLines;
    } catch (err) {
      _respBodyCtrl.text = 'Error: $err';
      _respHdrCtrl.text = '';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchApplicants() async {
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse("https://opensist.tech/api/list/applicants"),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'close',
          'X-Content-Type-Options': 'nosniff',
          'Cookie': await getCookie(),
        },
        body: json.encode({}),
      );

      // pretty-print response body JSON
      final bodyJson = json.decode(res.body);
      _respBodyCtrl.text = const JsonEncoder.withIndent('  ').convert(bodyJson);

      // format headers map into lines
      final hdrLines = res.headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      _respHdrCtrl.text = hdrLines;
    } catch (err) {
      _respBodyCtrl.text = 'Error: $err';
      _respHdrCtrl.text = '';
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _respBodyCtrl.dispose();
    _respHdrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Email
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),

            // Clear Cookie button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : clearCookie,
                child: _loading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Clear Cookie (Logout)'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              // width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: selectedFetch,
                decoration: InputDecoration(
                  labelText: 'Fetch Options',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Fetch Programs',
                  'Fetch Applicants',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() { selectedFetch = val; });
                },
              ),
            ),

            // Single action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                  switch (selectedFetch) {
                    case 'Fetch Programs':
                      _fetchPrograms();
                      break;
                    case 'Fetch Applicants':
                      _fetchApplicants();
                      break;
                  }
                },
                child: _loading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(selectedFetch),
              ),
            ),

            const SizedBox(height: 24),

            // Response Headers
            Expanded(
              flex: 1,
              child: TextField(
                controller: _respHdrCtrl,
                readOnly: true,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Response Headers',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Response Body
            Expanded(
              flex: 2,
              child: TextField(
                controller: _respBodyCtrl,
                readOnly: true,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Response JSON Body',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
