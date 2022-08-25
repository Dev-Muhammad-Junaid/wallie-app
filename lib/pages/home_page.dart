import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:the_wallpaper_app/pages/models/image_repository.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<ImageRepository> imageRepository = [
    ImageRepository(
        url:
            "https://images.pexels.com/photos/6985001/pexels-photo-6985001.jpeg?auto=compress&cs=tinysrgb&w=800"),
    ImageRepository(
        url:
            "https://images.pexels.com/photos/6985001/pexels-photo-6985001.jpeg?auto=compress&cs=tinysrgb&w=800"),
    ImageRepository(
        url:
            "https://images.pexels.com/photos/6985001/pexels-photo-6985001.jpeg?auto=compress&cs=tinysrgb&w=800"),
    ImageRepository(
        url:
            "https://images.pexels.com/photos/6985001/pexels-photo-6985001.jpeg?auto=compress&cs=tinysrgb&w=800"),
    ImageRepository(
        url:
            "https://images.pexels.com/photos/6985001/pexels-photo-6985001.jpeg?auto=compress&cs=tinysrgb&w=800"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                CupertinoSearchTextField(
                  placeholder: "Search anything",
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(10),
                ),
                SizedBox(height: 25,),
                Align(alignment:Alignment.centerLeft,child: Text("Best of the Month",textAlign: TextAlign.left,style: TextStyle(fontSize: 30,fontWeight: FontWeight.w900,color: Colors.white,),)),
                SizedBox(height: 15,),
                CarouselSlider(
                  options: CarouselOptions(height: 350.0),
                  items: imageRepository.map((i) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                    image: NetworkImage(imageRepository[imageRepository.indexOf(i)].url))),
                            child: Text(""));
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20,),
                Card(
                  elevation: 3,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    title: Text("Image"),
                    style: ListTileStyle.drawer,
                    leading: Image.network(
                        'https://images.pexels.com/photos/6984984/pexels-photo-6984984.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2'),
                    contentPadding: EdgeInsets.all(10),
                    tileColor: Colors.white,
                    selectedColor: Colors.deepOrange,
                    subtitle: Text("Subtitle"),
                  ),
                ),
                Card(
                  elevation: 3,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    title: Text("Image"),
                    style: ListTileStyle.drawer,
                    leading: Image.network(
                        'https://images.pexels.com/photos/6984984/pexels-photo-6984984.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2'),
                    contentPadding: EdgeInsets.all(10),
                    tileColor: Colors.white,
                    selectedColor: Colors.deepOrange,
                    subtitle: Text("Subtitle"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
