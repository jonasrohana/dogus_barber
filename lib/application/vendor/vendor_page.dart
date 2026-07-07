import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/application/chat/chat_overview.dart';
import 'package:dogus_barber/application/vendor/employee_tab/settings_employee.dart';
import 'package:dogus_barber/application/vendor/vendor_tab/settings_vendor.dart';
import 'package:dogus_barber/utils/widgets.dart';
import '../../controller+api/user_controller.dart';
import '../../utils/colors.dart';
import '../../utils/models.dart';
import 'bookings_tab/appointment2d.dart';
import 'bookings_tab/appointments.dart';

class VendorPage extends StatefulWidget {
  const VendorPage({super.key});

  @override
  State<VendorPage> createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> {

  StreamSubscription? authStream;
  StreamSubscription? chatStream;
  StreamSubscription? verifyStream;

  int tabIndex = 0;
  bool showChatBadge = false;
  bool showVerifyBadge = false;

  void initChatStream() {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    chatStream = FirebaseFirestore.instance
      .collection('vendors').doc(vendor.id)
      .collection('rooms')
      .where('userIds', arrayContains: uid)
      .where('unread', isEqualTo: [uid])
      .limit(1)
      .snapshots()
      .listen((event) => setState(() => showChatBadge = event.docs.isNotEmpty));
  }

  void initVerifyUserStream() {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    verifyStream = FirebaseFirestore.instance
      .collection('user')
      .where('unverifiedBy', arrayContains: vendor.id)
      .limit(1)
      .snapshots()
      .listen((event) => setState(() => showVerifyBadge = event.docs.isNotEmpty));
  }

  @override
  void initState() {
    super.initState();
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {
      if(user != null) {
        initChatStream();
        initVerifyUserStream();
      }
      else {
        chatStream?.cancel();
        showChatBadge = false;
        verifyStream?.cancel();
        showVerifyBadge = false;
      }
    });
  }

  @override
  void dispose() {
    authStream?.cancel();
    chatStream?.cancel();
    verifyStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
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
          appBar: [2,3].contains(tabIndex) ? null : AppBar(
            backgroundColor: Colors.transparent,
            leadingWidth: tabIndex == 0 ? 66 : null,
            toolbarHeight: 50,
            centerTitle: true,
            title: Text(
                vendor.name,
                style: TextStyle(
                    fontFamily: GoogleFonts.dancingScript().fontFamily,
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 26
                )
            ),
          ),
          backgroundColor: Colors.transparent,
          body: body,
          bottomNavigationBar: navBar,
        )
      ],
    );
  }

  Widget get body {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    bool isAdmin = vendor.admins.contains(uid);
    return FadeIndexedStack(
      index: tabIndex,
      children: [
        if(isAdmin)
          const AppointmentsTab2D(),
        const AppointmentsTab(),
        const ChatOverview(),
        if(isAdmin)
          const VendorSettings(),
        EmployeeSettings(showVerifyBadge: showVerifyBadge),
      ]
    );
  }

  Widget get navBar {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    Employee emp = Provider.of<UserController>(context).getEmployeeById(uid)!;

    // no services -> no work times -> show badge
    bool showConfigureBadge = emp.services.isEmpty || emp.workTimes.every((e) => e.isEmpty);
    bool isAdmin = vendor.admins.contains(uid);
    int profileIndex = isAdmin ? 4 : 2;
    int chatIndex = isAdmin? 2 : 1;
    bool showSubscriptionBadge = !vendor.active;
    return SizedBox(
      height: Platform.isIOS ? 85 : 70,
      child: BottomNavigationBar(
        selectedFontSize: 0,
        unselectedFontSize: 0,
        elevation: 0,
        backgroundColor: colors.buttonColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: tabIndex,
        onTap: (int index) => setState(() => tabIndex = index),
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: colors.textColor.withValues(alpha: 0.3),
        selectedItemColor: colors.textColor,
        items: [
          if(isAdmin)
            BottomNavigationBarItem(
                label: "appointmentsAll",
                icon: Column(
                  children: [
                    const SizedBox(height: 10),
                    Icon(
                      tabIndex == 1 ? Ionicons.apps : Ionicons.apps_outline,
                      size: 25,
                    ),
                    const SizedBox(height: 10),
                  ],
                )
            ),
          BottomNavigationBarItem(
            label: "appointments",
            icon: Column(
              children: [
                const SizedBox(height: 10),
                Icon(
                  tabIndex == 0 ? Ionicons.calendar : Ionicons.calendar_outline,
                  size: 25,
                ),
                const SizedBox(height: 10),
              ],
            )
          ),
          BottomNavigationBarItem(
            label: "chat",
            icon: Column(
              children: [
                const SizedBox(height: 10),
                Icon(
                  tabIndex == chatIndex ? Ionicons.chatbubbles : Ionicons.chatbubbles_outline,
                  size: 25,
                ),
                SizedBox(height: showChatBadge ? 4 : 10),
                if(showChatBadge)
                  Container(
                    height: 6,
                    width: 6,
                    decoration: const BoxDecoration(color: CupertinoColors.destructiveRed, shape: BoxShape.circle),
                  )
              ],
            )
          ),
          if(isAdmin)
            BottomNavigationBarItem(
                label: "shop",
                icon: Column(
                  children: [
                    const SizedBox(height: 10),
                    Icon(
                      tabIndex == 2 ? Ionicons.storefront : Ionicons.storefront_outline,
                      size: 25,
                    ),
                    SizedBox(height: showSubscriptionBadge ? 4 : 10),
                    if(showSubscriptionBadge)
                      Container(
                        height: 6,
                        width: 6,
                        decoration: const BoxDecoration(color: CupertinoColors.destructiveRed, shape: BoxShape.circle),
                      )
                  ],
                )
            ),
          BottomNavigationBarItem(
              label: "profile",
              icon: Column(
                children: [
                  const SizedBox(height: 10),
                  Icon(
                    tabIndex == profileIndex ? Ionicons.person : Ionicons.person_outline,
                    size: 25,
                  ),
                  SizedBox(height: showVerifyBadge || showConfigureBadge ? 4 : 10),
                  if(showVerifyBadge || showConfigureBadge)
                    Container(
                      height: 6,
                      width: 6,
                      decoration: const BoxDecoration(color: CupertinoColors.destructiveRed, shape: BoxShape.circle),
                    )
                ],
              )
          ),
        ],
      ),
    );
  }

}