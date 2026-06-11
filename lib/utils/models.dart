
// chat models
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dogus_barber/utils/functions.dart';

import 'constants.dart';

class ChatUser {
  String name;
  String userId;
  String imageUrl;

  ChatUser({
    required this.name,
    required this.userId,
    required this.imageUrl,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      name: map['name'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? ""
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'imageUrl': imageUrl
    };
  }
}

class Room {
  String id;
  List<String> userIds;
  DateTime lastMessageTime;
  String lastMessage;
  String lastMessageSenderId;
  List<String> unread;
  List<ChatUser> chatUser;

  Room({
    required this.id,
    required this.userIds,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.unread,
    required this.chatUser,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userIds': userIds,
      'lastMessageTime': lastMessageTime,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'unread': unread,
      'chatUser': chatUser.map((user) => user.toMap()).toList(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      userIds: List<String>.from(map['userIds']),
      lastMessageTime: map['lastMessageTime'].toDate(),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      unread: List<String>.from(map['unread']),
      chatUser: List<ChatUser>.from(map['chatUser'].map((user) => ChatUser.fromMap(user))),
    );
  }
}

// vendor models
class Vendor {
  String id;
  String name;
  String imageUrl;
  String phoneNr;
  Place place;
  int themeId;
  List<String> openingTimes;
  List<Employee> employees = [];
  List<String> invited;
  List<String> admins;
  bool active;

  Vendor({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.phoneNr,
    required this.place,
    required this.openingTimes,
    required this.themeId,
    required this.admins,
    this.invited = const [],
    required this.active
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'phoneNr': phoneNr,
      'openingTimes': openingTimes,
      'place': place.toMap(),
      'themeId': themeId,
      'admins': admins,
      'active': active
    };
  }

  static Vendor fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      phoneNr: map['phoneNr'],
      place: Place.fromMap(map['place']),
      openingTimes: List<String>.from(map['openingTimes']),
      admins: List<String>.from(map['admins'] ?? []),
      themeId: map['themeId'] ?? 0,
      invited: List<String>.from(map['invited'] ?? []),
      active: map['active'] ?? false
    );
  }
}

class Place {
  double? latitude, longitude;
  String? street, city, plz, country, state;

  Place({this.latitude, this.longitude, this.street, this.city, this.plz, this.country, this.state});

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'street': street,
      'city': city,
      'plz': plz,
      'country': country,
      'state': state,
    };
  }

  static Place fromMap(Map<String, dynamic> map) {
    return Place(
      latitude: map['latitude'],
      longitude: map['longitude'],
      street: map['street'],
      city: map['city'],
      plz: map['plz'],
      country: map['country'],
      state: map['state'],
    );
  }

  bool get isValid {
    // Regular expression to check for one or more digits in the street name
    final hasNumber = RegExp(r'\d+').hasMatch(street ?? "");
    return latitude != null &&
      longitude != null &&
      street != null && street!.isNotEmpty && hasNumber &&
      city != null && city!.isNotEmpty &&
      plz != null && plz!.isNotEmpty &&
      country != null && country!.isNotEmpty &&
      state != null && state!.isNotEmpty;
  }

  @override
  String toString() {
    return 'Place{latitude: $latitude, longitude: $longitude, street: $street, city: $city, plz: $plz, country: $country, state: $state}';
  }
}

class Employee {

  // personal details
  String id;
  String name;
  String imageUrl;
  String email;
  String phoneNr;

  // calendar details
  List<String> workTimes;
  List<String> breakTimes;
  List<Service> services;
  int numBookingWeeks;

  Employee({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.email,
    required this.phoneNr,
    required this.workTimes,
    required this.breakTimes,
    required this.services,
    this.numBookingWeeks = 3
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'email': email,
      'phoneNr': phoneNr,
      'workTimes': workTimes,
      'breakTimes': breakTimes,
      'services': services.map((service) => service.toMap()).toList(),
      'numBookingWeeks': numBookingWeeks
    };
  }

  static Employee fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      email: map['email'],
      phoneNr: map['phoneNr'],
      workTimes: List<String>.from(map['workTimes']),
      breakTimes: List<String>.from(map['breakTimes']),
      services: List<Service>.from(map['services'].map((service) => Service.fromMap(service))),
      numBookingWeeks: map['numBookingWeeks'].toInt() ?? 3
    );
  }
}

class Service {
  String id;
  String name;
  double price;
  int duration;
  int color;

  Service({required this.id, required this.name, required this.price, required this.duration, required this.color});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'color': color,
    };
  }

  static Service fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'],
      price: map['price'].toDouble(),
      duration: map['duration'],
      color: map['color'],
    );
  }
}

// user
class UserProfile {
  String id;
  String name;
  String imageUrl;
  String email;
  String phoneNr;

  List<String>? waitingList;

  // vendor holding state lists
  List<String> disabledBy;
  List<String> verifiedBy;
  List<String> unverifiedBy;

  String vendorId;
  String platform;
  String signInMethod;

  DateTime? lastSignIn;
  List<String> noShow;

  UserProfile({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.email,
    required this.phoneNr,
    required this.disabledBy,
    required this.verifiedBy,
    required this.unverifiedBy,
    required this.vendorId,
    required this.platform,
    required this.signInMethod,
    this.lastSignIn,
    this.waitingList,
    required this.noShow
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'email': email,
      'phoneNr': phoneNr,
      'disabledBy': disabledBy,
      'verifiedBy': verifiedBy,
      'unverifiedBy': unverifiedBy,
      'vendorId': vendorId,
      'platform': platform,
      'signInMethod': signInMethod,
      'lastSignIn': DateTime.now(),
      if(waitingList != null)
        'waitingDates': waitingList,
      'noShow': noShow
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'] ?? "",
      email: map['email'],
      phoneNr: map['phoneNr'],
      disabledBy: List<String>.from(map['disabledBy'] ?? []),
      verifiedBy: List<String>.from(map['verifiedBy'] ?? []),
      unverifiedBy: List<String>.from(map['unverifiedBy'] ?? []),
      vendorId: fixedVendorId,
      platform: map['platform'] ?? "",
      signInMethod: map['signInMethod'] ?? "",
      lastSignIn: map.containsKey('lastSignIn') ? map['lastSignIn'].toDate() : null,
      waitingList: map.containsKey("waitingDates") ? List.from(map["waitingDates"]) : [],
      noShow: map.containsKey("noShow") ? List.from(map["noShow"]) : []
    );
  }
}


// appointments and holidays
class FixedAppointment {
  String id;
  int weekDay;
  double startTime;
  double endTime;
  String userId;
  String name;
  String phoneNr;
  String description;

  FixedAppointment({
    required this.id,
    required this.weekDay,
    required this.startTime,
    required this.endTime,
    required this.userId,
    required this.name,
    required this.phoneNr,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekDay': weekDay,
      'startTime': startTime,
      'endTime': endTime,
      'userId': userId,
      'name': name,
      'phoneNr': phoneNr,
      'description': description,
    };
  }

  static FixedAppointment fromMap(Map<String, dynamic> map) {
    return FixedAppointment(
      id: map['id'],
      weekDay: map['weekDay'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      userId: map['userId'],
      name: map['name'],
      phoneNr: map['phoneNr'] ?? '',
      description: map['description'],
    );
  }
}

class Appointment implements Comparable<Appointment> {
  String id;
  String date;
  String userId;
  double startTime;
  double endTime;
  String? name;
  String? phoneNr;
  String? service;
  double? price;
  List<int>? colors;
  String? employeeId;
  String? vendorId;
  String? holidayId;

  // payment params
  String? status;

  Appointment({
    required this.id,
    required this.date,
    required this.userId,
    required this.startTime,
    required this.endTime,
    this.name,
    this.price,
    this.phoneNr,
    this.service,
    this.colors,
    this.employeeId,
    this.vendorId,
    this.holidayId,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
      'name': name,
      'phoneNr': phoneNr,
      'service': service,
      'price': price,
      'employeeId': employeeId,
      'vendorId': vendorId,
      'holidayId': holidayId,
      'status': status,
    };
  }

  static Appointment fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      date: map['date'],
      userId: map['userId'],
      startTime: map['startTime'].toDouble(),
      endTime: map['endTime'].toDouble(),
      name: map['name'],
      price: (map['price'] ?? 0.0).toDouble(),
      phoneNr: map['phoneNr'],
      service: map['service'] ?? '',
      colors: List<int>.from(map['colors'] ?? [Colors.blueGrey.value]),
      employeeId: map['employeeId'],
      vendorId: map['vendorId'],
      holidayId: map['holidayId'],
      status: map.containsKey("status") ? map['status'] : "pending_cash",
    );
  }

  @override
  int compareTo(Appointment other) {
    // Parse dates
    DateTime thisDate = parseDateString(date);
    DateTime otherDate = parseDateString(other.date);

    // Compare dates
    int dateComparison = thisDate.compareTo(otherDate);
    if (dateComparison != 0) {
      return dateComparison;
    }

    // If dates are the same, compare by startTime
    if (startTime < other.startTime) {
      return -1;
    } else if (startTime > other.startTime) {
      return 1;
    } else {
      return 0;
    }
  }
}

class Holiday implements Comparable<Holiday> {
  String id;
  String name;
  DateTime startDate;
  DateTime endDate;

  Holiday({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  static Holiday fromMap(Map<String, dynamic> map) {
    return Holiday(
      id: map['id'],
      name: map['name'],
      startDate: map['startDate'].toDate(),
      endDate: map['endDate'].toDate(),
    );
  }

  @override
  int compareTo(Holiday other) {
    return startDate.compareTo(other.startDate);
  }
}

class BookAppointmentParams {
  final String vendorId;
  final String employeeId;
  final String date;
  final String id;
  final double startTime;
  final double endTime;
  final String name;
  final String phoneNr;
  final String service;
  final double price;
  final List<int> colors;

  // payment params
  final String status;
  String? subId;

  // Constructor
  BookAppointmentParams({
    required this.vendorId,
    required this.employeeId,
    required this.date,
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.name,
    required this.price,
    required this.phoneNr,
    required this.service,
    required this.colors,
    required this.status,
    this.subId
  });

  // toMap method
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'employeeId': employeeId,
      'date': date,
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'name': name,
      'price': price,
      'phoneNr': phoneNr,
      'service': service,
      'colors': colors,
      'status': status,
      if(subId != null) 'subId': subId
    };
  }
}

class DynamicImage {
  bool isFile;
  String? url;
  CroppedFile? croppedFile;

  DynamicImage({required this.isFile, this.url, this.croppedFile});
}


class StripeSubscription {
  String subscriptionId;
  String status;
  String productId;

  // retrieved from product metadata
  String productName;
  String matchOn;
  int monthlyQuota;

  // to track usage, format: mm-yy: num_bookings through sub
  Map<String, int> usedQuota;

  StripeSubscription({
    required this.subscriptionId,
    required this.status,
    required this.productId,
    required this.productName,
    required this.matchOn,
    required this.monthlyQuota,
    required this.usedQuota,
  });

  factory StripeSubscription.fromMap(Map<String, dynamic> map) {
    return StripeSubscription(
      subscriptionId: map['subscriptionId'] ?? '',
      status: map['status'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      matchOn: map['matchOn'] ?? '',
      monthlyQuota: (map['monthlyQuota'] ?? 0).toInt(),
      usedQuota: map['usedQuota'] != null ? Map<String, int>.from(map['usedQuota']) : {},
    );
  }
}

class StripeProduct {
  final String id;
  final String name;
  final String description;
  final String defaultPrice;
  final bool active;
  final Map<String, dynamic> metadata;

  StripeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPrice,
    required this.active,
    required this.metadata,
  });

  factory StripeProduct.fromMap(Map<String, dynamic> map) {
    return StripeProduct(
      id: map["id"] ?? "",
      name: map["name"] ?? "",
      description: map["description"] ?? "",
      defaultPrice: map["default_price"] ?? "",
      active: map["active"] ?? false,
      metadata: Map<String, dynamic>.from(map["metadata"] ?? {}),
    );
  }
}

