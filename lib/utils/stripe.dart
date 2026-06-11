import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'constants.dart';

enum PaymentMethodEnum {
  cash, card, googlePay, applePay
}

Future<void> initStripe() async {
  Stripe.publishableKey = "pk_live_51THRcnDeFE8IzwVDCwcvAbqTHTCn5MbumqDUziVFQsQoqvkksrkixUiiQ0BJaOocEmUer6eaTWoaUcIB07b5KsYw0041QgnCft";
  Stripe.merchantIdentifier = "merchant.zTheMaster";
  //Stripe.stripeAccountId = stripeAccountId.value;
  //Stripe.urlScheme = AppConstants.stripeReturnUrl;
  //Stripe.setReturnUrlSchemeOnAndroid = true;
  await Stripe.instance.applySettings();
}

StripeHandler stripeInstance = StripeHandler();

class StripeHandler {
  static final StripeHandler _singleton = StripeHandler._internal();

  factory StripeHandler() => _singleton;

  StripeHandler._internal();

  Future<void> startPaymentFlow(String clientSecret, String customerId, String ephemeralKey, String treatment, double amount, PaymentMethodEnum paymentMethod) async {

    try {
      if(paymentMethod == PaymentMethodEnum.card) {
        await _startCreditCard(clientSecret, customerId, ephemeralKey);
      }
      else if(paymentMethod == PaymentMethodEnum.applePay) {
        await _startApplePay(clientSecret, treatment, amount.toString());
      }
      else if(paymentMethod == PaymentMethodEnum.googlePay) {
        await _startGooglePay(clientSecret);
      }
    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> _startCreditCard(String clientSecret, String customerId, String ephemeralKey) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: "Z THE MASTER STUDIO",
        paymentIntentClientSecret: clientSecret,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
        style: ThemeMode.dark,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> _startApplePay(String clientSecret, String treatment, String amount) async {
    final applePaySupported = await Stripe.instance.isPlatformPaySupported();
    if (applePaySupported) {
      // present apple pay sheet
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'De',
            currencyCode: 'EUR',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: "Z THE MASTER STUDIO - $treatment",
                amount: amount
              )
            ],
          ),
        )
      );
    }
    else {
      throw StripeException(
        error: LocalizedErrorMessage(
          code: FailureCode.Failed,
          message: 'Apple Pay is not supported on this device',
        ),
      );
    } 
  }

  Future<void> _startGooglePay(String clientSecret) async {
    final googlePaySupported = await Stripe.instance.isPlatformPaySupported(googlePay: const IsGooglePaySupportedParams(testEnv: kDebugMode));
    if (googlePaySupported) {
      // present google pay sheet
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: const PlatformPayConfirmParams.googlePay(
          googlePay: GooglePayParams(
            merchantName: 'Z THE MASTER STUDIO',
            merchantCountryCode: 'DE',
            currencyCode: 'EUR',
          ),
        )
      );
    }
    else {
      throw StripeException(
        error: LocalizedErrorMessage(
          code: FailureCode.Failed,
          message: 'Google Pay is not supported on this device',
        ),
      );
    }
  }

}



