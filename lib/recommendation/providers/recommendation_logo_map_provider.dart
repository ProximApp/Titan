import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/map_provider.dart';

class RecommendationLogoMapNotifier
    extends MapNotifier<Recommendation, Image> {}

final recommendationLogoMapProvider =
    NotifierProvider<
      RecommendationLogoMapNotifier,
      Map<Recommendation, AsyncValue<List<Image>>?>
    >(() => RecommendationLogoMapNotifier());
