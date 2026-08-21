import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller+api/user_controller.dart';
import '../../../controller+api/vendor_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/widgets.dart';

class SendPushNewsletter extends StatefulWidget {

  const SendPushNewsletter({super.key});

  @override SendPushNewsletterState createState() => SendPushNewsletterState();
}

class SendPushNewsletterState extends State<SendPushNewsletter> {

  bool loading = false;
  bool isSubmitted = false;

  TextEditingController title = TextEditingController();
  TextEditingController message = TextEditingController();

  bool get valid => title.text.isNotEmpty && message.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Rundnachricht",
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20
          ),
        ),
      ),
      body: LoadingStack(
          loading: loading,
          child: body
      ),
      backgroundColor: colors.backgroundColor,
    );
  }

  Widget get body {
    return FadeInUp(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          descriptionTF(title, TextInputType.text, TextInputAction.next,'Betreff', false),
          descriptionTF(message, TextInputType.multiline, null, 'Text', true),
          const SizedBox(height: 25),
          submitButton,
          const SizedBox(height: 50)
        ],
      ),
    );
  }

  Widget descriptionTF(
      TextEditingController textController,
      TextInputType keyboard,
      TextInputAction? action,
      String labelText,
      bool isMultiline
      ) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          autocorrect: false,
          textCapitalization: TextCapitalization.sentences,
          maxLength: isMultiline ? 800 : 100,
          minLines: isMultiline ? 10 : 1,
          maxLines: isMultiline ? 15 : 1,
          cursorColor: colors.textColor,
          keyboardType: keyboard,
          textInputAction: action,
          controller: textController,
          textAlign: TextAlign.start,
          onChanged: (value) => setState(() {}),
          style: TextStyle(color: colors.textColor, fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                width: 0,
                style: BorderStyle.none,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                width: 2,
                color: CupertinoColors.destructiveRed,
              ),
            ),
            filled: true,
            fillColor: colors.buttonColor,
            suffixIconConstraints: const BoxConstraints(maxWidth: 35, minWidth: 35),
            errorText: isSubmitted && isMultiline && textController.text.isEmpty ? "Darf nicht leer sein" : null,
            errorStyle: const TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ],
    );
  }

  Widget get submitButton {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: PrimaryButton(
        onPressed: () async {
          if(!valid) return;

          await FirebaseFirestore.instance.collection("broadcasts").add({
            "title": title.text.trim(),
            "text": message.text.trim(),
            "createdAt": DateTime.now()
          });

          if(mounted) {
            await showDialog(
              context: context,
              builder: (BuildContext context) =>
                AnimationDialog(text: "Die Rundnachricht wurde erfolgreich verschickt, deine Kunden werden die Information per Mail erhalten!", isSuccess: true)
            );
          }
          if(mounted) {
            Navigator.pop(context);
          }
        },
        text: "Rundnachricht senden",
        enabled: true,
        color: colors.primary
      ),
    );
  }

}