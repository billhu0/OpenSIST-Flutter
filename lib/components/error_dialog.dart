import 'package:flutter/material.dart';
import 'package:opensist_alpha/components/opensist_login.dart';

const COOKIE_INVALID_ERROR_STRING = "Exception: HTTP 401: Unauthorized";

void showErrorDialog(BuildContext context, String errorMessage, Function? retryFunction) {
  bool isLoginError = errorMessage == COOKIE_INVALID_ERROR_STRING;
  if (isLoginError) {
    errorMessage += "\nYou didn't login or your credentials expired. Login to continue";

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
    return;
  }
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(isLoginError ? 'Error: Please Login' : 'Error'),
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
          if (isLoginError)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/opensist_login');
              },
              child: const Text('Login'),
            )
          else if (retryFunction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                retryFunction();
              },
              child: const Text('Retry'),
            ),
        ],
      );
    },
  );
}
