// lib/main.dart
import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(FaceAuthApp());
}

class FaceAuthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        title: Text(
          "Face Auth",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegistrationScreen()),
                  );
                } catch (e) {
                  print("Navigation Error: $e");
                }
              },
              child: Text(
                "Register",
                style: TextStyle(
                  fontSize: 30.0,
                  color: Colors.green.shade900
                ),
              ),
            ),
            SizedBox(
                height:
                    50.0), // You can replace this with a constant or MediaQuery for dynamic spacing

            ElevatedButton(
              onPressed: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } catch (e) {
                  print("Navigation Error: $e");
                }
              },
              child: Text(
                "Login",
                style: TextStyle(
                    fontSize: 30.0,
                    color: Colors.green.shade900
                ), // Removed explicit color to keep consistent with the theme
              ),
            ),
          ],
        ),
      ),
    );
  }
}
