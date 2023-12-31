import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todo_riverpod/core/utils/constants.dart';
import 'package:todo_riverpod/core/widgets/core_widgets.dart';
import 'package:todo_riverpod/features/auth/widgets/alert_dialog_box.dart';

import '../../../core/helpers/notification_helper.dart';
import '../../../core/models/task_model.dart';
import '../controllers/date/date_provider.dart';
import '../controllers/todo/todo_provider.dart';
import 'homepage.dart';

class AddPage extends ConsumerStatefulWidget {
  const AddPage({super.key});

  @override
  ConsumerState<AddPage> createState() => _AddPageState();
}

class _AddPageState extends ConsumerState<AddPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late NotificationHelper notificationHelper;
  late NotificationHelper notificationController;
  List<int> notification = [];

  // late AnimationController animationController;
  @override
  void initState() {
    notificationHelper = NotificationHelper(ref: ref);
    notificationController = NotificationHelper(ref: ref);
    notificationHelper.initializeNotification();

    super.initState();
  }

  // @override
  // void dispose() {
  //   animationController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final scheduleDate = ref.watch(dateStateProvider);
    final startTime = ref.watch(startTimeStateProvider);
    final endTime = ref.watch(finishTimeStateProvider);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppConst.kLight,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            children: [
              HeightSpacer(
                spaceHeight: 20.h,
              ),
              CustomTextFormField(
                hintText: 'Enter your Title',
                controller: titleController,
              ),
              HeightSpacer(
                spaceHeight: 20.h,
              ),
              CustomTextFormField(
                hintText: 'Enter your Description',
                controller: descriptionController,
                // hintStyle: appStyle(16, AppConst.kGreyLight, FontWeight.normal),
              ),
              HeightSpacer(
                spaceHeight: 20.h,
              ),
              CustomOutlineButton(
                borderColor: AppConst.kLight,
                height: 52.h,
                bgColor: AppConst.kBlueLight,
                text: scheduleDate.isEmpty ? 'Set Date' : scheduleDate,
                width: AppConst.kWidth,
                onPressed: () {
                  picker.DatePicker.showDatePicker(context,
                      showTitleActions: true,
                      minTime: DateTime.now(),
                      maxTime:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                      theme: const picker.DatePickerTheme(
                          headerColor: Colors.white,
                          itemStyle: TextStyle(
                              color: AppConst.kBlueLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                          doneStyle:
                              TextStyle(color: AppConst.kGreen, fontSize: 16)),
                      //     onChanged: (date) {
                      //   if (kDebugMode) {
                      //     log('change $date in time zone ${date.timeZoneOffset.inHours}');
                      //   }
                      // },
                      onConfirm: (date) {
                    ref
                        .read(dateStateProvider.notifier)
                        .setDate(date.toString().substring(0, 10));
                  }, currentTime: DateTime.now(), locale: picker.LocaleType.en);
                },
              ),
              HeightSpacer(
                spaceHeight: 20.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomOutlineButton(
                    borderColor: AppConst.kLight,
                    height: 52.h,
                    bgColor: AppConst.kBlueLight,
                    text: startTime.isEmpty ? 'Start Time' : startTime,
                    width: AppConst.kWidth * 0.4,
                    onPressed: () {
                      picker.DatePicker.showDateTimePicker(context,
                          showTitleActions: true, onConfirm: (date) {
                        notification = ref
                            .read(startTimeStateProvider.notifier)
                            .dates(date);
                        ref
                            .read(startTimeStateProvider.notifier)
                            .setStart(date.toString().substring(10, 16));
                      }, locale: picker.LocaleType.en);
                    },
                  ),
                  CustomOutlineButton(
                    borderColor: AppConst.kLight,
                    height: 52.h,
                    bgColor: AppConst.kBlueLight,
                    text: endTime.isEmpty ? 'End Time' : endTime,
                    width: AppConst.kWidth * 0.4,
                    onPressed: () {
                      picker.DatePicker.showDateTimePicker(context,
                          showTitleActions: true, onConfirm: (date) {
                        ref
                            .read(finishTimeStateProvider.notifier)
                            .setFinish(date.toString().substring(10, 16));
                      }, locale: picker.LocaleType.en);
                    },
                  ),
                ],
              ),
              HeightSpacer(
                spaceHeight: 20.h,
              ),
              CustomOutlineButton(
                borderColor: AppConst.kLight,
                height: 52.h,
                bgColor: AppConst.kGreen,
                text: 'Submit',
                width: AppConst.kWidth,
                onPressed: () {
                  if (isContentNotEmpty(scheduleDate, startTime, endTime)) {
                    addTask(scheduleDate, startTime, endTime);
                    // clearSelectedDateAndTime();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()));
                  } else {
                    ref.read(checkTaskEntryProvider.notifier).state = false;
                    showAlertDialog(
                        context: context, message: "Failed to add task");
                  }
                },
              ),
            ],
          ),
        ));
  }

  addTask(String scheduleDate, String startTime, String endTime) {
    Task task = Task(
      title: titleController.text,
      desc: descriptionController.text,
      date: scheduleDate,
      startTime: startTime,
      endTime: endTime,
      isCompleted: 0,
      remind: 0,
      repeat: "yes",
    );
    notificationHelper.scheduleNotification(notification[0], notification[1],
        notification[2], notification[3], task);
    ref.read(todoStateProvider.notifier).addItem(task);
    ref.read(checkTaskEntryProvider.notifier).state = true;
  }

  bool isContentNotEmpty(
      String scheduleDate, String startTime, String endTime) {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        scheduleDate.isNotEmpty &&
        startTime.isNotEmpty &&
        endTime.isNotEmpty;
  }

  void clearSelectedDateAndTime() {
    ref.read(dateStateProvider.notifier).setDate('');
    ref.read(startTimeStateProvider.notifier).setStart('');
    ref.read(finishTimeStateProvider.notifier).setFinish('');
  }
}
