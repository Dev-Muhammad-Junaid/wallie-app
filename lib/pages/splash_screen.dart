import 'dart:async';

import 'package:flutter/material.dart';

import 'home_page.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 2), () {Navigator.pushReplacementNamed(context, '/home');});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)])
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Icon(Icons.wallet,color: Colors.white,size: 50,),
            Text("Wallie",style: TextStyle(fontSize: 50,color: Colors.white),textAlign: TextAlign.center,),
            Spacer(),
            Text("Jellyfish Studios",style: TextStyle(fontSize: 15,color: Colors.white,),textAlign: TextAlign.center),
            // Text("All Rights Reserved",style: TextStyle(fontSize: 15,color: Colors.white,),textAlign: TextAlign.center),
            SizedBox(height: 25,),
          ],
        ),
      ),
    );
  }
}
