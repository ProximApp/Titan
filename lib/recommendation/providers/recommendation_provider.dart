import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class RecommendationNotifier extends Notifier<Recommendation> {
  @override
  Recommendation build() {
    return EmptyModels.empty<Recommendation>();
  }

  void setRecommendation(Recommendation r) {
    state = r;
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, Recommendation>(
      RecommendationNotifier.new,
    );
