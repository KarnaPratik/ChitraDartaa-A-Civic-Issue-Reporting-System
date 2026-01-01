import 'package:flutter/material.dart';
import 'package:chitradartaa/frontend/citizen.dart';
import 'package:chitradartaa/frontend/admin.dart';
import 'package:chitradartaa/frontend/login.dart';
import 'package:chitradartaa/frontend/signup.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",

      routes:{
       "/login":(context)=>  MyLogin(),
        "/signup":(context)=> const MyRegister(),
        "/citizen":(context)=> const MyCitizen(),
        "/admin":(context)=> const Myadministrator(),
      }
    );
  }
}