import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/controller+api/google_places_api.dart';
import 'package:dogus_barber/utils/models.dart';
import 'package:dogus_barber/utils/validator.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/widgets.dart';

class EditVendor extends StatefulWidget {
  const EditVendor({super.key});

  @override
  State<EditVendor> createState() => _EditVendorState();
}

class _EditVendorState extends State<EditVendor> {

  bool uploading = false;

  late GooglePlacesApiCaller placesApi = GooglePlacesApiCaller(() => setState(() {}));

  TextEditingController name = TextEditingController();
  FocusNode nameFocus = FocusNode();
  TextEditingController phoneNr = TextEditingController();
  FocusNode phoneFocus = FocusNode();
  List<FocusNode> nodes = [];

  final ImagePicker _picker = ImagePicker();
  DynamicImage image = DynamicImage(isFile: false);

  bool get valid {
    return
      validateName(name.text) == null &&
      validatePhoneNr(phoneNr.text) == null &&
      placesApi.selectedPlace != null &&
      placesApi.selectedPlace!.isValid && placesApi.streetTf.text.isNotEmpty &&
      (image.url != null || image.croppedFile != null);
  }

  bool get showButton => nodes.every((element) => element.hasFocus == false);

  Future<void> pickImage() async {
    ColorTheme colors = Provider.of<UserController>(context, listen: false).getColors;
    FocusScope.of(context).unfocus();
    setState(() => uploading = true);
    final pickedFile =
    await _picker.pickImage(maxWidth: 1000, source: ImageSource.gallery);

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
        image.url = null;
        image.isFile = true;
        image.croppedFile = croppedFile;
        uploading = false;
      });
    }
  }

  void prefill() {
    Vendor vendor = Provider.of<UserController>(context, listen: false).getVendor!;
    name.text = vendor.name;
    phoneNr.text = vendor.phoneNr;
    image = DynamicImage(isFile: false, url: vendor.imageUrl);
    placesApi.prefill(vendor.place);
    setState(() {});
  }

  void initFocusNodes() {
    nodes = [nameFocus, phoneFocus, placesApi.locationFocus];
    for(FocusNode node in nodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void initState() {
    super.initState();
    initFocusNodes();
    prefill();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String language = context.locale.toString().split("_").first;
      placesApi.language = language;
    });
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
          "general.editVendor".tr(),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
              color: colors.backgroundColor
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  imagePicker,
                  if(image.url == null && image.croppedFile == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("validators.noPic".tr(),style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.destructiveRed,
                      ),),
                    ),
                  const SizedBox(height: 25),
                  nameTf,
                  const SizedBox(height: 15),
                  phoneTf,
                  const SizedBox(height: 15),
                  cityAutocompleteTf,
                  const SizedBox(height: 15),
                  disabledTf(placesApi.plzTf, "general.postalCode".tr()),
                  const SizedBox(height: 15),
                  disabledTf(placesApi.cityCountryTf, "general.cityCountry".tr())
                ],
              ),
            ),
          ),
        ),
        if(showButton)
          saveButton,
      ],
    );
  }

  Widget get imagePicker {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    double width = 120;
    late Widget child;
    if(image.url != null) {
      child = ClipOval(
        child: Image.network(
          image.url!,
          width: width,
          height: width,
          fit: BoxFit.cover,
        ),
      );
    }
    else {
      child = ClipOval(
        child: Image.file(
          File(image.croppedFile!.path),
          width: width,
          height: width,
          fit: BoxFit.cover,
        ),
      );
    }

    bool showGradientBorder = image.url != null || image.croppedFile != null;
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
      textCapitalization: TextCapitalization.sentences,
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
        labelText: "general.displayName".tr(),
        fillColor: colors.buttonColor,
        errorText: validateName(name.text),
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
      textInputAction: TextInputAction.next,
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
        errorText: validatePhoneNr(phoneNr.text),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

  Widget get cityAutocompleteTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      cursorColor: colors.textColor,
      focusNode: placesApi.locationFocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      controller: placesApi.streetTf,
      autofocus: false,
      onChanged: (value) => setState(() {}),
      style: TextStyle(color: colors.textColor),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
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
        labelStyle: TextStyle(
          color: colors.textColor.withValues(alpha: 0.5),
        ),
        labelText: "general.streetNr".tr(),
        fillColor: colors.buttonColor,
        errorText: validatePlace(placesApi),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        ),
      ),
      onSubmitted: (value) {
        placesApi.locationFocus.unfocus();
      },
    );;
  }

  Widget disabledTf(TextEditingController controller, String labelText) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      controller: controller,
      autofocus: false,
      enabled: false,
      style: TextStyle(color: colors.textColor.withValues(alpha: 0.7), fontSize: 15),
      decoration: InputDecoration(
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
                color: colors.secondary.withValues(alpha: 0.3),
                width: 0.5
            )
        ),
        filled: true,
        labelStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
        labelText: labelText,
        fillColor: colors.buttonColor,
        errorStyle: const TextStyle(color: CupertinoColors.destructiveRed),
      ),
    );
  }

  Widget get saveButton {
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
          height: 55,
          width: double.maxFinite,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
            ),
            onPressed: () async {
              if(!valid) return;

              setState(() => uploading = true);
              await Future.delayed(const Duration(seconds: 1)); // pleasing UI

              String imageUrl = "";
              if(image.isFile) {
                Reference storageReference = FirebaseStorage.instance
                    .ref().child('vendors').child(vendor.id).child(UniqueKey().toString());

                await storageReference.putFile(File(image.croppedFile!.path));
                imageUrl = await storageReference.getDownloadURL();
              }
              else {
                imageUrl = image.url!;
              }

              await FirebaseFirestore.instance
                .collection("vendors").doc(vendor.id)
                .update({
                  "name": name.text,
                  "imageUrl": imageUrl,
                  "phoneNr": phoneNr.text,
                  "place": placesApi.selectedPlace!.toMap()
                });

              if(!mounted) return;
              Navigator.pop(context);
            },
            child: Text(
              'general.save'.tr(),
              style: TextStyle(
                fontSize: 15,
                color: valid ? colors.primaryText : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
