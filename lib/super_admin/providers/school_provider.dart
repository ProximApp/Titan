import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/super_admin/class/school.dart';
import 'package:titan/super_admin/repositories/school_repository.dart';

class SchoolNotifier extends Notifier<School> {
  late final SchoolRepository schoolRepository;

  @override
  School build() {
    schoolRepository = ref.watch(schoolRepositoryProvider);
    return School.empty();
  }

  void setSchool(School school) {
    state = school;
  }
}

final schoolProvider = NotifierProvider<SchoolNotifier, School>(
  SchoolNotifier.new,
);
