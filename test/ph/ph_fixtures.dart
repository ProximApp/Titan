import 'package:titan/generated/openapi.models.swagger.dart';

/// The PH admin gate group.
const adminPhGroupId = '4ec5ae77-f955-4309-96a5-19cc3c8be71c';

/// Create a PH paper with a predictable release day; set [month] for a
/// specific journal month, otherwise journals use March.
PaperComplete paperFixture(String id, String name, int year, [int month = 3]) =>
    PaperComplete.empty().copyWith(
      id: id,
      name: name,
      releaseDate: DateTime(year, month, 7),
    );
