import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:dogus_barber/application/vendor/bookings_tab/reschedule.dart';
import 'package:dogus_barber/utils/validator.dart';
import 'package:dogus_barber/utils/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/functions.dart';
import '../../../utils/models.dart';
import '../../../utils/public_holidays.dart';
import '../../chat/chat_detail.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {

  String uid = FirebaseAuth.instance.currentUser!.uid;
  late String selectedEmployeeId = uid;
  AutoScrollController controller = AutoScrollController(axis: Axis.horizontal);
  DateTime date = DateTime.now();
  late Widget appointmentOverview = EmployeeAppointmentOverview(
    key: Key(selectedEmployeeId),
    employeeId: selectedEmployeeId,
    setDate: setDate,
    initialDate: date,
  );

  void setDate(DateTime d) => date = d;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          employeeSelection,
          appointmentOverview
        ],
      ),
    );
  }

  Widget get employeeSelection {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    bool isAdmin = vendor.admins.contains(uid);
    if(vendor.employees.length < 2 || !isAdmin) {
      return Container();
    }
    return SizedBox(
      height: 55,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: vendor.employees.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          Employee emp = vendor.employees[index];
          bool selected = emp.id == selectedEmployeeId;
          return AutoScrollTag(
            key: ValueKey(index),
            controller: controller,
            index: index,
            child: GestureDetector(
              onTap: () {
                if(selected) return;

                setState(() => selectedEmployeeId = emp.id);
                appointmentOverview = EmployeeAppointmentOverview(
                  key: Key(selectedEmployeeId),
                  employeeId: selectedEmployeeId,
                  setDate: setDate,
                  initialDate: date,
                );
                setState(() {});
                controller.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : colors.buttonColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5)
                ),
                child: Row(
                  children: [
                    ProfileImageCircle(emp.imageUrl, 35),
                    const SizedBox(width: 12),
                    Text(
                      emp.name,
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      )
    );
  }
}

class EmployeeAppointmentOverview extends StatefulWidget {

  final String employeeId;
  final Function(DateTime) setDate;
  final DateTime initialDate; // for maintaining date across employee changes

  const EmployeeAppointmentOverview({super.key, required this.employeeId, required this.setDate, required this.initialDate});

  @override
  State<EmployeeAppointmentOverview> createState() => _EmployeeAppointmentOverviewState();
}

class _EmployeeAppointmentOverviewState extends State<EmployeeAppointmentOverview> with TickerProviderStateMixin  {

  late TabController controller = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this
  );
  int tabIndex = 0;

  late Stream dayStream;
  late DateTime selectedDate = widget.initialDate;

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

  void setDate(DateTime date) {
    selectedDate = date;
    widget.setDate(date);
    setStream();
  }

  void setStream() {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    dayStream = FirebaseFirestore.instance
        .collection("vendors").doc(vendor.id)
        .collection("employees").doc(widget.employeeId)
        .collection("privateAppointments")
        .where("date", isEqualTo: firestoreString(selectedDate))
        .snapshots();
    setState(() {});
  }

  @override
  void initState() {
    if(selectedDate.hour > 19) {
      selectedDate = selectedDate.add(const Duration(days: 1));
    }
    setStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return SingleChildScrollView(
      child: Column(
        children: [
          dateWidgets,
          const SizedBox(height: 15),
          CustomTabBar(
              controller: controller,
              tabs: ["general.taken".tr(), "general.free".tr()],
              function: (i) => setState(() => tabIndex = i)
          ),
          const SizedBox(height: 25),
          appointmentList,
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget get dateWidgets {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(5, 15, 5, 20),
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
        dayTextColor = Colors.black;
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

  Widget get appointmentList {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    Employee emp = Provider.of<UserController>(context).getEmployeeById(widget.employeeId)!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    if(isPastDue(selectedDate) && tabIndex == 1){
      return Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "calendar", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'general.pastDateNoBookings'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textColor.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4
              ),
            ),
          )
        ],
      );
    }
    else if(isPublicHoliday(selectedDate, vendor.place.state ?? "")) {
      return Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "holiday", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'general.holidayDate'.tr(args: [getPublicHolidayName(selectedDate)]),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textColor.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4
              ),
            ),
          )
        ],
      );
    }
    else if (emp.workTimes[selectedDate.weekday-1].isEmpty) {
      return Column(
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
                  color: colors.textColor.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4
              ),
            ),
          )
        ],
      );
    }
    return StreamBuilder(
      stream: dayStream,
      builder: (context, snapshot) {

        if (snapshot.hasError) {
          return const Text('Es ist ein Fehler aufgetreten.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        // show booked termine
        if (tabIndex == 0) {
          return BookedAppointments(
            booked: snapshot.data!.docs,
            freeTermine: snapshot.data!.docs,
            employeeId: emp.id,
          );
        }

        // show free termine
        return FreeAppointments(
            selected: selectedDate,
            appointments: snapshot.data!.docs,
            employeeId: emp.id);
      },
    );
  }

}

class BookedAppointments extends StatefulWidget {

  final String employeeId;
  final List<QueryDocumentSnapshot> freeTermine;
  final List<DocumentSnapshot> booked;

  const BookedAppointments({super.key, required this.freeTermine, required this.booked, required this.employeeId});

  @override
  BookedAppointmentsState createState() => BookedAppointmentsState();
}

class BookedAppointmentsState extends State<BookedAppointments> {

  String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    List<Appointment> mapped = widget.booked.map<Appointment>((e) =>
      Appointment.fromMap(e.data() as Map<String, dynamic>, e.id)).toList();
    if (mapped.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const ThemedSvgImage(assetName: "calendar", height: 150),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'general.noBookings'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textColor.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4
                ),
              ),
            )
          ],
        ),
      );
    }

    mapped.sort();
    return Column(
      children: [
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0) + const EdgeInsets.only(bottom: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mapped.length,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) => AppointmentRow(app: mapped[index]),
        ),
        if(mapped.length > 1)
          deleteAllButton,
        const SizedBox(height: 40)
      ],
    );
  }

  Widget get deleteAllButton {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      width: double.maxFinite,
      height: 55,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0))
        ),
        onPressed: () async {
          final retVal = await showDialog(
            context: context,
            builder: (BuildContext context) =>
              NativeDialog(
                title: "general.cancelAllAppointments".tr(),
                content: "general.cancelAllAppointmentsDescription".tr(),
                buttonTextOne: "general.yes".tr(),
                buttonTextTwo: "general.no".tr(),
                buttonOne: () => Navigator.pop(context, true),
                buttonTwo: () => Navigator.pop(context, false),
                buttonOneRed: true,
              )
          );

          if(retVal != null && retVal is bool && retVal) {
            WriteBatch batch = FirebaseFirestore.instance.batch();
            for(var doc in widget.booked) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }
        },
        child: Text(
          "general.cancelAllAppointments".tr(),
          style: TextStyle(
            fontSize: 15,
            color: colors.secondaryText,
          ),
        ),
      ),
    );
  }

}

class AppointmentRow extends StatefulWidget {

  final Appointment app;

  const AppointmentRow({super.key, required this.app});

  @override
  State<AppointmentRow> createState() => _AppointmentRowState();
}

class _AppointmentRowState extends State<AppointmentRow> {

  String uid = FirebaseAuth.instance.currentUser!.uid;
  late Appointment app = widget.app;

  UserProfile? appUser;

  Future<void> fetchUser() async {
    if(app.userId.isEmpty) {
      return;
    }
    final doc = await FirebaseFirestore.instance.collection("user").doc(app.userId).get();
    if(doc.exists) {
      setState(() => appUser = UserProfile.fromMap(doc.data() as Map<String,dynamic>));
    }
  }

  @override
  void initState() {
    fetchUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    bool isHoliday = app.holidayId != null;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.buttonColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if(app.colors != null && app.colors!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 15),
                width: 15,
                child: Column(
                  children: [
                    for (var color in app.colors!)
                      Expanded(child: Container(color: Color(color).withValues(alpha: 0.75)))
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.service!.isNotEmpty ? app.service! : "booking.fixed".tr(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textColor),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        SizedBox(width: 20, child: Icon(Ionicons.calendar_outline,color: colors.textColor,size: 15)),
                        const SizedBox(width: 5),
                        Text(
                            isHoliday ? "general.allDay".tr() : "${timeToString(toTime(app.startTime))} - ${timeToString(toTime(app.endTime))}",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textColor.withValues(alpha: 0.75))
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    Row(
                      children: [
                        SizedBox(width: 20, child: Icon(Ionicons.person_outline, color: colors.textColor,size: 15)),
                        const SizedBox(width: 5),
                        Text(
                            isHoliday ? "${"general.holiday".tr()}${app.name!.isNotEmpty ? " - ${app.name}" : ""}" : (app.name ?? "general.noName".tr()),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textColor.withValues(alpha: 0.75))
                        ),
                      ],
                    ),
                    if(app.price! > 0)
                      ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            SizedBox(width: 20, child: Icon(Ionicons.wallet_outline,color: colors.textColor,size: 15)),
                            const SizedBox(width: 5),
                            Text(
                                doubleToEuroString(app.price!),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textColor.withValues(alpha: 0.75))
                            ),
                          ],
                        ),
                      ],
                    if(app.status != null)
                      ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: getColorByStatus(app.status!).withValues(alpha: 0.4)
                          ),
                          child: Text(
                            app.status!.tr(),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: getColorByStatus(app.status!))
                          ),
                        )
                      ],
                    if(appUser != null && appUser!.noShow.isNotEmpty)
                      ...[
                        const SizedBox(height: 8),
                        for(String noShower in appUser!.noShow)
                          Text(
                            "- No-Show vermerkt am $noShower",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CupertinoColors.destructiveRed),
                            maxLines: 1,
                          ),
                      ]
                  ],
                ),
              ),
            ),
            if(!isHoliday && (app.employeeId == uid || vendor.admins.contains(uid)))
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: colors.buttonColor,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                    context: context,
                    builder: (BuildContext context) => ActionSheet(
                      actions: [
                        if(!isFutureDate(app.date) && app.status == "pending_cash")
                          ActionSheetAction(
                            icon: Ionicons.cash_outline,
                            name: "Als bezahlt markieren",
                            onPressed: () async {
                              FirebaseFirestore.instance
                                .collection("vendors").doc(vendor.id)
                                .collection("employees").doc(app.employeeId)
                                .collection("privateAppointments").doc(app.id)
                                .update({ "status": "paid_cash" });
                              setState(() => app.status = "paid_cash");
                            }
                          ),
                        ActionSheetAction(
                          icon: Ionicons.chatbubble_ellipses_outline,
                          name: "actions.sendMessage".tr(),
                          enabled: app.userId.isNotEmpty,
                          onPressed: () => navigateToChat(context, app.userId, true)
                        ),
                        ActionSheetAction(
                          icon: Ionicons.swap_horizontal,
                          name: "actions.reschedule".tr(),
                          enabled: true,
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChangeAppointmentsTab(app: app)),
                            );
                          }
                        ),
                        ActionSheetAction(
                          icon: Ionicons.call_outline,
                          name: "actions.call".tr(),
                          enabled: (app.phoneNr ?? "").isNotEmpty,
                          onPressed: () => launchUrlString("tel://${app.phoneNr!}")
                        ),
                        if(appUser != null)
                          ActionSheetAction(
                            icon: Ionicons.pencil_outline,
                            name: "No-Show eintragen",
                            enabled: app.userId.isNotEmpty && !isFutureDate(app.date),
                            onPressed: () {
                              addNoShowFunctions.call({ "userId": app.userId, "date": app.date });
                              setState(() => appUser!.noShow.add(app.date));
                            }
                          ),
                        if(appUser != null && appUser!.noShow.isNotEmpty)
                          ActionSheetAction(
                            icon: Ionicons.alert_outline,
                            destructive: true,
                            name: "No-Shows löschen",
                            onPressed: () {
                              deleteNoShowFunctions.call({ "userId": app.userId });
                              setState(() => appUser!.noShow.clear());
                            }
                          ),
                        ActionSheetAction(
                          icon: Ionicons.lock_closed_outline,
                          destructive: true,
                          name: "actions.block".tr(),
                          enabled: app.userId.isNotEmpty,
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                NativeDialog(
                                  title: "actions.block".tr(),
                                  content: "actions.blockQuestion".tr(args: [app.name!]),
                                  buttonTextOne: "general.yes".tr(),
                                  buttonTextTwo: "general.no".tr(),
                                  buttonOne: () {
                                    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
                                    blockUser.call({
                                      'userId': app.userId,
                                      'vendorId': vendor.id
                                    });
                                    Navigator.pop(context);
                                  },
                                  buttonTwo: () => Navigator.pop(context),
                                  buttonOneRed: true,
                                )
                            );
                          }
                        ),
                        ActionSheetAction(
                          icon: Ionicons.close_outline,
                          name: "actions.cancel".tr(),
                          destructive: true,
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                NativeDialog(
                                  title: "actions.cancel".tr(),
                                  content: "actions.cancelMessage".tr(),
                                  buttonTextOne: "general.yes".tr(),
                                  buttonTextTwo: "general.no".tr(),
                                  buttonOne: () {
                                    FirebaseFirestore.instance
                                      .collection("vendors").doc(app.vendorId)
                                      .collection("employees").doc(app.employeeId)
                                      .collection("privateAppointments").doc(app.id)
                                      .delete();
                                    Navigator.pop(context);
                                  },
                                  buttonTwo: () => Navigator.pop(context),
                                  buttonOneRed: true,
                                )
                            );
                          }
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(Ionicons.ellipsis_vertical, size: 20, color: colors.textColor),
                )
              ),
          ],
        ),
      ),
    );
  }
}


class FreeAppointments extends StatefulWidget {

  final String employeeId;
  final DateTime selected;
  final List<QueryDocumentSnapshot> appointments;

  const FreeAppointments({super.key, required this.selected, required this.appointments, required this.employeeId});

  @override
  State<FreeAppointments> createState() => _FreeAppointmentsState();
}

class _FreeAppointmentsState extends State<FreeAppointments> {

  List<int> durations = [5,10,15,20,25,30,45,60,75,90,105,120];
  double durationIndex = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        durationSlider,
        const SizedBox(height: 10),
        freeAppointments,
        const SizedBox(height: 50)
      ],
    );
  }

  Widget get durationSlider {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 10),
          child: Row(
            children: [
              Text(
                  "durations.duration".tr(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textColor
                  )
              ),
              const SizedBox(width: 5),
              Text(
                  durationString(durations[durationIndex.toInt()]),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor
                  )
              )
            ],
          ),
        ),
        Slider(
          activeColor: colors.primary,
          inactiveColor: colors.primary.withValues(alpha: 0.3),
          value: durationIndex,
          min: 0,
          max: 11,
          divisions: 11,
          label: shortDurationString(durations[durationIndex.toInt()]),
          onChanged: (double value) => setState(() => durationIndex = value),
        ),
      ],
    );
  }

  Widget get freeAppointments {
    Employee emp = Provider.of<UserController>(context).getEmployeeById(widget.employeeId)!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    List<TimeSlot> freeTimes = getFreeAppointments(emp, widget.appointments, widget.selected, durations[durationIndex.toInt()]);
    if(freeTimes.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const ThemedSvgImage(assetName: "calendar", height: 150),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'booking.noFreeSlots'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textColor.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4
                ),
              ),
            )
          ],
        ),
      );
    }

    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.5,
      children: freeTimes.map((t) => GestureDetector(
        onTap: () {
          if(isToday(widget.selected) && toDouble(TimeOfDay.now()) > t.start) {
            setState(() {});
          } else {
            showModalBottomSheet(
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
              backgroundColor: colors.buttonColor,
              context: context,
              builder: (BuildContext context) => BookingSheet(selected: widget.selected, slot: t, employeeId: emp.id),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: colors.buttonColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
          ),
          child: Center(
            child: Text(
              "${timeToString(toTime(t.start))} - ${timeToString(toTime(t.end))}",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textColor),
            ),
          ),
        ),
      )).toList(),
    );
  }

}

class BookingSheet extends StatefulWidget {

  final String employeeId;
  final DateTime selected;
  final TimeSlot slot;

  const BookingSheet({super.key, required this.selected, required this.slot, required this.employeeId});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {

  TextEditingController nameTf = TextEditingController();
  TextEditingController serviceTf = TextEditingController();
  bool isSubmitted = false;

  bool get valid => validateName(nameTf.text) == null;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.buttonColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(15)
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "booking.bookAppointment".tr(),
                  style: TextStyle(
                      fontSize: 18,
                      color: colors.textColor,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: Text(
                  firestoreString(widget.selected),
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  "${timeToString(toTime(widget.slot.start))} - ${timeToString(toTime(widget.slot.end))}",
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              buildTf(nameTf, "booking.customerName".tr(), validateName(nameTf.text)),
              const SizedBox(height: 15),
              buildTf(serviceTf, "booking.serviceOptional".tr(), null),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  height: 55,
                  width: double.maxFinite,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                    onPressed: () async {
                      setState(() => isSubmitted = true);
                      if(!valid) return;

                      Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
                      String uid = FirebaseAuth.instance.currentUser!.uid;

                      final vendorRef = FirebaseFirestore.instance
                          .collection("vendors").doc(vendor.id)
                          .collection("employees").doc(widget.employeeId);
                      final privateRef = vendorRef.collection("privateAppointments").doc();

                      Appointment app = Appointment(id: privateRef.id, date: firestoreString(widget.selected), userId: "",
                          startTime: widget.slot.start, endTime: widget.slot.end, employeeId: widget.employeeId, vendorId: vendor.id);

                      // write termin to public and private collection
                      await vendorRef.collection("appointments").doc(privateRef.id).set(app.toMap());
                      app.name = nameTf.text;
                      app.service = serviceTf.text;
                      await privateRef.set(app.toMap());

                      if(!mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(
                      "booking.book".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          color: valid ? colors.primaryText : Colors.grey,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTf(TextEditingController controller, String label, String? errorText) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      cursorColor: colors.textColor,
      keyboardType: TextInputType.name,
      textInputAction: controller == serviceTf ? TextInputAction.done : TextInputAction.next,
      controller: controller,
      autofocus: false,
      onChanged: (value) => setState(() {}),
      style: TextStyle(color: colors.textColor),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.textColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.textColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        filled: true,
        labelStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
        labelText: label,
        fillColor: colors.textColor.withValues(alpha: 0.05),
        errorText: isSubmitted ? errorText : null,
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

}