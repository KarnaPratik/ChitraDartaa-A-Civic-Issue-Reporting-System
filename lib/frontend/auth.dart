import "dart:convert";//to convert json
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';//to store tokens


class AuthService{
  static const String url="http://127.0.0.1:5000";

  //this will call sign up function
  static Future<bool>signUp({
    required String username,
    required String password
  }) async{

    //first we try
try{
  final response=await http.post(
    Uri.parse("$url/auth/signup"),
    headers: {"Content-Type":"application/json"},
    body: jsonEncode({
      "username":username,
      "password":password
    }),

  );

  if(response.statusCode==201){
    return true;
  }
  else if(response.statusCode==409){
    //i think 409 is for same username and email in the flask app
    final data=jsonDecode(response.body);
    throw Exception(data["error"]??"username already exists!");
  }
  else{
    final data=jsonDecode(response.body);
    throw Exception(data["error"]??"Sign up Failed!");


  }
}

catch(e){
  throw Exception("Network error: ${e.toString()}");
}

  }


}