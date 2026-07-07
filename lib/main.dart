import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/application/customer/customer_page.dart';
import 'package:dogus_barber/application/vendor/vendor_page.dart';
import 'package:dogus_barber/auth+onboarding/employee_invitation.dart';
import 'package:dogus_barber/auth+onboarding/user_onboarding.dart';
import 'package:dogus_barber/controller+api/bookings_controller.dart';
import 'package:dogus_barber/utils/colors.dart';
import 'package:dogus_barber/utils/constants.dart';
import 'package:dogus_barber/utils/functions.dart';
import 'package:dogus_barber/utils/models.dart';
import 'package:dogus_barber/utils/widgets.dart';
import 'auth+onboarding/login_register.dart';
import 'controller+api/user_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // preserve splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  Future.delayed(const Duration(seconds: 2), () => FlutterNativeSplash.remove());

  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(EasyLocalization(
    supportedLocales: const [Locale('de')],
    path: 'assets/translations',
    fallbackLocale: const Locale('de'),
    child: const RestartWidget(child: MyApp())
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: UserController()),
        ChangeNotifierProvider.value(value: BookingsController())
      ],
      child: Builder(
        builder: (context) {
          ColorTheme colors = Provider.of<UserController>(context).getColors;
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            title: 'dogus_barber',
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                scrolledUnderElevation: 0.0,
                systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                iconTheme: IconThemeData(color: colors.textColor)
              ),
            ),
            home: const BasePage(),
          );
        },
      ),
    );
  }
}

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {

  StreamSubscription? authStream;
  StreamSubscription? invitationStream;
  String? invitationVendorId;

  void setInvitationStream() {
    if(FirebaseAuth.instance.currentUser == null) {
      return;
    }

    String email = FirebaseAuth.instance.currentUser!.email!.toLowerCase();
    invitationStream = FirebaseFirestore.instance
      .collection("vendors")
      .where("invited", arrayContains: email)
      .limit(1)
      .snapshots()
      .listen((query) {
        if(query.docs.isEmpty) {
          setState(() => invitationVendorId = null);
        }
        else {
          setState(() => invitationVendorId = query.docs.first.id);
        }
      });
  }

  Future<void> registerPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void logAppStart() {
    logAppStartFunctions.call();
  }

  @override
  void initState() {
    super.initState();
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {
      if(user != null) {
        setInvitationStream();
        registerPushNotifications();
      }
      else {
        invitationStream?.cancel();
        invitationVendorId = null;
      }
      setState(() {});
    });
    logAppStart();
  }

  @override
  void dispose() {
    authStream?.cancel();
    invitationStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    UserProfile? profile = Provider.of<UserController>(context).getUserProfile;
    Vendor? vendor = Provider.of<UserController>(context).getVendor;

    // not signed in -> show login screen
    if(user == null) {
      return const LoginScreen();
    }

    // user onboarding, required for user and vendor -> afterwards selection
    if(profile == null) {
      return const UserOnboarding();
    }

    // show employee invitation
    if(invitationVendorId != null) {
      return EmployeeInvitation(vendorId: invitationVendorId!);
    }

    if(vendor == null) {
      return Container();
    }

    // has vendor and is customer -> no employee has same id
    if(profile.vendorId.isNotEmpty && vendor.employees.every((element) => element.id != user.uid)) {
      return CustomerPage(key: Key(vendor.id));
    }

    // is vendor/employee -> employee has same uid as user
    // key to reload on vendor change
    return VendorPage(key: Key(vendor.id));
  }
}