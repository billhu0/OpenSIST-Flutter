import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context, String errorMessage, Function? retryFunction) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // retryFunction == null only happens when we are in login page.
              // In this scenario, don't exit. Instead prompt user to correct email and password.
              // In other cases, go back.
              if (retryFunction != null) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancel'),
          ),
          if (retryFunction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                retryFunction();
              },
              child: const Text('Retry'),
            ),
          // TextButton(
          //   onPressed: () {
          //     Navigator.of(context).pop();
          //     Navigator.of(context).pushNamed('/opensist_login');
          //   },
          //   child: const Text('Login'),
          // ),
        ],
      );
    },
  );
}
