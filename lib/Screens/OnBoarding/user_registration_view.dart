import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nowly/Configs/configs.dart';
import 'package:nowly/Controllers/controller_exporter.dart';
import 'package:nowly/Screens/OnBoarding/exercise_history.dart';
import 'package:nowly/Screens/OnBoarding/goal.dart';
import 'package:nowly/Screens/OnBoarding/injury_history.dart';
import 'package:nowly/Screens/OnBoarding/medical_history.dart';
import 'package:nowly/Screens/OnBoarding/name_and_info.dart';
import 'package:nowly/Widgets/widget_exporter.dart';

class UserRegistrationView extends GetView<RegistrationController> {
  UserRegistrationView({Key? key}) : super(key: key);
  final RegistrationController _controller = Get.put(RegistrationController());
  final headerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          // IconButton(
          //     onPressed: () => Get.find<AuthController>().signOut(),
          //     icon: Icon(Icons.exit_to_app))
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: UIParameters.screenPadding,
          child: SingleChildScrollView(
            child: SeperatedColumn(
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(
                  height: kContentGap,
                );
              },
              children: [
                Row(children: const [
                  CloseButton(),
                ]),
                // Text(
                //   'Our goal is to provide you the best fit trainer \n for your needs. Please take a moment and \n provide this info, help us help you!',
                //   textAlign: TextAlign.center,
                // ),
                Obx(
                  () => Transform.translate(
                    offset: const Offset(0, -15),
                    child: Text(
                      _controller.selectedQuestionnaire.value.header,
                      style: k16BoldTS,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                NameAndInfo(
                  controller: _controller,
                ),
                Goal(
                  controller: _controller,
                ),
                PScore(
                  controller: _controller,
                  key: headerKey,
                ),
                ExerciseHistory(controller: _controller),
                InjuryHistory(controller: _controller),
                MedicalHistory(controller: _controller),
                const SizedBox(
                  height: 5,
                ),
                MainButton(
                    onTap: () async {
                      await _controller.isEveryRequirmentsFilled();
                      _controller.createUser();
                      // _controller.testit();
                    },
                    title: 'CONTINUE')
              ],
            ),
          ),
        ),
      ),
    );
  }
}
