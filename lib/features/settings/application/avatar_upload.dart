import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../presentation/settings_screens.dart';

/// Lets the player take or choose a photo, ready to upload as their avatar:
/// its bytes and file extension, or null if they cancelled.
Future<(Uint8List, String)?> pickAvatar(ImageSourceChoice choice) async {
  final file = await ImagePicker().pickImage(
    source: choice == ImageSourceChoice.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.front,
  );
  if (file == null) return null;
  final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
  return (await file.readAsBytes(), ext);
}
