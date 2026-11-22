import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/my_association_list_provider.dart';
import 'package:titan/event/adapters/event_complete_ticket_url.dart';
import 'package:titan/event/ui/pages/event_pages/checkbox_entry.dart';
import 'package:titan/feed/providers/association_event_list_provider.dart';
import 'package:titan/feed/providers/event_image_provider.dart';
import 'package:titan/feed/providers/event_provider.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/feed/ui/feed.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/navigation/ui/scroll_to_hide_navbar.dart';
import 'package:titan/tickets/providers/association_tickets_provider.dart';
import 'package:titan/tickets/providers/can_manage_ticket_events_provider.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/styleguide/horizontal_multi_select.dart';
import 'package:titan/tools/ui/styleguide/text_entry.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';
import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';

class AddEditEventPage extends HookConsumerWidget {
  const AddEditEventPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final key = GlobalKey<FormState>();

    final myAssociations = ref.watch(myAssociationListProvider);
    final event = ref.watch(eventProvider);
    final eventCreationNotifier = ref.watch(eventProvider.notifier);
    final eventListNotifier = ref.watch(associationEventsListProvider.notifier);
    final eventImageNotifier = ref.watch(eventImageProvider.notifier);
    final newsListNotifier = ref.watch(newsListProvider.notifier);
    final image = ref.watch(eventImageProvider);
    final selectedAssociation = useState<Association?>(
      myAssociations.length == 1 ? myAssociations.first : null,
    );

    final ImagePicker picker = ImagePicker();

    void displayToastWithContext(TypeMsg type, String msg) {
      displayToast(context, type, msg);
    }

    final syncEvent = event.maybeWhen(
      data: (event) => event,
      orElse: () => EventCompleteTicketUrl.empty(),
    );
    final poster = useState<Uint8List?>(null);
    final posterFile = useState<Image?>(null);
    final allDay = useState(syncEvent.allDay);
    final notification = useState(
      syncEvent.id != "" ? syncEvent.notification : true,
    );
    final titleController = useTextEditingController(text: syncEvent.name);
    final locationController = useTextEditingController(
      text: syncEvent.location,
    );
    final shotgunDateController = useTextEditingController(
      text: syncEvent.ticketUrlOpening != null
          ? DateFormat.yMd(locale.toString())
                .add_Hm()
                .format(syncEvent.ticketUrlOpening!)
          : "",
    );
    final externalLinkController = useTextEditingController(
      text: syncEvent.ticketUrl,
    );

    // A ticketing this association already runs can be pointed at instead of
    // typing an external link by hand.
    final useExistingTicketEvent = useState(syncEvent.ticketEventId != null);
    final selectedTicketEventId = useState<String?>(syncEvent.ticketEventId);
    final associationTicketEventsNotifier = ref.watch(
      associationTicketEventListProvider.notifier,
    );
    final associationTicketEvents =
        ref.watch(associationTicketEventListProvider).asData?.value ??
        const <EventSimple>[];
    final associationId = syncEvent.id != ""
        ? syncEvent.associationId
        : selectedAssociation.value?.id;
    final canManageTicketEventsForAssociation = ref.watch(
      canManageTicketEventsForAssociationProvider(associationId),
    );
    useEffect(() {
      if (useExistingTicketEvent.value) {
        associationTicketEventsNotifier.loadTicketEvents(associationId);
      }
      return null;
    }, [useExistingTicketEvent.value, associationId]);
    useEffect(() {
      if (!canManageTicketEventsForAssociation &&
          syncEvent.ticketEventId == null) {
        useExistingTicketEvent.value = false;
        selectedTicketEventId.value = null;
      }
      return null;
    }, [canManageTicketEventsForAssociation, associationId]);
    final startDateController = useTextEditingController(
      text: syncEvent.id != ""
          ? (allDay.value
                ? DateFormat.yMd(locale.toString()).format(syncEvent.start)
                : DateFormat.yMd(locale.toString())
                      .add_Hm()
                      .format(syncEvent.start))
          : "",
    );
    final endDateController = useTextEditingController(
      text: syncEvent.id != ""
          ? (allDay.value
                ? DateFormat.yMd(locale.toString()).format(syncEvent.end)
                : DateFormat.yMd(locale.toString())
                      .add_Hm()
                      .format(syncEvent.end))
          : "",
    );
    image.maybeWhen(
      data: (image) => posterFile.value = image,
      orElse: () => null,
    );

    final localizeWithContext = AppLocalizations.of(context)!;
    // Edit mode names the event's association instead of offering the
    // picker. That association can be missing from THIS user's list (they
    // left the group, or a sync draft outlived it), and the bare
    // `myAssociations.firstWhere(...)` used to resolve the name threw
    // `Bad state: No element` straight out of build: an unresolvable
    // association now renders no line at all.
    final eventAssociationName = syncEvent.id == ""
        ? null
        : myAssociations
              .where((element) => element.id == syncEvent.associationId)
              .firstOrNull
              ?.name;

    return FeedTemplate(
      child: Form(
        key: key,
        child: ScrollToHideNavbar(
          controller: ScrollController(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  syncEvent.id == ""
                      ? SizedBox(
                          height: 50,
                          child: HorizontalMultiSelect<Association>(
                            items: myAssociations,
                            selectedItem: selectedAssociation.value,
                            onItemSelected: (association) {
                              selectedAssociation.value = association;
                              useExistingTicketEvent.value = false;
                              selectedTicketEventId.value = null;
                            },
                            itemBuilder:
                                (context, association, index, selected) => Text(
                                  association.name,
                                  style: TextStyle(
                                    color: selected
                                        ? ColorConstants.background
                                        : ColorConstants.tertiary,
                                    fontSize: 16,
                                  ),
                                ),
                          ),
                        )
                      : eventAssociationName == null
                      ? const SizedBox.shrink()
                      : Text(
                          localizeWithContext.feedAssociationEvent(
                            eventAssociationName,
                          ),
                        ),
                  const SizedBox(height: 10),
                  TextEntry(
                    label: localizeWithContext.feedTitle,
                    controller: titleController,
                    maxLength: 30,
                  ),
                  const SizedBox(height: 10),
                  CheckBoxEntry(
                    title: localizeWithContext.eventAllDay,
                    valueNotifier: allDay,
                    // CheckBoxEntry owns the flip and calls this to report
                    // it; flipping here too cancelled the widget's own flip.
                    onChanged: () {
                      startDateController.text = "";
                      endDateController.text = "";
                    },
                  ),

                  DateEntry(
                    onTap: () => allDay.value
                        ? getOnlyDayDate(context, startDateController)
                        : getFullDate(context, startDateController),
                    controller: startDateController,
                    label: localizeWithContext.eventStartDate,
                  ),
                  const SizedBox(height: 10),
                  DateEntry(
                    onTap: () => allDay.value
                        ? getOnlyDayDate(context, endDateController)
                        : getFullDate(context, endDateController),
                    controller: endDateController,
                    label: localizeWithContext.eventEndDate,
                  ),
                  SizedBox(height: 10),
                  TextEntry(
                    label: localizeWithContext.feedLocation,
                    controller: locationController,
                  ),
                  // An event either points at a ticketing this association
                  // already runs in the tickets module, or carries a date and
                  // a link to an external one — never both.
                  if (associationId != null) ...[
                    const SizedBox(height: 10),
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        title: Text(
                          localizeWithContext.feedUseExistingTicketing,
                          style: TextStyle(
                            fontSize: 16,
                            color: canManageTicketEventsForAssociation
                                ? null
                                : Colors.grey,
                          ),
                        ),
                        subtitle: !canManageTicketEventsForAssociation
                            ? Text(
                                localizeWithContext
                                    .feedUseExistingTicketingRequiresManageEventsPermission,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : null,
                        value: useExistingTicketEvent.value,
                        onChanged: canManageTicketEventsForAssociation
                            ? (value) => useExistingTicketEvent.value = value
                            : null,
                        activeThumbColor: ColorConstants.tertiary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (useExistingTicketEvent.value)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedTicketEventId.value,
                          decoration: InputDecoration(
                            labelText: localizeWithContext.feedSelectTicketing,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final ticketEvent in associationTicketEvents)
                              DropdownMenuItem(
                                value: ticketEvent.id,
                                child: Text(ticketEvent.name),
                              ),
                          ],
                          onChanged: canManageTicketEventsForAssociation
                              ? (value) => selectedTicketEventId.value = value
                              : null,
                        ),
                      ),
                  ],
                  if (!useExistingTicketEvent.value) ...[
                    SizedBox(height: 10),
                    DateEntry(
                      onTap: () => getFullDate(context, shotgunDateController),
                      controller: shotgunDateController,
                      label: localizeWithContext.feedSGDate,
                      canBeEmpty: true,
                    ),
                    SizedBox(height: 10),
                    TextEntry(
                      label: localizeWithContext.feedSGExternalLink,
                      controller: externalLinkController,
                      canBeEmpty: true,
                    ),
                  ],
                  const SizedBox(height: 10),
                  CheckBoxEntry(
                    title: localizeWithContext.feedNotification,
                    valueNotifier: notification,
                    onChanged: () {},
                  ),
                  const SizedBox(height: 10),
                  FormField<File>(
                    builder: (formFieldState) => Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ImagePickerOnTap(
                            picker: picker,
                            imageBytesNotifier: poster,
                            imageNotifier: posterFile,
                            displayToastWithContext: displayToastWithContext,
                            child: AspectRatio(
                              aspectRatio: 851 / 315,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: formFieldState.hasError
                                          ? Colors.red
                                          : Colors.black.withValues(alpha: 0.1),
                                      spreadRadius: 5,
                                      blurRadius: 10,
                                      offset: const Offset(2, 3),
                                    ),
                                  ],
                                ),
                                child: posterFile.value != null
                                    ? Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 851 / 315,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                      Radius.circular(5),
                                                    ),
                                                image: DecorationImage(
                                                  image: poster.value != null
                                                      ? Image.memory(
                                                          poster.value!,
                                                          fit: BoxFit.cover,
                                                        ).image
                                                      : posterFile.value!.image,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                          Radius.circular(5),
                                                        ),
                                                    color: Colors.white
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                  child: HeroIcon(
                                                    HeroIcons.photo,
                                                    size: 40,
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(5),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            const HeroIcon(
                                              HeroIcons.photo,
                                              size: 100,
                                              color: Colors.grey,
                                            ),
                                            Text("(851/315)"),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  WaitingButton(
                    child: Text(
                      syncEvent.id == ""
                          ? localizeWithContext.feedCreateEvent
                          : localizeWithContext.feedEditEvent,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    builder: (child) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstants.tertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ColorConstants.onTertiary),
                      ),
                      child: Center(child: child),
                    ),
                    onTap: () async {
                      if (key.currentState == null) {
                        return;
                      }
                      if (syncEvent.id == "" &&
                          selectedAssociation.value == null) {
                        displayToastWithContext(
                          TypeMsg.error,
                          localizeWithContext.feedPleaseSelectAnAssociation,
                        );
                        return;
                      }
                      if (!useExistingTicketEvent.value) {
                        if (externalLinkController.text.isEmpty &&
                            shotgunDateController.text.isNotEmpty) {
                          displayToastWithContext(
                            TypeMsg.error,
                            localizeWithContext
                                .feedPleaseProvideASGExternalLink,
                          );
                          return;
                        }
                        if (externalLinkController.text.isNotEmpty &&
                            shotgunDateController.text.isEmpty) {
                          displayToastWithContext(
                            TypeMsg.error,
                            localizeWithContext.feedPleaseProvideASGDate,
                          );
                          return;
                        }
                      } else if (selectedTicketEventId.value == null) {
                        displayToastWithContext(
                          TypeMsg.error,
                          localizeWithContext.feedPleaseSelectTicketing,
                        );
                        return;
                      }
                      if (key.currentState!.validate()) {
                        if (endDateController.text.contains("/") &&
                            isDateBefore(
                              processDateBackWithHourMaybe(
                                endDateController.text,
                                locale.toString(),
                              ),
                              processDateBackWithHourMaybe(
                                startDateController.text,
                                locale.toString(),
                              ),
                            )) {
                          displayToast(
                            context,
                            TypeMsg.error,
                            localizeWithContext.eventInvalidDates,
                          );
                        } else {
                          final newEvent = EventCompleteTicketUrl(
                            id: syncEvent.id,
                            start: DateTime.parse(
                              processDateBackWithHourMaybe(
                                startDateController.text,
                                locale.toString(),
                              ),
                            ),
                            end: DateTime.parse(
                              processDateBackWithHourMaybe(
                                endDateController.text,
                                locale.toString(),
                              ),
                            ),
                            location: locationController.text,
                            ticketUrlOpening:
                                useExistingTicketEvent.value ||
                                    shotgunDateController.text == ""
                                ? null
                                : DateTime.parse(
                                    processDateBackWithHourMaybe(
                                      shotgunDateController.text,
                                      locale.toString(),
                                    ),
                                  ),
                            name: titleController.text,
                            allDay: allDay.value,
                            // recurrenceRule: recurrenceRule,
                            recurrenceRule: "",
                            associationId: syncEvent.id != ""
                                ? syncEvent.associationId
                                : selectedAssociation.value!.id,
                            ticketUrl: useExistingTicketEvent.value
                                ? null
                                : externalLinkController.text,
                            ticketEventId: useExistingTicketEvent.value
                                ? selectedTicketEventId.value
                                : null,
                            notification: notification.value,
                            association:
                                selectedAssociation.value ??
                                Association.empty(),
                            decision: Decision.pending,
                          );
                          // Every success arm (update, update+poster, create,
                          // create+poster) did the same three things in the same
                          // order; they are one function so a change to the
                          // "saved" behaviour cannot drift between them.
                          void onSaved(String message) {
                            QR.back();
                            displayToastWithContext(TypeMsg.msg, message);
                            newsListNotifier.loadNewsList();
                          }

                          try {
                            if (syncEvent.id != "") {
                              final value = await eventListNotifier.updateEvent(
                                newEvent,
                              );
                              if (value) {
                                if (poster.value == null) {
                                  onSaved(
                                    localizeWithContext.eventModifiedEvent,
                                  );
                                  return;
                                }
                                final imageUploaded = await eventImageNotifier
                                    .addEventImage(syncEvent.id, poster.value!);
                                if (imageUploaded) {
                                  onSaved(
                                    localizeWithContext.eventModifiedEvent,
                                  );
                                } else {
                                  displayToastWithContext(
                                    TypeMsg.error,
                                    localizeWithContext.eventModifyingError,
                                  );
                                }
                              } else {
                                displayToastWithContext(
                                  TypeMsg.error,
                                  localizeWithContext.eventModifyingError,
                                );
                              }
                            } else {
                              final eventCreated = await eventCreationNotifier
                                  .addEvent(newEvent.toEventBaseCreation());
                              // The id is checked BEFORE the poster branch. The
                              // old order returned "Event added" and popped the
                              // page whenever no poster was attached, whether or
                              // not the server had created anything — a refused
                              // create read as a success, the user was sent back,
                              // and no event existed. That is the create failure
                              // the associations reported as "publish fails".
                              final eventCreatedId = eventCreated.maybeWhen(
                                orElse: () => "",
                                data: (event) => event.id,
                              );
                              if (eventCreatedId == "") {
                                displayToastWithContext(
                                  TypeMsg.error,
                                  localizeWithContext.eventAddingError,
                                );
                                return;
                              }
                              if (poster.value == null) {
                                onSaved(localizeWithContext.eventAddedEvent);
                                return;
                              }
                              // From here the event EXISTS on the server. A
                              // poster failure used to fall through to the
                              // generic "error while adding" and leave the form
                              // open, so the user published again and created a
                              // SECOND event — the duplicate-generating path.
                              // The event is named as saved, the IMAGE is named
                              // as the failure, and the form closes so a retry
                              // cannot duplicate it.
                              var uploaded = false;
                              try {
                                uploaded = await eventImageNotifier
                                    .addEventImage(
                                      eventCreatedId,
                                      poster.value!,
                                    );
                              } catch (_) {
                                uploaded = false;
                              }
                              if (uploaded) {
                                onSaved(localizeWithContext.eventAddedEvent);
                              } else {
                                QR.back();
                                displayToastWithContext(
                                  TypeMsg.error,
                                  localizeWithContext.othersImageError,
                                );
                                newsListNotifier.loadNewsList();
                              }
                            }
                          } catch (e) {
                            displayToastWithContext(
                              TypeMsg.error,
                              localizeWithContext.eventAddingError,
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
