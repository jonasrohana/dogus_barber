import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/utils/validator.dart';
import 'dart:io';
import '../controller+api/user_controller.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/models.dart';
import '../utils/widgets.dart';

class UserOnboarding extends StatefulWidget {
  const UserOnboarding({super.key});

  @override
  State<UserOnboarding> createState() => _UserOnboardingState();
}

class _UserOnboardingState extends State<UserOnboarding> {

  bool isSubmitted = false;
  bool uploading = false;

  TextEditingController name = TextEditingController();
  FocusNode nameFocus = FocusNode();
  TextEditingController phoneNr = TextEditingController();
  FocusNode phoneFocus = FocusNode();
  List<FocusNode> nodes = [];

  final ImagePicker _picker = ImagePicker();
  DynamicImage? image;

  bool get valid => name.text.isNotEmpty && phoneNr.text.isNotEmpty;
  bool get showButton => nodes.every((element) => element.hasFocus == false);

  Future<void> createProfile() async {
    setState(() => uploading = true);
    await Future.delayed(const Duration(seconds: 1)); // pleasing UI

    User authUser = FirebaseAuth.instance.currentUser!;
    String imageUrl = "";
    if(image != null && image!.isFile && image!.croppedFile != null) {
      Reference storageReference = FirebaseStorage.instance
        .ref().child('user').child(authUser.uid).child(UniqueKey().toString());

      await storageReference.putFile(File(image!.croppedFile!.path));
      imageUrl = await storageReference.getDownloadURL();
    }
    if(!mounted)  return;

    // compute platform and signInMethod
    String platform = Platform.isIOS ? "iOS" : "Android";
    String signInMethod = "Email";
    for (UserInfo userInfo in authUser.providerData) {
      if (userInfo.providerId == 'apple.com') {
        signInMethod = "Apple";
        break;
      }
      else if (userInfo.providerId == 'google.com') {
        signInMethod = "Google";
        break;
      }
    }

    // upload user profile to firestore
    UserProfile up = UserProfile(id: authUser.uid, name: name.text.trim(), imageUrl: imageUrl,
      email: authUser.email!, phoneNr: phoneNr.text, disabledBy: [], verifiedBy: [],
      unverifiedBy: [fixedVendorId], vendorId: fixedVendorId, platform: platform, signInMethod: signInMethod, noShow: []);

    // set language, token and signIn
    Map<String,dynamic> map = up.toMap();
    String language = context.locale.toString().split("_").first;
    //String? token = await FirebaseMessaging.instance.getToken();
    map.addAll({
      "language": language,
      //"tokens": FieldValue.arrayUnion([token]),
      "lastSignIn": DateTime.now()
    });

    // create doc in firestore
    await FirebaseFirestore.instance
      .collection("user").doc(authUser.uid)
      .set(map, SetOptions(merge: true));

    if(mounted) setState(() => uploading = false);
  }

  Future<void> pickImage() async {
    ColorTheme colors = Provider.of<UserController>(context, listen: false).getColors;
    FocusScope.of(context).unfocus();
    setState(() => uploading = true);
    final pickedFile =
    await _picker.pickImage(maxWidth: 600, source: ImageSource.gallery);

    if (pickedFile == null) {
      setState(() => uploading = false);
      return;
    }

    // cropping
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "general.crop".tr(),
          toolbarColor: colors.backgroundColor,
          toolbarWidgetColor: colors.textColor,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true),
        IOSUiSettings(
          title: "general.crop".tr(),
          doneButtonTitle: "general.confirm".tr(),
          cancelButtonTitle: "general.cancel".tr(),
          minimumAspectRatio: 1,
          aspectRatioLockDimensionSwapEnabled: false,
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          rotateButtonsHidden: true,
          resetAspectRatioEnabled: false),
      ],
    );

    if (croppedFile == null) {
      setState(() => uploading = false);
      return;
    }
    else {
      setState(() {
        image = DynamicImage(isFile: true, croppedFile: croppedFile);
        uploading = false;
      });
    }
  }

  void initFocusNodes() {
    nodes = [nameFocus, phoneFocus];
    for(FocusNode node in nodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void initState() {
    initFocusNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? appleSignInName = Provider.of<UserController>(context, listen: false).appleSignInName;
      if(appleSignInName != null && appleSignInName.isNotEmpty) {
        setState(() => name.text = appleSignInName);
      }
    });
    super.initState();
  }

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
          "general.createProfile".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: LoadingStack(loading: uploading, child: body)),
      backgroundColor: colors.buttonColor,
    );
  }

  Widget get body {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
              color: colors.backgroundColor
            ),
            child: mainInfo
          ),
        ),
        if(showButton)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: SafeArea(child: submitButton),
          ),
      ],
    );
  }

  // image, address, name
  Widget get mainInfo {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          imagePicker,
          const SizedBox(height: 40),
          nameTf,
          const SizedBox(height: 20),
          phoneTf,
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget get imagePicker {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    double width = 120;
    late Widget child;
    if(image == null) {
      child = Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey
        ),
        padding: const EdgeInsets.all(35),
        child: Icon(Ionicons.images_outline, size: 50, color: Colors.black.withValues(alpha: 0.6)),
      );
    }
    else if(image!.url != null) {
      child = ClipOval(
        child: Image.network(
          image!.url!,
          width: width,
          height: width,
          fit: BoxFit.cover,
        ),
      );
    }
    else {
      child = ClipOval(
        child: Image.file(
          File(image!.croppedFile!.path),
          width: width,
          height: width,
          fit: BoxFit.cover,
        ),
      );
    }

    bool showGradientBorder = image != null;
    return Center(
      child: InkWell(
        onTap: pickImage,
        customBorder: const CircleBorder(),
        child: Container(
          width: showGradientBorder ? width + 3 : width,
          height: showGradientBorder ? width + 3 : width,
          decoration: showGradientBorder ? BoxDecoration(
            shape: BoxShape.circle,
            border: GradientBoxBorder(
              gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
              width: 3,
            ),
          ) : null,
          child: child,
        ),
      ),
    );
  }

  Widget get nameTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      focusNode: nameFocus,
      cursorColor: colors.textColor,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      controller: name,
      autofocus: false,
      onChanged: (value) => setState(() {}),
      style: TextStyle(color: colors.textColor),
      decoration: InputDecoration(
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
        labelText: "general.name".tr(),
        fillColor: colors.buttonColor,
        errorText: isSubmitted ? name.text.isEmpty ? "validators.noName".tr() : name.text.length < 3 ? "validators.short".tr() : null : null,
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

  Widget get phoneTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      focusNode: phoneFocus,
      cursorColor: colors.textColor,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      inputFormatters: [PhoneNumberInputFormatter()],
      textInputAction: TextInputAction.done,
      controller: phoneNr,
      autofocus: false,
      onChanged: (value) => setState(() {}),
      style: TextStyle(color: colors.textColor),
      decoration: InputDecoration(
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
        labelText: "general.phoneNr".tr(),
        fillColor: colors.buttonColor,
        errorText: isSubmitted ? validatePhoneNr(phoneNr.text) : null,
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

  Widget get submitButton {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return SizedBox(
      width: double.maxFinite,
      height: 55,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
        ),
        onPressed: () async {
          setState(() => isSubmitted = true);
          if(valid) {
            createProfile();
          }
        },
        child: Text(
          "general.createProfile".tr(),
          style: TextStyle(
            fontSize: 15,
            color: valid ? colors.primaryText : Colors.grey,
          ),
        ),
      ),
    );
  }

}
