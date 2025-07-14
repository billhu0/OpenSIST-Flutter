import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum MenuOption { settings, about }

class _MyHomePageState extends State<MyHomePage> {

  void _onMenuSelected(MenuOption option) {
    switch (option) {
      case MenuOption.settings:
        Navigator.of(context).pushNamed('/settings');
        break;
      case MenuOption.about:
        showAboutDialog(
          context: context,
          applicationName: widget.title,
          applicationVersion: 'v1.0.0',
          children: [ const Text('OpenSIST Flutter App Prototype, created by Bill Hu <opensist@billhu.us>') ],
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton<MenuOption>(
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MenuOption.settings,
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: MenuOption.about,
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Text(
                  'My App Menu',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Useless Home'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('OpenSIST login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/opensist_login');
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('OpenSIST programs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/opensist_programs');
                },
              ),
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('OpenSIST datapoints'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/opensist_datapoints');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('OpenSIST applicants'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/opensist_applicants');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),

            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text('Welcome to OpenSIST!'),
          ],
        ),
      ),
    );
  }
}
