import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/image_compression.dart';

class ImagePickerOnTap extends StatelessWidget {
  final ImagePicker picker;
  final ValueNotifier<Uint8List?> imageBytesNotifier;
  final ValueNotifier<Image?> imageNotifier;
  final void Function(TypeMsg, String) displayToastWithContext;
  final Widget child;
  final int? imageQuality;

  const ImagePickerOnTap({
    super.key,
    required this.picker,
    required this.imageBytesNotifier,
    required this.imageNotifier,
    required this.displayToastWithContext,
    required this.child,
    this.imageQuality,
  });

  @override
  Widget build(BuildContext context) {
    final localizeWithContext = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        final crossFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: imageQuality,
        );
        if (crossFile == null) {
          return;
        }
        // The preview shows the compressed bytes rather than the picked file
        // so what the user validates is what gets sent.
        final bytes = await compressImageForUpload(
          await crossFile.readAsBytes(),
        );
        if (bytes == null) {
          displayToastWithContext(
            TypeMsg.error,
            localizeWithContext.othersImageSizeTooBig,
          );
          return;
        }
        imageBytesNotifier.value = bytes;
        imageNotifier.value = Image.memory(bytes);
      },
      child: child,
    );
  }
}
