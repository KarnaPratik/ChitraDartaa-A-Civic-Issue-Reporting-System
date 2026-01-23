import "dart:convert";//to convert json
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';//to store tokens


class AuthService{

  static const String url="https://wrongly-unapprovable-lizeth.ngrok-free";

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
      "email":email,
      "is_admin":"False",
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
  required String email,
  required String password,
  required bool isAdministrator,
 }) async{
  try{
    final response=await http.post(
      Uri.parse("$url/auth/login"),
      headers: {"Content-Type":"application/json"},
      body: jsonEncode({"email":email,
                      "password": password, 
                      "role":isAdministrator,
      }
      ),

    );

    if(response.statusCode==200){
      final data=jsonDecode(response.body);
      String token=data["token"];
      String is_admin=data["is_admin"].toString();
      String username=data["username"];

      final pref=await SharedPreferences.getInstance();
      await pref.setString("access_token",token);
      await pref.setString("user", username);
      await pref.setString("is_administrator",is_admin.toString());
      await pref.setString("email",email);
      return true;

    }

    else if (response.statusCode==401){
      throw Exception("Invalid username or password!!");
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
      await logout();
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
  await prefs.remove("user");
  await prefs.remove("is_administrator");
  await prefs.remove("email");

} 
static Future<bool> isLoggedIn()async{ //loggedin ==== locked in , ain't vibecoded *wink* *wink*
  final pref=await SharedPreferences.getInstance();
  String? token=pref.getString("access_token");
  return  token!=null && token.isNotEmpty ;
}
static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("access_token");
}

static Future<bool>isAdmin()async{
  final prefs=await SharedPreferences.getInstance();
  String? adminStr = prefs.getString("is_administrator");
  return adminStr == "true";
}


//For admin enpoint
static Future<List<Map<String, dynamic>>> fetchIssues() async {
    try {
      final response = await http.get(
        Uri.parse('$url/admin/reports'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['reports']);
      } else {
        throw Exception('Failed to load issues');
      }
    } catch (e) {
      print('Error fetching issues: $e');
      rethrow;
    }
  }

  static Future<bool> updateIssueStatus(int id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$url/admin/reports/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'is_resolved': status == 'resolved'
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating issue: $e');
      return false;
    }
  }
}

