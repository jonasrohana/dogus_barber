import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/utils/constants.dart';
import 'package:dogus_barber/utils/validator.dart';
import 'package:dogus_barber/utils/widgets.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';
import '../employee_tab/manage_calendar.dart';
import '../employee_tab/manage_holidays.dart';

class ManageEmployees extends StatefulWidget {
  const ManageEmployees({super.key});

  @override
  State<ManageEmployees> createState() => _ManageEmployeesState();
}

class _ManageEmployeesState extends State<ManageEmployees> with TickerProviderStateMixin {

  late TabController controller = TabController(length: 2, vsync: this);
  PageController pageController = PageController();
  int pageIndex = 0;

  String uid = FirebaseAuth.instance.currentUser!.uid;

  bool loading = false;

  void onPageChange(int i) {
    controller.animateTo(i);
    setState(() => pageIndex = i);
  }

  @override
  void dispose() {
    controller.dispose();
    pageController.dispose();
    super.dispose();
  }

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
          "general.employees".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: LoadingStack(loading: loading, child: body)),
      backgroundColor: colors.backgroundColor,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () async {
          final retVal = await showModalBottomSheet(
            backgroundColor: colors.buttonColor,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
            context: context,
            builder: (BuildContext context) => const AddEmployeeSheet(),
          );
          if(retVal != null && retVal is bool && retVal) {
            onPageChange(1);
          }
        },
        backgroundColor: colors.primary,
        child: Icon(Ionicons.add, color: colors.primaryText),
      )
    );
  }

  Widget get body {
    return Column(
      children: [
        const SizedBox(height: 10),
        CustomTabBar(
          controller: controller,
          tabs: [
            "general.active".tr(),
            "general.invited".tr(),
          ],
          function: onPageChange
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: controller,
            children: [
              KeepAlivePage(child: activeEmployeeList),
              KeepAlivePage(child: invitedEmployeeList),
            ],
          ),
        ),
      ],
    );
  }

  Widget get activeEmployeeList {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vendor.employees.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        Employee emp = vendor.employees[index];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: colors.buttonColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageViewer(hero: "emp-${emp.id}", url: emp.imageUrl))
                ),
                child: ProfileImageCircle(emp.imageUrl, 45, hero: "emp-${emp.id}")
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textColor)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emp.email,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.6))
                    ),
                    if(vendor.admins.contains(emp.id))
                      ...[
                        const SizedBox(height: 4),
                        Text(
                          "Admin",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300,
                              color: colors.textColor.withValues(alpha: 0.5), fontStyle: FontStyle.italic)
                        ),
                      ]
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if(emp.id != uid)
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: colors.buttonColor,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                    context: context,
                    builder: (BuildContext context) => ActionSheet(
                      actions: [
                        if(vendor.admins.contains(emp.id))
                          ActionSheetAction(
                            icon: Ionicons.person_remove_outline,
                            name: "actions.removeAdminRights".tr(),
                            onPressed: () => FirebaseFirestore.instance
                              .collection("vendors").doc(vendor.id)
                              .update({ 'admins': FieldValue.arrayRemove([emp.id]) })
                          )
                        else
                          ActionSheetAction(
                            icon: Ionicons.person_add_outline,
                            name: "actions.giveAdminRights".tr(),
                            onPressed: () => FirebaseFirestore.instance
                              .collection("vendors").doc(vendor.id)
                              .update({ "admins": FieldValue.arrayUnion([emp.id]) })
                          ),
                        ActionSheetAction(
                          icon: Ionicons.calendar_number_outline,
                          name: "Arbeitszeiten verwalten",
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                ManageCalendar(selectedEmployeeId: emp.id)
                            ),
                          )
                        ),
                        ActionSheetAction(
                          icon: Ionicons.airplane_outline,
                          name: "Urlaub verwalten",
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                              ManageHolidays(selectedEmployeeId: emp.id)
                            ),
                          )
                        ),
                        ActionSheetAction(
                          icon: Ionicons.close_outline,
                          destructive: true,
                          name: "actions.removeEmployee".tr(),
                          onPressed: () async {
                            final retVal = await showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                NativeDialog(
                                  title: "actions.removeEmployee".tr(),
                                  content: "actions.removeEmployeeText".tr(args: [emp.name]),
                                  buttonTextOne: "general.yes".tr(),
                                  buttonTextTwo: "general.no".tr(),
                                  buttonOne: () => Navigator.pop(context, true),
                                  buttonTwo: () => Navigator.pop(context, false),
                                  buttonOneRed: true,
                                )
                            );
                            if(retVal != null && retVal is bool && retVal) {
                              setState(() => loading = true);
                              try {
                                await removeEmployee.call({ "employeeId": emp.id, "vendorId": vendor.id });
                                setState(() => loading = false);
                              } catch (e) {
                                setState(() => loading = false);
                              }
                            }
                          }
                        ),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(Ionicons.ellipsis_vertical, size: 20, color: colors.textColor),
                  )
              ),
            ],
          ),
        );
      },
    );
  }

  Widget get invitedEmployeeList {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    if(vendor.invited.isEmpty) {
      return emptyState;
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vendor.invited.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        String name = vendor.invited[index];
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
                child: Text(
                  name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textColor)
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => FirebaseFirestore.instance
                  .collection('vendors').doc(vendor.id)
                  .update({ 'invited': FieldValue.arrayRemove([name]) }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.destructiveRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Ionicons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget get emptyState {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "user", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "general.noInvitedEmployees".tr(),
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

class AddEmployeeSheet extends StatefulWidget {

  const AddEmployeeSheet({super.key});

  @override
  State<AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<AddEmployeeSheet> {

  TextEditingController mail = TextEditingController();
  bool isSubmitted = false;

  bool get valid => validateEmail(mail.text) == null;

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
                  "general.inviteEmployee".tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.textColor,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Center(
                  child: Text(
                    "general.inviteEmployeeText".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textColor.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              mailTf,
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
                      if(vendor.invited.contains(mail.text)){
                        if(!mounted) return;
                        await showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                AnimationDialog(text: "general.alreadyInvited".tr(), isSuccess: false)
                        );
                        return;
                      }
                      for(var e in vendor.employees){
                        if(e.email.toLowerCase() == mail.text.toLowerCase()){
                          if(!mounted) return;
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  AnimationDialog(text: "general.alreadyEmployee".tr(), isSuccess: false)
                          );
                          return;
                        }
                      }
                      await FirebaseFirestore.instance
                        .collection("vendors").doc(vendor.id)
                        .update({ "invited": FieldValue.arrayUnion([mail.text.trim().toLowerCase()]) });

                      if(!mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      "general.invite".tr(),
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

  Widget get mailTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      cursorColor: colors.textColor,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      controller: mail,
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
        labelText: "login.email".tr(),
        fillColor: colors.textColor.withValues(alpha: 0.05),
        errorText: isSubmitted ? validateEmail(mail.text) : null,
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

}
