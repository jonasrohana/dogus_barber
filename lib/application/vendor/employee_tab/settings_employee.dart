import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dogus_barber/application/vendor/employee_tab/manage_fixed_appointments.dart';
import 'package:dogus_barber/application/vendor/employee_tab/manage_holidays.dart';
import 'package:dogus_barber/application/vendor/employee_tab/manage_services.dart';
import 'package:dogus_barber/application/vendor/employee_tab/edit_employee.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/models.dart';
import '../../../utils/widgets.dart';
import 'manage_calendar.dart';
import 'manage_user.dart';

class EmployeeSettings extends StatefulWidget {

  final bool showVerifyBadge;

  const EmployeeSettings({super.key, required this.showVerifyBadge});

  @override
  State<EmployeeSettings> createState() => _EmployeeSettingsState();
}

class _EmployeeSettingsState extends State<EmployeeSettings> {

  String userId = FirebaseAuth.instance.currentUser!.uid;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    Employee emp = Provider.of<UserController>(context).getEmployeeById(uid)!;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    bool isAdmin = vendor.admins.contains(uid);
    return LoadingStack(
      loading: loading,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  "general.settings".tr(),
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18
                  )
                ),
              ),
              const SizedBox(height: 15),
              userBox,
              const SizedBox(height: 5),
              SettingsMenu(
                showBadge: emp.services.isEmpty,
                icon: Ionicons.cut_outline,
                text: "services.services".tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageServices()),
                ),
              ),
              SettingsMenu(
                showBadge: emp.workTimes.every((e) => e.isEmpty),
                icon: Ionicons.calendar_number_outline,
                text: "general.calendar".tr(),
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ManageCalendar(selectedEmployeeId: uid)
                  ),
                ),
              ),
              SettingsMenu(
                showBadge: widget.showVerifyBadge,
                icon: Ionicons.people_outline,
                text: "user.manageUser".tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUser()),
                ),
              ),
              SettingsMenu(
                icon: Ionicons.airplane_outline,
                text: "general.holiday".tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageHolidays()),
                ),
              ),
              if(isAdmin)
                SettingsMenu(
                  icon: Ionicons.book_outline,
                  text: "booking.fixedAppointments".tr(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageFixedAppointments()),
                  ),
                ),
              SettingsMenu(
                isDestructive: true,
                icon: Ionicons.log_out_outline,
                text: "general.signOut".tr(),
                onPressed: () async {

                  setState(() => loading = true);
                  // get user and token
                  String userId = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseAuth.instance.signOut();

                  if(kDebugMode && mounted) {
                    Navigator.pop(context);
                    setState(() => loading = false);
                    return;
                  }

                  String? token = await FirebaseMessaging.instance.getToken();

                  if(token == null && mounted) {
                    Navigator.pop(context);
                    return;
                  }

                  // remove token from secure environment
                  removeToken.call({"token": token, "userId": userId});
                  if(!mounted) return;
                  setState(() => loading = true);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.fromLTRB(10,0,0,5),
                child: Text(
                  "Support",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18
                  )
                ),
              ),
              SettingsMenu(
                icon: Ionicons.language_outline,
                text: "language".tr(),
                onPressed: () => showModalBottomSheet(
                  backgroundColor: colors.buttonColor,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                  context: context,
                  builder: (BuildContext context) => ActionSheet(
                    actions: List.generate(3, (index) => ActionSheetAction(
                        leading: SizedBox(width: 38, height: 25, child: Image.asset("assets/languages/${languages[index]}.png", fit: BoxFit.fill)),
                        name: languages[index].tr(),
                        onPressed: () async {
                          context.setLocale(Locale(languages[index]));
                          Navigator.pop(context);
                          await FirebaseFirestore.instance
                              .collection("user").doc(userId)
                              .update({ "language": languages[index] });

                          if(!mounted) return;
                          RestartWidget.restartApp(context);
                        }
                    )),
                  ),
                ),
              ),
              SettingsMenu(
                icon: Ionicons.mail_outline,
                text: "general.support".tr(),
                onPressed: () async  {
                  const url = contactUrl;
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
              // SettingsMenu(
              //   icon: Ionicons.shield_checkmark_outline,
              //   text: "general.termsOfUse".tr(),
              //   onPressed: () { },
              // ),
              SettingsMenu(
                icon: Ionicons.eye_off_outline,
                text: "general.privacy".tr(),
                onPressed: () async  {
                  const url = privacyUrl;
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
              SettingsMenu(
                icon: Ionicons.people_outline,
                text: "general.imprint".tr(),
                onPressed: () async  {
                  const url = imprintUrl;
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
              SettingsMenu(
                isDestructive: true,
                icon: Ionicons.trash_outline,
                text: "general.deleteAccount".tr(),
                onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) => ShowDialogToDismiss(
                    buttonText: "OK",
                    title: "general.error".tr(),
                    content: "general.deleteAccountEmployeeText".tr()
                  )
                ),
              ),
              const SizedBox(height: 50)
            ],
          ),
        ),
      ),
    );
  }

  Widget get userBox {
    User authUser = FirebaseAuth.instance.currentUser!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Employee emp = Provider.of<UserController>(context).getEmployeeById(authUser.uid)!;
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: colors.buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    emp.name,
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  authUser.email ?? "",
                  style: TextStyle(
                    color: colors.textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    fontSize: 14
                  )
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditEmployee()),
                    ),
                    child: Text(
                      'general.editProfile'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ImageViewer(hero: emp.id, url: emp.imageUrl))
            ),
            child: ProfileImageCircle(emp.imageUrl, 100, hero: emp.id)
          ),
        ],
      ),
    );

  }
}

class ShareQRCode extends StatefulWidget {

  final String id;
  final String name;

  const ShareQRCode({super.key, required this.id, required this.name});

  @override
  State<ShareQRCode> createState() => _ShareQRCodeState();
}

class _ShareQRCodeState extends State<ShareQRCode> {

  GlobalKey qrKey = GlobalKey();

  Future<void> shareQrCode() async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/${widget.name}.png').create();
      await file.writeAsBytes(pngBytes);
      SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    double width = MediaQuery.of(context).size.width - 40;
    return Container(
      decoration: BoxDecoration(
        color: colors.buttonColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
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
                "general.shareQrCode".tr(),
                style: TextStyle(
                  fontSize: 18,
                  color: colors.textColor,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 25),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RepaintBoundary(
                key: qrKey,
                child: QrImageView(
                  padding: const EdgeInsets.all(20),
                  data: widget.id,
                  version: 2,
                  size: width,
                  eyeStyle: const QrEyeStyle(color: Colors.black),
                  gapless: false,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
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
                  onPressed: shareQrCode,
                  child: Text(
                    "general.share".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.primaryText,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}