import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:riderapp/AllScreens/loginScreen.dart';
import 'package:riderapp/AllScreens/registrationScreen.dart';
import 'AllScreens/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: ' Parking App ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: " Signatra ",
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: MainScreen.idScreen,
        routes: {
          registrationScreen.idScreen: (context) => registrationScreen(),
          loginScreen.idScreen: (context) => loginScreen(),
          MainScreen.idScreen: (context) => MainScreen(),
        });
  }
}
