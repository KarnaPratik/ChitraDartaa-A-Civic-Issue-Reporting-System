import 'package:flutter/material.dart';
import 'package:chitradartaa/frontend/signup.dart';
import 'package:chitradartaa/frontend/forgot.dart';


class MyLogin extends StatefulWidget {
  const MyLogin({super.key});

  @override
  State<MyLogin> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Citizen';
  bool _obscurePassword = true;

  @override
   void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(

        decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF56ab2f),
        Color(0xFFa8e063),
        Color(0xFF00b4db),
        Color(0xFF0083b0),
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    ),
  ),
  child: Stack(
    children: [
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      Positioned(
        bottom: -150,
        left: -150,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 16,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF8FFFE),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 36.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile Photo Section
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF56ab2f),
                                Color(0xFF00b4db),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF56ab2f).withOpacity(0.4),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                            // Add your image here
                            image: DecorationImage(
                              // For network image:
                              // image: NetworkImage('YOUR_IMAGE_URL'),
                              // For asset image:
                              image: AssetImage('assets/bg_login'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_person,
                            size: 45,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a472a),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 30),

                        // Role Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF5FBF7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color(0xFF56ab2f).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'I am a',
                              labelStyle: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1a472a),
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.person_pin_circle_outlined,
                                size: 28,
                                color: Color(0xFF56ab2f),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF1a472a),
                              fontWeight: FontWeight.w500,
                            ),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.arrow_drop_down_circle,
                              size: 28,
                              color: Color(0xFF56ab2f),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Citizen',
                                child: Text('Citizen', style: TextStyle(fontSize: 18)),
                              ),
                              DropdownMenuItem(
                                value: 'Administrator',
                                child: Text('Administrator', style: TextStyle(fontSize: 18)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 17),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a472a),
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 28,
                              color: Color(0xFF00b4db),
                            ),
                            filled: true,
                            fillColor: Color(0xFFF5FBFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFF00b4db).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFF00b4db).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFF00b4db),
                                width: 2.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.red.shade400,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(fontSize: 17),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a472a),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 28,
                              color: Color(0xFF00b4db),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 28,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Color(0xFFF5FBFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFF00b4db).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFF00b4db).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFF00b4db),
                                width: 2.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.red.shade400,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF0083b0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {
                             
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF56ab2f),
                                    Color(0xFF00b4db),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF56ab2f).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Need an account? ",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyRegister(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF56ab2f),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
      
        
        
      )
    );
  }
}