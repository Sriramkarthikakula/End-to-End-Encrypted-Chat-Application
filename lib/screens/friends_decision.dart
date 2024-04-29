import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FriendDecisionScreen extends StatefulWidget {
  static String id = 'friendsdecision';
  @override
  _FriendDecisionScreenState createState() => _FriendDecisionScreenState();
}

class _FriendDecisionScreenState extends State<FriendDecisionScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<dynamic> frlis = [];
  void onFriendAction(String friend, bool isAdding) async{
    if (isAdding) {
      await _firestore.collection('requested_data').add({
        'Actionmaker':friend,
        'requested_guy':curr
      });
    } else {

    }
  }
  void acceptFriend(String Friendemail, String Curremail) async {
    QuerySnapshot UserquerySnapshot = await _firestore.collection('Userdetails')
        .where('email', isEqualTo: Curremail)
        .get();
    if (UserquerySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = UserquerySnapshot.docs.first;
      frlis = doc['friends_list'];
      frlis.add(Friendemail);
      DocumentReference docRef = doc.reference;
      await docRef.update({'friends_list': frlis});
    }
    QuerySnapshot FriendquerySnapshot = await _firestore.collection(
        'Userdetails').where('email', isEqualTo: Friendemail).get();
    if (FriendquerySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = FriendquerySnapshot.docs.first;
      frlis = doc['friends_list'];
      frlis.add(Curremail);
      DocumentReference docRef = doc.reference;
      await docRef.update({'friends_list': frlis});
    }
    QuerySnapshot checkinng = await _firestore.collection('requested_data')
        .where('Actionmaker', isEqualTo: Curremail).where(
        'requested_guy', isEqualTo: Friendemail)
        .get();
    if (checkinng.docs.isNotEmpty) {
      DocumentSnapshot doc = checkinng.docs.first;
      await doc.reference.delete();
    }
    else {
      print('No matching documents found');
    }
  }
  void DeleteFriend(String Friendemail, String Curremail) async {
    QuerySnapshot checkinng = await _firestore.collection('requested_data')
        .where('Actionmaker', isEqualTo: Curremail).where(
        'requested_guy', isEqualTo: Friendemail)
        .get();
    if (checkinng.docs.isNotEmpty) {
      DocumentSnapshot doc = checkinng.docs.first;
      await doc.reference.delete();
    }
    else {
      print('No matching documents found');
    }
  }

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
              stream: _firestore.collection('requested_data').where('Actionmaker', isEqualTo: curr).snapshots(),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                  );
                }
                if (asyncSnapshot.hasError) {
                  return Text('Error: ${asyncSnapshot.error}');
                }

                // Process data only if it's available
                if (asyncSnapshot.hasData) {

                  final friends = asyncSnapshot.data?.docs;
                  List<Textwidget> friendsWidgets = [];

                  // Use Future.forEach to iterate over the documents asynchronously
                  return FutureBuilder<void>(
                    future: Future.forEach(friends!, (friend) async {
                      QuerySnapshot querySnapshot = await _firestore.collection('Userdetails').where('email', isEqualTo: friend['requested_guy']).get();

                      if (querySnapshot.docs.isNotEmpty) {
                        DocumentSnapshot doc = querySnapshot.docs.first;
                        print(doc['email']);
                        final profilePhoto = doc['profile_image'];
                        final messageSender = doc['username'];
                        final messageSendermail = doc['email'];
                        final currentuser = curr;
                        final messageContainer = Textwidget(profilePhoto, messageSender, currentuser!, messageSendermail,acceptFriend);
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
                }

                // Return a default widget if there's no data
                return Center(
                  child: Text('No data available.'),
                );
              },
            ),





            TextButton(onPressed: null, child: Text('submit')),
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
 // Define callback function
  final Function(String friendemail,String curremail) AcceptFriend;
  final String friendemail;
  Textwidget(
      this.profile,
      this.friend,
  this.user,
      this.friendemail,// Receive callback function
this.AcceptFriend,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(widget.profile),
            radius: 40.0,
          ),
          Text(widget.friend),
          TextButton(onPressed: (){
            widget.AcceptFriend(widget.friendemail,widget.user);
          }, child: Text("Accept")),
          TextButton(onPressed: null, child: Text("Delete")),
          SizedBox(height: 1.0,)
          // IconButton(
          //   icon: Icon(isFriend ? Icons.remove : Icons.add),
          //   onPressed: () {
          //     setState(() {
          //       isFriend = !isFriend;
          //       // Call callback function to add or remove friend
          //       widget.onFriendAction(widget.friendemail, isFriend);
          //     });
          //   },
          // ),
        ],
      ),
    );
  }
}


