import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/router.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/centralisation/router.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/event/router.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:collection/collection.dart';
import 'package:titan/home/router.dart';
import 'package:titan/mypayment/router.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/purchases/router.dart';
import 'package:titan/raffle/router.dart';
import 'package:titan/recommendation/router.dart';
import 'package:titan/seed-library/router.dart';
import 'package:titan/tickets/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/settings/router.dart';
import 'package:titan/super_admin/providers/is_super_admin_provider.dart';
import 'package:titan/super_admin/router.dart';
import 'package:titan/vote/router.dart';

final modulesProvider = NotifierProvider<ModulesNotifier, List<Module>>(
  ModulesNotifier.new,
);

class ModulesNotifier extends Notifier<List<Module>> {
  String dbModule = "modules";
  String dbAllModules = "allModules";
  bool isAdmin = false;
  bool isSuperAdmin = false;
  int _loadCounter = 0;
  final eq = const DeepCollectionEquality.unordered();
  List<Module> allModules = [
    HomeRouter.module,
    AdvertRouter.module,
    AmapRouter.module,
    BookingRouter.module,
    CentralisationRouter.module,
    CinemaRouter.module,
    EventRouter.module,
    LoanRouter.module,
    PaymentRouter.module,
    PhonebookRouter.module,
    PhRouter.module,
    PurchasesRouter.module,
    RaffleRouter.module,
    RecommendationRouter.module,
    VoteRouter.module,
    SeedLibraryRouter.module,
    TicketsRouter.module,
  ];

  @override
  List<Module> build() {
    final moduleRootsAsync = ref.watch(moduleRootListProvider);

    isAdmin = ref.watch(isAdminProvider);
    isSuperAdmin = ref.watch(isSuperAdminProvider);

    moduleRootsAsync.whenData((roots) {
      final myModulesRoot = roots.map((root) => '/$root').toList();
      debugPrint(
        '[Modules] build() → roots=$myModulesRoot, '
        'isAdmin=$isAdmin, isSuperAdmin=$isSuperAdmin, '
        'allModulesInMemory=${allModules.map((m) => m.root).toList()}',
      );
      loadModules(myModulesRoot);
    });

    if (moduleRootsAsync.isLoading) {
      debugPrint('[Modules] build() → en attente des permissions');
    }

    return [];
  }

  void saveModules() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(dbModule);
      prefs.setStringList(
        dbModule,
        state.map((e) => e.root.toString()).toList(),
      );
    });
  }

  void saveAllModules() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(dbAllModules);
      prefs.setStringList(
        dbAllModules,
        allModules.map((e) => e.root.toString()).toList(),
      );
    });
  }

  Module getModuleByRoot(String root) {
    try {
      return allModules.firstWhere((m) => m.root.toString() == root);
    } catch (e) {
      return allModules.first;
    }
  }

  Future loadModules(List<String> roots) async {
    final loadId = ++_loadCounter;
    debugPrint(
      '[Modules] loadModules#$loadId START → roots=$roots, '
      'allModulesInMemory(${allModules.length})=${allModules.map((m) => m.root).toList()}',
    );

    final prefs = await SharedPreferences.getInstance();
    List<String> modulesName = prefs.getStringList(dbModule) ?? [];
    List<String> allSavedModulesName = prefs.getStringList(dbAllModules) ?? [];
    final allModulesName = allModules.map((e) => e.root.toString()).toList();

    debugPrint(
      '[Modules] loadModules#$loadId prefs → '
      'modulesName=$modulesName, allSavedModulesName=$allSavedModulesName',
    );

    if (modulesName.isEmpty) {
      debugPrint('[Modules] loadModules#$loadId → modulesName vide, init depuis allModules');
      modulesName = allModulesName;
      saveModules();
    }
    if (allSavedModulesName.isEmpty ||
        !eq.equals(allSavedModulesName, allModulesName)) {
      debugPrint(
        '[Modules] loadModules#$loadId → reset prefs '
        '(allSaved=${allSavedModulesName.length}, inMemory=${allModulesName.length})',
      );
      allSavedModulesName = allModulesName;
      modulesName = allModulesName;
      saveAllModules();
      saveModules();
    } else {
      debugPrint('[Modules] loadModules#$loadId → tri depuis prefs existantes');
      allModules.sort(
        (a, b) => allSavedModulesName
            .indexOf(a.root.toString())
            .compareTo(allSavedModulesName.indexOf(b.root.toString())),
      );
      modulesName.sort(
        (a, b) => allSavedModulesName
            .indexOf(a)
            .compareTo(allSavedModulesName.indexOf(b)),
      );
    }
    List<Module> modules = [];
    List<Module> toDelete = [];
    for (String name in modulesName) {
      if (allModulesName.contains(name)) {
        Module module = allModules[allSavedModulesName.indexOf(name)];
        if (roots.contains(module.root)) {
          debugPrint('[Modules] loadModules#$loadId ✓ keep ${module.root} (permission OK)');
          modules.add(module);
        } else {
          debugPrint('[Modules] loadModules#$loadId ✗ remove ${module.root} (pas dans roots=$roots)');
          toDelete.add(module);
        }
      } else {
        debugPrint('[Modules] loadModules#$loadId ⚠ skip $name (absent de allModulesInMemory)');
      }
    }
    for (Module module in toDelete) {
      allModules.remove(module);
    }
    for (final module in [
      SettingsRouter.module,
      if (isAdmin) AdminRouter.module,
      if (isSuperAdmin) SuperAdminRouter.module,
    ]) {
      if (!allModules.contains(module)) {
        debugPrint('[Modules] loadModules#$loadId + inject ${module.root} (système)');
        allModules.add(module);
      }
    }
    state = allModules;
    debugPrint(
      '[Modules] loadModules#$loadId END → state(${state.length})=${state.map((m) => m.root).toList()}',
    );
  }

  void sortModules() {
    final allModulesName = allModules.map((e) => e.root.toString()).toList();
    final sorted = state.sublist(0)
      ..sort(
        (a, b) => allModulesName
            .indexOf(a.root.toString())
            .compareTo(allModulesName.indexOf(b.root.toString())),
      );
    state = sorted;
    saveModules();
  }

  void reorderModules(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    allModules.insert(newIndex, allModules.removeAt(oldIndex));
    final modulesIds = state.map((e) => e.root.toString()).toList();
    state = allModules
        .where((e) => modulesIds.contains(e.root.toString()))
        .toList();
    saveAllModules();
  }

  void toggleModule(Module m) {
    List<Module> r = state.sublist(0);
    if (r.contains(m)) {
      r.remove(m);
    } else {
      r.add(m);
    }
    state = r;
    sortModules();
    saveModules();
  }
}
