import 'package:cloud_functions/cloud_functions.dart';

// constant values
const fixedVendorId = "H1d9tejlBogXJ1r3k49a";
const languages = ["de"];
const privacyUrl = "https://zthemaster.de/datenschutz";
const userPlaceholderImage = "https://firebasestorage.googleapis.com/v0/b/artletics-22b28.appspot.com/o/user-placeholder.png?alt=media&token=3a39fe46-498c-44cc-8292-4fddab85b3c8";



// cloud function invocations
final HttpsCallable getAppVersionFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("getMinimumAcceptedAppVersion");
final HttpsCallable logAppStartFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("logAppStart");

final HttpsCallable removeToken = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("removeToken");
final HttpsCallable verifyUser = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("verifyUser");
final HttpsCallable blockUser = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("blockUser");
final HttpsCallable removeEmployee = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("removeEmployee");
final HttpsCallable acceptEmployeeInvitation = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("acceptEmployeeInvitation");
final HttpsCallable declineEmployeeInvitation = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("declineEmployeeInvitation");
final HttpsCallable deleteAccountFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
  .httpsCallable("deleteAccount");
final HttpsCallable addNoShowFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("addNoShow");
final HttpsCallable deleteNoShowFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("deleteNoShow");

// stripe calls
final HttpsCallable bookAppointmentWithPaymentFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("bookAppointmentWithPayment");
final HttpsCallable getStripeProductsFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("getStripeProducts");
final HttpsCallable createCheckoutSessionFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("createCheckoutSession");
final HttpsCallable createSubscriptionManagementSessionFunctions = FirebaseFunctions.instanceFor(region: "europe-west3")
    .httpsCallable("createSubscriptionManagementSession");
