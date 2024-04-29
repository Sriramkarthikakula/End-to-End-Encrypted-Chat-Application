import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AddFriendScreen extends StatefulWidget {
  static String id = 'addfriends';
  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _firestore = FirebaseFirestore.instance;
  void onFriendAction(String friend, bool isAdding) async{
    if (isAdding) {
      await _firestore.collection('requested_data').add({
        'Actionmaker':friend,
        'requested_guy':curr
      });
    } else {
     QuerySnapshot querySnapshot = await _firestore.collection('requested_data').where('Actionmaker', isEqualTo: friend).where('requested_guy',isEqualTo: curr).get();
     if(querySnapshot.docs.isNotEmpty){
       DocumentSnapshot doc = querySnapshot.docs.first;
       await doc.reference.delete();
     }
     else {
       print('No matching documents found');
     }
    }
  }
  final messageTextController = TextEditingController();

  String? curr;
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
        title: Text('⚡️Add Friends'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Userdetails').where('email', isNotEqualTo: curr).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> Asyncsnapshots) {
                if (Asyncsnapshots.hasData) {
                  final friends = Asyncsnapshots.data?.docs;
                  List<Textwidget> friendsWidgets = [];
                  for (var friend in friends!) {
                    final profilePhoto = friend['profile_image'];
                    final messageSender = friend['username'];
                    final messageSendermail = friend['email'];
                    final currentuser = curr;
                    final messageContainer = Textwidget(profilePhoto, messageSender, currentuser!, onFriendAction,messageSendermail);
                    friendsWidgets.add(messageContainer);
                  }
                  return Expanded(
                    child: ListView(
                      children: friendsWidgets,
                    ),
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
              Navigator.pushNamed(context, DashboardScreen.id);
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
  final String user;
  final Function(String friend, bool isAdding) onFriendAction; // Define callback function
  final String friendemail;
  Textwidget(
    this.profile,
    this.friend,
   this.user,
    this.onFriendAction,
      this.friendemail// Receive callback function
  );

  @override
  _TextwidgetState createState() => _TextwidgetState();
}

class _TextwidgetState extends State<Textwidget> {
  bool isFriend = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            IconButton(
              icon: Icon(isFriend ? Icons.remove : Icons.add),
              onPressed: () {
                setState(() {
                  isFriend = !isFriend;
                  // Call callback function to add or remove friend
                  widget.onFriendAction(widget.friendemail, isFriend);
                });
              },
            ),
          ],
        ),
          Container(
            height: 1, // Adjust the height of the line
            color: Colors.black.withOpacity(0.2), // Set the color of the line
            margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
          ),
        ],
      ),
    );
  }
}


