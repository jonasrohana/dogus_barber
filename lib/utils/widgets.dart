import 'package:blur/blur.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:time_range/time_range.dart';
import 'package:dogus_barber/utils/constants.dart';
import '../auth+onboarding/login_register.dart';
import '../controller+api/user_controller.dart';
import '../controller+api/vendor_controller.dart';
import 'colors.dart';
import 'functions.dart';
import 'models.dart';


class LoginBanner extends StatelessWidget {
  const LoginBanner({super.key});

  @override
  Widget build(BuildContext context) {
    UserProfile? profile = Provider.of<UserController>(context).getUserProfile;
    if(profile != null) {
      return Container();
    }

    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        children: [
          Text(
            "accountInfo".tr(),
            style: TextStyle(
              fontSize: 14,
              color: colors.textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 55,
              width: double.maxFinite,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                ),
                onPressed: () => showModalBottomSheet(
                  backgroundColor: colors.buttonColor,
                  isScrollControlled: true,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                  context: context,
                  builder: (BuildContext context) => Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                    height: MediaQuery.of(context).size.height*0.75,
                    child: LoginScreen())
                ),
                child:
                Text(
                  "loginSignUp".tr(),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// restart widget, root of whole app for language change
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<RestartWidgetState>()?.restartApp();
  }

  @override
  RestartWidgetState createState() => RestartWidgetState();
}

class RestartWidgetState extends State<RestartWidget> {

  Key key = UniqueKey();

  void restartApp() => setState(() => key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

// appointment widgets
class TimeRangeSheet extends StatefulWidget {

  final String label;
  final String time;
  final bool isBreakTimeEdit;

  const TimeRangeSheet({super.key, required this.label, required this.time, this.isBreakTimeEdit = false});

  @override
  TimeRangeSheetState createState() => TimeRangeSheetState();
}

class TimeRangeSheetState extends State<TimeRangeSheet> {

  late TimeRangeResult openingEdit;
  bool closed = false;

  @override
  void initState() {
    super.initState();

    if(widget.isBreakTimeEdit) {
      if(widget.time.isNotEmpty) {
        openingEdit = TimeRangeResult(stringToTime(widget.time.split("-").first), stringToTime(widget.time.split("-").last));
      }
      else {
        openingEdit = TimeRangeResult(const TimeOfDay(hour: 12, minute: 00), const TimeOfDay(hour: 12, minute: 30));
      }
      closed = false;
    }
    else {
      if(widget.time.isNotEmpty) {
        openingEdit = TimeRangeResult(stringToTime(widget.time.split("-").first), stringToTime(widget.time.split("-").last));
      }
      else {
        openingEdit = TimeRangeResult(const TimeOfDay(hour: 10, minute: 00), const TimeOfDay(hour: 10, minute: 00));
      }
      closed = openingEdit.start == openingEdit.end;
    }

  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.buttonColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15)
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  color: colors.textColor,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 20),
            if(!closed)
              ...[
                TimeRange(
                  fromTitle: Text(
                    "general.from".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  toTitle: Text(
                    "general.until".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  titlePadding: 20,
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: colors.textColor,
                  ),
                  activeTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: colors.secondaryText,
                  ),
                  borderColor: colors.textColor,
                  activeBorderColor: colors.secondary,
                  backgroundColor: Colors.transparent,
                  activeBackgroundColor: colors.secondary,
                  firstTime: const TimeOfDay(hour: 6, minute: 00),
                  lastTime: const TimeOfDay(hour: 22, minute: 00),
                  initialRange: openingEdit,
                  timeStep: widget.isBreakTimeEdit ? 15 : 30,
                  timeBlock: widget.isBreakTimeEdit ? 15 : 30,
                  onRangeCompleted: (range) {
                    if(range != null) {
                      setState(() => openingEdit = range);
                    }
                  },
                ),
                const SizedBox(height: 20)
              ],
            if(!widget.isBreakTimeEdit)
              closedSwitchTile,
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  height: 55,
                  width: double.maxFinite,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                    onPressed: () {
                      String start = "${openingEdit.start.hour.toString().padLeft(2,'0')}.${openingEdit.start.minute.toString().padLeft(2,'0')}";
                      String end = "${openingEdit.end.hour.toString().padLeft(2,'0')}.${openingEdit.end.minute.toString().padLeft(2,'0')}";
                      String result = closed || start == end ? "" : "$start-$end";
                      Navigator.pop(context, result);
                    },
                    child: Text(
                      "general.save".tr(),
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get closedSwitchTile {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Theme(
      data: ThemeData().copyWith(highlightColor: Colors.transparent),
      child: SwitchListTile.adaptive(
        activeColor: colors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Text(
          "general.closed".tr(),
          style: TextStyle(
            fontSize: 15,
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "general.closedDescription".tr(),
          style: TextStyle(
            fontSize: 12,
            color: colors.textColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
        value: closed,
        onChanged: (val) => setState(() {
          closed = val;
          openingEdit = TimeRangeResult(const TimeOfDay(hour: 10, minute: 00),
            const TimeOfDay(hour: 10, minute: 00));
        })
      ),
    );
  }

}

class DatePickerSheet extends StatefulWidget {

  final DateTime initialDate;
  final DateRangePickerView? view;
  final DateTime? minDate;
  final DateTime? maxDate;

  const DatePickerSheet({super.key, required this.initialDate, this.view, this.minDate, this.maxDate});

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {

  late DateTime selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        color: colors.buttonColor
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 5, width: 45,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15)
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "general.selectDate".tr(),
                  style: TextStyle(color: colors.textColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 15),
              SfDateRangePicker(
                backgroundColor: Colors.transparent,
                maxDate: widget.maxDate,
                minDate: widget.minDate,
                initialDisplayDate: widget.initialDate,
                initialSelectedDate: widget.initialDate,
                showActionButtons: false,
                view: widget.view ?? DateRangePickerView.month,
                monthViewSettings: DateRangePickerMonthViewSettings(
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(textStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.7))),
                  firstDayOfWeek: 1,
                ),
                selectionMode: DateRangePickerSelectionMode.single,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is DateTime) {
                    setState(() => selectedDate = args.value);
                  }
                },
                selectionColor: colors.primary,
                selectionTextStyle: TextStyle(color: colors.primaryText),
                startRangeSelectionColor: colors.primary,
                endRangeSelectionColor: colors.primary,
                rangeSelectionColor: colors.primary.withValues(alpha: 0.5),
                todayHighlightColor: colors.primary,
                headerStyle: DateRangePickerHeaderStyle(
                  backgroundColor: Colors.transparent,
                  textStyle: TextStyle(color: colors.textColor),
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: TextStyle(color: colors.textColor),
                  todayTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  leadingDatesTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
                  disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(color: colors.textColor),
                  weekendTextStyle: TextStyle(color: colors.textColor),
                  todayTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  leadingDatesTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
                  disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                ),
              ),

              PrimaryButton(text: "general.save".tr(), onPressed: () => Navigator.pop(context, selectedDate), color: colors.primary, enabled: true)
            ],
          ),
        ),
      ),
    );
  }
}

class DateRangePickerSheet extends StatefulWidget {

  const DateRangePickerSheet({super.key});

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {

  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        color: colors.buttonColor
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 5, width: 45,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15)
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "general.selectHolidayDates".tr(),
                  style: TextStyle(color: colors.textColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 15),
              SfDateRangePicker(
                minDate: DateTime.now(),
                initialDisplayDate: DateTime.now(),
                showActionButtons: false,
                view: DateRangePickerView.month,
                monthViewSettings: DateRangePickerMonthViewSettings(
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(textStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.7))),
                  firstDayOfWeek: 1,
                ),
                selectionMode: DateRangePickerSelectionMode.range,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  final value = args.value;
                  if (value is PickerDateRange) {
                    setState(() {
                      startDate = value.startDate;
                      endDate = value.endDate;
                    });
                  }
                },
                selectionColor: colors.primary,
                selectionTextStyle: TextStyle(color: colors.primaryText),
                startRangeSelectionColor: colors.primary,
                endRangeSelectionColor: colors.primary,
                rangeSelectionColor: colors.primary.withValues(alpha: 0.5),
                todayHighlightColor: colors.primary,
                headerStyle: DateRangePickerHeaderStyle(
                  textStyle: TextStyle(color: colors.textColor),
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: TextStyle(color: colors.textColor),
                  todayTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  leadingDatesTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
                  disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(color: colors.textColor),
                  weekendTextStyle: TextStyle(color: colors.textColor),
                  todayTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  leadingDatesTextStyle: TextStyle(color: colors.textColor.withValues(alpha: 0.5)),
                  disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                ),
              ),

              PrimaryButton(
                text: "general.save".tr(),
                onPressed: () {
                  if(startDate != null && endDate != null) {
                    Navigator.pop(context, PickerDateRange(startDate!, endDate!));
                  }
                },
                color: colors.textColor,
                enabled: startDate != null && endDate != null
              )
            ],
          ),
        ),
      ),
    );
  }
}




// dialogs
class AnimationDialog extends StatefulWidget {

  final String text;
  final bool isSuccess;

  const AnimationDialog({super.key, required this.text, required this.isSuccess});

  @override
  State<AnimationDialog> createState() => _AnimationDialogState();
}

class _AnimationDialogState extends State<AnimationDialog> {

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      if(mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Dialog(
      backgroundColor: colors.buttonColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'assets/logo/logo-transparent.png',
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                widget.text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: colors.textColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Image.asset(
                  widget.isSuccess ? 'assets/images/check.png' : 'assets/images/remove.png',
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NativeDialog extends StatelessWidget {
  final String content;
  final String title;
  final String buttonTextOne;
  final String buttonTextTwo;
  final Function()? buttonOne;
  final Function()? buttonTwo;
  final bool buttonOneRed;

  const NativeDialog({
    super.key,
    required this.content,
    required this.title,
    required this.buttonTextOne,
    required this.buttonTextTwo,
    this.buttonOne,
    this.buttonTwo,
    required this.buttonOneRed
  });

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Dialog(
      backgroundColor: colors.buttonColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      child: Container(
        decoration: BoxDecoration(
            color: colors.buttonColor,
            borderRadius: BorderRadius.circular(25.0)
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'assets/logo/logo-transparent.png',
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                content,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: colors.textColor.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => buttonOne!(),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: buttonOneRed ? CupertinoColors.destructiveRed : colors.primary,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        child: Center(
                          child: Text(
                            buttonTextOne,
                            style: TextStyle(
                              fontSize: 15,
                              color: buttonOneRed ? Colors.white : colors.primaryText,
                            ),
                          )
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => buttonTwo!(),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        child: Center(
                          child: Text(buttonTextTwo,
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.secondaryText,
                            ),
                          )
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ShowDialogToDismiss extends StatelessWidget {
  final String content;
  final String title;
  final String buttonText;
  final VoidCallback? function;

  const ShowDialogToDismiss({super.key, required this.title, required this.buttonText, required this.content, this.function});

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Dialog(
      backgroundColor: colors.buttonColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0),),
      child: Container(
        decoration: BoxDecoration(
            color: colors.buttonColor,
            borderRadius: BorderRadius.circular(25.0)
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'assets/logo/logo-transparent.png',
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                content,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: colors.textColor.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  if(function != null) {
                    function!();
                  }
                  Navigator.pop(context);
                },
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(
                        child: Text(buttonText,
                          style: TextStyle(
                              fontSize: 15,
                              color: colors.primaryText
                          ),
                        )
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ForceUpdateDialog extends StatelessWidget{
  const ForceUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Dialog(
      backgroundColor: colors.buttonColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0),),
      child: Container(
        decoration: BoxDecoration(
            color: colors.buttonColor,
            borderRadius: BorderRadius.circular(25.0)
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset(
                  'assets/logo/logo-transparent.png',
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "UPDATE",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "pleaseUpdate".tr(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: colors.textColor.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => openStoreListing(),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(
                      child: Text("updateNow".tr(),
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.primaryText
                        ),
                      )
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


// useful widgets
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 300,
    ),
  });

  @override
  FadeIndexedStackState createState() => FadeIndexedStackState();
}

class FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}

class ExpandedSection extends StatefulWidget {

  final Widget child;
  final bool expand;
  const ExpandedSection({super.key, this.expand = false, required this.child});

  @override
  ExpandedSectionState createState() => ExpandedSectionState();
}

class ExpandedSectionState extends State<ExpandedSection> with SingleTickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    if(widget.expand) {
      expandController.forward();
    }
  }

  ///Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300)
    );
    Animation curve = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
    animation = Tween(begin: 0.0, end: 1.0).animate(curve as Animation<double>)
      ..addListener(() {
        setState(() {

        });
      }
      );
  }

  @override
  void didUpdateWidget(ExpandedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.expand) {
      expandController.forward();
    }
    else {
      expandController.reverse();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        axisAlignment: 1.0,
        sizeFactor: animation,
        child: widget.child
    );
  }
}

class ProfileImageCircle extends StatelessWidget {

  final String imageUrl;
  final double width;
  final String hero;

  const ProfileImageCircle(this.imageUrl, this.width, {super.key, this.hero = ''});

  @override
  Widget build(BuildContext context) {
    if(imageUrl.isEmpty) {

      return ClipOval(
        child: Image.network(
          userPlaceholderImage,
          width: width,
          height: width,
          fit: BoxFit.cover,
        ),
      );
    }

    return Hero(
      tag: hero.isNotEmpty ? hero : UniqueKey().toString(),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: width,
          height: width,
          fit: BoxFit.cover,
          loadingBuilder: (context,child,progress) {
            if (progress == null) return child;
            return SizedBox(
              width: width,
              height: width,
              child: Center(child: CupertinoActivityIndicator()),
            );
          },
        ),
      ),
    );
  }
}

class LoadingStack extends StatelessWidget {

  final Widget child;
  final bool loading;

  const LoadingStack({super.key, required this.child, required this.loading});

  @override
  Widget build(BuildContext context) {
    if(!loading) {
      return child;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
            child: Blur(
                blur: 1.5,
                colorOpacity: 0,
                child: child
            )
        ),

        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withValues(alpha: 0.9)
          ),
          child: Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.white.withValues(alpha: 0.6))),
        )
      ],
    );
  }
}

class KeepAlivePage extends StatefulWidget {

  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  KeepAlivePageState createState() => KeepAlivePageState();
}

class KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1.0});

  final Gradient gradient;

  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
      Canvas canvas,
      Rect rect, {
        TextDirection? textDirection,
        BoxShape shape = BoxShape.rectangle,
        BorderRadius? borderRadius,
      }) {
    switch (shape) {
      case BoxShape.circle:
        assert(
        borderRadius == null,
        'A borderRadius can only be given for rectangular boxes.',
        );
        _paintCircle(canvas, rect);
        break;
      case BoxShape.rectangle:
        if (borderRadius != null) {
          _paintRRect(canvas, rect, borderRadius);
          return;
        }
        _paintRect(canvas, rect);
        break;
    }
  }

  void _paintRect(Canvas canvas, Rect rect) {
    canvas.drawRect(rect.deflate(width / 2), _getPaint(rect));
  }

  void _paintRRect(Canvas canvas, Rect rect, BorderRadius borderRadius) {
    final rrect = borderRadius.toRRect(rect).deflate(width / 2);
    canvas.drawRRect(rrect, _getPaint(rect));
  }

  void _paintCircle(Canvas canvas, Rect rect) {
    final paint = _getPaint(rect);
    final radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  Paint _getPaint(Rect rect) {
    return Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;
  }
}

class ThemedSvgImage extends StatelessWidget {
  final String assetName;
  final double height;

  const ThemedSvgImage({super.key, required this.assetName, required this.height});

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    String directory = colors.isDarkTheme ? "undraw_dark" : "undraw_light";
    return SvgPicture.asset(
      "assets/$directory/$assetName.svg",
      height: height,
    );
  }
}

class PhoneNumberInputFormatter extends TextInputFormatter {

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // allows only numbers and + at the beginning
    String pattern = r'^\+?[0-9]*$';
    RegExp regExp = RegExp(pattern);

    // allows change if valid
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue; // invalid -> discard change
  }
}

class SettingsMenu extends StatelessWidget {

  final IconData icon;
  final String text;
  final Function() onPressed;
  final bool isDestructive;
  final bool showBadge;
  final bool enabled;

  const SettingsMenu({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.showBadge = false,
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    Color color = isDestructive ? CupertinoColors.destructiveRed : colors.textColor;
    if(!enabled) {
      color = color.withValues(alpha: 0.7);
    }
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: colors.buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textColor.withValues(alpha: 0.1))
        ),
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Badge(
              isLabelVisible: showBadge,
              backgroundColor: CupertinoColors.destructiveRed,
              smallSize: 10,
              largeSize: 10,
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w500
              ),
            ),
            const Spacer(),
            Icon(Ionicons.arrow_forward, color: colors.textColor.withValues(alpha: 0.5), size: 20,)
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {

  final String text;
  final Function() onPressed;
  final bool enabled;
  final Color color;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return SizedBox(
      width: double.maxFinite,
      height: 55,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
        ),
        onPressed: onPressed,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: enabled ? colors.primaryText : Colors.grey,
            ),
          ),
        ),
      ),
    );

  }
}

class CustomTabBar extends StatelessWidget {

  final List<String> tabs;
  final Function(int) function;
  final TabController? controller;

  const CustomTabBar({
    super.key,
    this.controller,
    required this.function,
    required this.tabs
  });

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return TabBar(
      controller: controller,
      onTap: function,

      indicatorColor: colors.textColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      labelPadding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 10, bottom: 10),

      dividerColor: Colors.transparent,
      labelColor: colors.textColor,
      unselectedLabelColor: colors.textColor.withValues(alpha: 0.6),
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 16),
      tabs: List.generate(tabs.length, (index) => Text(
        tabs[index],
      ))
    );
  }
}

class ActionSheetAction {
  final String name;
  final VoidCallback onPressed;
  final bool destructive;
  final IconData? icon;
  final bool enabled;
  final Widget? leading;

  ActionSheetAction({
    required this.name,
    required this.onPressed,
    this.destructive = false,
    this.enabled = true,
    this.icon,
    this.leading
  });
}

class ActionSheet extends StatelessWidget {

  final List<ActionSheetAction> actions;

  const ActionSheet({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    ColorTheme colors = Provider.of<VendorController>(context).getColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        color: colors.buttonColor
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 5, width: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15)
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: colors.textColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(25)
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: actions.length,
                  separatorBuilder: (BuildContext context, int index) => Container(height: 1, width: double.maxFinite, color: colors.textColor.withValues(alpha: 0.06)),
                  itemBuilder: (BuildContext context, int index) {
                    ActionSheetAction action = actions[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: ()  {
                        Navigator.pop(context);
                        if(action.enabled) {
                          action.onPressed();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          children: [
                            if(action.leading != null)
                              ...[
                                action.leading!,
                                const SizedBox(width: 15)
                              ],
                            Expanded(
                              child: TextScroll(
                                action.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: action.destructive ? CupertinoColors.destructiveRed : colors.textColor.withValues(alpha: action.enabled ? 1 : 0.6),
                                  fontWeight: FontWeight.w500
                                ),
                                mode: TextScrollMode.bouncing,
                                delayBefore: const Duration(milliseconds: 2000),
                                pauseBetween: const Duration(milliseconds: 1000),
                                velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                              ),
                            ),
                            if(action.icon != null)
                              ...[
                                const SizedBox(width: 15),
                                Icon(action.icon, color: action.destructive ? CupertinoColors.destructiveRed : colors.textColor.withValues(alpha: action.enabled ? 1 : 0.6), size: 22)
                              ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageViewer extends StatelessWidget {

  final String hero;
  final String url;

  const ImageViewer({super.key, required this.hero, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              child: Text(
                "general.close".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: PhotoView(
        heroAttributes: PhotoViewHeroAttributes(tag: hero),
        imageProvider: NetworkImage(url)
      ),
    );
  }
}

