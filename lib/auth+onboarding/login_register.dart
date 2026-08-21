import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../controller+api/user_controller.dart';
import '../controller+api/vendor_controller.dart';
import '../utils/colors.dart';
import '../utils/validator.dart';
import '../utils/widgets.dart';

enum LoginPageState {
  reset,
  login,
  signUp
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  LoginPageState type = LoginPageState.login;

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool showPassword = false;
  bool _isSubmitted = false;
  bool _isLoggingIn = false;

  String errorMessage = "";

  bool get valid {
    if(type == LoginPageState.reset) {
      return validateEmail(email.text) == null;
    }
    if(type == LoginPageState.login) {
      return validateEmail(email.text) == null &&
          validatePassword(password.text) == null;
    }
    return validateEmail(email.text) == null &&
        validatePassword(password.text) == null;
  }

  void handleFirebaseAuthError(String code) {
    if(kDebugMode) print(code);
    if(code == "INVALID_LOGIN_CREDENTIALS") code = "invalid";
    setState(() => errorMessage = "auth.$code".tr());
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Stack(
      children: [
        Stack(
          children: [
            Image.asset(
              "assets/images/background.jpeg",
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: colors.backgroundColor.withValues(alpha: 0.0)
              ),
            ),
          ],
        ),
        body
      ],
    );
  }

  Widget get body {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(15),
              height: 180,
              alignment: Alignment.center,
              child: Image.asset('assets/logo/logo-transparent.png'),
            ),
          ),
          buildTF(15, 5, TextInputType.emailAddress, type == LoginPageState.reset ? TextInputAction.done : TextInputAction.next, email, false, "login.email".tr(), _isSubmitted ? validateEmail(email.text) : null),
          if(type != LoginPageState.reset)
            buildTF(0,5, TextInputType.text, type == LoginPageState.signUp ? TextInputAction.next : TextInputAction.done, password, true, "login.password".tr(), _isSubmitted ? validatePassword(password.text) : null),
          if(type != LoginPageState.signUp)
            Container(
              padding: const EdgeInsets.only(top: 10, right: 20),
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => setState(() => type = type == LoginPageState.login ? LoginPageState.reset :  LoginPageState.login),
                child: Text(
                  type != LoginPageState.login ? "login.login".tr() : "login.forgot".tr(),
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if(type == LoginPageState.signUp)
            const SizedBox(height: 30,),
          const SizedBox(height: 15),
          if(errorMessage.isNotEmpty)
            ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Center(child: Text(errorMessage, textAlign: TextAlign.center,style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
              ),
              const SizedBox(height: 10),
            ],
          submitButton,
          if(type != LoginPageState.reset)
            ...[
              signUpRow,
            ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildTF(double bottomPadding, double leftPadding, TextInputType inputType, TextInputAction inputAction,
      TextEditingController controller, bool obscure, String labelText, String? errorText) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    bool isPw = controller == password;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextField(
        cursorColor: colors.textColor.withValues(alpha: 0.5),
        keyboardType: inputType,
        textInputAction: inputAction,
        controller: controller,
        obscureText: obscure && !showPassword,
        autofocus: false,
        onChanged: (value) => setState(() { errorMessage = "";}),
        style: TextStyle(color: colors.textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(isPw ? Ionicons.lock_closed_outline : Ionicons.mail_outline, color: colors.textColor, size: 25),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          suffixIcon: isPw ? IconButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: () => setState(() => showPassword = !showPassword),
            icon: Icon(showPassword ? Ionicons.eye_off_outline : Ionicons.eye_outline, color: colors.textColor),
          ) : null,
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
          labelText: labelText,
          fillColor: colors.buttonColor,
          errorText: errorText,
          errorStyle: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.destructiveRed,
          ),
        ),
      ),
    );
  }

  Widget get signUpRow {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            type != LoginPageState.login ? 'login.gotAccount'.tr() : 'login.noAccount'.tr(),
            style: TextStyle(
              color: colors.textColor,
              fontSize: 15.0,
              fontWeight: FontWeight.w300,
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                errorMessage = "";
                if(type == LoginPageState.login) {
                  type = LoginPageState.signUp;
                }
                else {
                  type = LoginPageState.login;
                }
              });
            },
            child: Text(
              type != LoginPageState.login ? " ${"login.login".tr()} " : " ${"login.create".tr()} ",
              style: TextStyle(
                color: colors.textColor,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget get submitButton {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Center(
        child: SizedBox(
          height: 55,
          width: double.maxFinite,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            ),
            onPressed: submitAction,
            child: _isLoggingIn
                ?
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
                :
            Text(
              type == LoginPageState.reset ? "login.reset".tr() : (type == LoginPageState.login ? 'login.login'.tr() : "login.createAccount".tr()),
              style: TextStyle(
                fontSize: 15,
                color: valid ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submitAction() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitted = true;
      _isLoggingIn = true;
    });
    if(valid) {
      if(type == LoginPageState.reset){
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
          if(!mounted)  return;
          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => AnimationDialog(
              text: "auth.password-reset-email-sent".tr(),
              isSuccess: true
            )
          );
          setState(() => errorMessage = "");
          if(mounted) Navigator.pop(context);
        } on FirebaseAuthException catch (e) {
          handleFirebaseAuthError(e.code);
        }
      }
      else if(type == LoginPageState.login) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text
          );
          if(mounted) Navigator.pop(context);
        }
        on FirebaseAuthException catch (e) {
          handleFirebaseAuthError(e.code);
        }
      }
      else {
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text
          );
          if(mounted) Navigator.pop(context);
        } on FirebaseAuthException catch (e) {
          handleFirebaseAuthError(e.code);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
      }
    }
    else {
      setState(() => errorMessage = "login.info".tr());
    }
    setState(() => _isLoggingIn = false);
  }

}
