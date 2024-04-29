import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/Hillcipher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:fast_rsa/fast_rsa.dart';

class ChatScreen extends StatefulWidget {
  static String id = 'chat';
  final String profile;
  final String friendUsername;
  final String friendEmail;

  ChatScreen(this.profile, this.friendUsername, this.friendEmail);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  String chat = '';
  String mail = '';
  var pub_key;
  var friend_pub_key;
  var User_private_key;
  List<List<int>> keymatrix=[[],[]];
  final secureStorage = FlutterSecureStorage();
  // List<TextWidget> messageWidgets = [];

  @override
  void initState() {
    getCurrentuser();
    super.initState();
  }
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  void getPublicKey(String recipientEmail) async {
    try {
      final snapshot = await _firestore.collection('Userdetails').where('email', isEqualTo: recipientEmail).get();
      if (snapshot.docs.isNotEmpty) {
        final publicKey = snapshot.docs.first;
        var key = publicKey['publicKey'];

        setState(() {
          pub_key = key;
        });
      } else {
        print('No matching documents found for email: $recipientEmail');
        // Handle case where no public key is found
      }
    } catch (e) {
      print('Error retrieving public key: $e');
      // Handle error appropriately
    }
  }
  void getfriendPublicKey(String recipientEmail) async {
    try {
      final snapshot = await _firestore.collection('Userdetails').where('email', isEqualTo: recipientEmail).get();
      if (snapshot.docs.isNotEmpty) {
        final publicKey = snapshot.docs.first;
        var key = publicKey['publicKey'];
        setState(() {
          friend_pub_key = key;
        });
      } else {
        print('No matching documents found for email: $recipientEmail');
        // Handle case where no public key is found
      }
    } catch (e) {
      print('Error retrieving public key: $e');
      // Handle error appropriately
    }
  }
  void getCurrentuser() async {
    try {
      User user = await _auth.currentUser!;
      if (user != null) {
        setState(() {
          mail = user.email!;
        });
        setState(() {
          getPublicKey(mail);
        });
        setState(() {
          getfriendPublicKey(widget.friendEmail);
        });
        setState(() async{
          User_private_key = await secureStorage.read(key: "private_key");
        });
      }
    } catch (e) {
      print(e);
    }
  }

  String serializeHillCipherKey(List<List<int>> key) {
    return key.map((row) => row.join(',')).join(';');
  }

  Future<String> encryptHillCipherKey(List<List<int>> keyMatrix, String publicKey) async {
    try {
      final serializedKey = serializeHillCipherKey(keyMatrix);
      final encryptedKey = await RSA.encryptPKCS1v15(serializedKey, publicKey);
      return encryptedKey;
    } catch (e) {
      print('Error encrypting Hill cipher key: $e');
      return ''; // Handle error appropriately
    }
  }

  List<List<int>> deserializeHillCipherKey(String serializedKey) {
    // Split the serialized key into rows

    List<String> rows = serializedKey.split(';');
    // Initialize the key matrix
    List<List<int>> keyMatrix = [];

    // Iterate over each row
    for (String row in rows) {
      // Split the row into individual numbers
      List<String> numbers = row.split(',');

      // Parse each number and add it to the row list
      List<int> rowList = [];
      for (String number in numbers) {
        rowList.add(int.parse(number));
      }

      // Add the row list to the key matrix
      keyMatrix.add(rowList);
    }

    return keyMatrix;
  }



  Future<List<List<int>>> decryptHillCipherKey(String encryptedKey, String privateKey) async {
    try {
      final decryptedKey = await RSA.decryptPKCS1v15(encryptedKey, privateKey);
      final finding_key = deserializeHillCipherKey(decryptedKey);

      final key = deserializeHillCipherKey(decryptedKey);
      return key;
    } catch (e) {
      print('Error decrypting Hill cipher key: $e');
      return []; // Handle error appropriately
    }
  }



  List<List<int>> generateRandomKeyMatrix(int size) {
    final Random random = Random();
    List<List<int>> keyMatrix;

    // Keep generating key matrix until a suitable one is found
    while (true) {
      // Create an empty key matrix
      keyMatrix = List.generate(size, (_) => List.filled(size, 0));

      // Generate random values for the key matrix
      for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
          // Generate a random integer between 0 and 25 (inclusive)
          keyMatrix[i][j] = random.nextInt(26);
        }
      }

      // Ensure that the determinant is non-zero (the matrix is invertible)
      if (_determinant(keyMatrix) != 0) {
        // Ensure that the determinant has a modular multiplicative inverse modulo 26
        if (_modInverse(_determinant(keyMatrix), 26) != -1) {
          break; // Suitable key found, exit the loop
        }
      }
    }

    return keyMatrix;
  }

  int _determinant(List<List<int>> matrix) {
    if (matrix.length == 2) {
      // For a 2x2 matrix, calculate the determinant directly
      return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
    } else {
      // For larger matrices, use the Laplace expansion to calculate the determinant
      int det = 0;
      for (int i = 0; i < matrix.length; i++) {
        det += (i.isEven ? 1 : -1) * matrix[0][i] * _determinant(_subMatrix(matrix, 0, i));
      }
      return det;
    }
  }

  List<List<int>> _subMatrix(List<List<int>> matrix, int rowToRemove, int colToRemove) {
    return matrix
        .asMap()
        .entries
        .where((entry) => entry.key != rowToRemove)
        .map((entry) => entry.value.sublist(0, colToRemove) + entry.value.sublist(colToRemove + 1))
        .toList();
  }
  int _modInverse(int a, int m) {
    for (int i = 1; i < m; i++) {
      if ((a * i) % m == 1) {
        return i;
      }
    }
    return -1;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80.0,
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.profile),
          radius: 40.0,
        ),
        title: Text(widget.friendUsername),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('sender', whereIn: [mail, widget.friendEmail])
                  .orderBy('timestamp',descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> Asyncsnapshots) {
                if (Asyncsnapshots.hasData) {
                  final List<DocumentSnapshot> messages = Asyncsnapshots.data!
                      .docs;

                  // Filter messages where the receiver is the current user or the friend
                  final filteredMessages = messages.where((message) =>
                  message['receiver'] == mail ||
                      message['receiver'] == widget.friendEmail).toList();
                  if (filteredMessages.length > 0) {
                    return FutureBuilder<dynamic>(
                        future: decrptMsg(filteredMessages),
                        builder: (context,
                            AsyncSnapshot<dynamic> Asyncsnapshots) {
                          if (Asyncsnapshots.hasData) {
                            return Expanded(
                                child: ListView.builder(
                                  itemBuilder: (context, index) =>
                                      buildItem(
                                          index, Asyncsnapshots.data?[index]),
                                  itemCount: Asyncsnapshots.data?.length,
                                  reverse: true,
                                ));
                          }
                          else {
                            return CircularProgressIndicator();
                          }
                        });
                  } else {
                    return Center(child: Text("No message here yet..."));
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  );
                }
              },
      ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          chat = value;
                        },
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (chat.length % 2 != 0) {
                        chat += ' ';
                      }
                      final List<List<int>> keyMatrix = generateRandomKeyMatrix(2);

                      HillCipher hillCipher = HillCipher(keyMatrix);
                      String encryptedText = hillCipher.encrypt(chat);
                      // String decrypted = hillCipher.decrypt(encryptedText);


                         final Sender_encrypted_key = await encryptHillCipherKey(keyMatrix,pub_key);

                          final reciver_encrypted_key = await encryptHillCipherKey(keyMatrix,friend_pub_key);

                          _firestore.collection('messages').add({
                            'sender_key':Sender_encrypted_key,
                            'reciver_key':reciver_encrypted_key,
                            'text': encryptedText, // Send the encrypted chat message
                            'sender': mail,
                            'receiver': widget.friendEmail,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          messageTextController.clear();
                    },
                    icon: Icon(
                      Icons.send,
                      color: Colors.lightBlueAccent,
                    ),
                  ),

                ],
              ),
            ),
            ],
        ),
      ),
    );
  }

  Widget buildItem(int index, document) {
    if (document != null) {
      return Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: document['sender'] == mail ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              document['sender'],
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black54,
              ),
            ),
            Material(
              borderRadius: document['sender'] == mail
                  ? BorderRadius.only(
                topLeft: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              )
                  : BorderRadius.only(
                topRight: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
              elevation: 5.0,
              color: document['sender'] == mail ? Colors.lightBlueAccent : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(
                  document['text'],
                  style: TextStyle(
                    color: document['sender']== mail ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Return a placeholder widget, such as Container
      return Container();
    }
  }

  decrptMsg(List<DocumentSnapshot<Object?>> listMessage) async{
    var msg_list = [];
    for (var message in listMessage) {
      final messageText = message['text'];
      final messageSender = message['sender'];
      final currentuser = mail;

      if (messageSender == currentuser) {
        final encryptedSenderKey = message['sender_key'];

        // Decrypt the message
        final decryptedSenderKey = await decryptHillCipherKey(encryptedSenderKey, User_private_key);
        HillCipher hillCipher = HillCipher(decryptedSenderKey);
        final decryptedText = hillCipher.decrypt(messageText);
        var data = {
          'text':decryptedText,
          'sender':messageSender,
        };
        msg_list.add(data);
      }
      else{
        final encryptedSenderKey = message['reciver_key'];

        // Decrypt the message
        final decryptedSenderKey = await decryptHillCipherKey(encryptedSenderKey, User_private_key);
        HillCipher hillCipher = HillCipher(decryptedSenderKey);
        final decryptedText = hillCipher.decrypt(messageText);
        var data = {
          'text':decryptedText,
          'sender':messageSender,
        };
        msg_list.add(data);
      }
    }
    return msg_list;
  }
}
