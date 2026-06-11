import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller+api/user_controller.dart';
import '../../utils/colors.dart';
import '../../utils/models.dart';
import '../../utils/widgets.dart';
import 'chat_detail.dart';

class ChatDecision extends StatefulWidget{

  final List<String> unread;

  const ChatDecision({super.key, required this.unread});

  @override
  State<ChatDecision> createState() => _ChatDecisionState();
}

class _ChatDecisionState extends State<ChatDecision>{

  Employee? selectedEmployee;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        title: Text(
          "general.selectEmployee".tr(),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor)
        ),
      ),
      body: employeePage(context),
    );
  }

  Widget employeePage(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            physics: const BouncingScrollPhysics(),
            children: [
              ListView.separated(
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vendor.employees.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 15),
                itemBuilder: (BuildContext context, int index) {
                  Employee emp = vendor.employees[index];
                  bool isSelected = selectedEmployee != null && selectedEmployee!.id == emp.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedEmployee = emp);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.textColor : colors.buttonColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          ProfileImageCircle(emp.imageUrl, 45),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              emp.name,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? colors.backgroundColor : colors.textColor
                              )
                            ),
                          ),
                          if(widget.unread.contains(emp.id))
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: colors.primary,
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SafeArea(child: submitButton),
      ],
    );
  }

  Widget get submitButton {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border(top: BorderSide(color: colors.textColor.withValues(alpha: 0.1), width: 1))
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Center(
        child: PrimaryButton(
          text: 'general.continue'.tr(),
          onPressed: () => navigateToChat(context, selectedEmployee!.id, false, doublePop: true),
          enabled: selectedEmployee != null,
          color: selectedEmployee != null ? colors.primary : colors.primary.withValues(alpha: 0.5)
        )
      ),
    );
  }

}