import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context, String errorMessage, Function retryFunction) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              retryFunction();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/opensist_login');
            },
            child: const Text('Login'),
          ),
        ],
      );
    },
  );
}
