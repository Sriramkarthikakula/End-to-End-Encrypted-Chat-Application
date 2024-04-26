import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/components/Funcbuttons.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';

class LoginScreen extends StatefulWidget {
  static String id = 'login';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  String email = '';
  String password = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ProgressHUD(
        child: Builder(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Hero(
                    tag: 'logo',
                    child: Container(
                      height: 200.0,
                      child: Image.asset('images/logo.png'),
                    ),
                  ),
                  SizedBox(
                    height: 48.0,
                  ),
                  TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      email=value;
                    },

                    decoration: kInputting.copyWith(hintText: 'Enter your email'),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  TextField(
                      textAlign: TextAlign.center,
                      obscureText: true,
                    onChanged: (value) {
                      password = value;
                    },

                    decoration: kInputting.copyWith(hintText: 'Enter your password')
                  ),
                  SizedBox(
                    height: 24.0,
                  ),
                  FuncButtons(Colors.lightBlueAccent,() async{
                    try{
                      final progress = ProgressHUD.of(context);
                      progress?.showWithText('Loading...');
                      final user =await _auth.signInWithEmailAndPassword(email: email, password: password);
                      if(user != null){

                          Navigator.pushNamed(context, DashboardScreen.id);
                      }
                      Future.delayed(Duration(seconds: 2), () {
                        progress?.dismiss();
                      });

                    }
                    catch(e){
                      print(e);
                    }

                  }, 'Log In'),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
