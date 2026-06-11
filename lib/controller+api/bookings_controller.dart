import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/models.dart';

class BookingsController extends ChangeNotifier {

  StreamSubscription? stream;
  List<Appointment> appointments = [];

  BookingsController() {
    init();
  }

  void init() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      // user signed in -> fetch bookings
      if(user != null) {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        stream = FirebaseFirestore.instance
          .collectionGroup("privateAppointments")
          .where("userId", isEqualTo: uid)
          .snapshots()
          .listen(onAppointmentChange);
      }
      // user signed out, cancel streams and reset values
      else {
        stream?.cancel();
        appointments.clear();
      }
      notifyListeners();
    });
  }

  void onAppointmentChange(QuerySnapshot event) {
    for (var docChange in event.docChanges)  {
      if(docChange.type == DocumentChangeType.added) {
        int index = appointments.indexWhere((element) => element.id == docChange.doc.id);
        Appointment app = Appointment.fromMap(docChange.doc.data() as Map<String, dynamic>, docChange.doc.id);
        if(index != -1) {
          appointments[index] = app;
        }
        else {
          appointments.add(app);
        }
      }
      else if(docChange.type == DocumentChangeType.modified) {
        int index = appointments.indexWhere((element) => element.id == docChange.doc.id);
        if(index != -1) {
          appointments[index] = Appointment.fromMap(docChange.doc.data() as Map<String, dynamic>, docChange.doc.id);
        }
      }
      else if(docChange.type == DocumentChangeType.removed) {
        int index = appointments.indexWhere((element) => element.id == docChange.doc.id);
        if(index != -1) {
          appointments.removeAt(index);
        }
      }
    }
    appointments.sort();
    notifyListeners();
  }

  String? isDateTaken(String date, String employeeId) {
    List<Appointment> dateAppointments = appointments.where((appointment) => appointment.date == date).toList();
    int totalAppointments = dateAppointments.length;
    bool employeeHasAppointment = dateAppointments.any((appointment) => appointment.employeeId == employeeId);

    // Condition 1: If there are already 2 appointments on this date, return a message
    if (totalAppointments >= 2) {
      return "twoAppointments";
    }

    // Condition 2: If the employee already has an appointment on this date, return a message
    if (employeeHasAppointment) {
      return "appSameEmployee";
    }

    // If neither condition is met, the date is available for booking
    return null;
  }

}