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
import '../../../controller+api/user_controller.dart';
import '../../../controller+api/vendor_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';
import '../../../utils/widgets.dart';

class ManageCalendar extends StatefulWidget {

  final String? selectedEmployeeId;

  const ManageCalendar({super.key, this.selectedEmployeeId});

  @override
  State<ManageCalendar> createState() => _ManageCalendarState();
}

class _ManageCalendarState extends State<ManageCalendar> {

  String uid = FirebaseAuth.instance.currentUser!.uid;
  late String selectedEmployeeId = uid;
  AutoScrollController controller = AutoScrollController(axis: Axis.horizontal);

  bool showWorkTimes = false;
  bool showBreakTimes = false;

  late List<String> workTimes;
  late List<String> breakTimes ;

  late double weeksIndex;

  void setEmployee() {
    Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;
    Employee emp = Provider.of<VendorController>(context, listen: false).getEmployeeById(selectedEmployeeId)!;
    workTimes = emp.workTimes;
    breakTimes = emp.breakTimes;
    weeksIndex = emp.numBookingWeeks.toDouble();
    setState(() {});

    int index = vendor.employees.map((e) => e.id).toList().indexOf(selectedEmployeeId);
    controller.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
  }

  @override
  void initState() {
    selectedEmployeeId = widget.selectedEmployeeId != null ? widget.selectedEmployeeId! : uid;
    setEmployee();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "booking.manageCalendar".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.buttonColor,
    );
  }

  Widget get body {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  bookingWeeks,
                  pageTitle("general.workTimes".tr(), 0),
                  ExpandedSection(expand: showWorkTimes, child: workTimesEdit),
                  pageTitle("general.breakTimes".tr(), 1),
                  ExpandedSection(expand: showBreakTimes, child: breakTimesEdit),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          if(isAdmin)
            submitButton
        ],
      ),
    );
  }


  Widget get employeeSelection {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
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
                setEmployee();
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

  Widget get bookingWeeks {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Text(
            "booking.maxWeeks".tr(),
            style: TextStyle(
                color: colors.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500
            ),
          ),
        ),
        const SizedBox(height: 5.5,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "${weeksIndex.toInt()} Wochen",
            style: TextStyle(
                color: colors.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500
            ),
          ),
        ),
        Slider(
          activeColor: colors.primary,
          inactiveColor: colors.primary.withValues(alpha: 0.3),
          value: weeksIndex,
          min: 1,
          max: 10,
          divisions: 9,
          label: weeksIndex.toInt().toString(),
          onChanged:(double value) {
            if(isAdmin) setState(() => weeksIndex = value);
          },
        ),
      ],
    );
  }

  Widget pageTitle(String text, int type) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    bool expanded = type == 0 ? showWorkTimes : showBreakTimes;
    return GestureDetector(
      onTap: () => setState(() {
        if(type == 0) {
          showWorkTimes = !showWorkTimes;
        }
        else {
          showBreakTimes = !showBreakTimes;
        }
      }),
      child: Container(
        color: colors.buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700
                ),
              ),
            ),
            Icon(
              expanded ? Ionicons.chevron_down : Ionicons.chevron_forward,
              color: colors.textColor,
              size: 20,
            )
          ],
        ),
      ),
    );
  }
  
  Widget get workTimesEdit {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: colors.buttonColor
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: workTimes.length,
        separatorBuilder: (BuildContext context, int index) => Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
        itemBuilder: (BuildContext context, int index) {
          bool closed = workTimes[index].isEmpty;
          String label = "weekdays.weekday_${index+1}".tr();
          return InkWell(
            onTap: isAdmin ? () async {
              final retVal = await showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: colors.backgroundColor,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                context: context,
                builder: (BuildContext context) => TimeRangeSheet(label: label, time: workTimes[index]),
              );
              if(retVal != null && retVal is String) {
                setState(() => workTimes[index] = retVal);
              }
            } : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                          fontSize: 15,
                          color: colors.textColor,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                  Text(
                    closed ? "general.closed".tr() : workTimes[index],
                    style: TextStyle(
                      fontSize: 15,
                      color: closed ? CupertinoColors.destructiveRed : colors.textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get breakTimesEdit {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: colors.buttonColor
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: breakTimes.length,
        separatorBuilder: (BuildContext context, int index) => Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
        itemBuilder: (BuildContext context, int index) {
          List<String> breakTimeForDay = breakTimes[index].split(";");
          String label = "weekdays.weekday_${index+1}".tr();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 105,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textColor,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    runSpacing: 4,
                    spacing: 4,
                    children: [

                      ...List.generate(breakTimeForDay.length, (i) {
                        return breakTimeForDay[i].isNotEmpty ? InkWell(
                          onTap: isAdmin ? () async {
                            final retVal = await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: colors.backgroundColor,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                              context: context,
                              builder: (BuildContext context) => TimeRangeSheet(label: label, time: breakTimes[index], isBreakTimeEdit: true),
                            );
                            if(retVal != null && retVal is String) {
                              breakTimeForDay[i] = retVal;
                              setState(() => breakTimes[index] = breakTimeForDay.join(";"));
                            }
                          } : null,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              color: colors.backgroundColor
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  breakTimeForDay[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textColor,
                                  )
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    breakTimeForDay.removeAt(i);
                                    setState(() => breakTimes[index] = breakTimeForDay.join(";"));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.withValues(alpha: 0.6),
                                    ),
                                    child: Center(child: Icon(Ionicons.close, size: 14, color: colors.textColor))
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ) : Container();
                      }),
                      if(isAdmin)
                        GestureDetector(
                          onTap: () async {
                            final retVal = await showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: colors.backgroundColor,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                              context: context,
                              builder: (BuildContext context) => TimeRangeSheet(label: label, time: "", isBreakTimeEdit: true),
                            );
                            if(retVal != null && retVal is String) {
                              if(breakTimes[index].isEmpty) {
                                setState(() => breakTimes[index] = retVal);
                              }
                              else {
                                setState(() => breakTimes[index] = "${breakTimes[index]};$retVal");
                              }
                            }
                          },
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              color: colors.backgroundColor
                            ),
                            child: Icon(Icons.add, size: 20, color: colors.textColor)
                          )
                        ),
                    ]
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget get submitButton {
    Vendor vendor = Provider.of<VendorController>(context).getVendor!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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
              await FirebaseFirestore.instance
                .collection("vendors").doc(vendor.id)
                .collection("employees").doc(selectedEmployeeId)
                .update({
                  'workTimes': workTimes,
                  'breakTimes': breakTimes,
                  'numBookingWeeks': weeksIndex
                });
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
