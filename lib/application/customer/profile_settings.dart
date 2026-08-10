import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/application/customer/edit_profile.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/models.dart';
import '../../../utils/widgets.dart';
import '../../auth+onboarding/reauth_dialog.dart';

class CustomerSettingsProfile extends StatefulWidget {

  const CustomerSettingsProfile({super.key});

  @override
  State<CustomerSettingsProfile> createState() => _CustomerSettingsProfileState();
}

class _CustomerSettingsProfileState extends State<CustomerSettingsProfile> {

  bool loading = false;
  String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<bool> reauthenticate() async {
    User user = FirebaseAuth.instance.currentUser!;
    try {
      final result = await showDialog(
        context: context,
        builder: (context) => const ReAuthDialog(),
      );

      if(result == null) {
        return false;
      }

      await user.reauthenticateWithCredential(result);
    } catch (e) {
      if (kDebugMode) {
        print("Fehler bei der Reauthentifizierung: $e");
      }
      return false;
    }
    return true;
  }

  Future<void> deleteAction() async {

    bool success = await reauthenticate();
    if(!success || !mounted) return;

    final retVal = await showDialog(
      context: context,
      builder: (BuildContext context) =>
        NativeDialog(
          title: "general.deleteAcc".tr(),
          content: "general.deleteQuestion".tr(),
          buttonTextOne: "general.yes".tr(),
          buttonTextTwo: "general.no".tr(),
          buttonOne: () => Navigator.pop(context, true),
          buttonTwo: () => Navigator.pop(context, false),
          buttonOneRed: true,
        )
    );

    if(retVal && retVal is bool && retVal) {
      setState(() => loading = true);
      await deleteTermine();

      String path = '/user/$userId';
      deleteAccountFunctions.call({'path': path});

      // delete user doc
      await FirebaseFirestore.instance
        .collection("user").doc(userId)
        .delete();

      // delete user
      await FirebaseAuth.instance.currentUser!.delete();
      setState(() => loading = false);

      // pop dialog and settings screen
      if(!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> deleteTermine() async {
    var query = await FirebaseFirestore.instance.collectionGroup("privateAppointments").where('userId', isEqualTo: userId).get();
    List<Appointment> allTermine = query.docs.map((doc) => Appointment.fromMap(doc.data(), doc.id)).toList();
    for(Appointment t in allTermine) {
      FirebaseFirestore.instance
        .collection("vendors").doc(t.vendorId)
        .collection("employees").doc(t.employeeId)
        .collection("privateAppointments").doc(t.id)
        .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return WillPopScope(
      onWillPop: () => Future.value(!loading),
      child: Stack(
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
              backgroundColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                  "general.settings".tr(),
                  style: TextStyle(
                      color: colors.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                  )
              ),
            ),
            backgroundColor: Colors.transparent,
            body: FadeInUp(child: LoadingStack(loading: loading, child: body)),
          ),
        ],
      )
    );
  }

  Widget get body {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          userBox,
          const SizedBox(height: 6),
          SettingsMenu(
            isDestructive: true,
            icon: Ionicons.log_out_outline,
            text: "general.signOut".tr(),
            onPressed: () async {
              // get user and token
              setState(() => loading = true);
              String? token;
              if (!kDebugMode) {
                try {
                  token = await FirebaseMessaging.instance.getToken();
                } catch (e) {
                  print('FCM token error: $e');
                }
              }
              await FirebaseAuth.instance.signOut();

              if(!mounted) return;
              Navigator.pop(context);

              if(!kDebugMode && token != null) removeToken.call({"token": token, "userId": userId});

              setState(() => loading = false);
            },
          ),
          const SizedBox(height: 25),
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
            onPressed: () => deleteAction(),
          ),
          const SizedBox(height: 80)
        ],
      ),
    );
  }

  Widget get userBox {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    UserProfile? user = Provider.of<UserController>(context).getUserProfile;

    if(user != null){
      User authUser = FirebaseAuth.instance.currentUser!;
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
                    user.name,
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
                        MaterialPageRoute(builder: (context) => const EditProfile()),
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
                MaterialPageRoute(builder: (context) => ImageViewer(hero: user.id, url: user.imageUrl))
              ),
              child: ProfileImageCircle(user.imageUrl, 100, hero: user.id)
            ),
          ],
        ),
      );
    }
    else {
      return Container();
    }

  }
}
