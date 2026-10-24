import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../presentation/settings_screens.dart';

/// Lets the player take or choose a photo, then uploads it as their avatar.
/// Returns the new URL, or null if they cancelled.
Future<String?> pickAndUploadAvatar(
  WidgetRef ref,
  ImageSourceChoice choice,
) async {
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
  final bytes = await file.readAsBytes();
  final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
  final url = await ref
      .read(settingsRepositoryProvider)
      .uploadAvatar(bytes, ext);
  await ref.read(sessionProfileProvider.notifier).reload();
  return url;
}
