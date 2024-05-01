
import 'package:flash_chat/screens/add_friends.dart';
import 'package:flash_chat/screens/dashboard.dart';
import 'package:flash_chat/screens/friends_decision.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Ensure that Firebase is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: 'Your Api key',
          appId: 'Your AppId',
          messagingSenderId: 'Your messageId',
          projectId: 'Your project Id',
      ),
  );
      runApp(FlashChat());
}
class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: WelcomeScreen.id,
      routes: {
        WelcomeScreen.id:(context)=>WelcomeScreen(),
        LoginScreen.id:(context)=>LoginScreen(),
        RegistrationScreen.id:(context)=>RegistrationScreen(),
        AddFriendScreen.id:(context)=>AddFriendScreen(),
        FriendDecisionScreen.id:(context)=>FriendDecisionScreen(),
        DashboardScreen.id:(context)=>DashboardScreen(),
      },
    );
  }
}
