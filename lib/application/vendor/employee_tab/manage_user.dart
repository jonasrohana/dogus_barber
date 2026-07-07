import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:time_range/time_range.dart';
import 'package:dogus_barber/utils/constants.dart';
import 'package:dogus_barber/utils/functions.dart';
import 'package:dogus_barber/utils/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';
import '../../chat/chat_detail.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ManageUser extends StatefulWidget {
  const ManageUser({super.key});

  @override
  State<ManageUser> createState() => _ManageUserState();
}

class _ManageUserState extends State<ManageUser> with TickerProviderStateMixin {

  late TabController controller = TabController(length: 3, vsync: this);
  PageController pageController = PageController();
  int pageIndex = 0;

  String uid = FirebaseAuth.instance.currentUser!.uid;

  List<bool> loading = [true, true, true];

  TextEditingController searchString = TextEditingController();

  List<UserProfile> missingVerification = [];
  List<UserProfile> allUser = [];
  List<UserProfile> blocked = [];

  Future<void> fetchOpenVerificationUser() async {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    var query = await FirebaseFirestore.instance
      .collection('user')
      .where('unverifiedBy', arrayContains: vendor.id)
      .get();
    setState(() {
      missingVerification = query.docs.map((e) => UserProfile.fromMap(e.data())).toList();
      missingVerification.sort((a, b) => a.name.compareTo(b.name));
      loading[0] = false;
    });
  }

  Future<void> fetchAllUser() async {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    var query = await FirebaseFirestore.instance
      .collection('user')
      .where('verifiedBy', arrayContains: vendor.id)
      .get();
    setState(() {
      allUser = query.docs.map((e) => UserProfile.fromMap(e.data())).toList();
      allUser.sort((a, b) => a.name.compareTo(b.name));
      loading[1] = false;
    });
  }

  Future<void> fetchBlockedUser() async {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    var query = await FirebaseFirestore.instance
      .collection('user')
      .where('disabledBy', arrayContains: vendor.id)
      .get();
    setState(() {
      blocked = query.docs.map((e) => UserProfile.fromMap(e.data())).toList();
      blocked.sort((a, b) => a.name.compareTo(b.name));
      loading[2] = false;
    });
  }

  void onPageChange(int i) {
    if(i == 1 && loading[1]) {
      fetchAllUser();
    }
    if(i == 2 && loading[2]) {
      fetchBlockedUser();
    }
    controller.animateTo(i);
    setState(() => pageIndex = i);
  }

  @override
  void initState() {
    fetchOpenVerificationUser();
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
          "user.manageUser".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: body,
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget get body {
    return Column(
      children: [
        const SizedBox(height: 10),
        CustomTabBar(
          controller: controller,
          tabs: [
            "user.requests".tr(),
            "user.verified".tr(),
            "user.blocked".tr(),
          ],
          function: onPageChange
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: controller,
            children: [
              KeepAlivePage(child: unverifiedUserList),
              KeepAlivePage(child: allUserList),
              KeepAlivePage(child: blockedUserList),
            ],
          ),
        ),
      ],
    );
  }

  Widget get unverifiedUserList {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    if(loading[0]) {
      return Column(
        children: [
          const SizedBox(height: 80),
          Center(child: CupertinoActivityIndicator(color: colors.textColor))
        ],
      );
    }
    if(missingVerification.isEmpty) {
      return emptyState(0);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 80),
      itemCount: missingVerification.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        UserProfile up = missingVerification[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(15,15,10,15),
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
                      MaterialPageRoute(builder: (context) => ImageViewer(hero: "user-${up.id}", url: up.imageUrl))
                  ),
                  child: ProfileImageCircle(up.imageUrl, 50, hero: "user-${up.id}")
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextScroll(
                        up.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textColor)
                    ),
                    const SizedBox(height: 2),
                    TextScroll(
                        up.email,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.6))
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  verifyUser.call({
                    'userId': up.id,
                    'vendorId': vendor.id
                  });
                  setState(() {
                    missingVerification.removeAt(index);
                    allUser.add(up);
                    allUser.sort((a, b) => a.name.compareTo(b.name));
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.activeGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Ionicons.checkmark,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  blockUser.call({
                    'userId': up.id,
                    'vendorId': vendor.id
                  });
                  setState(() {
                    missingVerification.removeAt(index);
                    blocked.add(up);
                    blocked.sort((a, b) => a.name.compareTo(b.name));
                  });
                },
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

  Widget get allUserList {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    bool isAdmin = vendor.admins.contains(uid);
    bool fixedApps = vendor.employees.any(
          (emp) => emp.workTimes.any((day) => day.isNotEmpty),
    );
    if(loading[1]) {
      return Column(
        children: [
          const SizedBox(height: 80),
          Center(child: CupertinoActivityIndicator(color: colors.textColor))
        ],
      );
    }

    String normalizedSearchString = searchString.text.toLowerCase();
    List<UserProfile> filteredUser = allUser.where((user) {
      String normalizedUserName = user.name.toLowerCase();
      return normalizedUserName.contains(normalizedSearchString);
    }).toList();

    if (filteredUser.isEmpty) {
      return Column(
        children: [
          searchBar,
          Expanded(child: emptyState(1)),
        ],
      );
    }

    return Column(
      children: [
        searchBar,
        const SizedBox(height: 15),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 80),
            itemCount: filteredUser.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              UserProfile up = filteredUser[index];
              return Container(
                padding: const EdgeInsets.fromLTRB(15,15,0,15),
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
                            MaterialPageRoute(builder: (context) => ImageViewer(hero: "user-${up.id}", url: up.imageUrl))
                        ),
                        child: ProfileImageCircle(up.imageUrl, 60, hero: "user-${up.id}")
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextScroll(
                              up.name,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textColor)
                          ),
                          TextScroll(
                              up.email,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.8))
                          ),
                          if(up.lastSignIn != null)
                            ...[
                              const SizedBox(height: 3),
                              Text(
                                  "${"dates.lastAccess".tr()}${createLastAccessString(up.lastSignIn!)}",
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.5))
                              ),
                            ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: colors.buttonColor,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                            context: context,
                            builder: (BuildContext context) => ActionSheet(
                              actions: [
                                ActionSheetAction(
                                    icon: Ionicons.chatbubble_ellipses_outline,
                                    name: "actions.sendMessage".tr(),
                                    enabled: up.id.isNotEmpty,
                                    onPressed: () => navigateToChat(context, up.id, true)
                                ),
                                ActionSheetAction(
                                    icon: Ionicons.call_outline,
                                    name: "actions.call".tr(),
                                    enabled: up.phoneNr.isNotEmpty,
                                    onPressed: () => launchUrlString("tel://${up.phoneNr}")
                                ),
                                if(isAdmin && fixedApps)
                                  ActionSheetAction(
                                      icon: Ionicons.calendar_number_outline,
                                      name: "actions.bookFixedApp".tr(),
                                      enabled: up.id.isNotEmpty,
                                      onPressed: () async {
                                        await showModalBottomSheet(
                                            isScrollControlled: true,
                                            backgroundColor: colors.buttonColor,
                                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                                            context: context,
                                            builder: (BuildContext context) => BookingFixedAppointmentSheet(
                                                up: up)
                                        );
                                      }
                                  ),
                                ActionSheetAction(
                                    icon: Ionicons.close_outline,
                                    name: "Nutzer sperren",
                                    destructive: true,
                                    onPressed: () async {
                                      await showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              NativeDialog(
                                                title: "Nutzer sperren",
                                                content: "Willst du den Nutzer ${up.name} wirklich sperren?",
                                                buttonTextOne: "Ja",
                                                buttonTextTwo: "Nein",
                                                buttonOne: () {
                                                  blockUser.call({
                                                    'userId': up.id,
                                                    'vendorId': vendor.id
                                                  });
                                                  setState(() {
                                                    allUser.removeAt(index);
                                                    blocked.add(up);
                                                    blocked.sort((a, b) => a.name.compareTo(b.name));
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                buttonTwo: () => Navigator.pop(context),
                                                buttonOneRed: true,
                                              )
                                      );
                                    }
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(Ionicons.ellipsis_vertical, size: 20, color: colors.textColor),
                        )
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget get blockedUserList {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    if(loading[2]) {
      return Column(
        children: [
          const SizedBox(height: 80),
          Center(child: CupertinoActivityIndicator(color: colors.textColor))
        ],
      );
    }
    if(blocked.isEmpty) {
      return emptyState(2);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 80),
      itemCount: blocked.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        UserProfile up = blocked[index];
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
                  MaterialPageRoute(builder: (context) => ImageViewer(hero: "user-${up.id}", url: up.imageUrl))
                ),
                child: ProfileImageCircle(up.imageUrl, 50, hero: "user-${up.id}")
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextScroll(
                      up.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textColor)
                    ),
                    const SizedBox(height: 2),
                    TextScroll(
                      up.email,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textColor.withValues(alpha: 0.6))
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))
                ),
                onPressed: () {
                  verifyUser.call({
                    'userId': up.id,
                    'vendorId': vendor.id
                  });
                  setState(() {
                    blocked.removeAt(index);
                    allUser.add(up);
                    allUser.sort((a, b) => a.name.compareTo(b.name));
                  });
                },
                child: Text(
                  'user.unblock'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.primaryText,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget get searchBar {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        cursorColor: colors.textColor.withValues(alpha: 0.5),
        controller: searchString,
        autofocus: false,
        onChanged: (value) => setState(() {}),
        style: TextStyle(color: colors.textColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          prefixIcon: Icon(Ionicons.search_outline, color: colors.textColor, size: 20),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          suffixIcon: searchString.text.isNotEmpty ? IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => searchString.clear());
            },
            icon: Icon(Ionicons.close_circle, color: colors.textColor, size: 20),
          ) : null,
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
          labelText: "${"general.searchCustomer".tr()}...",
          labelStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
          fillColor: colors.buttonColor,
        ),
      ),
    );
  }

  Widget emptyState(int type) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    late String text;
    if(type == 0) {
      text = "user.noUnverifiedUser".tr();
    }
    else if(type == 1) {
      text = "user.noUser".tr();
    }
    else {
      text = "user.noBlockedUser".tr();
    }

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const ThemedSvgImage(assetName: "user", height: 150),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              text,
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

class BookingFixedAppointmentSheet extends StatefulWidget {
  final UserProfile up;

  const BookingFixedAppointmentSheet({
    super.key,
    required this.up,
  });

  @override
  State<BookingFixedAppointmentSheet> createState() =>
      _BookingFixedAppointmentSheetState();
}

class _BookingFixedAppointmentSheetState extends State<BookingFixedAppointmentSheet> {
  TextEditingController name = TextEditingController();
  TextEditingController service = TextEditingController();

  String uid = FirebaseAuth.instance.currentUser!.uid;

  late String selectedEmployeeId;
  AutoScrollController employeeController =
  AutoScrollController(axis: Axis.horizontal);

  List<FixedAppointment> fixedAppointments = [];
  bool loadingFixedAppointments = true;

  Map<int, String> days = {};
  int? selectedDay;

  TimeRangeResult timeRange = TimeRangeResult(
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
  );

  bool get isAdmin {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    return vendor.admins.contains(uid);
  }

  @override
  void initState() {
    super.initState();

    name.text = widget.up.name;

    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;

    selectedEmployeeId = vendor.employees.firstWhere((emp) => emp.workTimes.any((day) => day.isNotEmpty)).id;

    setEmployee();
  }

  void setEmployee() {
    Employee emp = Provider.of<UserController>(context, listen: false)
        .getEmployeeById(selectedEmployeeId)!;

    days.clear();

    int i = 1;
    for (String day in emp.workTimes) {
      if (day.isNotEmpty) {
        days[i] = "weekdays.weekday_$i".tr();
      }
      i++;
    }

    selectedDay = days.isNotEmpty ? days.keys.first : null;
    loadingFixedAppointments = true;

    fetchFixedAppointments();

    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    int index = vendor.employees.map((e) => e.id).toList().indexOf(selectedEmployeeId);

    if (index >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !employeeController.hasClients) return;
        employeeController.scrollToIndex(
          index,
          preferPosition: AutoScrollPosition.middle,
        );
      });
    }
  }

  Future<void> fetchFixedAppointments() async {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    final String empId = selectedEmployeeId;

    var query = await FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendor.id)
        .collection('employees')
        .doc(empId)
        .collection('fixedAppointments')
        .get();

    if (!mounted || selectedEmployeeId != empId) return;

    setState(() {
      fixedAppointments =
          query.docs.map((e) => FixedAppointment.fromMap(e.data())).toList();
      loadingFixedAppointments = false;
    });
  }

  Future<void> bookFixedAppointment() async {
    if (selectedDay == null || loadingFixedAppointments) return;

    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;

    var newDoc = FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendor.id)
        .collection('employees')
        .doc(selectedEmployeeId)
        .collection('fixedAppointments')
        .doc();

    FixedAppointment newAppointment = FixedAppointment(
      id: newDoc.id,
      weekDay: selectedDay! - 1,
      startTime: toDouble(timeRange.start),
      endTime: toDouble(timeRange.end),
      userId: widget.up.id,
      phoneNr: widget.up.phoneNr,
      name: name.text,
      description: service.text,
    );

    bool collision = doesAppointmentCollide(fixedAppointments, newAppointment);
    bool sameDay =
    doesUserHaveFixedAppointmentOnThisDay(fixedAppointments, newAppointment);

    if (collision) {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            AnimationDialog(text: "user.timeNotFree".tr(), isSuccess: false),
      );
    } else if (sameDay) {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            AnimationDialog(text: "user.sameDayFixed".tr(), isSuccess: false),
      );
    } else {
      await newDoc.set(newAppointment.toMap());

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (BuildContext context) =>
            AnimationDialog(text: "booking.success".tr(), isSuccess: true),
      );

      if (!mounted) return;
      Navigator.pop(context, newAppointment);
    }
  }

  @override
  void dispose() {
    employeeController.dispose();
    name.dispose();
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.buttonColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
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
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "booking.fixedBookAppointment".tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (isAdmin) ...[
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "general.selectEmployee".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                employeeSelection,
              ],

              const SizedBox(height: 25),

              if (loadingFixedAppointments)
                Center(
                  child: CupertinoActivityIndicator(color: colors.textColor),
                )
              else if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "general.closedVendor".tr(),
                    style: TextStyle(
                      color: colors.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                )
              else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "weekdays.selectDay".tr(),
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  daySelection,
                  const SizedBox(height: 6),
                  timeRangeSelection,
                  const SizedBox(height: 25),
                  disabledNameTf,
                  const SizedBox(height: 15),
                  serviceTf,
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        height: 55,
                        width: double.maxFinite,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          onPressed: bookFixedAppointment,
                          child: Text(
                            "booking.book".tr(),
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget get employeeSelection {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;

    if (vendor.employees.length < 2 || !isAdmin) {
      return Container();
    }

    return SizedBox(
      height: 55,
      child: ListView.separated(
        controller: employeeController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: vendor.employees.length,
        separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          Employee emp = vendor.employees[index];
          bool selected = emp.id == selectedEmployeeId;
          bool hasWorkTimes = emp.workTimes.any((day) => day.isNotEmpty);

          return AutoScrollTag(
            key: ValueKey(index),
            controller: employeeController,
            index: index,
            child: GestureDetector(
              onTap: !hasWorkTimes
                  ? null
                  : () {
                if (selected) return;
                selectedEmployeeId = emp.id;
                setEmployee();
              },
              child: Opacity(
                opacity: hasWorkTimes ? 1 : 0.4,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.textColor : colors.buttonColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.textColor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      ProfileImageCircle(emp.imageUrl, 35),
                      const SizedBox(width: 12),
                      Text(
                        emp.name,
                        style: TextStyle(
                          color: selected
                              ? colors.backgroundColor
                              : colors.textColor,
                          fontSize: 15,
                          fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get daySelection {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(days.keys.length, (index) {
          int key = days.keys.toList()[index];

          return GestureDetector(
            onTap: () {
              if (selectedDay != key) {
                selectedDay = key;
              }
              setState(() {});
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selectedDay == key ? colors.textColor : colors.buttonColor,
              ),
              child: SizedBox(
                width: 22,
                child: Center(
                  child: Text(
                    days[key]!.substring(0, 2),
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDay == key
                          ? colors.backgroundColor
                          : colors.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget get timeRangeSelection {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return TimeRange(
      fromTitle: Text(
        "general.from".tr(),
        style: TextStyle(
          fontSize: 15,
          color: colors.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      toTitle: Text(
        "general.until".tr(),
        style: TextStyle(
          fontSize: 15,
          color: colors.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      titlePadding: 20,
      textStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: colors.textColor,
      ),
      activeTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: colors.backgroundColor,
      ),
      borderColor: colors.textColor,
      activeBorderColor: colors.secondary,
      backgroundColor: Colors.transparent,
      activeBackgroundColor: colors.textColor,
      firstTime: const TimeOfDay(hour: 6, minute: 00),
      lastTime: const TimeOfDay(hour: 22, minute: 00),
      initialRange: timeRange,
      timeStep: 15,
      timeBlock: 15,
      onRangeCompleted: (range) {
        if (range != null) {
          setState(() => timeRange = range);
        }
      },
    );
  }

  Widget get serviceTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        cursorColor: colors.textColor,
        textInputAction: TextInputAction.done,
        controller: service,
        autofocus: false,
        onChanged: (value) => setState(() {}),
        style: TextStyle(color: colors.textColor),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
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
          labelText: "booking.serviceOptional".tr(),
          fillColor: colors.textColor.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget get disabledNameTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: name,
        autofocus: false,
        enabled: false,
        style: TextStyle(
          color: colors.textColor.withValues(alpha: 0.7),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: colors.secondary.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          filled: true,
          labelStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
          labelText: "booking.customerName".tr(),
          fillColor: colors.textColor.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}