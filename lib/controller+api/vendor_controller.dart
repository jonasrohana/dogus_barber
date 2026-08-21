import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dogus_barber/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/colors.dart';
import '../utils/models.dart';

class VendorController extends ChangeNotifier {

  StreamSubscription? vendorStream;
  StreamSubscription? employeeStream;
  Vendor? _vendor;

  ColorTheme _colors = mainThemeDark;

  VendorController() {
    init();
  }

  void init() {
    // initialize all streams
    vendorStream = FirebaseFirestore.instance
      .collection("vendors").doc(fixedVendorId)
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
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    int ownIndex = _vendor!.employees.indexWhere((element) => element.id == uid);
    if(ownIndex > 0) {
      Employee emp = _vendor!.employees[ownIndex];
      _vendor!.employees.removeAt(ownIndex);
      _vendor!.employees.insert(0, emp);
    }

    notifyListeners();
  }

  Vendor? get getVendor => _vendor;

  Employee? getEmployeeById(String id) {
    int index = _vendor!.employees.indexWhere((element) => element.id == id);
    return index == -1 ? null : _vendor!.employees[index];
  }

  ColorTheme get getColors => _colors;


}