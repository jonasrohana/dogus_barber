import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';
import '../../../utils/widgets.dart';

class ManageOpeningTimes extends StatefulWidget {

  final List<String> openingTimes;

  const ManageOpeningTimes({super.key, required this.openingTimes});

  @override
  State<ManageOpeningTimes> createState() => _ManageOpeningTimesState();
}

class _ManageOpeningTimesState extends State<ManageOpeningTimes> {

  late List<String> openingTimes = widget.openingTimes;

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
          "general.openingTimes".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget get body {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: openingTimesEdit,
          ),
        ),
        submitButton
      ],
    );
  }

  Widget get openingTimesEdit {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: colors.buttonColor
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: openingTimes.length,
        separatorBuilder: (BuildContext context, int index) => Container(margin: const EdgeInsets.symmetric(horizontal: 20), color: colors.textColor.withValues(alpha: 0.1), height: 1),
        itemBuilder: (BuildContext context, int index) {
          bool closed = openingTimes[index].isEmpty;
          String label = "weekdays.weekday_${index+1}".tr();
          return InkWell(
            onTap: () async {
              final retVal = await showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: colors.backgroundColor,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                context: context,
                builder: (BuildContext context) => TimeRangeSheet(label: label, time: openingTimes[index]),
              );
              if(retVal != null && retVal is String) {
                setState(() => openingTimes[index] = retVal);
              }
            },
            child: Container(
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
                    closed ? "general.closed".tr() : openingTimes[index],
                    style: TextStyle(
                        fontSize: 15,
                        color: closed ? CupertinoColors.destructiveRed : colors.textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get submitButton {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
          color: colors.backgroundColor,
          border: Border(top: BorderSide(color: colors.textColor.withValues(alpha: 0.1), width: 1))
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          height: 55,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                .collection("vendors").doc(vendor.id)
                .update({ 'openingTimes': openingTimes });
              if(!mounted) return;
              Navigator.pop(context);
            },
            child: Text(
              'general.save'.tr(),
              style: TextStyle(
                fontSize: 15,
                color: colors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
