import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/colors.dart';
import '../utils/models.dart';

class UserController extends ChangeNotifier {

  StreamSubscription? stream;
  User? _user;
  UserProfile? _userProfile;

  bool loading = true;

  // sign in with apple handling
  String? appleSignInName;
  
  StreamSubscription? vendorStream;
  StreamSubscription? employeeStream;
  Vendor? _vendor;

  ColorTheme _colors = mainThemeDark;

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
        vendorStream?.cancel();
        _vendor = null;
        employeeStream?.cancel();
        employeeStream = null;
        appleSignInName = null;
        _colors = mainThemeDark;
      }

      notifyListeners();
    });
  }

  void handleUserDocChange(DocumentSnapshot doc) {
    loading = false;
    if(!doc.exists) {
      _userProfile = null;
      _vendor = null;
      vendorStream?.cancel();
      employeeStream?.cancel();
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

    // initialize all streams
    vendorStream = FirebaseFirestore.instance
      .collection("vendors").doc('H1d9tejlBogXJ1r3k49a')
      .snapshots()
      .listen((vendorDoc) {
        if(!vendorDoc.exists) {
          vendorStream?.cancel();
          _vendor = null;
          employeeStream?.cancel();
          employeeStream = null;
          _colors = mainThemeDark;
          notifyListeners();
          return;
        }

        // update vendor object -> init stream if not initialized
        Vendor? prev = _vendor;
        _vendor = Vendor.fromMap(vendorDoc.data() as Map<String,dynamic>);
        if(prev != null) {
          // avoid overwriting employees
          _vendor!.employees = prev.employees;
        }
        employeeStream ??= FirebaseFirestore.instance
          .collection("vendors").doc(vendorDoc.id)
          .collection("employees")
          .snapshots().listen(onEmployeeChange);

        // set colors to colors of vendor
        _colors = getThemeById(_vendor!.themeId);
        notifyListeners();
      });

    
    notifyListeners();
  }

  void onEmployeeChange(QuerySnapshot event) {
    for (var docChange in event.docChanges)  {
      if(docChange.type == DocumentChangeType.added) {
        int index = _vendor!.employees.indexWhere((element) => element.id == docChange.doc.id);
        Employee emp = Employee.fromMap(docChange.doc.data() as Map<String, dynamic>);
        if(index != -1) {
          _vendor!.employees[index] = emp;
        }
        else {
          _vendor!.employees.add(emp);
        }
      }
      else if(docChange.type == DocumentChangeType.modified) {
        int index = _vendor!.employees.indexWhere((element) => element.id == docChange.doc.id);
        if(index != -1) {
          _vendor!.employees[index] = Employee.fromMap(docChange.doc.data() as Map<String, dynamic>);
        }
      }
      else if(docChange.type == DocumentChangeType.removed) {
        int index = _vendor!.employees.indexWhere((element) => element.id == docChange.doc.id);
        if(index != -1) {
          _vendor!.employees.removeAt(index);
        }
      }
    }

    // make sure if employee to always have own profile at first place in list
    String uid = FirebaseAuth.instance.currentUser!.uid;
    int ownIndex = _vendor!.employees.indexWhere((element) => element.id == uid);
    if(ownIndex > 0) {
      Employee emp = _vendor!.employees[ownIndex];
      _vendor!.employees.removeAt(ownIndex);
      _vendor!.employees.insert(0, emp);
    }

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

  Vendor? get getVendor => _vendor;

  Employee? getEmployeeById(String id) {
    int index = _vendor!.employees.indexWhere((element) => element.id == id);
    return index == -1 ? null : _vendor!.employees[index];
  }

  UserProfile? get getUserProfile => _userProfile;

  User? get getUser => _user;

  ColorTheme get getColors => _colors;

  void setAppleSignInName(String? value) => appleSignInName = value;

}