import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dogus_barber/application/vendor/bookings_tab/reschedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/functions.dart';
import '../../../utils/models.dart';
import '../../../utils/widgets.dart';
import '../../chat/chat_detail.dart';

class AppointmentsTab2D extends StatefulWidget {
  const AppointmentsTab2D({super.key});

  @override
  State<AppointmentsTab2D> createState() => _AppointmentsTab2DState();
}

class _AppointmentsTab2DState extends State<AppointmentsTab2D> {

  double pixelsPerMinute = 2.4; // 1 minute = 2 px
  List<Employee> employees = [];

  String uid = FirebaseAuth.instance.currentUser!.uid;
  AutoScrollController controller3 = AutoScrollController(axis: Axis.horizontal);
  DateTime selectedDate = DateTime.now();

  void setDate(DateTime d) {
    selectedDate = d;
    setStream();
  }

  late Stream dayStream;
  final ScrollController controller = ScrollController();
  final ScrollController controller2 = ScrollController();

  void setStream() {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    dayStream = FirebaseFirestore.instance
        .collectionGroup("privateAppointments")
        .where("vendorId", isEqualTo: vendor.id)
        .where("date", isEqualTo: firestoreString(selectedDate))
        .snapshots();

    print(dayStream);
    setState(() {});
  }

  @override
  void initState() {
    if(selectedDate.hour > 20) {
      selectedDate = selectedDate.add(const Duration(days: 1));
    }
    setStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    List<TimeOfDay> timeOfDays = getOpeningTimes(selectedDate, vendor.openingTimes);
    List<Widget> timeSlots = [];

    if(timeOfDays.isNotEmpty) {
      for (double hour = timeOfDays.first.minute != 0 ? (timeOfDays.first.hour + (timeOfDays.first.minute / 60.0)).toDouble() : timeOfDays.first.hour.toDouble(); hour <= (timeOfDays.last.hour + (timeOfDays.last.minute / 60.0)).toDouble(); hour = hour + 0.5) {
        String hourString = doubleToTimeString(hour);
        timeSlots.add(Container(
            height: 30*pixelsPerMinute,
            width: 60,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.textColor.withValues(alpha: 0.7), width: 1),
              ),
            ),
            child: Text(hourString, style:  TextStyle(fontSize: 12, color: colors.textColor.withValues(alpha: 0.7)))));
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: timeOfDays.isEmpty ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        dateWidgets,
        const SizedBox(height: 5),
        StreamBuilder(
          stream: dayStream,
          builder: (context, snapshot) {

            if (snapshot.hasError) {

              print(snapshot);
              return const Text('Es ist ein Fehler aufgetreten.');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            List<Appointment> mapped = snapshot.data?.docs.map<Appointment>((e) =>
                Appointment.fromMap(e.data() as Map<String, dynamic>, e.id)).toList();

            Map<String, List<Appointment>> apps = {};
            employees = vendor.employees;
            for(var em in employees){
              List<Appointment> empApps = [];
              for(var ap in mapped){
                if(ap.employeeId == em.id){
                  empApps.add(ap);
                }
              }
              empApps.sort((a, b) => a.startTime.compareTo(b.startTime));
              apps.addAll({em.id: empApps});
            }
            List<String> entries = apps.keys.toList();

            if(timeOfDays.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const ThemedSvgImage(assetName: "empty", height: 150),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'general.closedVendor'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: colors.textColor.withValues(alpha: 0.5),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4
                      ),
                    ),
                  )
                ],
              );
            }

            return Expanded(
              child: Scrollbar(
                controller: controller2,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: controller2,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 60,),
                          ...List.generate(employees.length, (index) {
                            Employee emp = employees[index];
                            return Container(
                              width: 100,
                              padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 2.5),
                              decoration: BoxDecoration(
                                  color: colors.buttonColor,
                                  border: Border.all(color: colors.textColor.withValues(alpha: 0.2), width: 0.5)
                              ),
                              child: Column(
                                children: [
                                  ProfileImageCircle(emp.imageUrl, 35),
                                  TextScroll(
                                    emp.name.split(" ").first,
                                    style: TextStyle(
                                        color: colors.textColor,
                                        fontSize: 11, fontWeight: FontWeight.w500
                                    ),
                                    mode: TextScrollMode.bouncing,
                                    delayBefore: const Duration(milliseconds: 2000),
                                    pauseBetween: const Duration(milliseconds: 1000),
                                    velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      Expanded(
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            controller: controller,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: timeSlots,
                                ),
                                ...List.generate(entries.length, (i) {
                                  if(apps[entries[i]]!.isEmpty) {
                                    return Container(height: 90,
                                      width: 100,
                                      color: Colors.transparent,
                                    );
                                  }
                                  final empAppointments = apps[entries[i]]!;
                                  return buildAppointmentColumn(
                                      earliest: (timeOfDays.first.hour + (timeOfDays.first.minute / 60.0)),
                                      latest:  (timeOfDays.last.hour +  (timeOfDays.last.minute / 60.0)),
                                      appointments: empAppointments, contextChat: context
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  Widget buildAppointmentColumn({
    required double earliest,
    required double latest,
    required List<Appointment> appointments,
    required BuildContext contextChat
  }) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    List<Widget> columnWidgets = [];

    double lastEnd = earliest;

    for (var appt in appointments) {
      // 1) gap between lastEnd and this appointment's start
      double gapMinutes = (appt.startTime - lastEnd) * 60;
      if (gapMinutes > 0) {
        columnWidgets.add(SizedBox(
          height: gapMinutes * pixelsPerMinute, // empty space
        ));
      }

      if(appt.holidayId != null) {
        // 2) appointment container
        double durationMinutes = (appt.endTime - appt.startTime) * 60;
        columnWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              height: durationMinutes * pixelsPerMinute,
              width: 100,
              decoration: BoxDecoration(
                  color: colors.buttonColor.withValues(alpha: 0.15),
                  border: Border.all(color: colors.textColor.withValues(alpha: 0.2), width: 0.5)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextScroll(
                    "general.holiday".tr(),
                    style: TextStyle(
                        color: colors.textColor,
                        fontSize: 10, fontWeight: FontWeight.w600
                    ),
                    mode: TextScrollMode.endless,
                    delayBefore: const Duration(milliseconds: 4000),
                    pauseBetween: const Duration(milliseconds: 2000),
                    velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
                  ),
                  Text(
                    'general.allDay'.tr(),
                    style: TextStyle(color: colors.textColor, fontSize: 10),
                  ),
                ],
              ),
            ));
      }
      else {
        // 2) appointment container
        double durationMinutes = (appt.endTime - appt.startTime) * 60;
        columnWidgets.add(
            GestureDetector(
              onTap: () => showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: colors.buttonColor,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                context: context,
                builder: (BuildContext context) => ActionSheet(
                  actions: [
                    ActionSheetAction(
                        icon: Ionicons.information,
                        name: "terminInfo".tr(),
                        enabled: true,
                        onPressed: () async => await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AppointmentSummary(appointment: appt)),
                        )
                    ),
                    ActionSheetAction(
                        icon: Ionicons.chatbubble_ellipses_outline,
                        name: "actions.sendMessage".tr(),
                        enabled: appt.userId.isNotEmpty,
                        onPressed: () => navigateToChat(contextChat, appt.userId, true)
                    ),
                    ActionSheetAction(
                        icon: Ionicons.swap_horizontal,
                        name: "actions.reschedule".tr(),
                        enabled: true,
                        onPressed: () async => await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChangeAppointmentsTab(app: appt)),
                        )
                    ),
                    ActionSheetAction(
                        icon: Ionicons.call_outline,
                        name: "actions.call".tr(),
                        enabled: (appt.phoneNr ?? "").isNotEmpty,
                        onPressed: () => launchUrlString("tel://${appt.phoneNr!}")
                    ),
                    ActionSheetAction(
                        icon: Ionicons.lock_closed_outline,
                        destructive: true,
                        name: "actions.block".tr(),
                        enabled: appt.userId.isNotEmpty,
                        onPressed: () async => await showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                NativeDialog(
                                  title: "actions.block".tr(),
                                  content: "actions.blockQuestion".tr(args: [appt.name!]),
                                  buttonTextOne: "general.yes".tr(),
                                  buttonTextTwo: "general.no".tr(),
                                  buttonOne: () {
                                    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
                                    blockUser.call({
                                      'userId': appt.userId,
                                      'vendorId': vendor.id
                                    });
                                    Navigator.pop(context);
                                  },
                                  buttonTwo: () => Navigator.pop(context),
                                  buttonOneRed: true,
                                )
                        )
                    ),
                    ActionSheetAction(
                        icon: Ionicons.close_outline,
                        name: "actions.cancel".tr(),
                        destructive: true,
                        onPressed: () async => await showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                NativeDialog(
                                  title: "actions.cancel".tr(),
                                  content: "actions.cancelMessage".tr(),
                                  buttonTextOne: "general.yes".tr(),
                                  buttonTextTwo: "general.no".tr(),
                                  buttonOne: () {
                                    FirebaseFirestore.instance
                                        .collection("vendors").doc(appt.vendorId)
                                        .collection("employees").doc(appt.employeeId)
                                        .collection("privateAppointments").doc(appt.id)
                                        .delete();
                                    Navigator.pop(context);
                                  },
                                  buttonTwo: () => Navigator.pop(context),
                                  buttonOneRed: true,
                                )
                        )
                    ),
                  ],
                ),
              ),
              child: Container(
                height: durationMinutes * pixelsPerMinute,
                width: 100,
                decoration: BoxDecoration(
                    color: colors.buttonColor,
                    border: Border.all(color: colors.textColor.withValues(alpha: 0.2), width: 0.5)
                ),
                child: Row(
                  children: [
                    if(appt.colors != null && appt.colors!.isNotEmpty)
                      SizedBox(
                        width: 5,
                        child: Column(
                          children: [
                            for (var color in appt.colors!)
                              Expanded(child: Container(color: Color(color).withValues(alpha: 0.75)))
                          ],
                        ),
                      ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextScroll(
                              appt.name != null ? appt.name! : "general.noName".tr(),
                              style: TextStyle(
                                  color: colors.textColor,
                                  fontSize: 11, fontWeight: FontWeight.w800
                              ),
                              mode: TextScrollMode.endless,
                              delayBefore: const Duration(milliseconds: 4000),
                              pauseBetween: const Duration(milliseconds: 2000),
                              velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
                            ),
                            TextScroll(
                              appt.service != null ? appt.service! : "noService".tr(),
                              style: TextStyle(
                                  color: colors.textColor,
                                  fontSize: 11, fontWeight: FontWeight.w600
                              ),
                              mode: TextScrollMode.endless,
                              delayBefore: const Duration(milliseconds: 4000),
                              pauseBetween: const Duration(milliseconds: 2000),
                              velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
                            ),
                            Text(
                              '${doubleToTimeString(appt.startTime)} - ${doubleToTimeString(appt.endTime)}',
                              style: TextStyle(color: colors.textColor, fontSize: 11),
                            ),
                            if(appt.price != null)
                              Text(
                                doubleToEuroString(appt.price!),
                                style: TextStyle(color: colors.textColor, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));

        // update lastEnd
        lastEnd = appt.endTime;
      }


    }
    // 3) optional: leftover gap from the last appointment to "latest" time
    double leftover = (latest - lastEnd) * 60;
    if (leftover > 0) {
      columnWidgets.add(SizedBox(height: leftover * pixelsPerMinute));
    }


    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnWidgets,
    );
  }

  Future<void> showDatePicker() async {
    ColorTheme colors = Provider.of<UserController>(context,listen: false).getColors;
    DateTime initialDate = selectedDate;
    final retVal = await showModalBottomSheet(
      backgroundColor: colors.buttonColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (BuildContext context) => DatePickerSheet(
          initialDate: initialDate, view: DateRangePickerView.month),
    );
    if (retVal != null && retVal is DateTime) {
      setDate(retVal);
    }
  }


  Widget get dateWidgets {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 20),
      decoration: BoxDecoration(
        color: colors.buttonColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () => setDate(selectedDate.subtract(const Duration(days: 7))),
                  icon: Icon(Ionicons.arrow_back, size: 25, color: colors.textColor),
                ),
                Expanded(
                  child: Center(
                    child: TextButton(
                      onPressed: showDatePicker,
                      child: Text(
                        isToday(selectedDate) ? "general.today".tr() : dateFormat(selectedDate),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: colors.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () => setDate(selectedDate.add(const Duration(days: 7))),
                  icon: Icon(Ionicons.arrow_forward, size: 25, color: colors.textColor),
                ),
              ]
          ),
          const SizedBox(height: 10),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: getWeekWidgets(getWeeksForRange(selectedDate))
          )
        ],
      ),
    );
  }

  List<Widget> getWeekWidgets(List<DateTime> dates) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    List<Widget> widgetList = [];
    for (var d in dates) {
      bool isSelected = d.day == selectedDate.day && d.month == selectedDate.month && d.year == selectedDate.year;
      Color dayTextColor = colors.textColor;
      if(isToday(d) && !isSelected) {
        dayTextColor = colors.primary;
      }
      else if(isSelected) {
        dayTextColor = colors.primaryText;
      }
      Widget button = InkWell(
        onTap: () {
          if(!isSelected){
            setDate(d);
          }
        },
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
              color: getDayColor(d,selectedDate,colors),
              shape: BoxShape.circle,
              border: isToday(d) ? Border.all(color: colors.primary, width: 0.5) : null
          ),
          child: Center(
            child: Text(
              "${d.day}",
              style: TextStyle(
                  fontSize: 15,
                  color: dayTextColor
              ),
            ),
          ),
        ),
      );
      widgetList.add(button);
    }
    return widgetList;
  }

}

class AppointmentSummary extends StatefulWidget {

  final Appointment appointment;

  const AppointmentSummary({super.key, required this.appointment});

  @override
  State<AppointmentSummary> createState() => _AppointmentSummaryState();
}

class _AppointmentSummaryState extends State<AppointmentSummary> {

  late Appointment appointment = widget.appointment;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "terminInfo".tr(),
          style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget get body {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: summary,
          ),
        ),
        //submitButton
      ],
    );
  }

  Widget get summary {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Column(
        children: [
          pageTitle("general.summary".tr()),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: colors.buttonColor
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                displayText("general.date".tr(), appointment.date, true),
                Container(margin: const EdgeInsets.only(left: 20, right: 85), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                displayText("general.timeSlot".tr(), "${timeToString(toTime(appointment.startTime))} - ${timeToString(toTime(appointment.endTime))}", false),
                Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                displayText("services.services".tr(), appointment.service!.isNotEmpty ? appointment.service! : "Keine Dienstleistung angegeben", false),
                Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                displayText("services.price".tr(), doubleToEuroString(appointment.price!), false),
                Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                displayText("general.duration".tr(), decimalHoursToString(appointment.endTime-appointment.startTime), false),
                if(appointment.name != null)
                  ...[
                    Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                    displayText("general.customer".tr(), appointment.name!, false),
                  ],
                const SizedBox(height: 5),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget displayText(String label, String text, bool showImage) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Employee? emp = Provider.of<UserController>(context, listen: false).getEmployeeById(appointment.employeeId!);
    Widget imageWidget = Container();
    if(showImage) {
      imageWidget =  ClipOval(
          child: ProfileImageCircle(emp!.imageUrl, 50)
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: colors.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                      color: colors.textColor.withValues(alpha: 0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500
                  ),
                )
              ],
            ),
          ),
          if(showImage)
            Column(
              children: [
                imageWidget,
                const SizedBox(height: 2),
                TextScroll(
                  emp!.name.split(" ").first,
                  style: TextStyle(
                      color: colors.textColor.withValues(alpha: 0.6),
                      fontSize: 10, fontWeight: FontWeight.w500
                  ),
                  mode: TextScrollMode.bouncing,
                  delayBefore: const Duration(milliseconds: 2000),
                  pauseBetween: const Duration(milliseconds: 1000),
                  velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget pageTitle(String text) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      padding: const EdgeInsets.only(left: 15),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
            color: colors.textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700
        ),
      ),
    );
  }

  Widget get submitButton {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
          color: colors.backgroundColor,
          border: Border(top: BorderSide(color: colors.textColor.withValues(alpha: 0.1), width: 1))
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          height: 55,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
            ),
            onPressed: () async {
              //TODO:
              if(!mounted) return;
              Navigator.pop(context);
            },
            child: Text(
              'general.save'.tr(),
              style: TextStyle(
                fontSize: 15,
                color: colors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

