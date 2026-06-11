import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../controller+api/user_controller.dart';
import '../utils/colors.dart';

class ReAuthDialog extends StatefulWidget {

  const ReAuthDialog({super.key});

  @override
  ReAuthDialogState createState() => ReAuthDialogState();
}

class ReAuthDialogState extends State<ReAuthDialog> {

  late TextEditingController textControllerEmail;
  late FocusNode textFocusNodeEmail;

  late TextEditingController textControllerPassword;
  late FocusNode textFocusNodePassword;
  bool showPassword = false;

  bool _isLoggingIn = false;
  bool _isSubmitted = false;

  String? loginStatus;
  Color loginStringColor = Colors.green;

  String? _validateEmail(String value) {
    value = value.trim();

    if (!EmailValidator.validate(value)) {
      return 'login.errorEmail'.tr();
    }

    return null;
  }

  @override
  void initState() {
    textControllerEmail = TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
    textControllerPassword = TextEditingController();
    textFocusNodeEmail = FocusNode();
    textFocusNodePassword = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Dialog(
      backgroundColor: colors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: colors.backgroundColor,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Image.asset(
                  colors.isDarkTheme ? 'assets/logo/logo-font-dark.png' : 'assets/logo/logo-font-light.png',
                  height: 40,
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  'auth.reauthenticate'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                enabled: false,
                cursorColor: colors.textColor,
                focusNode: textFocusNodeEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                controller: textControllerEmail,
                onChanged: (value) {
                  setState(() { });
                },
                onSubmitted: (value) {
                  textFocusNodeEmail.unfocus();
                  FocusScope.of(context)
                      .requestFocus(textFocusNodePassword);
                },
                style: TextStyle(color: colors.textColor,),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: colors.textColor.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: colors.textColor.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  labelStyle: TextStyle(
                    color: colors.textColor.withValues(alpha: 0.8),
                  ),
                  labelText: "login.eMail".tr(),
                  fillColor: colors.buttonColor.withValues(alpha: 0.8),
                  errorText: _isSubmitted
                      ? _validateEmail(textControllerEmail.text)
                      : null,
                  errorStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  cursorColor: colors.textColor,
                  focusNode: textFocusNodePassword,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  controller: textControllerPassword,
                  obscureText: !showPassword,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() { });
                  },
                  onSubmitted: (value) {
                    textFocusNodePassword.unfocus();
                  },
                  style: TextStyle(color: colors.textColor),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      onPressed: () => setState(() => showPassword = !showPassword),
                      icon: Icon(
                        !showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        size: 24,
                        color: colors.textColor,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                          color: colors.textColor.withValues(alpha: 0.7),
                          width: 2
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                          color: colors.textColor.withValues(alpha: 0.7),
                          width: 2
                      ),
                    ),
                    filled: true,
                    labelStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.8)),
                    labelText: "login.password".tr(),
                    fillColor: colors.buttonColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: Center(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          _isLoggingIn = true;
                          _isSubmitted = true;
                          textFocusNodeEmail.unfocus();
                          textFocusNodePassword.unfocus();
                        });
                        if (_validateEmail(textControllerEmail.text) == null) {
                          try {
                            AuthCredential credential = EmailAuthProvider.credential(email: textControllerEmail.text, password: textControllerPassword.text);

                            await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);

                            if(!mounted)return;
                            Navigator.pop(context, credential);

                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              setState(() {
                                loginStatus ='auth.invalid'.tr();
                                loginStringColor = Colors.red;
                              });
                              if (kDebugMode) {
                                print('No user found for that email.');
                              }
                            } else if (e.code == 'wrong-password') {
                              setState(() {
                                loginStatus ='validators.wrongPW'.tr();
                                loginStringColor = Colors.red;
                              });
                            }
                            else {
                              setState(() {
                                loginStatus = e.message!;
                                loginStringColor = Colors.red;
                              });
                            }
                          }
                        } else {
                          setState(() {
                            loginStatus = 'login.emailAndPW'.tr();
                            loginStringColor = Colors.red;
                          });
                        }
                        setState(() {
                          _isLoggingIn = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: _isLoggingIn
                            ?
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.textColor),
                          ),
                        )
                            :
                        Text(
                          'auth.reauth'.tr(),
                          style: TextStyle(
                              fontSize: 16,
                              color: colors.primaryText,
                              fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              loginStatus != null
                  ?
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 5.0),
                  child: Text(
                    loginStatus!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: loginStringColor,
                      fontSize: 14,
                      // letterSpacing: 3,
                    ),
                  ),
                ),
              )
                  :
              Container(),
            ],
          ),
        ),
      ),
    );
  }
}
