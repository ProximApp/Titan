import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/class/ticket_url.dart';
import 'package:titan/feed/repositories/event_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TicketUrlNotifier extends SingleNotifier<TicketUrl> {
  @override
  AsyncValue<TicketUrl> build() {
    return const AsyncValue.loading();
  }

  EventRepository get eventRepository => ref.watch(eventRepositoryProvider);

  Future<AsyncValue<TicketUrl>> getTicketUrl(String eventId) async {
    return await load(() => eventRepository.getTicketUrl(eventId));
  }
}

final ticketUrlProvider =
    NotifierProvider<TicketUrlNotifier, AsyncValue<TicketUrl>>(
      TicketUrlNotifier.new,
    );
