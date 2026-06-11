import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:dogus_barber/controller+api/google_places_api.dart';
import 'package:dogus_barber/utils/functions.dart';

String? validateName(String value) {
  if(value.isEmpty) return "validators.noName".tr();
  if(value.length < 3) return "validators.short".tr();
  return null;
}

String? validatePrice(String value) {
  if(value.isEmpty) return "validators.emptyPrice".tr();
  if(euroStringToDouble(value) < 5) return "validators.price".tr();

  return null;
}

String? validatePlace(GooglePlacesApiCaller value) {
  if(value.streetTf.text.isEmpty || value.selectedPlace == null ||
      !value.selectedPlace!.isValid) {
    return "validators.invalidPlace".tr();
  }

  return null;
}

String? validatePhoneNr(String value) {
  if(value.length < 7)  return "validators.wrongPhoneNr".tr();
  return null;
}

String? validateEmail(String value) {
  value = value.trim();

  if (!EmailValidator.validate(value)) {
    return "login.errorEmail".tr();
  }

  return null;
}

String? validatePassword(String value) {

  if (value.length < 6) {
    return "login.errorPasswordLength".tr();
  }

  return null;
}