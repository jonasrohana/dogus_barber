import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:dogus_barber/utils/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

import '../controller+api/subscription_controller.dart';
import '../controller+api/user_controller.dart';
import 'colors.dart';
import 'constants.dart';
import 'functions.dart';
import 'models.dart';

class SubscriptionPaywall extends StatefulWidget {
  final List<StripeProduct> products;

  const SubscriptionPaywall({
    super.key,
    required this.products,
  });

  @override
  State<SubscriptionPaywall> createState() => _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends State<SubscriptionPaywall> {
  late List<StripeProduct> products = widget.products;

  List<String> hairPackages = [
    "Z-BARBER H2",
    "Z-BARBER H4",
    "Z-BARBER HB2",
    "Z-BARBER HB4"
  ];

  List<String> soliPackages = [
    "Z-SOLI 2",
    "Z-SOLI 3",
    "Z-SOLI 4"
  ];

  bool buying = false;
  StripeProduct? selectedProduct;

  bool isActiveProduct(StripeProduct product) {
    List<StripeSubscription> subs = Provider.of<SubscriptionController>(context, listen: false).subs;
    List<StripeSubscription> activeSubs = getActiveSubs(subs);
    return activeSubs.any((s) => s.productId == product.id);
  }

  StripeProduct? productById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isBlockedProduct(StripeProduct product) {
    if (isActiveProduct(product)) return false;

    List<StripeSubscription> subs = Provider.of<SubscriptionController>(context, listen: false).subs;
    List<StripeSubscription> activeSubs = getActiveSubs(subs);

    bool productIsHair = hairPackages.contains(product.name);
    bool productIsSoli = soliPackages.contains(product.name);

    for (var activeSub in activeSubs) {
      StripeProduct? activeProduct = productById(activeSub.productId);
      if (activeProduct == null) continue;

      if (productIsHair && hairPackages.contains(activeProduct.name)) {
        return true;
      }

      if (productIsSoli && soliPackages.contains(activeProduct.name)) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: FadeInUp(
        child: LoadingStack(
          loading: buying,
          child: body,
        ),
      ),
    );
  }

  Widget get body {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          CupertinoIcons.xmark,
                          color: colors.textColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "paywall.choose_package".tr(),
                    style: TextStyle(
                      color: colors.textColor.withValues(alpha: 0.68),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(
                    products.length,
                        (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == products.length - 1 ? 0 : 12,
                      ),
                      child: productCard(products[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: buyButton,
            ),
          ),
        ],
      ),
    );
  }

  Widget productCard(StripeProduct product) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    final bool isActive = isActiveProduct(product);
    final bool isBlocked = isBlockedProduct(product);
    final bool selected = selectedProduct?.id == product.id;

    final double? previous =
    double.tryParse(product.metadata["previous"]?.toString() ?? "");
    final double? current =
    double.tryParse(product.metadata["current"]?.toString() ?? "");

    num savedMoney = previous! - current!;
    String savedMoneyString = savedMoney % 1 == 0
        ? savedMoney.toInt().toString()
        : savedMoney.toStringAsFixed(2);

    return InkWell(
      onTap: (isActive || isBlocked) ? null : () {
        setState(() => selectedProduct = product);
      },
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: (isBlocked) ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected && !isBlocked ? colors.textColor : colors.buttonColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? colors.primary : selected && !isBlocked ? colors.primary : colors.textColor.withValues(alpha: 0.1),
              width: (selected && !isBlocked) || isActive ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : selected && !isBlocked ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isActive ? colors.primary : selected && !isBlocked ? colors.primary : colors.textColor.withValues(alpha: 0.35),
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        color: selected && !isBlocked ? colors.buttonColor : colors.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: colors.primary,
                          width: 1.8,
                        ),
                      ),
                      child: Text(
                        "paywall.active".tr(),
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  product.description,
                  style: TextStyle(
                    color: selected && !isBlocked ? colors.buttonColor.withValues(alpha: 0.74) : colors.textColor.withValues(alpha: 0.74),
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      "${previous.toStringAsFixed(previous % 1 == 0 ? 0 : 2)}€",
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${current.toStringAsFixed(current % 1 == 0 ? 0 : 2)}€",
                    style: TextStyle(
                      color: selected && !isBlocked
                          ? colors.buttonColor
                          : colors.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!isActive && !isBlocked)
                    Text(
                      "paywall.save_percent".tr(args: [savedMoneyString]),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get buyButton {
    ColorTheme colors = Provider.of<UserController>(context).getColors;

    return SizedBox(
      width: double.maxFinite,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: selectedProduct == null ? null : () async {
          try {
            setState(() => buying = true);

            final response = await createCheckoutSessionFunctions.call({
              "price_id": selectedProduct?.defaultPrice,
            });

            setState(() => buying = false);

            Map<String, dynamic> data =
            Map<String, dynamic>.from(response.data);

            if (data['status'] == 'success') {
              String url = data['url'];

              if (await canLaunchUrlString(url) && mounted) {
                Navigator.pop(context);
                launchUrlString(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                throw 'Could not launch $url';
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print(e);
            }
          }
        },
        child: Text(
          "paywall.subscribe".tr(),
          style: TextStyle(
            color: colors.primaryText.withValues(
              alpha: selectedProduct == null ? 0.5 : 1,
            ),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}