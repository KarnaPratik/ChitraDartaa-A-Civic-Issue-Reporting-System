import "dart:convert";//to convert json
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';//to store tokens


class AuthService{
  static const String url="http://localhost:6969";

  //this will call sign up function
  static Future<bool>signUp({
    required String username,
    required String password,
    required String email,
  }) async{

    //first we try
try{
  final response=await http.post(
    Uri.parse("$url/auth/signup"),
    headers: {"Content-Type":"application/json"},
    body: jsonEncode({
      "username":username,
      "password":password,
      "email":email
    }),

  );


  if(response.statusCode==201){
    return true;
  }
  else if(response.statusCode==409){
    //I think 409 is for same username and email in the flask app
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



  //for login
 static Future <bool>logIn({
  required String username,
  required String password,
  required bool isAdministrator,
 }) async{
  try{
    final response=await http.post(
      Uri.parse("$url/auth/login"),
      headers: {"Content-Type":"application/json"},
      body: jsonEncode({"username":username,
                      "password": password, 
                      "role":isAdministrator,
      }
      ),

    );

    if(response.statusCode==200){
      final data=jsonDecode(response.body);
      String token=data["token"];
      String is_admin=data["is_admin"];

      final pref=await SharedPreferences.getInstance();
      await pref.setString("access_token",token);
      await pref.setString("username", username);
      await pref.setString("is_administrator",is_admin);
      return true;

    }

    else if (response.statusCode==401){
      throw Exception("Invalid username!! or password");
    }
    else{
      final data=jsonDecode(response.body);
      throw Exception(data["error"]??"Invalid issue with the login");
    }

  }

  catch(e){
    throw Exception("Network error:${e.toString()}");
  }
 }


 //to store user info and access we do following
 static Future <Map<String, dynamic>> getCurrentUser() async{
  try{
    final prefs=await SharedPreferences.getInstance();
    String? token=prefs.getString("access_token");
    if(token==null){
      throw Exception("No token found! Login again!");
    }
    final response=await http.get(
      Uri.parse("$url/auth/whoami"),
      headers: {
        "Authorization": "Bearer $token",
      },

    );
    if(response.statusCode==200){
      return jsonDecode(response.body);
    }
    else if(response.statusCode==401){
      await logout();// not written this function yet will do it later
      throw Exception("Session has expired, login again!");
    }
    else{
      throw Exception("Failed to get the user!");
    }
  


  }

  catch(e){
    throw Exception("Error:${e.toString()}");
  }
 }



//for logout====this comment seems vibecoded-but it ain't ;)
static Future<void> logout() async{
  final prefs=await SharedPreferences.getInstance();
  await prefs.remove("access_token");
  await prefs.remove("username");
  await prefs.remove("is_administrator");

} 
static Future<bool> isLoggedIn()async{
  final pref=await SharedPreferences.getInstance();
  return pref.containsKey("access_token");
}

static Future<bool>isAdmin()async{
  final prefs=await SharedPreferences.getInstance();
  return prefs.getBool("is_administrator")??false;
}




}