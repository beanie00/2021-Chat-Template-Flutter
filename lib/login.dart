import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dearplant/const.dart';
import 'package:dearplant/home.dart';
import 'package:dearplant/widget/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dearplant/chat.dart';

String fireUserUid = '';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, @required this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  User currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();
    var user = firebaseAuth.currentUser;
    //isLoggedIn = await googleSignIn.isSignedIn();
    if (user != null) {
      fireUserUid = prefs.getString('id');
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomeScreen(currentUserId: prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<String> handleSignIn(LoginData data) async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    User firebaseUser = (await firebaseAuth.signInWithEmailAndPassword(
            email: data.name, password: data.password))
        .user;
    if (firebaseUser != null) {
      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() {
        isLoading = false;
      });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(currentUserId: firebaseUser.uid)));

      return Future.delayed(Duration(milliseconds: 10)).then((_) {
        return null;
      });
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
      return Future.delayed(Duration(milliseconds: 10)).then((_) {
        return "Sign in fail";
      });
    }
  }

  Future<String> handleSignUp(LoginData data) async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    User firebaseUser = (await firebaseAuth.createUserWithEmailAndPassword(
            email: data.name, password: data.password))
        .user;
    if (firebaseUser != null) {
      // Check is already sign up
      fireUserUid = firebaseUser.uid;
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      if (documents.length == 0) {
        // Update data to server if new user
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'nickname': data.name,
          'photoUrl': firebaseUser.photoURL,
          'id': firebaseUser.uid,
          'aboutMe': "",
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingWith': null
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', firebaseUser.uid);
        await prefs.setString('nickname', data.name);
      }
      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() {
        isLoading = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(currentUserId: firebaseUser.uid)));

      return Future.delayed(Duration(milliseconds: 10)).then((_) {
        return null;
      });
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
      return Future.delayed(Duration(milliseconds: 10)).then((_) {
        return "Sign in fail";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      logo: 'assets/images/dearplant_white.webp',
      onLogin: (loginData) {
        return handleSignIn(loginData);
      },
      onSignup: (loginData) {
        print('Signup info');
        print('Name: ${loginData.name}');
        print('Password: ${loginData.password}');
        return handleSignUp(loginData);
      },
      onSubmitAnimationCompleted: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(currentUserId: fireUserUid)));
      },
      onRecoverPassword: (_) => Future(null),
      theme: LoginTheme(
        primaryColor: Colors.purple,
        errorColor: Colors.deepOrange,
      ),
      messages: LoginMessages(
        usernameHint: 'Email',
        passwordHint: 'Password',
        confirmPasswordHint: 'Confirm',
        loginButton: 'LOG IN',
        signupButton: 'REGISTER',
        forgotPasswordButton: 'Forgot password?',
        recoverPasswordButton: 'HELP ME',
        goBackButton: 'GO BACK',
        confirmPasswordError: 'Not match!',
        recoverPasswordDescription:
            '가입시 사용했던 이메일 주소를 입력해주시면 비밀번호 재설정 링크를 보내드립니다.',
        recoverPasswordSuccess: 'Password rescued successfully',
      ),
    );
  }
}
