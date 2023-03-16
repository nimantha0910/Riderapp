import "dart:developer";
import "package:firebase_database/firebase_database.dart";
import "package:flutter/material.dart";
import "package:riderapp/AllScreens/mainscreen.dart";
import "package:riderapp/AllScreens/registrationScreen.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:riderapp/AllWidgets/progressDialog.dart";
import "../main.dart";

class loginScreen extends StatelessWidget {
  //const loginScreen({super.key});
  static const String idScreen = "login";

  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 45.0,
          ),
          Image(
            image: AssetImage("assets/images/logo.png"),
            width: 390.0,
            height: 200.0,
            alignment: Alignment.center,
          ),
          SizedBox(
            height: 1.0,
          ),
          Text(
            "Login as a Rider",
            style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.all(40.0),
            child: Column(
              children: [
                SizedBox(
                  height: 4.0,
                ),
                TextField(
                  controller: emailTextEditingController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      fontSize: 14.0,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 10.0,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.0),
                ),
                SizedBox(
                  height: 9.0,
                ),
                TextField(
                  controller: passwordTextEditingController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(
                      fontSize: 14.0,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 10.0,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.0),
                ),
                SizedBox(
                  height: 80.0,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.yellow,
                    minimumSize: const Size(88, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 120, vertical: 15),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                  ),
                  onPressed: () {
                    if (!emailTextEditingController.text.contains("@")) {
                      displayToastMessage(
                          "Email address is not Valid ", context);
                    } else if (passwordTextEditingController.text.isEmpty) {
                      displayToastMessage("Password is mandatory", context);
                    } else {
                      loginAndAuthonticateUser(context);
                    }
                  },
                  child: const Text('Login',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                          fontFamily: "Brand Bold")),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, registrationScreen.idScreen, (route) => false);
            },
            child: Text(
              "Do not have an Account? Register Here.",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void loginAndAuthonticateUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return progressDialog(message: "Authenticating, Please wait...");
        });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text,
      );

      User? firebaseUser = userCredential.user;
      log(firebaseUser!.uid);

      if (firebaseUser != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) => MainScreen()),
          ),
        );
      } else {
        Navigator.pop(context);
        _firebaseAuth.signOut();
        displayToastMessage(
            "No records exits for this user. Please create a new account.",
            context);
      }
    } catch (e) {
      Navigator.pop(context);
      displayToastMessage("Invalid Credential.", context);
      // Handle any errors that may occur during registration.
      print('Error occurred while logging user: $e');
      // Show an error message to the user or handle the error in another way.
    }
  }
}
