import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/providers/map_provider.dart';

class AssociationLogoMapNotifier extends MapNotifier<String, Image> {}

final associationLogoMapProvider =
    NotifierProvider<
      AssociationLogoMapNotifier,
      Map<String, AsyncValue<List<Image>>?>
    >(() => AssociationLogoMapNotifier());
