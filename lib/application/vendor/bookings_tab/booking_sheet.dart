import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import '../../../controller+api/user_controller.dart';
import '../../../controller+api/vendor_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/functions.dart';
import '../../../utils/models.dart';
import '../../../utils/validator.dart';
import '../../../utils/widgets.dart';

class BookingSheet extends StatefulWidget {

  final String employeeId;
  final DateTime selected;
  final TimeSlot slot;

  const BookingSheet({super.key, required this.selected, required this.slot, required this.employeeId});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {

  TextEditingController nameTf = TextEditingController();
  TextEditingController serviceTf = TextEditingController();
  bool isSubmitted = false;

  UserProfile? user;
  List<Service> services = [];

  bool get valid => validateName(nameTf.text) == null || user != null;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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
                  "addAppointment".tr(),
                  style: TextStyle(
                      fontSize: 18,
                      color: colors.textColor,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: Text(
                  firestoreString(widget.selected),
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  "${timeToString(toTime(widget.slot.start))} - ${timeToString(toTime(widget.slot.end))}",
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              userRow,
              const SizedBox(height: 15),
              serviceRow,
              const SizedBox(height: 20),
              bookingButton
            ],
          ),
        ),
      ),
    );
  }

  Widget get userRow {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    if(user == null) {
      return Row(
        children: [
          Expanded(child: buildTf(nameTf, "booking.customerName".tr(), validateName(nameTf.text))),
          const SizedBox(width: 10),
          GestureDetector(
              onTap: () async {
                user = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChooseUser()),
                );
                setState(() {});
              },
              child: Container(
                  decoration: BoxDecoration(
                      color: colors.textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                      child: Icon(Ionicons.person_add, color: colors.textColor, size: 20)
                  )
              )
          )
        ],
      );
    }

    return Row(
      children: [
        GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImageViewer(hero: "user-${user!.id}", url: user!.imageUrl))
            ),
            child: ProfileImageCircle(user!.imageUrl, 50, hero: "user-${user!.id}")
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextScroll(
                  user!.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textColor)
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
            onTap: () => setState(() => user = null),
            child: Container(
                decoration: BoxDecoration(
                    color: colors.textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
                ),
                padding: const EdgeInsets.all(16.0),
                child: Center(
                    child: Icon(Ionicons.person_remove, color: colors.textColor, size: 20)
                )
            )
        )
      ],
    );
  }

  Widget get serviceRow {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    if(services.isEmpty) {
      return Row(
        children: [
          Expanded(child: buildTf(serviceTf, "booking.serviceOptional".tr(), null),),
          const SizedBox(width: 10),
          GestureDetector(
              onTap: () async {
                services = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChooseServices(services: services, empId: widget.employeeId,)),
                ) ?? [];
                setState(() {});
              },
              child: Container(
                  decoration: BoxDecoration(
                      color: colors.textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                      child: Icon(Ionicons.list, color: colors.textColor, size: 20)
                  )
              )
          )
        ],
      );
    }

    return GestureDetector(
      onTap: () async {
        services = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChooseServices(services: services, empId: widget.employeeId)),
        ) ?? [];
        setState(() {});
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: colors.textColor.withValues(alpha: 0.05),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 10),
                width: 15,
                child: Column(
                  children: [
                    for (var color in services.map((e) => e.color))
                      Expanded(child: Container(color: Color(color).withValues(alpha: 0.75)))
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        services.map((e) => e.name).join(", "),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textColor
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                  onTap: () => setState(() => services = []),
                  child: Container(
                      padding: const EdgeInsets.all(10.0),
                      child: const Center(child: Icon(Ionicons.close, color: CupertinoColors.destructiveRed, size: 25))
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTf(TextEditingController controller, String label, String? errorText) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return TextField(
        textCapitalization: TextCapitalization.sentences,
        cursorColor: colors.textColor,
        keyboardType: TextInputType.name,
        textInputAction: controller == serviceTf ? TextInputAction.done : TextInputAction.next,
        controller: controller,
        autofocus: false,
        onChanged: (value) => setState(() {}),
        style: TextStyle(color: colors.textColor),
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(16),
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
            labelText: label,
            fillColor: colors.textColor.withValues(alpha: 0.05),
            errorText: isSubmitted ? errorText : null,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.destructiveRed,
            )
        )
    );
  }

  Widget get bookingButton {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Center(
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

            Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;

            final vendorRef = FirebaseFirestore.instance
                .collection("vendors").doc(vendor.id)
                .collection("employees").doc(widget.employeeId);
            final privateRef = vendorRef.collection("privateAppointments").doc();

            Appointment app = Appointment(id: privateRef.id, date: firestoreString(widget.selected), price: getPrice(services), userId: user != null ? user!.id : "",
                startTime: widget.slot.start, endTime: widget.slot.end, employeeId: widget.employeeId, vendorId: vendor.id);

            // write termin to public collection
            await vendorRef.collection("appointments").doc(privateRef.id).set(app.toMap());

            // set user attributes and add to private collection
            if(user != null) {
              app.name = user!.name;
              app.phoneNr = user!.phoneNr;
              app.userId = user!.id;
            }
            else {
              app.name = nameTf.text;
            }

            if(services.isNotEmpty) {
              app.service = services.map((e) => e.name).join(", ");
              app.colors = services.map((e) => e.color).toList();
            }
            else {
              app.service = serviceTf.text;
            }
            await privateRef.set(app.toMap());

            if(!mounted) return;
            Navigator.pop(context);
          },
          child: Text(
            "booking.book".tr(),
            style: TextStyle(
                fontSize: 15,
                color: valid ? colors.primaryText : Colors.grey,
                fontWeight: FontWeight.w600
            ),
          ),
        ),
      ),
    );
  }

}

class ChooseUser extends StatefulWidget {
  const ChooseUser({super.key});

  @override
  State<ChooseUser> createState() => _ChooseUserState();
}

class _ChooseUserState extends State<ChooseUser> {

  String uid = FirebaseAuth.instance.currentUser!.uid;

  TextEditingController searchString = TextEditingController();

  bool _isRequesting = false;

  List<UserProfile> allUser = [];

  void onUserChange(QuerySnapshot event) {
    List<UserProfile> refList = allUser;
    for (var docChange in event.docChanges)  {
      int index = refList.indexWhere((element) => element.id == docChange.doc.id);
      UserProfile up = UserProfile.fromMap(docChange.doc.data() as Map<String, dynamic>);
      if(docChange.type == DocumentChangeType.added) {
        if(index != -1) {
          refList[index] = up;
        }
        else {
          refList.add(up);
        }
      }
      else if(docChange.type == DocumentChangeType.modified) {
        if(index != -1) {
          refList[index] = up;
        }
      }
      else if(docChange.type == DocumentChangeType.removed) {
        if(index != -1) {
          refList.removeAt(index);
        }
      }
    }
    refList.sort((a, b) => a.name.compareTo(b.name));
    setState(() {});
  }

  Future<void> fetchAllUser() async {
    setState(() =>_isRequesting = true );
    Vendor vendor = Provider.of<VendorController>(context, listen: false).getVendor!;
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('user')
        .where('verifiedBy', arrayContains: vendor.id)
        .get();
    allUser = query.docs.map((e) => UserProfile.fromMap(e.data() as Map<String, dynamic>)).toList();
    setState(() =>_isRequesting = false );
  }

  @override
  void initState() {
    fetchAllUser();
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
          "selectCustomer".tr(),
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
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    if(allUser.isEmpty && _isRequesting) {
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

    return SingleChildScrollView(
      child: Column(
        children: [
          searchBar,
          const SizedBox(height: 15),
          if(filteredUser.isEmpty)
            emptyState
          else
            FadeInUp(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUser.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  UserProfile up = filteredUser[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, up),
                    child: Container(
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
                          Icon(Ionicons.arrow_forward, color: colors.textColor.withValues(alpha: 0.5), size: 20,)
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 80)
        ],
      ),
    );
  }

  Widget get searchBar {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
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

  Widget get emptyState {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;

    late String text;
    text = "user.noUser".tr();


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
                  color: colors.textColor.withValues(alpha: 0.5),
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

class ChooseServices extends StatefulWidget {

  final List<Service> services;
  final String empId;

  const ChooseServices({super.key, required this.services, required this.empId});

  @override
  State<ChooseServices> createState() => _ChooseServicesState();
}

class _ChooseServicesState extends State<ChooseServices> {

  late List<Service> chosenServices = widget.services;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: colors.backgroundColor,
        centerTitle: true,
        title: Text(
          "selectService".tr(),
          style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.backgroundColor,
      floatingActionButton: chosenServices.isNotEmpty ? FloatingActionButton(
        onPressed: () => Navigator.pop(context, chosenServices),
        shape: const CircleBorder(),
        backgroundColor: Colors.green,
        child: const Icon(Ionicons.checkmark, color: Colors.white, size: 30,),
      ) : null,
    );
  }

  Widget get body {
    Employee emp = Provider.of<VendorController>(context).getEmployeeById(widget.empId)!;
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Container(
      margin: const EdgeInsets.only(top: 0),
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
          color: colors.backgroundColor
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 100, top: 5),
        itemCount: emp.services.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
        itemBuilder: (BuildContext context, int index) {
          Service s = emp.services[index];
          return GestureDetector(
            onTap: () {
              if(chosenServices.contains(s)){
                chosenServices.remove(s);
              }
              else {
                chosenServices.add(s);
              }
              setState(() {});
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: chosenServices.contains(s) ? colors.textColor : colors.buttonColor,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 15,
                      color: Color(s.color).withValues(alpha: 1),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                s.name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: chosenServices.contains(s) ? colors.backgroundColor : colors.textColor
                                )
                            ),
                            const SizedBox(height: 3,),
                            Text(
                                durationString(s.duration),
                                style: TextStyle(
                                    fontSize: 15,
                                    color: chosenServices.contains(s) ? colors.backgroundColor.withValues(alpha: 0.7) : colors.textColor.withValues(alpha: 0.7)
                                )
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Text(
                          doubleToEuroString(s.price),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: chosenServices.contains(s) ? colors.backgroundColor.withValues(alpha: 0.8) : colors.textColor.withValues(alpha: 0.8)
                          )
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


}