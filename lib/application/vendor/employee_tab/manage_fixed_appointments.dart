import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/utils/functions.dart';
import 'package:dogus_barber/utils/widgets.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';


class ManageFixedAppointments extends StatefulWidget {
  const ManageFixedAppointments({super.key});

  @override
  State<ManageFixedAppointments> createState() => _ManageFixedAppointmentsState();
}

class _ManageFixedAppointmentsState extends State<ManageFixedAppointments> {

  late Stream fixedAppointmentsStream;

  String uid = FirebaseAuth.instance.currentUser!.uid;

  void setFixedAppointmentsStream()  {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    fixedAppointmentsStream = FirebaseFirestore.instance
      .collection("vendors").doc(vendor.id)
      .collection("employees").doc(uid)
      .collection("fixedAppointments")
      .snapshots();
  }

  @override
  void initState() {
    setFixedAppointmentsStream();
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
          "booking.fixedAppointments".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.buttonColor,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) => ShowDialogToDismiss(
            buttonText: "OK",
            title: "booking.fixedBookAppointment".tr(),
            content: "booking.addFixedDescription".tr()
          )
        ),
        backgroundColor: colors.primary,
        child: Icon(Ionicons.add, color: colors.primaryText),
      ),
    );
  }

  Widget get body {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.only(top: 20),
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
          color: colors.backgroundColor
      ),
      child: StreamBuilder(
        stream: fixedAppointmentsStream,
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

          List<FixedAppointment> fixedAppointments = snapshot.data!.docs.map<FixedAppointment>((e) =>
              FixedAppointment.fromMap(e.data() as Map<String, dynamic>)).toList();

          if(fixedAppointments.isEmpty) {
            return emptyState;
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 100),
            itemCount: fixedAppointments.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              FixedAppointment fixedApp = fixedAppointments[index];
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
                            fixedApp.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textColor)
                          ),
                          const SizedBox(height: 3),
                          Text(
                              "${"weekdays.weekday_${fixedApp.weekDay+1}".tr()}, ${timeToString(toTime(fixedApp.startTime))} - ${timeToString(toTime(fixedApp.endTime))}",
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.7))
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final retVal = await showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                            NativeDialog(
                              title: "booking.cancelFixed".tr(),
                              content: "booking.cancelFixedDescription".tr(),
                              buttonTextOne: "general.yes".tr(),
                              buttonTextTwo: "general.no".tr(),
                              buttonOne: () => Navigator.pop(context, true),
                              buttonTwo: () => Navigator.pop(context, false),
                              buttonOneRed: true,
                            )
                        );

                        if(retVal != null && retVal is bool && retVal) {
                          FirebaseFirestore.instance
                            .collection("vendors").doc(vendor.id)
                            .collection("employees").doc(uid)
                            .collection("fixedAppointments").doc(fixedApp.id)
                            .delete();
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
    );
  }

  Widget get emptyState {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "calendar", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "booking.noFixedAppointments".tr(),
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
