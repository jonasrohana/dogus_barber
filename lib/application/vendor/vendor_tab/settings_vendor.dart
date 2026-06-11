import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:dogus_barber/application/vendor/vendor_tab/edit_vendor.dart';
import 'package:dogus_barber/application/vendor/vendor_tab/manage_employees.dart';
import 'package:dogus_barber/application/vendor/vendor_tab/manage_opening_times.dart';
import 'package:dogus_barber/application/vendor/vendor_tab/push_newsletter.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/models.dart';
import '../../../utils/widgets.dart';

class VendorSettings extends StatefulWidget {

  const VendorSettings({super.key});

  @override
  State<VendorSettings> createState() => _VendorSettingsState();
}

class _VendorSettingsState extends State<VendorSettings> {

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return SafeArea(
      child: LoadingStack(
        loading: loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.only(left: 10,),
                child: Text(
                  "general.vendor".tr(),
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18
                  )
                ),
              ),
              const SizedBox(height: 15),
              shopBox,
              const SizedBox(height: 5),
              SettingsMenu(
                icon: Ionicons.time_outline,
                text: "general.openingTimes".tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageOpeningTimes(
                    openingTimes: vendor.openingTimes
                  )),
                )
              ),
              SettingsMenu(
                icon: Ionicons.person_add_outline,
                text: "general.employees".tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                    const ManageEmployees()),
                )
              ),
              SettingsMenu(
                icon: Ionicons.mail_open_outline,
                text: "Rundnachricht senden",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SendPushNewsletter())
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget get shopBox {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    Vendor vendor = Provider.of<UserController>(context).getVendor!;
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
                  vendor.name,
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  vendor.phoneNr,
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
                      MaterialPageRoute(builder: (context) => const EditVendor()),
                    ),
                    child: TextScroll(
                      'general.editVendor'.tr(),
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
              MaterialPageRoute(builder: (context) => ImageViewer(hero: vendor.id, url: vendor.imageUrl))
            ),
            child: ProfileImageCircle(vendor.imageUrl, 100, hero: vendor.id)
          ),
        ],
      ),
    );

  }

}
