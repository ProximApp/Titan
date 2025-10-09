import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/recommendation/class/recommendation.dart';

class RecommendationNotifier extends Notifier<Recommendation> {
  @override
  Recommendation build() {
    return Recommendation.empty();
  }

  void setRecommendation(Recommendation r) {
    state = r;
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, Recommendation>(
      RecommendationNotifier.new,
    );
