import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/super_admin/providers/account_types_list_provider.dart';

final allAccountTypes = Provider<List<enums.AccountType>>((ref) {
  return ref
      .watch(allAccountTypesListProvider)
      .maybeWhen(data: (data) => data, orElse: () => []);
});
