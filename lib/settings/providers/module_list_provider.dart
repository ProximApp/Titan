import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/router.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/centralisation/router.dart';
import 'package:titan/cinema/router.dart';
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
  final eq = const DeepCollectionEquality.unordered();
  List<Module> allModules = [
    HomeRouter.module,
    AdvertRouter.module,
    AmapRouter.module,
    BookingRouter.module,
    CentralisationRouter.module,
    CinemaRouter.module,
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
      loadModules(myModulesRoot);
    });

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
    for (final module in allModules) {
      if (module.root.toString() == root) return module;
    }
    for (final module in state) {
      if (module.root.toString() == root) return module;
    }
    return state.isNotEmpty ? state.first : allModules.first;
  }

  Future loadModules(List<String> roots) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> modulesName = prefs.getStringList(dbModule) ?? [];
    List<String> allSavedModulesName = prefs.getStringList(dbAllModules) ?? [];
    final allModulesName = allModules.map((e) => e.root.toString()).toList();

    if (modulesName.isEmpty) {
      modulesName = allModulesName;
      saveModules();
    }
    if (allSavedModulesName.isEmpty ||
        !eq.equals(allSavedModulesName, allModulesName)) {
      allSavedModulesName = allModulesName;
      modulesName = allModulesName;
      saveAllModules();
      saveModules();
    } else {
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
    for (String name in modulesName) {
      if (allModulesName.contains(name)) {
        Module module = allModules[allSavedModulesName.indexOf(name)];
        if (roots.contains(module.root)) {
          modules.add(module);
        }
      }
    }
    for (final module in [
      SettingsRouter.module,
      if (isAdmin) AdminRouter.module,
      if (isSuperAdmin) SuperAdminRouter.module,
    ]) {
      if (!modules.contains(module)) {
        modules.add(module);
      }
    }
    state = modules;
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
    final visible = List<Module>.of(state);
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);
    if (allModules.contains(moved)) {
      allModules.remove(moved);
      Module? anchor;
      for (var i = newIndex - 1; i >= 0; i--) {
        if (allModules.contains(visible[i])) {
          anchor = visible[i];
          break;
        }
      }
      final insertAt = anchor == null ? 0 : allModules.indexOf(anchor) + 1;
      allModules.insert(insertAt, moved);
    }
    state = visible;
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
