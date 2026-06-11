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
import 'package:dogus_barber/utils/models.dart';
import '../../controller+api/user_controller.dart';
import '../../utils/colors.dart';
import '../../utils/widgets.dart';

class EmployeeInvitation extends StatefulWidget {

  final String vendorId;

  const EmployeeInvitation({super.key, required this.vendorId});

  @override
  State<EmployeeInvitation> createState() => _EmployeeInvitationState();
}

class _EmployeeInvitationState extends State<EmployeeInvitation> {

  Vendor? vendor;
  List<Employee> employees = [];

  bool loading = false;

  Future<void> fetchVendorAndEmployees() async {
    String vendorId = widget.vendorId;

    var vendorDoc = await FirebaseFirestore.instance
      .collection("vendors").doc(vendorId)
      .get();

    if(!vendorDoc.exists) {
      await declineEmployeeInvitation.call({ "vendorId": vendorId });
      return;
    }

    var query = await FirebaseFirestore.instance
      .collection("vendors").doc(vendorId)
      .collection("employees").get();

    setState(() {
      vendor = Vendor.fromMap(vendorDoc.data() as Map<String,dynamic>);
      employees.addAll(query.docs.map((e) =>
        Employee.fromMap(e.data())));
    });
  }

  @override
  void initState() {
    fetchVendorAndEmployees();
    super.initState();
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
          "general.joinAsEmployee".tr(),
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
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    if(vendor == null) {
      return Column(
        children: [
          const SizedBox(height: 80),
          Center(child: CupertinoActivityIndicator(color: colors.textColor))
        ],
      );
    }

    return LoadingStack(
      loading: loading,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
                color: colors.backgroundColor
              ),
              child: summary,
            ),
          ),
          buttonRow,
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

  Widget get summary {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          vendorImage,
          const SizedBox(height: 25),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: colors.buttonColor
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                displayText("Name", vendor!.name, false),
                Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                displayText("general.streetNr".tr(), vendor!.place.street!, true),
                Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
                displayText("general.plzCity".tr(), "${vendor!.place.plz!} ${vendor!.place.city!}", false),
                const SizedBox(height: 5),
              ],
            ),
          ),
          const SizedBox(height: 20),
          pageTitle("general.openingTimes".tr()),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: colors.buttonColor
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vendor!.openingTimes.length,
              separatorBuilder: (BuildContext context, int index) => Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
              itemBuilder: (BuildContext context, int index) {
                bool closed = vendor!.openingTimes[index].isEmpty;
                String label = "weekdays.weekday_${index+1}".tr();
                return Container(
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
                        closed ? "general.closed".tr() : vendor!.openingTimes[index],
                        style: TextStyle(
                            fontSize: 15,
                            color: closed ? CupertinoColors.destructiveRed : colors.textColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          pageTitle("general.employees".tr()),
          const SizedBox(height: 20),
          ListView.separated(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
            itemBuilder: (BuildContext context, int index) {
              Employee emp = employees[index];
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
                        MaterialPageRoute(builder: (context) => ImageViewer(hero: "join-${emp.id}", url: emp.imageUrl))
                      ),
                      child: ProfileImageCircle(emp.imageUrl, 45, hero: "join-${emp.id}")
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        emp.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textColor)
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget get vendorImage {
    if(vendor == null) {
      return Container();
    }
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    double width = 120;
    return Center(
      child: Container(
        width: width + 3,
        height: width + 3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: GradientBoxBorder(
            gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
            width: 3,
          ),
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ImageViewer(hero: "join-${vendor!.id}", url: vendor!.imageUrl))
          ),
          child: ProfileImageCircle(vendor!.imageUrl, width, hero: "join-${vendor!.id}")
        ),
      ),
    );
  }

  Widget displayText(String label, String text, bool showMapsIcon) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
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
          if (showMapsIcon)
            Container(
                padding: const EdgeInsets.all(10),
                child: Icon(Ionicons.map_outline, color: colors.textColor, size: 23)
            )
        ],
      ),
    );
  }

  Widget get buttonRow {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border(top: BorderSide(color: colors.textColor.withValues(alpha: 0.1), width: 1))
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SafeArea(
        child: Column(
          children: [
            Text(
              'general.joinAsEmployeeText'.tr(),
              style: TextStyle(
                fontSize: 15,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
                      ),
                      onPressed: () async {
                        setState(() => loading = true);
                        // update user profile
                        User authUser = FirebaseAuth.instance.currentUser!;
                        String uid = authUser.uid;
                        UserProfile up = Provider.of<UserController>(context, listen: false).getUserProfile!;
                        await FirebaseFirestore.instance.collection("user").doc(uid).update({ "vendorId": vendor!.id });

                        // make https call to update vendor doc and create employee profile
                        Employee emp = Employee(id: uid, name: up.name, imageUrl: up.imageUrl, email: authUser.email ?? "", phoneNr: up.phoneNr,
                            workTimes: List.generate(7, (index) => ""), breakTimes: List.generate(7, (index) => ""), services: []);
                        await acceptEmployeeInvitation.call({ 'vendorId': vendor!.id, 'employee': emp.toMap(), 'email': authUser.email });
                      },
                      child: Text(
                        'general.yes'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: FilledButton(
                      style: TextButton.styleFrom(
                        backgroundColor: colors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      onPressed: () async {
                        setState(() => loading = true);
                        User authUser = FirebaseAuth.instance.currentUser!;
                        await declineEmployeeInvitation.call({ 'vendorId': vendor!.id, 'email': authUser.email });
                      },
                      child: Text(
                        'general.no'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}