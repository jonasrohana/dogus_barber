import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/application/customer/profile_settings.dart';
import 'package:dogus_barber/controller+api/bookings_controller.dart';
import 'package:dogus_barber/utils/models.dart';
import '../../auth+onboarding/login_register.dart';
import '../../controller+api/user_controller.dart';
import '../../controller+api/vendor_controller.dart';
import '../../utils/colors.dart';
import '../../utils/functions.dart';
import '../../utils/widgets.dart';
import '../chat/chat_decision.dart';
import '../chat/chat_detail.dart';
import 'book_appointment.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> with TickerProviderStateMixin  {

  StreamSubscription? authStream;
  StreamSubscription? chatStream;
  List<String> unreadEmployeeIds = [];

  void initChatStream() {
    Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    UserProfile? profile = Provider.of<UserController>(context, listen: false).getUserProfile;
    if(profile != null && !profile.disabledBy.contains(vendor.id)) {
      chatStream = FirebaseFirestore.instance
      .collection('vendors').doc(vendor.id)
      .collection('rooms')
      .where('userIds', arrayContains: uid)
      .where('unread', isEqualTo: [uid])
      .snapshots()
      .listen((event) {
        unreadEmployeeIds.clear();
        for (var doc in event.docs) {
          Room room = Room.fromMap(doc.data());
          String employeeId = room.userIds.firstWhere((id) => id != uid);
          if (room.unread.contains(uid)) {
            unreadEmployeeIds.add(employeeId);
          }
        }
        setState(() {});
      });
    }
  }

  Future<void> handleWaitingDates() async {
    UserProfile? user = Provider.of<UserController>(context, listen: false).getUserProfile;
    List<String> removeDates = [];
    if(user != null && user.waitingList != null && user.waitingList!.isNotEmpty) {
      for(var i in user.waitingList!) {
        DateTime waitDate = parseDateString(i.split("/").last);
        String empId = i.split("/").first;
        if(waitDate.isBefore(DateTime.now())) {
          removeDates.add("$empId/${firestoreString(waitDate)}");
        }
      }
      await FirebaseFirestore.instance
        .collection('user').doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'waitingDates': FieldValue.arrayRemove(removeDates)});
    }
  }

  @override
  void initState() {
    super.initState();
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {
      if(user != null) {
        initChatStream();
        handleWaitingDates();
      }
      else {
        chatStream?.cancel();
        unreadEmployeeIds.clear();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    authStream?.cancel();
    chatStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    UserProfile? user = Provider.of<UserController>(context).getUserProfile;
    bool showFab = user == null || (user.verifiedBy.contains(vendor.id) && !user.disabledBy.contains(vendor.id))  ;
    return Stack(
      children: <Widget>[
        Stack(
          children: [
            Image.asset(
              "assets/images/background.jpeg",
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: colors.backgroundColor.withValues(alpha: 0.4)
              ),
            ),
          ],
        ),
        Scaffold(
          appBar: AppBar(
            actions: [
              if(user != null && !user.disabledBy.contains(vendor.id))
                IconButton(
                  visualDensity: const VisualDensity(horizontal: -4),
                  padding: const EdgeInsets.all(6),
                  onPressed: () {

                    if(vendor.employees.length == 1) {
                      navigateToChat(context, vendor.employees.first.id, false);
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatDecision(unread: unreadEmployeeIds)),
                    );
                  },
                  icon: Badge(
                    isLabelVisible: unreadEmployeeIds.isNotEmpty,
                    backgroundColor: CupertinoColors.destructiveRed,
                    smallSize: 10,
                    largeSize: 10,
                    child: Icon(Ionicons.chatbubbles_outline, color: colors.textColor, size: 25)
                  ),
                ),
              IconButton(
                visualDensity: const VisualDensity(horizontal: -4),
                padding: const EdgeInsets.all(6),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerSettingsProfile()),
                ),
                icon: Icon(Ionicons.settings_outline, color: colors.textColor, size: 25),
              ),
              const SizedBox(width: 8)
            ],
            backgroundColor: Colors.transparent,
            leadingWidth: 66,
            toolbarHeight: 50,
            centerTitle: true,
            title: Text(
              vendor.name,
              style: TextStyle(
                  fontFamily: GoogleFonts.dancingScript().fontFamily,
                  color: colors.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 26
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          backgroundColor: Colors.transparent,
          body: body,
          floatingActionButton: showFab ? fab : null,
        )
      ],
    );
  }

  Widget get body {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    UserProfile? user = Provider.of<UserController>(context).getUserProfile;

    if (user == null) {
      return noLoginPage;
    }
    else {
      if(user.disabledBy.contains(vendor.id)) {
        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const ThemedSvgImage(assetName: "empty", height: 150),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'general.blocked'.tr(),
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
          ),
        );
      }

      if(user.unverifiedBy.contains(vendor.id) || !user.verifiedBy.contains(vendor.id)){
        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const ThemedSvgImage(assetName: "user", height: 150),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'general.notVerified'.tr(),
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
          ),
        );
      }

      if(user.verifiedBy.contains(vendor.id)){
        return const CustomerBookings();
      }
    }

    return Container();
  }

  Widget? get fab {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {

        if(FirebaseAuth.instance.currentUser == null) {
          showModalBottomSheet(
            backgroundColor: colors.buttonColor,
            isScrollControlled: true,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), topRight: Radius.circular(30))),
            context: context,
            builder: (BuildContext context) => Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                height: MediaQuery.of(context).size.height*0.75,
                child: LoginScreen())
          );
          return;
        }

        // check if vendor has active subscription
        if(!vendor.active) {
          showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
              buttonText: "OK",
              title: "general.error".tr(),
              content: "subscription.noBookingAllowed".tr()
            )
          );
          return;
        }
        // check if there are any active employees
        if(vendor.employees.where((emp) => emp.services.isNotEmpty).isEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
              buttonText: "OK",
              title: "general.error".tr(),
              content: "booking.noEmployees".tr()
            )
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateAppointment())
        );
      },
      backgroundColor: colors.primary,
      child: Icon(Ionicons.add, color: colors.primaryText, size: 25),
    );
  }

  Widget get noLoginPage {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    List<Employee> validEmployees = vendor.employees.where((element) => element.services.isNotEmpty).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      children: [
        LoginBanner(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Text(
            "employeeServices".tr(),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor)
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: validEmployees.length,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
          itemBuilder: (BuildContext context, int index) {
            Employee emp = validEmployees[index];
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colors.buttonColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ImageViewer(hero: emp.id, url: emp.imageUrl))
                        ),
                        child: ProfileImageCircle(emp.imageUrl, 50, hero: emp.id)
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          emp.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.textColor
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ListView.separated(
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: emp.services.length,
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
                    itemBuilder: (BuildContext context, int index) {
                      Service s = emp.services[index];
                      return Container(
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: colors.backgroundColor,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 15,
                                color: Color(s.color).withValues(alpha: 1),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          s.name,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: colors.textColor
                                          )
                                      ),
                                      const SizedBox(height: 3,),
                                      Text(
                                          durationString(s.duration),
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: colors.textColor.withValues(alpha: 0.7)
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                child: Text(
                                  doubleToEuroString(s.price),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textColor.withValues(alpha: 0.8)
                                  )
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }

}

class CustomerBookings extends StatefulWidget {

  const CustomerBookings({super.key});

  @override
  State<CustomerBookings> createState() => _CustomerBookingsState();
}

class _CustomerBookingsState extends State<CustomerBookings> {

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return SingleChildScrollView(
      child: LoadingStack(
        loading: loading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 5),
              child: Text("general.yourAppointments".tr(), style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 18),),
            ),
            body
          ],
        ),
      ),
    );
  }

  // Event buildEvent(BuildContext context, Appointment app, {Recurrence? recurrence}) {
  //   Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
  //   Employee emp =  Provider.of<UserController>(context, listen: false).getEmployeeById(app.employeeId!)!;
  //   String start = timeToString(toTime(app.startTime));
  //   String end = timeToString(toTime(app.endTime));
  //   return Event(
  //     title: "calendar.title".tr(args: [(app.service ?? "calendar.appointment".tr()), vendor.name]),
  //     location: "${vendor.place.street}, ${vendor.place.plz} ${vendor.place.city}",
  //     description: "calendar.text".tr(args: [app.date, start, end, vendor.name, emp.name]),
  //     startDate: parseDateString(app.date).add( Duration(hours: app.startTime.truncate(), minutes: int.parse(start.split(":").last))),
  //     endDate: parseDateString(app.date).add( Duration(hours: app.endTime.truncate(), minutes: int.parse(end.split(":").last))),
  //     allDay: false,
  //     iosParams: const IOSParams(),
  //     androidParams: const AndroidParams(),
  //     recurrence: recurrence,
  //   );
  // }

  Widget get body {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    List<Appointment> booked = Provider.of<BookingsController>(context).appointments;
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;

    // filter for selected vendor and future dates
    DateTime now = DateTime.now();
    booked = booked.where((e) =>
      e.vendorId == vendor.id &&
      (DateUtils.isSameDay(now, parseDateString(e.date)) || parseDateString(e.date).isAfter(now)))
      .toList();
    if (booked.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const ThemedSvgImage(assetName: "calendar", height: 150),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'general.noBookingsCustomer'.tr(),
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

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12.0) + const EdgeInsets.only(bottom: 120, top: 5),
      shrinkWrap: true,
      itemCount: booked.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) => appointmentRow(booked[index], context),
    );
  }

  Widget appointmentRow(Appointment app, context) {
    Employee? emp = Provider.of<VendorController>(context).getEmployeeById(app.employeeId ?? "");
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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
                          "${dateFormat(parseDate(app.date))}, ${timeToString(toTime(app.startTime))} - ${timeToString(toTime(app.endTime))}",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textColor.withValues(alpha: 0.75))
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if(app.price! > 0)
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
                    if(emp != null)
                      ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            SizedBox(width: 20, child: Icon(Ionicons.person_outline, color: colors.textColor,size: 15)),
                            const SizedBox(width: 5),
                            Text(
                              emp.name,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textColor.withValues(alpha: 0.75))
                            ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: colors.buttonColor,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                  context: context,
                  builder: (BuildContext context) => ActionSheet(
                    actions: [
                      ActionSheetAction(
                        icon: Ionicons.chatbubble_ellipses_outline,
                        name: "actions.sendMessage".tr(),
                        enabled: app.userId.isNotEmpty,
                        onPressed: () => navigateToChat(context, emp!.id, false)
                      ),
                      // ActionSheetAction(
                      //   icon: Ionicons.calendar_outline,
                      //   destructive: false,
                      //   name: "actions.addCalender".tr(),
                      //   enabled: app.userId.isNotEmpty,
                      //   onPressed: () => Add2Calendar.addEvent2Cal(buildEvent(context,app))
                      // ),
                      if(isAtLeast24HoursBefore(parseDateString(app.date), app.startTime))
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
