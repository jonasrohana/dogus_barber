import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'colors.dart';
import 'models.dart';

bool isFutureDate(String dateString) {
  final parts = dateString.split('.');

  if (parts.length != 3) {
    return false;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return false;
  }

  final date = DateTime(year, month, day);
  final today = DateTime.now();

  final todayStart = DateTime(today.year, today.month, today.day);
  final dateStart = DateTime(date.year, date.month, date.day);

  return dateStart.isAfter(todayStart);
}

String dateTimeToQuotaString(DateTime d) => "${d.month.toString().padLeft(2, "0")}-${d.year}";

List<StripeSubscription> getActiveSubs(List<StripeSubscription> subs) {
  return subs.where((s) => ["active","start_next_month","past_due"].contains(s.status)).toList();
}

Map<String,dynamic> getDesignBySubStatus(String status) {
  DateTime nextMonth = Jiffy.now().add(months: 1).dateTime;
  switch(status) {
    case "active": return { "name": "Aktiv", "color": Colors.green };
    case "start_next_month": return { "name": "Ab ${"months.month_${nextMonth.month}".tr()}", "color": Colors.orange };
    case "past_due": return { "name": "Zahlung offen", "color": Colors.red };
    default: return { "name": "FEHLER", "color": Colors.red };
  }
}

Color getColorByStatus(String status) {
  switch(status) {
    case "paid_sub": return Colors.green;
    case "paid_cash": return Colors.green;
    case "paid_card": return Colors.green;
    case "pending_cash": return Colors.yellow;
    case "reserved": return Colors.orange;
    default: return Colors.yellow;
  }
}

Future<void> openStoreListing() async {
  final Uri uri = Platform.isAndroid
      ? Uri.parse('market://details?id=rohana.apps.dogus_barber')
      : Uri.parse('itms-apps://itunes.apple.com/app/id6483612114');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }

  final Uri fallback = Platform.isAndroid
      ? Uri.parse(
    'https://play.google.com/store/apps/details?id=rohana.apps.dogus_barber',
  )
      : Uri.parse('https://apps.apple.com/de/app/z-the-master-studio/id6483612114');

  await launchUrl(fallback, mode: LaunchMode.externalApplication);
}

bool isVersionLower(String current, String required) {
  List<int> parse(String v) =>
      v.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  final a = parse(current);
  final b = parse(required);

  final maxLen = a.length > b.length ? a.length : b.length;
  while (a.length < maxLen) {
    a.add(0);
  }
  while (b.length < maxLen) {
    b.add(0);
  }

  for (int i = 0; i < maxLen; i++) {
    if (a[i] < b[i]) return true;
    if (a[i] > b[i]) return false;
  }
  return false;
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

bool doesAppointmentCollide(List<FixedAppointment> existingAppointments, FixedAppointment newAppointment) {
  for (var existingAppointment in existingAppointments) {
    // Check if the appointments are on the same weekday
    if (existingAppointment.weekDay == newAppointment.weekDay) {
      // Check for time overlap
      bool startsDuringAnother = newAppointment.startTime < existingAppointment.endTime &&
          newAppointment.startTime >= existingAppointment.startTime;
      bool endsDuringAnother = newAppointment.endTime > existingAppointment.startTime &&
          newAppointment.endTime <= existingAppointment.endTime;
      bool surroundsAnother = newAppointment.startTime <= existingAppointment.startTime &&
          newAppointment.endTime >= existingAppointment.endTime;

      if (startsDuringAnother || endsDuringAnother || surroundsAnother) {
        return true; // Collision detected
      }
    }
  }

  return false; // No collision detected
}

bool doesUserHaveFixedAppointmentOnThisDay(List<FixedAppointment> existingAppointments, FixedAppointment newAppointment) {
  for (var existingAppointment in existingAppointments) {
    // Check if the appointments are on the same weekday
    if (existingAppointment.weekDay == newAppointment.weekDay) {

      if(newAppointment.userId == existingAppointment.userId) {
        return true;
      }
    }
  }

  return false; // No collision detected
}

List<DateTime> getWeeksForRange(DateTime start) {
  List<DateTime> week = [];

  DateTime date = start;
  DateTime end = start;
  int diff = date.weekday - 1;
  date = date.subtract(Duration(days: diff));

  diff = 7 - end.weekday;
  end = end.add(Duration(days: diff));

  while(date.difference(end).inDays <= 0) {

    if (date.weekday == 1 && week.isNotEmpty) {
      break;
    }

    week.add(date);

    date = date.add(const Duration(days: 1));
  }

  return week;
}

Color getDayColor(DateTime d, DateTime selected, ColorTheme colors) {
  DateTime now = DateTime.now();
  if(d.day == selected.day && d.month == selected.month && d.year == selected.year) {
    return colors.primary;
  } else if(isToday(d)) {
    return Colors.transparent;
  }
  else if(d.isBefore(now)) {
    return Colors.grey;
  }
  return colors.backgroundColor;
}

TimeOfDay stringToTime(String s) => TimeOfDay(hour:int.parse(s.split(".")[0]),minute: int.parse(s.split(".")[1]));

String doubleToEuroString(double d) => NumberFormat.currency(locale: "de", symbol: "€").format(d);

double euroStringToDouble(String s) => double.parse(s.replaceAll(".", "").replaceAll("€", "").replaceAll(",", "."));

double getFileSizeInMB(int bytes) {
  if (bytes <= 0) return 0;
  return bytes / (1024 * 1024);
}

String durationString(int dur) {
  if (dur % 60 == 0) { // full hour
    int hours = dur ~/ 60;
    if(hours == 1) {
      return 'durations.hour'.tr(args: [hours.toString()]);
    }
    return 'durations.hours'.tr(args: [hours.toString()]);
  }
  else {
    int hours = dur ~/ 60;
    int minutes = dur % 60;
    if (hours > 0) {
      // hour + minutes
      if(hours == 1) {
        return 'durations.hour_minutes'.tr(args: [hours.toString(), minutes.toString()]);
      }
      return 'durations.hours_minutes'.tr(args: [hours.toString(), minutes.toString()]);
    }
    else {
      // only minutes
      return 'durations.minutes'.tr(args: [minutes.toString()]);
    }
  }
}

String shortDurationString(int dur) {
  if (dur <= 0) return '0m';

  String result = '';
  int hours = dur ~/ 60;
  int minutes = dur % 60;

  if (hours > 0) result += '${hours}h ';
  if (minutes > 0) result += '${minutes}m';

  return result.trim();
}

String getTimeString(DateTime date) {
  final compare = DateTime(date.year, date.month, date.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if(compare == today) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  else if(compare == yesterday) {
    return 'dates.yesterday'.tr();
  }
  else {
    return "${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}";
  }
}

double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute/60.0;

String timeToString(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

String firestoreString(DateTime d) => "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

DateTime parseDateString(String dateString) {
  // Date format: "27.08.1997"
  List<String> parts = dateString.split('.');
  int day = int.parse(parts[0]);
  int month = int.parse(parts[1]);
  int year = int.parse(parts[2]);
  return DateTime(year, month, day);
}

String formatTime(TimeOfDay time) {
  double hour = time.hour.toDouble();
  double minuteFraction = time.minute / 60.0;
  return hour.toString() + minuteFraction.toString().substring(1);
}

TimeOfDay toTime(double value) {
  int flooredValue = value.floor();
  double decimalValue = value - flooredValue;
  int hour = flooredValue % 24;
  int minute = (decimalValue * 60).round();
  return TimeOfDay(hour: hour, minute: minute);
}

String dateFormat(DateTime d) {

  String weekday = "weekdays.weekday_${d.weekday}".tr().substring(0,2);
  String month = "months.month_${d.month}".tr();

  return "$weekday, ${d.day}. $month";
}

String createLastAccessString(DateTime date) {
  DateTime now = DateTime.now();
  DateTime yesterday = now.subtract(const Duration(days: 1));
  DateTime oneWeekAgo = now.subtract(const Duration(days: 7));
  DateTime fourWeeksAgo = now.subtract(const Duration(days: 28));

  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'dates.today'.tr();
  }
  else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
    return 'dates.yesterday'.tr();
  }
  else if (date.isAfter(oneWeekAgo)) {
    return plural('dates.days', now.difference(date).inDays);
  }
  else if (date.isAfter(fourWeeksAgo)) {
    int weeks = now.difference(date).inDays ~/ 7;
    return plural('dates.weeks', weeks);
  }
  else {
    return '${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}';
  }
}

bool isToday(DateTime d) {
  return DateTime.now().difference(d).inDays == 0 && d.day == DateTime.now().day;
}

bool isPastDue(DateTime selected) {
  DateTime tmp = DateTime.now();
  DateTime today = DateTime(tmp.year, tmp.month, tmp.day, 0, 0);
  return selected.isBefore(today);
}

bool isWeekOver(DateTime d) {
  int diff = 7 - d.weekday;
  d = d.add(Duration(days: diff));
  DateTime tmp = DateTime.now();
  DateTime today = DateTime(tmp.year, tmp.month, tmp.day, 0, 0);
  return d.isBefore(today);
}

DateTime parseDate(String date) {
  List<String> parts = date.split(".");
  return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
}

bool isOlderDateString(Appointment app) {
  DateTime firstDate = parseDate(app.date);
  DateTime now = DateTime.now();
  return firstDate.isBefore(DateTime(now.year, now.month, now.day)) ||
      (firstDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day)) && app.startTime < toDouble(TimeOfDay.now()));
}

bool isDeleteDateString(Appointment app) {
  DateTime firstDate = parseDate(app.date);
  DateTime threeDaysAgo = DateTime.now().subtract(const Duration(days: 14));
  return firstDate.isBefore(DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day));
}

double timeStringToDouble(String time) {
  var parts = time.split('.');
  int hours = int.parse(parts[0]);
  double minutes = (parts.length > 1 ? int.parse(parts[1]) : 0) / 60.0;
  return hours + minutes;
}

// appointment creating algorithms
class TimeSlot {
  double start;
  double end;

  TimeSlot({required this.start, required this.end});

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('startTime') || !map.containsKey('endTime')) {
      throw const FormatException('Map must contain both a start and an end key.');
    }
    double start = map['startTime'].toDouble();
    double end = map['endTime'].toDouble();

    return TimeSlot(start: start, end: end);
  }
}

List<TimeOfDay> getOpeningTimes(DateTime selected, List<String> openingTimes) {

  // Retrieve opening times for the selected weekday.
  // Note: `weekday` in Dart's DateTime returns an int where 1 is Monday and 7 is Sunday.
  String dayOpeningTimes = openingTimes[selected.weekday - 1];

  // Check if the place is closed on the selected day.
  if (dayOpeningTimes.isEmpty) {
    return [];
  }

  // Split the opening hours and convert them to TimeOfDay.
  List<String> times = dayOpeningTimes.split("-");
  List<TimeOfDay> retVal = times.map((time) {
    List<String> hourMinute = time.split(".");
    return TimeOfDay(hour: int.parse(hourMinute[0]), minute: int.parse(hourMinute[1]));
  }).toList();

  return retVal;
}

bool isOccupied(TimeSlot timeSlot, List<TimeSlot> timeSlots) {
  return timeSlots.any((existingTimeSlot) {
    // Check if there's any overlap between the given timeSlot and any existing timeSlot
    bool startsDuringAnother = timeSlot.start >= existingTimeSlot.start &&
        timeSlot.start < existingTimeSlot.end;
    bool endsDuringAnother = timeSlot.end > existingTimeSlot.start &&
        timeSlot.end <= existingTimeSlot.end;
    bool encompassesAnother = timeSlot.start <= existingTimeSlot.start &&
        timeSlot.end >= existingTimeSlot.end;

    return startsDuringAnother || endsDuringAnother || encompassesAnother;
  });
}

List<TimeSlot> parseBreakTimes(String breakTimes) {
  List<TimeSlot> slots = [];

  // Split the break times string into individual time slots
  var timeSlots = breakTimes.split(';');

  for (var slot in timeSlots) {
    if (slot.isNotEmpty) {
      // Split each slot by '-' to get start and end times
      var times = slot.split('-');
      if (times.length == 2) {
        // Convert start and end times to double
        double startTime = timeStringToDouble(times[0]);
        double endTime = timeStringToDouble(times[1]);

        // Create a TimeSlot instance and add it to the list
        slots.add(TimeSlot(start: startTime, end: endTime));
      }
    }
  }

  return slots;
}

double addMinutes(double time, int minutes) {
  int hours = time.toInt(); // Extracts the hour part
  double decimalPart = time - hours; // Extracts the minute part as a fraction of an hour
  int totalMinutes = (decimalPart * 60).toInt() + minutes; // Converts fractional hour to minutes and adds the minutes

  // Calculate the new time, adjusting for overflow of 60 minutes into an hour
  int additionalHours = totalMinutes ~/ 60;
  int remainingMinutes = totalMinutes % 60;

  double newTime = hours + additionalHours + remainingMinutes / 60.0; // Converts back to double, with minutes as fraction
  return newTime;
}

List<TimeSlot> getFreeAppointments(Employee? employee, List<DocumentSnapshot> appointments, DateTime selected, int duration) {
  if(employee == null) {
    return [];
  }

  List<TimeOfDay> openingTimes = getOpeningTimes(selected, employee.workTimes);

  // closed days, no service selected -> break out
  if(openingTimes.isEmpty || duration == 0) {
    return [];
  }

  List<TimeSlot> blockedSlots = [];

  // get break times and block them, add all booked appointments
  blockedSlots.addAll(parseBreakTimes(employee.breakTimes[selected.weekday-1]));
  blockedSlots.addAll(appointments.map((e) => TimeSlot.fromMap(e.data() as Map<String,dynamic>)));

  // create all possible slots
  double start = toDouble(openingTimes.first);
  double end = toDouble(openingTimes.last);
  List<TimeSlot> allSlots = [];
  List<TimeSlot> freeSlots = [];

  var begin = start;
  while (begin < end) {
    final go = begin;
    final stop = addMinutes(begin, duration); // Use the addMinutes function
    final next = addMinutes(begin, 15); // Increment by 15 minutes for the next slot

    if (stop > end) break;

    allSlots.add(TimeSlot(start: go, end: stop));
    begin = next;
  }

  // filter out occupied slots
  for(var t in allSlots) {
    if(!isOccupied(t, blockedSlots)) {
      freeSlots.add(t);
    }
  }

  // if selected day is today, filter termine with starting time which is already past due
  if(isToday(selected)) {
    TimeOfDay now = TimeOfDay.now();
    freeSlots = freeSlots.where((t) => t.start > toDouble(now)).toList();
  }

  return freeSlots;
}

List<TimeSlot> computeFreeToChangeSlots(Employee? employee, List<DocumentSnapshot> appointments, DateTime selected, int duration, Appointment termin) {
  if(employee == null) {
    return [];
  }

  List<TimeOfDay> openingTimes = getOpeningTimes(selected, employee.workTimes);

  // closed days, no service selected -> break out
  if(openingTimes.isEmpty || duration == 0) {
    return [];
  }

  List<TimeSlot> blockedSlots = [];

  // get break times and block them, add all booked appointments
  blockedSlots.addAll(parseBreakTimes(employee.breakTimes[selected.weekday-1]));
  blockedSlots.addAll(appointments.map((e) => TimeSlot.fromMap(e.data() as Map<String,dynamic>)));

  // create all possible slots
  double start = toDouble(openingTimes.first);
  double end = toDouble(openingTimes.last);
  List<TimeSlot> allSlots = [];
  List<TimeSlot> freeSlots = [];

  var begin = start;
  while (begin < end) {
    final go = begin;
    final stop = addMinutes(begin, duration); // Use the addMinutes function
    final next = addMinutes(begin, 15); // Increment by 15 minutes for the next slot

    if (stop > end) break;

    allSlots.add(TimeSlot(start: go, end: stop));
    begin = next;
  }

  for(int i = 0; i < blockedSlots.length; i++){
    if(blockedSlots[i].start == termin.startTime && blockedSlots[i].end == termin.endTime){
      blockedSlots.removeAt(i);
    }
  }

  // filter out occupied slots
  for(var t in allSlots) {
    if(!isOccupied(t, blockedSlots)) {
      freeSlots.add(t);
    }
  }

  for(int i = 0; i < freeSlots.length; i++){
    if(freeSlots[i].start == termin.startTime && freeSlots[i].end == termin.endTime){
      freeSlots.removeAt(i);
    }
  }

  // if selected day is today, filter termine with starting time which is already past due
  if(isToday(selected)) {
    TimeOfDay now = TimeOfDay.now();
    freeSlots = freeSlots.where((t) => t.start > toDouble(now)).toList();
  }

  return freeSlots;
}


String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

bool isAtLeast24HoursBefore(DateTime date, double startTime) {
  // Extract hours and minutes from startTime
  int hours = startTime.truncate();
  int minutes = ((startTime - hours) * 60).round();

  // Construct the target DateTime
  DateTime targetDateTime = DateTime(date.year, date.month, date.day, hours, minutes);

  // Get the current DateTime
  DateTime now = DateTime.now();

  // Check if the difference is at least 24 hours
  return targetDateTime.difference(now).inHours >= 24;
}