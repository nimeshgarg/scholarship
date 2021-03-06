import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'firebase_options.dart';

var email = TextEditingController();
var pass = TextEditingController();
var _hidden = true;

class AdminLogin extends StatefulWidget {
  const AdminLogin({Key? key}) : super(key: key);

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.loaderOverlay.show();
    startService();
    email.text = '';
    pass.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Center(child: Text('Thapar Scholarship Portal - Admin Mode')),
        actions:<Widget> [
          TextButton(
            onPressed: (){
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Student',style: TextStyle(color: Colors.white),),),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 224, 202, 2),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * .4,
          height: MediaQuery.of(context).size.height * .45,
          child: Card(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(padding: EdgeInsets.all(20)),
                  const Text(
                    'Admin Login',
                    style: TextStyle(
                      fontSize: 32.0,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(20)),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .2,
                    child: TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: email,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        hintText: 'Enter Email-Id',
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .2,
                    child: TextField(
                      keyboardType: TextInputType.visiblePassword,
                      controller: pass,
                      obscureText: _hidden,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Password',
                        hintText: 'Enter Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              if (_hidden == true) {
                                _hidden = false;
                              } else {
                                _hidden = true;
                              }
                            });
                          },
                          icon: Icon(_hidden == true
                              ? Icons.visibility
                              : Icons.visibility_off),
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hidden = true;
                      });
                      context.loaderOverlay.show();
                      authValidate();
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 20.0),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> startService() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/dashboard', (route) => false);
    } else {
      context.loaderOverlay.hide();
    }
  }

  Future<void> authValidate() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      pass.text = '';
      if (e.code == 'user-not-found') {
        //print('No user found for that email.');
        showAlert('No User Found');
      } else if (e.code == 'wrong-password') {
        //print('Wrong password provided for that user.');
        showAlert('Invalid EmailID/Password\nTry Again');
      } else if (e.code == 'invalid-email') {
        //print('Invalid Email Entered');
        showAlert('Enter valid EmailID');
      } else if (e.code == 'network-request-failed') {
        //print('Internet not connected');
        showAlert('Please Check Internet Connection');
      } else {
        if (kDebugMode) {
          print(e.code);
        }
        showAlert('System Error\nTry Again Later');
      }
      return;
    }
    pass.text = '';
    checkAdmin();
  }
  Future<void> checkAdmin()async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference userDetails = firestore.collection('user');
    userDetails
        .doc(FirebaseAuth.instance.currentUser?.email.toString())
        .get()
        .then((value) {
      if (value.data() != null) {
        if(value['isAdmin']==true) {
          Navigator.pushNamedAndRemoveUntil(context, '/AdminDash', (route) => false);
        }else{
          FirebaseAuth.instance.signOut();
          showAlert('No Admin Privileges');
        }
      } else {
        showAlert('Account Info Incorrect\n Contact Admin');
      }
    });
  }

  void showAlert(var message) {
    var alert = AlertDialog(
      title: const Text('Error!'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return alert;
        });
    context.loaderOverlay.hide();
  }
}
