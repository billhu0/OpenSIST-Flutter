import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // so we can access seedColorNotifier & themeModeNotifier
import '../models/opensist_api.dart' as api;

Future<void> clearCookie() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cookie', "");
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showTimelineDates = true;

  @override
  void initState() {
    super.initState();
    _loadShowTimelineDates();
  }

  Future<void> _loadShowTimelineDates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showTimelineDates = prefs.getBool('showTimelineDates') ?? true;
    });
  }

  Future<void> _saveShowTimelineDates(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTimelineDates', newValue);
  }

  // 1. Define your options in one place:
  static const colorOptions = <String, Color>{
    'Red Accent': Colors.redAccent,
    'Pink Accent': Colors.pinkAccent,
    'Purple Accent': Colors.purpleAccent,
    'Deep Purple Accent': Colors.deepPurpleAccent,
    'Indigo Accent': Colors.indigoAccent,
    'Blue Accent': Colors.blueAccent,
    'Light Blue Accent': Colors.lightBlueAccent,
    'Cyan Accent': Colors.cyanAccent,
    'Teal Accent': Colors.tealAccent,
    'Green Accent': Colors.greenAccent,
    'Light Green Accent': Colors.lightGreenAccent,
    'Lime Accent': Colors.limeAccent,
    'Yellow Accent': Colors.yellowAccent,
    'Amber Accent': Colors.amberAccent,
    'Orange Accent': Colors.orangeAccent,
    'Deep Orange Accent': Colors.deepOrangeAccent,
  };

  Future<void> _pickSeedColor(BuildContext context) async {
    // 2. Build & show the dialog dynamically:
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select theme color'),
        children: colorOptions.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, entry.value),
            child: Row(
              children: [
                // color swatch
                Container(width: 24, height: 24, color: entry.value),
                const SizedBox(width: 12),
                // label
                Text(entry.key),
              ],
            ),
          );
        }).toList(),
      ),
    );

    // 3. Persist & notify if they picked something:
    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('seedColor', selected.value);
      seedColorNotifier.value = selected;
    }
  }


  Future<void> _pickThemeMode(BuildContext context) async {
    final mode = await showDialog<ThemeMode>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select theme mode'),
        children: [
          SimpleDialogOption(
            child: const Text('Light'),
            onPressed: () => Navigator.pop(context, ThemeMode.light),
          ),
          SimpleDialogOption(
            child: const Text('Dark'),
            onPressed: () => Navigator.pop(context, ThemeMode.dark),
          ),
          SimpleDialogOption(
            child: const Text('Follow System'),
            onPressed: () => Navigator.pop(context, ThemeMode.system),
          ),
        ],
      ),
    );
    if (mode != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', mode.index);
      themeModeNotifier.value = mode;
    }
  }
  
  void showClearCacheDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear all loaded data and force a fresh fetch on next load.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              api.clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('This will clear your session. You will need to login again to access OpenSIST.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await clearCookie();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Login'),
            onTap: () {
              Navigator.of(context).pushNamed('/opensist_login');
            },
          ),
          const Divider(),

          // THEME COLOR ITEM
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme Color'),
            onTap: () => _pickSeedColor(context),
          ),
          const Divider(),

          // DARK MODE ITEM
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Dark Mode'),
            onTap: () => _pickThemeMode(context),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.cached),
            title: const Text('Clear API Cache'),
            onTap: () => showClearCacheDialog(context),
          ),
          const Divider(),

          // Show dates or not (申请时间，面试时间，结果通知时间)
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Show Timeline Dates'),
            trailing: Switch(
              value: _showTimelineDates,
              onChanged: (newValue) {
                setState(() {
                  _showTimelineDates = newValue;
                });
                _saveShowTimelineDates(newValue);
              },
            ),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => showLogoutDialog(context),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.more_horiz_sharp),
            title: const Text(
              'About',
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'OpenSIST',
              applicationVersion: 'v1.0.0',
              children: [ const Text('OpenSIST Flutter App Prototype, created by Bill Hu <opensist@billhu.us>') ],
            ),
          )
        ],
      ),
    );
  }
}