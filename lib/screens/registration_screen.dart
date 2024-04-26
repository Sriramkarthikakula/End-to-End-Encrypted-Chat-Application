import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flash_chat/screens/add_friends.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegistrationScreen extends StatefulWidget {
  static String id = 'register';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String username = '';
  String email = '';
  String password = '';
  String searching = '';
  String UniqueName = "";
  String imageurl = "";
  final secureStorage = FlutterSecureStorage();
  var pub_key;
  var private_key;
  void PickImage() async {
    ImagePicker imagepicker = ImagePicker();
    XFile? file = await imagepicker.pickImage(source: ImageSource.gallery);
    UniqueName = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instanceFor(app: Firebase.app(), bucket: 'gs://flash-chat-38707.appspot.com');
    Reference referenceDir = storage.ref().child('images');
    Reference referenceImage = referenceDir.child(UniqueName);
    File imageFile = File(file!.path);
    try {
      await referenceImage.putFile(imageFile);
      imageurl = await referenceImage.getDownloadURL();
      setState(() {
        searching = imageurl;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, String>> generateRSAKeys() async {
    final key = await RSA.generate(2048);
      final publicKey= key.publicKey;
     final privateKey = key.privateKey;
    return {'privateKey': privateKey,'publicKey': publicKey};
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 120.0),
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
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      username = value;
                    },
                    decoration: InputDecoration(hintText: 'Enter your Username'),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      email = value;
                    },
                    decoration: InputDecoration(hintText: 'Enter your email'),
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
                    decoration: InputDecoration(hintText: 'Enter your password'),
                  ),
                  SizedBox(
                    height: 24.0,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 35.0),
                    child: Row(
                      children: [
                        // Image
                        Container(
                          width: 100.0,
                          height: 100.0,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(searching == '' ? 'https://cdn.pixabay.com/photo/2018/11/13/21/43/avatar-3814049_640.png' : searching),
                            radius: 40.0,
                          ),
                        ),
                        // Button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextButton(
                              onPressed: () {
                                PickImage();
                              },
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.perm_media),
                                    SizedBox(width: 10.0,),
                                    Text("Upload Image"),
                                  ]
                              ),
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(Color(0xff2D3250)),
                                minimumSize: MaterialStateProperty.all(Size(150.0, 50.0)),
                                foregroundColor: MaterialStateProperty.all(Colors.white),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 24.0,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final progress = ProgressHUD.of(context);
                        progress?.showWithText('Loading...');

                        final newUser = await _auth.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        if (newUser != null) {
                          final rsaKeys = await generateRSAKeys();
                          final privateKey = rsaKeys['privateKey'];
                          final publicKey = rsaKeys['publicKey'];
                          await secureStorage.write(key: 'private_key', value: privateKey);

                          _firestore.collection('Userdetails').add({
                            'username': username,
                            'email': email,
                            'profile_image': searching,
                            'friends_list': [],
                            'publicKey': publicKey,
                          });

                          Navigator.pushNamed(context, AddFriendScreen.id);
                        }

                        Future.delayed(Duration(seconds: 2), () {
                          progress?.dismiss();
                        });
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
