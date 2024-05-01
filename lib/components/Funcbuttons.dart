import 'package:flutter/material.dart';

class FuncButtons extends StatelessWidget {
  FuncButtons(this.buttoncolor, this.whatfunc, this.whattext);
  final Color buttoncolor;
  final VoidCallback whatfunc;
  final String whattext;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: buttoncolor,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: whatfunc,
          minWidth: 200.0,
          height: 42.0,
          child: Text(
            '$whattext',
            style: TextStyle(
              color: Colors.white,
            ),
          ),

        ),
      ),
    );
  }
}
