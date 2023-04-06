import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/AllScreens/loginScreen.dart';
import 'package:riderapp/AllScreens/registrationScreen.dart';
import 'package:riderapp/DataHandler/appData.dart';
import 'AllScreens/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");

class MyApp extends StatelessWidget {
  // This widget is the root of your a1pplication.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
          title: ' Parking App ',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: " Signatra ",
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          initialRoute: FirebaseAuth.instance.currentUser == null
              ? loginScreen.idScreen
              : MainScreen.idScreen,
          routes: {
            registrationScreen.idScreen: (context) => registrationScreen(),
            loginScreen.idScreen: (context) => loginScreen(),
            MainScreen.idScreen: (context) => MainScreen(),
          }),
    );
  }
}
