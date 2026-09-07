import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/adapters/ticket_event.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class ShotgunListNotifier extends ListNotifierAPI<EventSimple> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<EventSimple>> build() {
    loadShotgunList();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<EventSimple>>> loadShotgunList() async {
    return await loadList(repository.ticketsEventsGet);
  }

  Future<bool> createTicketEvent(EventCreate event) async {
    return await add(
      () => repository
          .ticketsAdminEventsPost(body: event)
          // TODO : Fix back
          .then(
            (response) =>
                Response(response.base, response.body?.toEventSimple()),
          ),
      event,
    );
  }
}

final ticketEventListProvider =
    NotifierProvider<ShotgunListNotifier, AsyncValue<List<EventSimple>>>(
      ShotgunListNotifier.new,
    );
