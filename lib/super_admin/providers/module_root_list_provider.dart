import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/super_admin/providers/permission_name_list_provider.dart';
import 'package:titan/super_admin/providers/permissions_list_provider.dart';
import 'package:titan/super_admin/tools/module_roots.dart';
import 'package:titan/user/providers/user_provider.dart';

final moduleRootListProvider = Provider<AsyncValue<List<String>>>((ref) {
  final userAsync = ref.watch(asyncUserProvider);
  final permissionsAsync = ref.watch(permissionsProvider);
  final catalogAsync = ref.watch(permissionsNamesListProvider);

  if (userAsync.isLoading ||
      permissionsAsync.isLoading ||
      catalogAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (userAsync.hasError) {
    return AsyncValue.error(userAsync.error!, userAsync.stackTrace!);
  }
  if (permissionsAsync.hasError) {
    return AsyncValue.error(
      permissionsAsync.error!,
      permissionsAsync.stackTrace!,
    );
  }
  if (catalogAsync.hasError) {
    return AsyncValue.error(catalogAsync.error!, catalogAsync.stackTrace!);
  }

  final user = userAsync.requireValue;
  final permissions = permissionsAsync.requireValue;
  final catalog = catalogAsync.requireValue;

  final moduleRoots = computeUserModuleRoots(
    user: user,
    permissions: permissions,
    permissionCatalog: catalog,
  );

  return AsyncValue.data(moduleRoots);
});
