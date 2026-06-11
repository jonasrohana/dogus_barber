import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:dogus_barber/utils/functions.dart';
import 'package:dogus_barber/utils/widgets.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';

class ManageHolidays extends StatefulWidget {

  final String? selectedEmployeeId;

  const ManageHolidays({super.key, this.selectedEmployeeId});

  @override
  State<ManageHolidays> createState() => _ManageHolidaysState();
}

class _ManageHolidaysState extends State<ManageHolidays> with TickerProviderStateMixin {

  late Stream holidayStream;
  late String selectedEmployeeId;
  AutoScrollController controller = AutoScrollController(axis: Axis.horizontal);

  String uid = FirebaseAuth.instance.currentUser!.uid;
  
  void setHolidayStream()  {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    holidayStream = FirebaseFirestore.instance
      .collection("vendors").doc(vendor.id)
      .collection("employees").doc(selectedEmployeeId)
      .collection("holidays")
      .where("endDate", isGreaterThan: DateTime.now())
      .snapshots();

    int index = vendor.employees.map((e) => e.id).toList().indexOf(selectedEmployeeId);
    controller.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
  }

  @override
  void initState() {
    super.initState();
    selectedEmployeeId = widget.selectedEmployeeId != null ? widget.selectedEmployeeId! : uid;
    setHolidayStream();
  }

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "general.manageHolidays".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.buttonColor,
      floatingActionButton: isAdmin ? FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => showModalBottomSheet(
          backgroundColor: colors.buttonColor,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30))),
          context: context,
          builder: (BuildContext context) => CreateHolidaySheet(employeeId: selectedEmployeeId),
        ),
        backgroundColor: colors.primary,
        child: Icon(Ionicons.add, color: colors.primaryText),
      ) : null,
    );
  }

  Widget get body {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.only(top: 15),
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
          color: colors.backgroundColor
      ),
      child: Column(
        children: [
          if(isAdmin)
            ...[
              const SizedBox(height: 15),
              employeeSelection,
              const SizedBox(height: 15),
            ],
          Expanded(
            child: StreamBuilder(
              stream: holidayStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Es ist ein Fehler aufgetreten.', style: TextStyle(color: Colors.white));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      SizedBox(height: 20),
                      Center(child: CircularProgressIndicator()),
                      SizedBox(height: 20)
                    ],
                  );
                }

                List<Holiday> holidays = snapshot.data!.docs.map<Holiday>((e) =>
                    Holiday.fromMap(e.data() as Map<String, dynamic>)).toList();

                if(holidays.isEmpty) {
                  return emptyState;
                }

                holidays.sort();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 100),
                  itemCount: holidays.length,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    Holiday hol = holidays[index];
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: colors.buttonColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hol.name,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textColor)
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "${firestoreString(hol.startDate)} - ${firestoreString(hol.endDate)}",
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.7))
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if(isAdmin)
                            GestureDetector(
                            onTap: () async {
                              final retVal = await showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                  NativeDialog(
                                    title: "general.cancelHoliday".tr(),
                                    content: "general.cancelHolidayDescription".tr(),
                                    buttonTextOne: "general.yes".tr(),
                                    buttonTextTwo: "general.no".tr(),
                                    buttonOne: () => Navigator.pop(context, true),
                                    buttonTwo: () => Navigator.pop(context, false),
                                    buttonOneRed: true,
                                  )
                              );

                              if(retVal != null && retVal is bool && retVal) {
                                var mainDocRef = FirebaseFirestore.instance
                                  .collection("vendors").doc(vendor.id)
                                  .collection("employees").doc(selectedEmployeeId)
                                  .collection("holidays").doc(hol.id);

                                var query = await FirebaseFirestore.instance
                                  .collection("vendors").doc(vendor.id)
                                  .collection("employees").doc(selectedEmployeeId)
                                  .collection("privateAppointments")
                                  .where("holidayId", isEqualTo: hol.id)
                                  .get();

                                WriteBatch batch = FirebaseFirestore.instance.batch();
                                for(var doc in query.docs) {
                                  batch.delete(doc.reference);
                                }
                                batch.delete(mainDocRef);
                                await batch.commit();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: CupertinoColors.destructiveRed,
                                shape: BoxShape.circle
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.multiply,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
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

                selectedEmployeeId = emp.id;
                setHolidayStream();
                setState(() {});
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

  Widget get emptyState {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "holiday", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "general.noHolidays".tr(),
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

}

class CreateHolidaySheet extends StatefulWidget {

  final String employeeId;

  const CreateHolidaySheet({super.key, required this.employeeId});

  @override
  State<CreateHolidaySheet> createState() => _CreateHolidaySheetState();
}

class _CreateHolidaySheetState extends State<CreateHolidaySheet> {

  TextEditingController name = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: colors.buttonColor
      ),
      child: LoadingStack(
        loading: loading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                Center(
                  child: Container(
                    height: 5, width: 45,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(15)
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    "general.selectHolidayDates".tr(),
                    style: TextStyle(color: colors.textColor, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: colors.textColor,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  controller: name,
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
                    labelText: "general.holidayName".tr(),
                    fillColor: colors.textColor.withValues(alpha: 0.05),
                  )
                ),
                const SizedBox(height: 15),
                SfDateRangePicker(
                  backgroundColor: Colors.transparent,
                  minDate: DateTime.now(),
                  initialDisplayDate: DateTime.now(),
                  showActionButtons: false,
                  view: DateRangePickerView.month,
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    viewHeaderStyle: DateRangePickerViewHeaderStyle(textStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.7))),
                    firstDayOfWeek: 1,
                  ),
                  selectionMode: DateRangePickerSelectionMode.range,
                  onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                    final value = args.value;
                    if (value is PickerDateRange) {
                      setState(() {
                        startDate = value.startDate;
                        endDate = value.endDate;
                      });
                    }
                  },
                  selectionColor: colors.primary,
                  selectionTextStyle: TextStyle(color: colors.primaryText),
                  startRangeSelectionColor: colors.primary,
                  endRangeSelectionColor: colors.primary,
                  rangeSelectionColor: colors.primary.withValues(alpha: 0.5),
                  todayHighlightColor: colors.primary,
                  headerStyle: DateRangePickerHeaderStyle(
                    backgroundColor: Colors.transparent,
                    textStyle: TextStyle(color: colors.textColor),
                  ),
                  yearCellStyle: DateRangePickerYearCellStyle(
                    textStyle: TextStyle(color: colors.textColor),
                    todayTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    leadingDatesTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
                    disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                  ),
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: TextStyle(color: colors.textColor),
                    weekendTextStyle: TextStyle(color: colors.textColor),
                    todayTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    leadingDatesTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
                    disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                PrimaryButton(
                  text: "general.save".tr(),
                  onPressed: () async {
                    if(startDate == null || endDate == null || loading) {
                      return;
                    }

                    setState(() => loading = true);
                    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
                    String uid = FirebaseAuth.instance.currentUser!.uid;

                    var mainDocRef = FirebaseFirestore.instance
                      .collection("vendors").doc(vendor.id)
                      .collection("employees").doc(widget.employeeId)
                      .collection("holidays").doc();

                    var privateRef = FirebaseFirestore.instance
                      .collection("vendors").doc(vendor.id)
                      .collection("employees").doc(widget.employeeId)
                      .collection("privateAppointments");

                    var publicRef = FirebaseFirestore.instance
                      .collection("vendors").doc(vendor.id)
                      .collection("employees").doc(widget.employeeId)
                      .collection("appointments");

                    Holiday holiday = Holiday(id: mainDocRef.id, name: name.text,
                        startDate: startDate!, endDate: endDate!);

                    WriteBatch batch = FirebaseFirestore.instance.batch();
                    batch.set(mainDocRef, holiday.toMap());

                    // loop over all dates and set appointments
                    var runnerDate = startDate!;
                    while([-1, 0].contains(runnerDate.compareTo(endDate!))) {
                      var doc = privateRef.doc();
                      Appointment app = Appointment(id: doc.id, date: firestoreString(runnerDate), userId: "",
                          startTime: 6, endTime: 23, holidayId: mainDocRef.id, employeeId: uid, vendorId: vendor.id);
                      batch.set(publicRef.doc(doc.id), app.toMap());
                      app.name = name.text;
                      batch.set(privateRef.doc(doc.id), app.toMap());
                      runnerDate = runnerDate.add(const Duration(days: 1));
                    }

                    await batch.commit();
                    setState(() => loading = false);

                    if(!context.mounted) return;
                    Navigator.pop(context);
                  },
                  color: colors.textColor,
                  enabled: startDate != null && endDate != null
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}