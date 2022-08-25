import 'package:flutter/material.dart';
import 'package:the_wallpaper_app/pages/home_page.dart';
import 'package:the_wallpaper_app/pages/splash_screen.dart';



void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => SplashScreen(),
      '/home': (context) => Home(),
      // '/categories' : (context) => Categories(),
    },
  ));
}

