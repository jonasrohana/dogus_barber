import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/models.dart';

class UserController extends ChangeNotifier {

  StreamSubscription? stream;
  User? _user;
  UserProfile? _userProfile;

  bool loading = true;

  // sign in with apple handling
  String? appleSignInName;

  UserController() {
    init();
  }

  void init() {
    FirebaseAuth.instance.authStateChanges().listen((event) {
      _user = event;

      // user signed in -> initialize streams
      if(_user != null) {
        String? uid = FirebaseAuth.instance.currentUser?.uid;

        // delayed so we have a document to check if it exists
        Future.delayed(const Duration(seconds: 5), () => setupToken());

        stream = FirebaseFirestore.instance
          .collection("user").doc(uid)
          .snapshots()
          .listen(handleUserDocChange);
      }
      // user signed out, cancel streams and reset values
      else {
        stream?.cancel();
        _userProfile = null;
        appleSignInName = null;
      }

      notifyListeners();
    });


  }

  void handleUserDocChange(DocumentSnapshot doc) {
    loading = false;
    if(!doc.exists) {
      _userProfile = null;
      appleSignInName = null;
      notifyListeners();
      return;
    }

    // needed for initial setting of token
    if((doc.data() as Map<String,dynamic>).containsKey("tokens") == false) {
      setupToken();
    }

    // set user profile
    _userProfile = UserProfile.fromMap(doc.data() as Map<String,dynamic>);

    
    notifyListeners();
  }
  
  Future<void> saveTokenToFirestore(String token) async {
    if(FirebaseAuth.instance.currentUser == null || _userProfile == null) {
      return;
    }
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
      .collection("user").doc(userId)
      .set({
        "tokens": FieldValue.arrayUnion([token]),
        "lastSignIn": DateTime.now()
      }, SetOptions(merge: true));
  }

  Future<void> setupToken() async {
    if(kDebugMode) return;

    // get token and save to firestore
    String? token = await FirebaseMessaging.instance.getToken();
    saveTokenToFirestore(token!);
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToFirestore);
  }

  UserProfile? get getUserProfile => _userProfile;

  User? get getUser => _user;

  void setAppleSignInName(String? value) => appleSignInName = value;

}