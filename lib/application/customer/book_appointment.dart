import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:dogus_barber/utils/models.dart';
import '../../controller+api/bookings_controller.dart';
import '../../controller+api/user_controller.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/functions.dart';
import '../../utils/public_holidays.dart';
import '../../utils/widgets.dart';

class CreateAppointment extends StatefulWidget {
  const CreateAppointment({super.key});

  @override
  State<CreateAppointment> createState() => _CreateAppointmentState();
}

class _CreateAppointmentState extends State<CreateAppointment> with TickerProviderStateMixin  {

  int index = 0;
  final controller = PageController(keepPage: true, initialPage: 0);

  Stream? dayStream;
  DateTime selectedDate = DateTime.now();

  List<Service> chosenServices = [];

  Employee? selectedEmployee;

  TimeSlot? selectedTime;

  DateTime max = DateTime.now().add(const Duration(days: 21));

  bool loading = false;

  Future<void> waitingListAction(String dateString) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
      .collection('user').doc(userId)
      .update({ 'waitingDates': FieldValue.arrayUnion([dateString]) });
  }

  Future<void> showWaitingListDialog(String d) {
    return showDialog(
      context: context,
      builder: (context) => NativeDialog(
        content: "general.waitingListText".tr(),
        title: "general.push".tr(),
        buttonTextOne: "general.yes".tr(),
        buttonTextTwo: "general.no".tr(),
        buttonOne: () async {
          waitingListAction(d);
          setState(() {});
          Navigator.pop(context);
        },
        buttonTwo: () => Navigator.pop(context),
        buttonOneRed: false
      ),
    );
  }

  Future<void> bookAppointment() async {

    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    UserProfile? user = Provider.of<UserController>(context, listen: false).getUserProfile!;

    String? dateTakenString = Provider.of<BookingsController>(context,listen: false).isDateTaken(firestoreString(selectedDate), selectedEmployee!.id);
    if(dateTakenString != null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) =>
          ShowDialogToDismiss(
            title: "general.error".tr(),
            buttonText: "Ok",
            content: dateTakenString.tr(),
          )
      );
      return;
    }

    List<int> colors = chosenServices.map((e) => e.color).toList();
    String serviceString = chosenServices.map((e) => e.name).join(", ");

    String id = FirebaseFirestore.instance
      .collection("vendors").doc(vendor.id)
      .collection("employees").doc(selectedEmployee!.id)
      .collection("privateAppointments").doc().id;

    BookAppointmentParams params = BookAppointmentParams(vendorId: vendor.id, price: getPrice(chosenServices),
      date: firestoreString(selectedDate), id: id, startTime: selectedTime!.start, service: serviceString,
      endTime: selectedTime!.end, name: user.name, phoneNr: user.phoneNr, colors: colors,
      employeeId: selectedEmployee!.id);

    setState(() => loading = true);
    try {

      final response = await bookAppointmentFunctions.call(params.toMap());
      print(response);
      String result = Map<String, dynamic>.from(response.data)["result"];
      setState(() => loading = false);

      // Handling the response
      if(!mounted)  return;
      if (result == 'Success') {
        await showDialog(
          context: context,
          builder: (BuildContext context) =>
            AnimationDialog(text: "booking.success".tr(), isSuccess: true)
        );
        if(!mounted)return;
        Navigator.pop(context);
      }
      else if(result == "Error: Transaction failure"){
        print(result);
        await showDialog(
          context: context,
          builder: (BuildContext context) =>  ShowDialogToDismiss(
            buttonText: "OK",
            title: "general.error".tr(),
            content: "booking.error".tr()
          )
        );
      }
      else {
        print(result);
        controller.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.linear);
        await showDialog(
          context: context,
          builder: (BuildContext context) =>  ShowDialogToDismiss(
            buttonText: "OK",
            title: "general.error".tr(),
            content: "booking.tooSlow".tr()
          )
        );

      }
    }
    catch (e) {
      print(e);
      setState(() => loading = false);
      if(!mounted)return;
      await showDialog(
        context: context,
        builder: (BuildContext context) =>  ShowDialogToDismiss(
          buttonText: "OK",
          title: "general.error".tr(),
          content: "booking.error".tr()
        )
      );
    }

  }

  Future<void> showDatePicker() async {
    ColorTheme colors = Provider.of<UserController>(context,listen:false).getColors;
    DateTime initialDate = selectedDate;
    final retVal = await showModalBottomSheet(
      backgroundColor: colors.buttonColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (BuildContext context) => DatePickerSheet(
          initialDate: initialDate, view: DateRangePickerView.month, minDate: DateTime.now(), maxDate: max),
    );
    if (retVal != null && retVal is DateTime) {
      setDate(retVal);
    }
  }

  bool valid(int index) {
    if(index == 0) {
      return selectedEmployee != null;
    }
    if(index == 1) {
      return chosenServices.isNotEmpty;
    }
    if(index == 2) {
      return selectedTime != null;
    }
    return true;
  }

  void setDate(DateTime date) {
    selectedDate = date;
    selectedTime = null;
    setStream();
  }

  int get getDuration {
    int duration = 0;
    for(var i in chosenServices) {
      duration = duration + i.duration;
    }
    return duration;
  }

  void setStream() {
    if(selectedEmployee == null) {
      return;
    }
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    dayStream = FirebaseFirestore.instance
      .collection("vendors").doc(vendor.id)
      .collection("employees").doc(selectedEmployee!.id)
      .collection("appointments")
      .where("date", isEqualTo: firestoreString(selectedDate))
      .snapshots();
    setState(() {});
  }

  @override
  void initState() {
    if(selectedDate.hour > 16) {
      selectedDate = selectedDate.add(const Duration(days: 1));
    }
    setStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Scaffold(
      extendBodyBehindAppBar: false,
      body: SafeArea(child: pages),
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget get pages {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        appBar,
        Expanded(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: controller,
            onPageChanged: (i) => setState(() => index = i),
            children: [
              KeepAlivePage(child: employeePage),
              KeepAlivePage(child: servicePage),
              KeepAlivePage(child: timeSlotPage),
              KeepAlivePage(child: summary)
            ],
          ),
        ),
        SafeArea(child: submitButton),
      ],
    );
  }

  Widget get appBar {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if(loading) {
                return;
              }

              if(index > 0) {
                controller.animateToPage(index-1, duration: const Duration(milliseconds: 300), curve: Curves.linear);
              }
              else {
                Navigator.pop(context);
              }
            },
            child: Icon(
              LineAwesomeIcons.angle_left,
              size: 25,
              color: colors.textColor,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: LinearPercentIndicator(
              barRadius: const Radius.circular(20),
              lineHeight: 10.0,
              percent: (index+1)/4,
              backgroundColor: colors.primary.withValues(alpha: 0.2),
              progressColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget get employeePage {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    List<Employee> validEmployees = vendor.employees.where((element) =>
        element.services.isNotEmpty).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          "general.selectEmployee".tr(),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor)
        ),
        const SizedBox(height: 20),
        if(validEmployees.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const ThemedSvgImage(assetName: "user", height: 150),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "booking.noEmployees".tr(),
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
          )
        else
          ListView.separated(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: validEmployees.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
            itemBuilder: (BuildContext context, int index) {
              Employee emp = validEmployees[index];
              bool isSelected = selectedEmployee != null && selectedEmployee!.id == emp.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedEmployee = emp;
                    max = DateTime.now().add(Duration(days: selectedEmployee!.numBookingWeeks * 7));
                  });
                  setStream();
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.textColor : colors.buttonColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
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
                            color: isSelected ? colors.backgroundColor : colors.textColor
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
        ),
      ],
    );
  }

  Widget get servicePage {
    if(selectedEmployee == null) {
      return Container();
    }

    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          "services.selectServices".tr(),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor)
        ),
        const SizedBox(height: 20),
        ListView.separated(
          padding: const EdgeInsets.all(0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedEmployee!.services.length,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
          itemBuilder: (BuildContext context, int index) {
            Service s = selectedEmployee!.services[index];
            return GestureDetector(
              onTap: () {
                if(chosenServices.contains(s)){
                  chosenServices.remove(s);
                }
                else {
                  chosenServices.add(s);
                }
                setState(() {});
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: chosenServices.contains(s) ? colors.textColor : colors.buttonColor,
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
                                      color: chosenServices.contains(s) ? colors.backgroundColor : colors.textColor
                                  )
                              ),
                              const SizedBox(height: 3,),
                              Text(
                                  durationString(s.duration),
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: chosenServices.contains(s) ? colors.backgroundColor.withValues(alpha: 0.7) : colors.textColor.withValues(alpha: 0.7)
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
                                color: chosenServices.contains(s) ? colors.backgroundColor.withValues(alpha: 0.8) : colors.textColor.withValues(alpha: 0.8)
                            )
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

  Widget get timeSlotPage {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          dateWidgets,
          const SizedBox(height: 15),
          appointmentList
        ],
      ),
    );
  }

  Widget get summary {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    String serviceString = chosenServices.map((e) => e.name).join(", ");
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: LoadingStack(
        loading: loading,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15) + const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'booking.bookingMessage'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: colors.buttonColor
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  displayText("general.date".tr(), dateFormat(selectedDate), true),
                  Container(margin: const EdgeInsets.only(left: 20, right: 85), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "general.timeSlot".tr(),
                                style: TextStyle(
                                  color: colors.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedTime == null ? "" : "${timeToString(toTime(selectedTime!.start))} - ${timeToString(toTime(selectedTime!.end))}",
                                style: TextStyle(
                                    color: colors.textColor.withValues(alpha: 0.6),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500
                                ),
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "services.price".tr(),
                                style: TextStyle(
                                    color: colors.textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doubleToEuroString(getPrice(chosenServices)),
                                style: TextStyle(
                                    color: colors.textColor.withValues(alpha: 0.6),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            const SizedBox(height: 10),
            pageTitle("services.services".tr()),
            const SizedBox(height: 10),
            ListView.separated(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chosenServices.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
              itemBuilder: (BuildContext context, int index) {
                Service s = chosenServices[index];
                return Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: colors.buttonColor,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget displayText(String label, String text, bool showImage) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Widget imageWidget = Container();
    if(showImage && selectedEmployee != null) {
      imageWidget =  ClipOval(
        child: ProfileImageCircle(selectedEmployee!.imageUrl, 50)
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
            imageWidget
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

  Widget get appointmentList {
    if(selectedEmployee == null) {
      return Container();
    }
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    if(isPastDue(selectedDate)){
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
                color: colors.textColor.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4
              ),
            ),
          )
        ],
      );
    }
    else if(selectedDate.isAfter(max)){
      return Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "calendar", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'general.notYet'.tr(),
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
                color: colors.textColor.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4
              ),
            ),
          )
        ],
      );
    }
    else if (selectedEmployee!.workTimes[selectedDate.weekday-1].isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "empty", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'general.vendorNotOpen'.tr(args: [selectedEmployee!.name]),
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            freeAppointments(snapshot.data!.docs, getDuration),
            const SizedBox(height: 25)
          ],
        );
      },
    );
  }

  Widget freeAppointments(List<QueryDocumentSnapshot<Object?>> appointments, int duration) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    List<TimeSlot> freeTimes = getFreeAppointments(selectedEmployee, appointments, selectedDate, duration.round());
    UserProfile? user = Provider.of<UserController>(context).getUserProfile;
    Employee? emp = Provider.of<UserController>(context).getEmployeeById(selectedEmployee!.id);
    String waitingDateString = "${emp!.id}/${firestoreString(selectedDate)}";
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
            ),

            const SizedBox(height: 10),
            if(!user!.waitingList!.contains(waitingDateString))
              ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: PrimaryButton(
                    text: 'general.pushMe'.tr(),
                    onPressed: () => showWaitingListDialog(waitingDateString),
                    enabled: true,
                    color: colors.primary
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
                  child: Text(
                    'general.pushMeText'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ]
            else
              ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'general.alreadyWaiting'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textColor.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  )
                ),
              ],
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
      children: freeTimes.map((t) {
        bool isSelectedTime = selectedTime?.start == t.start && selectedTime?.end == t.end;
        return GestureDetector(
          onTap: () {
            if(isToday(selectedDate) && toDouble(TimeOfDay.now()) > t.start) {
              setState(() {});
            }
            else {
              setState(() => selectedTime = t);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelectedTime ? colors.textColor : colors.buttonColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
            ),
            child: Center(
              child: Text(
                "${timeToString(toTime(t.start))} - ${timeToString(toTime(t.end))}",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isSelectedTime ? colors.buttonColor : colors.textColor),
              ),
            ),
          ),
        );
      }).toList(),
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

  Widget get submitButton {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border(top: BorderSide(color: colors.textColor.withValues(alpha: 0.1), width: 1))
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Center(
        child: PrimaryButton(
          text: index == 3 ? 'booking.book'.tr() : 'general.continue'.tr(),
          onPressed: () async {
            if(loading) {
              return;
            }

            if(index != 3) {
              if(valid(index)) {
                controller.animateToPage(index+1, duration: const Duration(milliseconds: 300), curve: Curves.linear);
                FocusScope.of(context).unfocus();
              }
            }
            else {
              print("Hier)");
              bookAppointment();
            }
          },
          enabled: valid(index),
          color: valid(index) ? colors.primary : colors.primary.withValues(alpha: 0.5)
        )
      ),
    );
  }

}