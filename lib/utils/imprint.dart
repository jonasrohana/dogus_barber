import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../controller+api/user_controller.dart';
import 'colors.dart';

class Imprint extends StatelessWidget {
  const Imprint({super.key});

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    final boldStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 17,
      color: colors.textColor,
      height: 1.2
    );
    final normalStyle = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: colors.textColor.withValues(alpha: 0.7),
      height: 1.2
    );
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: colors.isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "general.imprint".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      backgroundColor: colors.backgroundColor,
      body: FadeInUp(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Z THE MASTER', style: boldStyle),
              const SizedBox(height: 5),
              Text('Emserstraße 111', style: normalStyle),
              const SizedBox(height: 5),
              Text('12051 Berlin', style: normalStyle),
              const SizedBox(height: 5),
              Text('Deutschland', style: normalStyle),
              const SizedBox(height: 25),
              Text('general.contact'.tr(), style: boldStyle),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  const url = 'mailto:info@zthemaster.de';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text('E-Mail: info@zthemaster.de', style: normalStyle)
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  const url = 'tel:+491633300375';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text('Telefon: +49 15510 741975', style: normalStyle)
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

}