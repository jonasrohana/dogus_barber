import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/colors.dart';
import '../utils/models.dart';

class SubscriptionController extends ChangeNotifier {

  StreamSubscription? authStream;
  StreamSubscription? subStream;
  List<StripeSubscription> subs = [];

  SubscriptionController() {
    init();
  }

  @override
  void dispose() {
    authStream?.cancel();
    subStream?.cancel();
    super.dispose();
  }

  void init() {
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {

      // user signed in -> initialize stream
      if(user != null) {
        String? uid = FirebaseAuth.instance.currentUser!.uid;

        subStream = FirebaseFirestore.instance
          .collection("user").doc(uid)
          .collection("subscriptions")
          .snapshots()
          .listen(onSubChange);
      }
      // user signed out, cancel streams and reset values
      else {
        subStream?.cancel();
        subs.clear();
      }
      notifyListeners();
    });
  }

  void onSubChange(QuerySnapshot event) {
    for (var docChange in event.docChanges)  {
      int index = subs.indexWhere((element) => element.subscriptionId == (docChange.doc.data() as Map<String,dynamic>)["subscriptionId"]);
      if(docChange.type == DocumentChangeType.added) {
        StripeSubscription sub = StripeSubscription.fromMap(docChange.doc.data() as Map<String, dynamic>);
        if(index != -1) {
          subs[index] = sub;
        }
        else {
          subs.add(sub);
        }
      }
      else if(docChange.type == DocumentChangeType.modified) {
        if(index != -1) {
          subs[index] = StripeSubscription.fromMap(docChange.doc.data() as Map<String, dynamic>);
        }
      }
      else if(docChange.type == DocumentChangeType.removed) {
        if(index != -1) {
          subs.removeAt(index);
        }
      }
    }
    notifyListeners();
  }


}