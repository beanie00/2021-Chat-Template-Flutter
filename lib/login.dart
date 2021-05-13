import 'package:firebase_messaging/firebase_messaging.dart';
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

import 'constants/app_colors.dart';
import 'controllers/http_controller.dart';

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
  User firebaseUser;
  String errorMessage;

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
      //print("fireUserUid" + fireUserUid);
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

    try {
      firebaseUser = (await firebaseAuth.signInWithEmailAndPassword(
              email: data.name, password: data.password))
          .user;
    } catch (error) {
      switch (error.code) {
        case "ERROR_INVALID_EMAIL":
          errorMessage = "이메일 형식을 확인해주세요.";
          break;
        case "ERROR_WRONG_PASSWORD":
          errorMessage = "비밀번호를 확인해주세요.";
          break;
        case "ERROR_USER_NOT_FOUND":
          errorMessage = "회원가입을 먼저 진행해주세요.";
          break;
        case "ERROR_USER_DISABLED":
          errorMessage = "User with this email has been disabled.";
          break;
        case "ERROR_TOO_MANY_REQUESTS":
          errorMessage = "Too many requests. Try again later.";
          break;
        case "ERROR_OPERATION_NOT_ALLOWED":
          errorMessage = "Signing in with Email and Password is not enabled.";
          break;
        default:
          errorMessage = "아이디, 비밀번호를 확인해주세요.";
      }
      Fluttertoast.showToast(msg: errorMessage);
      this.setState(() {
        isLoading = false;
      });
      return errorMessage;
    }
    if (firebaseUser != null) {
      Fluttertoast.showToast(msg: "로그인 되었습니다.");
      this.setState(() {
        isLoading = false;
      });
      currentUser = firebaseUser;
      fireUserUid = firebaseUser.uid;
      await prefs.setString('id', fireUserUid);
      await prefs.setString('nickname', data.name);

      HttpController.signIn(email: data.name);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(currentUserId: fireUserUid)));

      return Future.delayed(Duration(milliseconds: 10)).then((_) {
        return null;
      });
    }
  }

  Future<String> handleSignUp(LoginData data) async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });
    try {
      firebaseUser = (await firebaseAuth.createUserWithEmailAndPassword(
              email: data.name, password: data.password))
          .user;
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
      this.setState(() {
        isLoading = false;
      });
      return error.toString();
    }
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

        FirebaseMessaging.instance.getToken().then((token) {
          print('token: $token');
          HttpController.signUp(email: data.name, fcmId: token);
        }).catchError((err) {
          Fluttertoast.showToast(msg: err.message.toString());
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', firebaseUser.uid);
        await prefs.setString('nickname', data.name);
      }
      Fluttertoast.showToast(msg: "로그인 되었습니다.");
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
      logo: 'assets/images/dearplant_white.png',
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
        primaryColor: AppColors.purple,
        errorColor: Colors.deepOrange,
      ),
      messages: LoginMessages(
        usernameHint: '이메일',
        passwordHint: '비밀번호',
        confirmPasswordHint: '비밀번호 확인',
        loginButton: '로그인',
        signupButton: '회원가입',
        forgotPasswordButton: '비밀번호 찾기',
        recoverPasswordButton: 'HELP ME',
        goBackButton: 'GO BACK',
        confirmPasswordError: '두 비밀번호가 일치하지 않습니다.',
        recoverPasswordDescription:
            '가입시 사용했던 이메일 주소를 입력해주시면 비밀번호 재설정 링크를 보내드립니다.',
        recoverPasswordSuccess: 'Password rescued successfully',
      ),
    );
  }
}
