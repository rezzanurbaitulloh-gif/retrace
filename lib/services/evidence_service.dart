import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Thin platform wrapper around image picking (§33).
/// Permission gating lives in the UI via [permissionServiceProvider] —
/// this service never requests permissions itself, so denial stays honest
/// and explainable at the call site.
abstract class EvidenceCaptureService {
  Future<XFile?> pickImage(ImageSource source);
}

final class RealEvidenceCaptureService implements EvidenceCaptureService {
  RealEvidenceCaptureService([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }
}

final evidenceCaptureServiceProvider = Provider<EvidenceCaptureService>(
  (Ref ref) => RealEvidenceCaptureService(),
);
