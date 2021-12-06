import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app/controllers/camera_controller.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/data/services/app_photo.dart';
import '../../../../core/themes/text.dart';
import '../../../../core/widgets/member_image_leading.dart';
import '../../../07_settings/views/controllers/user_controller.dart';
import '../controllers/verify_controller.dart';
import 'static_verifier_sheet_lock.dart';

class VerifierScreen extends StatefulWidget {
  const VerifierScreen({Key? key}) : super(key: key);

  @override
  State<VerifierScreen> createState() => _VerifierScreenState();
}

class _VerifierScreenState extends State<VerifierScreen> {
  /* <---- We should wait a little bit to finish the build,
  because on lower end device it takes time to start the device,
  so the controller doesn't start immedietly.Then we see some white screen, that's why we should wait a little bit.
   -----> */
  final RxBool _isScreenReady = false.obs;

  Future<void> _waitABit() async {
    await Future.delayed(
      const Duration(seconds: 1),
    ).then((value) {
      Get.put(AppCameraController());
    });
    _isScreenReady.trigger(true);
  }

  /// State
  @override
  void initState() {
    super.initState();
    _waitABit();
  }

  @override
  void dispose() {
    Get.delete<AppCameraController>(force: true);
    _isScreenReady.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Verifier',
                style: AppText.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            Obx(() => _isScreenReady.isFalse
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const _CameraSection()),
          ],
        ),
      ),
    );
  }
}

class _CameraSection extends StatelessWidget {
  const _CameraSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppCameraController>(
      builder: (controller) => controller.activatingCamera == true
          ? const Expanded(child: Center(child: CircularProgressIndicator()))
          : Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(controller.cameraController),
                  ),
                  /* <---- Verifier Button ----> */
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: const [
                        _UseAsAVerifierButton(),
                      ],
                    ),
                  ),
                  /* <---- Camera Switch Button ----> */
                  Positioned(
                    top: 15,
                    right: 10,
                    child: Opacity(
                      opacity: 0.5,
                      child: FloatingActionButton(
                        onPressed: controller.toggleCameraLens,
                        child: const Icon(Icons.switch_camera_rounded),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                  ),

                  /// MESSAGE SHOWING
                  Positioned(
                    bottom: Get.height * 0.10,
                    left: 0,
                    right: 0,
                    child: const _ShowMessage(),
                  ),

                  /// TEMPORARY
                  const _TemporaryFunctionToCheckMethod(),
                ],
              ),
            ),
    );
  }
}

class _ShowMessage extends StatelessWidget {
  /// This will show up when verification started
  const _ShowMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VerifyController>(
      builder: (controller) {
        return Center(
          child: AnimatedOpacity(
            // IF We Should show the card
            opacity: controller.showProgressIndicator ? 1.0 : 0.0,
            duration: AppDefaults.defaultDuration,
            child: AnimatedContainer(
              duration: AppDefaults.defaultDuration,
              margin: const EdgeInsets.all(AppSizes.defaultMargin),
              padding: const EdgeInsets.all(10),
              width: Get.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDefaults.defaulBorderRadius,
                boxShadow: AppDefaults.defaultBoxShadow,
              ),
              child: controller.isVerifyingNow
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          AppSizes.wGap10,
                          Text('Verifying'),
                        ],
                      ),
                    )
                  : controller.verifiedMember == null
                      ? const ListTile(
                          title: Text('No Member Found'),
                          trailing: Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        )
                      : ListTile(
                          leading: MemberImageLeading(
                            imageLink: controller.verifiedMember!.memberPicture,
                          ),
                          title: Text(controller.verifiedMember!.memberName),
                          subtitle: Text(controller.verifiedMember!.memberNumber
                              .toString()),
                          trailing: const Icon(
                            Icons.check_box_rounded,
                            color: AppColors.appGreen,
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}

class _TemporaryFunctionToCheckMethod extends GetView<AppCameraController> {
  const _TemporaryFunctionToCheckMethod({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: Get.height * 0.12,
      child: Column(
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              XFile _image = await controller.cameraController.takePicture();
              Uint8List _file = await _image.readAsBytes();

              bool _isPersonPresent = await Get.find<VerifyController>()
                  .isPersonDetected(capturedImage: _file);

              if (_isPersonPresent) {
                Get.snackbar(
                  'A Face is detected',
                  'This is a dummy function, you should return the real value',
                  colorText: Colors.white,
                  backgroundColor: Colors.green,
                );
              }
            },
            label: const Text('Detect Person'),
            icon: const Icon(Icons.camera),
            backgroundColor: AppColors.primaryColor,
          ),
          AppSizes.hGap20,
          /* <----  -----> */
          FloatingActionButton.extended(
            onPressed: () async {
              XFile _image = await controller.cameraController.takePicture();
              Uint8List _uin8file = await _image.readAsBytes();
              // File _file = File.fromRawPath(_uin8file);

              String? user = await Get.find<VerifyController>()
                  .verifyPersonList(memberToBeVerified: _uin8file);

              if (user != null) {
                Get.snackbar(
                  'Person Verified: $user',
                  'Verified Member',
                  colorText: Colors.white,
                  backgroundColor: Colors.green,
                );
              }
            },
            label: const Text('Verify From All'),
            icon: const Icon(Icons.people_alt_rounded),
            backgroundColor: AppColors.primaryColor,
          ),
          AppSizes.hGap20,
          /* <----  -----> */
          FloatingActionButton.extended(
            onPressed: () async {
              XFile _image = await controller.cameraController.takePicture();
              Uint8List _file = await _image.readAsBytes();

              String _currentUserImageUrl =
                  Get.find<AppUserController>().currentUser.userProfilePicture!;
              File _currentUserImage =
                  await AppPhotoService.fileFromImageUrl(_currentUserImageUrl);

              bool _isVerified =
                  await Get.find<VerifyController>().verfiyPersonSingle(
                capturedImage: _file,
                personImage: _currentUserImage,
              );

              if (_isVerified) {
                Get.snackbar(
                  'Person Verified Successfull',
                  'Verified Member',
                  colorText: Colors.white,
                  backgroundColor: Colors.green,
                );
              }
            },
            label: const Text('Verify Single'),
            icon: const Icon(Icons.person),
            backgroundColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _UseAsAVerifierButton extends StatelessWidget {
  const _UseAsAVerifierButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Get.bottomSheet(
        //   StaticVerifierPasswordSet(),
        //   isScrollControlled: true,
        // );
        Get.bottomSheet(
            const StaticVerifierLockUnlock(
              isLockMode: true,
            ),
            isScrollControlled: true);
      },
      child: Container(
        width: Get.width,
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.defaultRadius),
            topRight: Radius.circular(AppSizes.defaultRadius),
          ),
          boxShadow: AppDefaults.defaultBoxShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Use as a static verifier',
              style: AppText.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
