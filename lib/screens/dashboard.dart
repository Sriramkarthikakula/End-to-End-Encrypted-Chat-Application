import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/friends_decision.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DashboardScreen extends StatefulWidget {
  static String id = 'dashboard';
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? curr;
  List<dynamic> frinedslist=[];
  @override
  void initState() {
    final _auth = FirebaseAuth.instance;
    curr = _auth.currentUser!.email;

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.account_tree_outlined),
              onPressed:(){ Navigator.pushNamed(context, FriendDecisionScreen.id);}),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Userdetails').where('email', isEqualTo: curr).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> Asyncsnapshots) {
                if (Asyncsnapshots.hasData) {
                  final friends = Asyncsnapshots.data?.docs.first;

                  frinedslist = friends?['friends_list'];
                  List<Textwidget> friendsWidgets = [];
                  return FutureBuilder<void>(
                    future: Future.forEach(frinedslist, (friend) async {
                      QuerySnapshot querySnapshot = await _firestore.collection('Userdetails').where('email', isEqualTo: friend).get();

                      if (querySnapshot.docs.isNotEmpty) {
                        DocumentSnapshot doc = querySnapshot.docs.first;

                        final profilePhoto = doc['profile_image'];
                        final messageSender = doc['username'];
                        final messageSendermail = doc['email'];
                        final messageContainer = Textwidget(profilePhoto, messageSender, messageSendermail);
                        friendsWidgets.add(messageContainer);
                      }
                    }),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.lightBlueAccent,
                          ),
                        );
                      }

                      // After processing all documents, return the widget
                      return Expanded(
                        child: ListView(
                          children: friendsWidgets,
                        ),
                      );
                    },
                  );

                } else if (Asyncsnapshots.hasError) {
                  return Text('Error: ${Asyncsnapshots.error}');
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                  );
                }
              },
            ),
            TextButton(onPressed: (){
              Navigator.pushNamed(context, ChatScreen.id);
            }, child: Text('submit')),
          ],
        ),
      ),
    );
  }
}

class Textwidget extends StatefulWidget {
  final String profile;
  final String friend;

  final String friendemail;
  Textwidget(
      this.profile,
      this.friend,
      this.friendemail// Receive callback function
      );

  @override
  _TextwidgetState createState() => _TextwidgetState();
}

class _TextwidgetState extends State<Textwidget> {
  bool isFriend = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context){
          return ChatScreen(widget.profile,widget.friend,widget.friendemail);
        }));
      },
      child: Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.profile),
                  radius: 40.0,
                ),
                Text(widget.friend),
                Text(widget.friendemail),
              ],
            ),
            Container(
              height: 1, // Adjust the height of the line
              color: Colors.black.withOpacity(0.2), // Set the color of the line
              margin: EdgeInsets.symmetric(vertical: 5.0), // Adjust the margin if needed
            ),
          ],
        ),
      ),
    );
  }
}


