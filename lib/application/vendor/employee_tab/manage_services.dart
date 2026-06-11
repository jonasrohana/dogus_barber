import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:dogus_barber/application/vendor/employee_tab/create_edit_service.dart';
import 'package:dogus_barber/utils/functions.dart';
import 'package:dogus_barber/utils/models.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/widgets.dart';

class ManageServices extends StatefulWidget {

  final String? selectedEmployeeId;

  const ManageServices({super.key, this.selectedEmployeeId});

  @override
  State<ManageServices> createState() => _ManageServicesState();
}

class _ManageServicesState extends State<ManageServices> {

  String uid = FirebaseAuth.instance.currentUser!.uid;
  late List<Service> services;

  late String selectedEmployeeId;
  AutoScrollController controller = AutoScrollController(axis: Axis.horizontal);

  void setEmployee() {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;

    Employee emp = Provider.of<UserController>(context, listen: false).getEmployeeById(selectedEmployeeId)!;
    services = emp.services;
    setState(() {});

    int index = vendor.employees.map((e) => e.id).toList().indexOf(selectedEmployeeId);
    controller.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
  }

  @override
  void initState() {
    super.initState();
    selectedEmployeeId = widget.selectedEmployeeId != null ? widget.selectedEmployeeId! : uid;
    setEmployee();
  }

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "services.services".tr(),
          style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.buttonColor,
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () async {
          final retVal = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEditService(edit: false)),
          );
          if(retVal != null && retVal is Service) {
            services.add(retVal);
            await FirebaseFirestore.instance
              .collection("vendors").doc(vendor.id)
              .collection("employees").doc(selectedEmployeeId)
              .update({
                'services': services.map((service) => service.toMap()).toList()
              });
            setState(() {});
          }
        },
        shape: const CircleBorder(),
        backgroundColor: colors.primary,
        child: Icon(Ionicons.add, color: colors.primaryText),
      ): null,
    );
  }

  Widget get body {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    bool isAdmin = vendor.admins.contains(uid);
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
        color: colors.backgroundColor
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if(isAdmin)
              ...[
                const SizedBox(height: 15),
                employeeSelection,
                const SizedBox(height: 15),
              ],
            const SizedBox(height: 20),
            if(services.isNotEmpty)
              ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
                itemBuilder: (BuildContext context, int index) {
                  Service s = services[index];
                  return GestureDetector(
                    onTap: isAdmin ? () async {

                      final retVal = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateEditService(edit: true, service: s)),
                      );

                      // edit
                      if(retVal != null && retVal is Service) {
                        services[index] = retVal;
                        await FirebaseFirestore.instance
                          .collection("vendors").doc(vendor.id)
                          .collection("employees").doc(selectedEmployeeId)
                          .update({
                            'services': services.map((service) => service.toMap()).toList()
                          });
                        setState(() {});
                      }

                      // delete
                      else if(retVal != null && retVal is String && retVal == 'delete') {
                        setState(() => services.removeAt(index));
                        await FirebaseFirestore.instance
                          .collection("vendors").doc(vendor.id)
                          .collection("employees").doc(selectedEmployeeId)
                          .update({
                            'services': services.map((service) => service.toMap()).toList()
                          });
                      }
                    } : () {},
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: colors.buttonColor,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: double.infinity,
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
                                        color: colors.textColor
                                      )
                                    ),
                                    const SizedBox(height: 3,),
                                    Text(
                                      durationString(s.duration),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: colors.textColor.withValues(alpha: 0.7)
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
                                  color: colors.textColor.withValues(alpha: 0.8)
                                )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              ...[
                const SizedBox(height: 20),
                const ThemedSvgImage(assetName: "services", height: 150),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'services.noServices'.tr(),
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
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }

  Widget get employeeSelection {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
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


}
