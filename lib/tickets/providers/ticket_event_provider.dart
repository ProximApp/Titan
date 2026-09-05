import 'package:chopper/chopper.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/client_mapping.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/adapters/category.dart';
import 'package:titan/tickets/adapters/question.dart';
import 'package:titan/tickets/adapters/session.dart';
import 'package:titan/tickets/adapters/ticket_event.dart';
import 'package:titan/tools/providers/single_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

/// The event an admin is currently looking at, plus every edit that can be made
/// to it.
///
/// Sessions, categories and questions live inside [EventAdmin], so their
/// endpoints all go through [update]: the request is sent, and on success the
/// state becomes the locally recomputed event. That avoids a refetch, which
/// would discard the unsaved form input the edit page is holding.
class TicketEventNotifier extends SingleNotifierAPI<EventAdmin> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<EventAdmin> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<EventAdmin>> loadTicketEvent(String eventId) async {
    return await load(
      () => repository.ticketsAdminEventsEventIdGet(eventId: eventId),
    );
  }

  void setTicketEvent(EventAdmin ticketEvent) {
    state = AsyncValue.data(ticketEvent);
  }

  Future<bool> editTicketEvent(EventAdmin ticketEvent) async {
    return await update(
      () => repository.client.send<void, void>(
        Request(
          'PATCH',
          Uri.parse('/tickets/admin/events/${ticketEvent.id}'),
          repository.client.baseUrl,
          body: ticketEvent.toUpdateJson(),
        ),
      ),
      ticketEvent,
    );
  }

  Future<bool> deleteEvent(String eventId) async {
    return await this.delete(
      () => repository.ticketsAdminEventsEventIdDelete(eventId: eventId),
    );
  }

  /// Cancels the event: unlike a delete, the sales stay on record and the
  /// attendees are refunded.
  ///
  /// The endpoint does not exist yet — it arrives with a later codegen pass —
  /// so this reports a failure rather than pretending the event was cancelled.
  /// Once generated, call it through [update] like the other mutations and drop
  /// the `ticketsCancelEventUnavailable` reason at the call site.
  Future<bool> cancelEvent(String eventId) async {
    return false;
  }

  // --- Sessions ---

  /// Returns the created session, or null when the backend refused it.
  ///
  /// The id only exists once the response comes back, so the merged event is
  /// applied after [update] rather than being handed to it up front.
  Future<SessionAdmin?> createSession(
    EventAdmin event,
    SessionCreate session,
  ) async {
    SessionComplete? created;
    await update(() async {
      generatedMapping.putIfAbsent(
        SessionComplete,
        () => SessionComplete.fromJsonFactory,
      );
      final response = await repository.client
          .send<SessionComplete, SessionComplete>(
            Request(
              'POST',
              Uri.parse('/tickets/admin/events/${event.id}/sessions'),
              repository.client.baseUrl,
              body: session.toCreateJson(),
            ),
          );
      if (response.isSuccessful) created = response.body;
      return response;
    }, event);

    final body = created;
    if (body == null) return null;
    final admin = body.toSessionAdmin();
    setTicketEvent(event.copyWith(sessions: [...event.sessions, admin]));
    return admin;
  }

  Future<bool> updateSession(EventAdmin event, SessionAdmin session) async {
    return await update(
      () => repository.client.send<void, void>(
        Request(
          'PATCH',
          Uri.parse('/tickets/admin/events/${event.id}/sessions/${session.id}'),
          repository.client.baseUrl,
          body: session.toUpdateJson(),
        ),
      ),
      event.copyWith(
        sessions: [
          for (final s in event.sessions) s.id == session.id ? session : s,
        ],
      ),
    );
  }

  Future<bool> deleteSession(EventAdmin event, String sessionId) async {
    return await update(
      () => repository.ticketsAdminEventsEventIdSessionsSessionIdDelete(
        eventId: event.id,
        sessionId: sessionId,
      ),
      event.copyWith(
        sessions: event.sessions.where((s) => s.id != sessionId).toList(),
      ),
    );
  }

  // --- Categories ---

  /// Returns the created category, or null when the backend refused it.
  ///
  /// The id only exists once the response comes back, so the merged event is
  /// applied after [update] rather than being handed to it up front.
  Future<CategoryAdmin?> createCategory(
    EventAdmin event,
    CategoryCreate category,
  ) async {
    CategoryComplete? created;
    await update(() async {
      generatedMapping.putIfAbsent(
        CategoryComplete,
        () => CategoryComplete.fromJsonFactory,
      );
      final response = await repository.client
          .send<CategoryComplete, CategoryComplete>(
            Request(
              'POST',
              Uri.parse('/tickets/admin/events/${event.id}/categories'),
              repository.client.baseUrl,
              body: category.toCreateJson(),
            ),
          );
      if (response.isSuccessful) created = response.body;
      return response;
    }, event);

    final body = created;
    if (body == null) return null;
    final admin = body.toCategoryAdmin();
    setTicketEvent(event.copyWith(categories: [...event.categories, admin]));
    return admin;
  }

  Future<bool> updateCategory(EventAdmin event, CategoryAdmin category) async {
    return await update(
      () => repository.client.send<void, void>(
        Request(
          'PATCH',
          Uri.parse(
            '/tickets/admin/events/${event.id}/categories/${category.id}',
          ),
          repository.client.baseUrl,
          body: category.toUpdateJson(),
        ),
      ),
      event.copyWith(
        categories: [
          for (final c in event.categories) c.id == category.id ? category : c,
        ],
      ),
    );
  }

  Future<bool> deleteCategory(EventAdmin event, String categoryId) async {
    return await update(
      () => repository.ticketsAdminEventsEventIdCategoriesCategoryIdDelete(
        eventId: event.id,
        categoryId: categoryId,
      ),
      event.copyWith(
        categories: event.categories.where((c) => c.id != categoryId).toList(),
      ),
    );
  }

  // --- Questions ---

  /// Returns the created question, or null when the backend refused it.
  Future<QuestionAdmin?> createQuestion(
    EventAdmin event,
    QuestionCreate question,
  ) async {
    Question? created;
    await update(() async {
      generatedMapping.putIfAbsent(Question, () => Question.fromJsonFactory);
      final response = await repository.client.send<Question, Question>(
        Request(
          'POST',
          Uri.parse('/tickets/admin/events/${event.id}/questions'),
          repository.client.baseUrl,
          body: question.toCreateJson(),
        ),
      );
      if (response.isSuccessful) created = response.body;
      return response;
    }, event);

    final body = created;
    if (body == null) return null;
    final admin = body.toQuestionAdmin();
    setTicketEvent(event.copyWith(questions: [...event.questions, admin]));
    return admin;
  }

  Future<bool> updateQuestion(EventAdmin event, QuestionAdmin question) async {
    return await update(
      () => repository.client.send<void, void>(
        Request(
          'PATCH',
          Uri.parse(
            '/tickets/admin/events/${event.id}/questions/${question.id}',
          ),
          repository.client.baseUrl,
          body: question.toUpdateJson(),
        ),
      ),
      event.copyWith(
        questions: [
          for (final q in event.questions) q.id == question.id ? question : q,
        ],
      ),
    );
  }

  Future<bool> deleteQuestion(EventAdmin event, String questionId) async {
    return await update(
      () => repository.ticketsAdminEventsEventIdQuestionsQuestionIdDelete(
        eventId: event.id,
        questionId: questionId,
      ),
      event.copyWith(
        questions: event.questions.where((q) => q.id != questionId).toList(),
      ),
    );
  }
}

final ticketEventProvider =
    NotifierProvider<TicketEventNotifier, AsyncValue<EventAdmin>>(
      TicketEventNotifier.new,
    );

class PublicTicketEventByIdNotifier extends AsyncNotifier<EventPublic> {
  PublicTicketEventByIdNotifier(this._id);

  final String _id;

  Openapi get repository => ref.watch(repositoryProvider);

  @override
  Future<EventPublic> build() async {
    final response = await repository.ticketsEventsEventIdGet(eventId: _id);
    return response.body!;
  }
}

final publicTicketEventByIdProvider =
    AsyncNotifierProvider.family<
      PublicTicketEventByIdNotifier,
      EventPublic,
      String
    >(PublicTicketEventByIdNotifier.new);
