import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../controller+api/user_controller.dart';
import '../../../controller+api/vendor_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/functions.dart';
import '../../../utils/models.dart';
import '../../../utils/public_holidays.dart';
import '../../../utils/widgets.dart';

class ChangeAppointmentsTab extends StatefulWidget {
  final Appointment app;

  const ChangeAppointmentsTab({super.key, required this.app});

  @override
  State<ChangeAppointmentsTab> createState() => _ChangeAppointmentsTabState();
}

class _ChangeAppointmentsTabState extends State<ChangeAppointmentsTab> {

  late DateTime date = parseDateString(widget.app.date);
  late Widget appointmentOverview = EmployeeAppointmentOverview(
    key: Key(widget.app.employeeId!),
    employeeId: widget.app.employeeId!,
    setDate: setDate,
    initialDate: date, app: widget.app,
  );

  void setDate(DateTime d) => date = d;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leadingWidth: 66 ,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text(
            "Termin verschieben",
            style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 26
            )
        ),
      ),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            appointmentOverview
          ],
        ),
      ),
    );
  }
}

class EmployeeAppointmentOverview extends StatefulWidget {

  final String employeeId;
  final Function(DateTime) setDate;
  final Appointment app;
  final DateTime initialDate; // for maintaining date across employee changes

  const EmployeeAppointmentOverview({super.key, required this.employeeId, required this.setDate, required this.initialDate, required this.app});

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
    ColorTheme colors = Provider.of<VendorController>(context,listen: false).getColors;
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
    if (isPastDue(date)) return;

    selectedDate = date;
    widget.setDate(date);
    setStream();
  }

  void setStream() {
    Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;
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
    return SingleChildScrollView(
      child: Column(
        children: [
          dateWidgets,
          const SizedBox(height: 15),
          appointmentList
        ],
      ),
    );
  }

  Widget get dateWidgets {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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

  Widget get appointmentList {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    Employee emp = Provider.of<VendorController>(context).getEmployeeById(widget.employeeId)!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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

        return ChangeAppointment(
          selected: selectedDate,
          appointments: snapshot.data!.docs,
          app: widget.app, employeeId: widget.employeeId,
        );
      },
    );
  }

}

class ChangeAppointment extends StatefulWidget {

  final DateTime selected;
  final String employeeId;
  final List<QueryDocumentSnapshot> appointments;
  final Appointment app;

  const ChangeAppointment({super.key, required this.selected, required this.appointments, required this.app, required this.employeeId});

  @override
  State<ChangeAppointment> createState() => _ChangeAppointmentState();
}

class _ChangeAppointmentState extends State<ChangeAppointment> {

  late DateTime selectedDate = widget.selected;
  TimeSlot? newSlot;

  double selected = 0.0;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    Employee? emp = Provider.of<VendorController>(context).getEmployeeById(widget.app.employeeId!);
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    double width = MediaQuery.of(context).size.width - 52;
    List<TimeSlot> termine = computeFreeToChangeSlots(emp, widget.appointments, widget.selected ,((widget.app.endTime-widget.app.startTime)*60).toInt(), widget.app);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: colors.buttonColor
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${widget.app.name!}: ${timeToString(toTime(widget.app.startTime))} - ${timeToString(toTime(widget.app.endTime))}",
                style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              if(newSlot != null)
                Text(
                  "${"actions.newTime".tr()}${timeToString(toTime(newSlot!.start))} - ${timeToString(toTime(newSlot!.end))}",
                  style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 10),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(termine.length, (index) {

                    TimeSlot termin = termine[index];
                    return GestureDetector(
                      onTap: () {
                        if(selected == termin.start){
                          selected = 0.0;
                          newSlot = null;
                        }
                        else {
                          selected = termin.start;
                          newSlot = termin;
                        }
                        setState(() {});
                      },
                      child: Container(
                        width: width/3,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: selected == termin.start ? colors.primary : colors.textColor, width: 1),
                          color: selected == termin.start ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Center(
                          child: Text(
                            "${timeToString(toTime(termin.start))}-${timeToString(toTime(termin.end))}",
                            style: TextStyle(
                                color: selected == termin.start ? colors.primaryText : colors.textColor, fontSize: 14
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  )
              ),
              const SizedBox(height: 15),
              SafeArea(
                child: PrimaryButton(
                    text: "actions.reschedule".tr(),
                    onPressed: () async {
                      if(newSlot != null) {

                        if (widget.employeeId != widget.app.employeeId) {
                          String empID = widget.app.employeeId!;
                          String appID = widget.app.id;
                          Appointment newApp = widget.app;
                          newApp.employeeId = widget.employeeId;
                          newApp.startTime = newSlot!.start;
                          newApp.endTime = newSlot!.end;
                          newApp.date = firestoreString(widget.selected);


                          var newDoc = await FirebaseFirestore.instance
                              .collection("vendors").doc(vendor.id)
                              .collection("employees").doc(widget.employeeId)
                              .collection("privateAppointments")
                              .add(newApp.toMap());
                          FirebaseFirestore.instance
                              .collection("vendors").doc(vendor.id)
                              .collection("employees").doc(widget.employeeId)
                              .collection("appointments").doc(newDoc.id)
                              .set(newApp.toMap());

                          FirebaseFirestore.instance
                              .collection("vendors").doc("H1d9tejlBogXJ1r3k49a")
                              .collection("employees").doc(empID)
                              .collection("privateAppointments").doc(appID)
                              .delete();
                          FirebaseFirestore.instance
                              .collection("vendors").doc("H1d9tejlBogXJ1r3k49a")
                              .collection("employees").doc(empID)
                              .collection("appointments").doc(appID)
                              .delete();
                        }
                        else {
                          FirebaseFirestore.instance
                              .collection("vendors").doc(vendor.id)
                              .collection("employees").doc(widget.employeeId)
                              .collection("privateAppointments").doc(widget.app.id)
                              .update({
                            'startTime': newSlot!.start,
                            'endTime': newSlot!.end,
                            'date': firestoreString(widget.selected)
                          });
                          FirebaseFirestore.instance
                              .collection("vendors").doc(vendor.id)
                              .collection("employees").doc(widget.employeeId)
                              .collection("appointments").doc(widget.app.id)
                              .update({
                            'startTime': newSlot!.start,
                            'endTime': newSlot!.end,
                            'date': firestoreString(widget.selected)
                          });
                        }


                        Navigator.pop(context);
                      }

                    },
                    color: colors.primary,
                    enabled: newSlot != null
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}