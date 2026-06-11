import 'package:animate_do/animate_do.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dogus_barber/utils/functions.dart';
import 'package:dogus_barber/utils/models.dart';
import 'package:uuid/uuid.dart';
import '../../../controller+api/user_controller.dart';
import '../../../utils/colors.dart';
import '../../../utils/validator.dart';
import '../../../utils/widgets.dart';

class CreateEditService extends StatefulWidget {

  final bool edit;
  final Service? service;

  const CreateEditService({super.key, required this.edit, this.service});

  @override
  State<CreateEditService> createState() => _CreateEditServiceState();
}

class _CreateEditServiceState extends State<CreateEditService> {

  TextEditingController name = TextEditingController();
  FocusNode nameFocus = FocusNode();
  TextEditingController price = TextEditingController();
  FocusNode priceFocus = FocusNode();
  bool showButton = true;
  List<FocusNode> nodes = [];

  List<int> durations = [5,10,15,20,25,30,45,60,75,90,105,120];
  double durationIndex = 5;

  Color selectedColor = Colors.blue;

  bool isSubmitted = false;

  bool get valid => validateName(name.text) == null && validatePrice(price.text) == null;

  void onFocusChange() {
    setState(() => showButton = nodes.every((element) => element.hasFocus == false));
  }

  void initFocusNodes() {
    nodes = [nameFocus, priceFocus];
    for(FocusNode node in nodes) {
      node.addListener(onFocusChange);
    }
  }

  @override
  void initState() {
    if(widget.edit) {
      name.text = widget.service!.name;
      price.text = doubleToEuroString(widget.service!.price);
      durationIndex = durations.indexOf(widget.service!.duration).toDouble();
      selectedColor = Color(widget.service!.color);
    }
    initFocusNodes();
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
          "services.${widget.edit ? "edit" : "create"}".tr(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19
          ),
        ),
      ),
      body: FadeInUp(child: body),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  nameTf,
                  const SizedBox(height: 20),
                  priceTf,
                  const SizedBox(height: 20),
                  durationSlider,
                  const SizedBox(height: 20),
                  colorPicker,
                  const SizedBox(height: 50),
                ],
              ),
            )
          ),
        ),
        if(showButton)
          if(widget.edit)
            ...[
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 20, left: 10, right: 10),
                child: Row(
                  children: [
                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),

                      child: submitButton,
                    )),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      child: deleteButton,
                    )),

                  ],
                ),
              ),
            ],
          if(!widget.edit)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: SafeArea(child: submitButton),
            ),
      ],
    );
  }

  Widget get nameTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      focusNode: nameFocus,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: colors.textColor,
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
        labelText: "services.name".tr(),
        fillColor: colors.buttonColor,
        errorText: isSubmitted ? validateName(name.text) : null,
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

  Widget get priceTf {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return TextField(
      focusNode: priceFocus,
      cursorColor: colors.textColor,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      inputFormatters: [CurrencyTextInputFormatter.currency(decimalDigits: 2,symbol: '€', enableNegative: false)],
      textInputAction: TextInputAction.done,
      controller: price,
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
        labelText: "services.price".tr(),
        fillColor: colors.buttonColor,
        errorText: isSubmitted ? validatePrice(price.text) : null,
        errorStyle: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.destructiveRed,
        )
      )
    );
  }

  Widget get durationSlider {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15.0, bottom: 10),
          child: Row(
            children: [
              Text(
                "durations.duration".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textColor
                )
              ),
              const SizedBox(width: 5),
              Text(
                durationString(durations[durationIndex.toInt()]),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor
                )
              )
            ],
          ),
        ),
        Slider(
          activeColor: colors.primary,
          inactiveColor: colors.primary.withValues(alpha: 0.3),
          value: durationIndex,
          min: 0,
          max: 11,
          divisions: 11,
          label: shortDurationString(durations[durationIndex.toInt()]),
          onChanged: (double value) => setState(() => durationIndex = value),
        ),
      ],
    );
  }

  Widget get colorPicker {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return ColorPicker(
      padding: const EdgeInsets.all(0),
      pickersEnabled: const <ColorPickerType, bool>{ColorPickerType.primary : true, ColorPickerType.accent: false},
      color: selectedColor,
      onColorChanged: (Color color) => setState(() => selectedColor = color),
      width: 30,
      height: 30,
      borderRadius: 20,
      heading: Text(
        "services.selectColor".tr(),
        style: TextStyle(
          color: colors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600
        ),
      ),
      subheading: Text(
        "services.selectColorShade".tr(),
        style: TextStyle(
          color: colors.textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500
        ),
      ),
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
            String id = widget.edit ? widget.service!.id : const Uuid().v4();
            int duration = durations[durationIndex.toInt()];
            Service s = Service(id: id, name: name.text.trim(), price: euroStringToDouble(price.text),
                duration: duration, color: selectedColor.value);
            Navigator.pop(context, s);
          }
        },
        child: Text(
          "general.save".tr(),
          style: TextStyle(
            fontSize: 15,
            color: valid ? colors.primaryText : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget get deleteButton {
    ColorTheme colors = Provider.of<UserController>(context).getColors;
    return SizedBox(
      width: double.maxFinite,
      height: 55,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
        ),
        onPressed: () async {
          final retVal = await showDialog(
            context: context,
            builder: (BuildContext context) =>
              NativeDialog(
                title: "actions.cancelService".tr(),
                content: "actions.cancelServiceMessage".tr(),
                buttonTextOne: "general.yes".tr(),
                buttonTextTwo: "general.no".tr(),
                buttonOne: () => Navigator.pop(context, 'delete'),
                buttonTwo: () => Navigator.pop(context),
                buttonOneRed: true,
              )
          );
          if(retVal == 'delete' && mounted) {
            Navigator.pop(context, 'delete');
          }
        },
        child: Text(
          "general.delete".tr(),
          style: TextStyle(
            fontSize: 15,
            color: valid ? Colors.red : Colors.grey,
          ),
        ),
      ),
    );
  }

}