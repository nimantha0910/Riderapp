import "dart:convert";
import "package:riderapp/AllWidgets/progressDialog.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/ui/firebase_sorted_list.dart";
import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:riderapp/AllScreens/loginScreen.dart";
import 'package:http/http.dart' as http;
import "package:riderapp/main.dart";
import "mainscreen.dart";

class registrationScreen extends StatelessWidget {
  //const registrationScreen({super.key});
  static const String idScreen = "register";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
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
            image: AssetImage("assets/images/logo2.png"),
            width: 390.0,
            height: 200.0,
            alignment: Alignment.center,
          ),
          SizedBox(
            height: 1.0,
          ),
          Text(
            "Register as a Rider",
            style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bold"),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.all(40.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 4.0,
                  ),
                  TextField(
                    controller: nameTextEditingController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "Name",
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
                    height: 4.0,
                  ),
                  TextField(
                    controller: phoneTextEditingController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone",
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
                          horizontal: 120, vertical: 5),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                    ),
                    onPressed: () {
                      if (nameTextEditingController.text.length < 3) {
                        displayToastMessage(
                            "Name must be at least 3 characters.", context);
                      } else if (!emailTextEditingController.text
                          .contains("@")) {
                        displayToastMessage(
                            "Email address is not Valid ", context);
                      } else if (phoneTextEditingController.text.isEmpty) {
                        displayToastMessage(
                            "Phone number is mandatory", context);
                      } else if (passwordTextEditingController.text.length <
                          6) {
                        displayToastMessage(
                            "Password must be at least 6 characters", context);
                      } else {
                        registerNewUser(context);
                      }
                    },
                    child: const Text('Create Account',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 17.0,
                            fontFamily: "Brand Bold")),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, loginScreen.idScreen, (route) => false);
            },
            child: Text(
              "Already have an Account? Login Here.",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return progressDialog(message: "Registring, Please wait...");
        });

    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text,
      );
      const url =
          'https://rider-app-29f66-default-rtdb.firebaseio.com/user.json';
      await http.post(Uri.parse(url),
          body: json.encode({
            "name": nameTextEditingController.text.trim(),
            "email": emailTextEditingController.text.trim(),
            "phone": phoneTextEditingController.text.trim(),
          }));
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: ((context) => loginScreen()),
        ),
      );

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        Map userDataMap = {
          "name": nameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
        };

        userRef.child(firebaseUser.uid).set(userDataMap);
        displayToastMessage(
            "Congratulations, your account has been created", context);
      } else {
        Navigator.pop(context);
        displayToastMessage("New user account has been created", context);
      }

      // Do something with the user, such as store their data in Firestore or redirect them to a new screen.
    } catch (e) {
      Navigator.pop(context);
      // Handle any errors that may occur during registration.
      print('Error occurred while registering user: $e');
      // Show an error message to the user or handle the error in another way.
    }
  }
}

displayToastMessage(String message, BuildContext context) {
  Fluttertoast.showToast(msg: message);
}
