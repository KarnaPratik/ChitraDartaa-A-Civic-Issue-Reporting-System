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
      initialRoute: "login_page",
      routes:{
       "login_page":(context)=>  MyLogin(),
        "register_page":(context)=> const MyRegister(),
        "citizen_side":(context)=> const MyCitizen(),
        "administrator_side":(context)=> const Myadministrator(),
      }
    );
  }
}