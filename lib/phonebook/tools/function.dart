import 'package:diacritic/diacritic.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

MembershipComplete getMembershipForAssociation(
  MemberComplete member,
  AssociationComplete association,
) {
  return member.memberships.firstWhere(
    (element) =>
        element.associationId == association.id &&
        element.mandateYear == association.mandateYear,
    orElse: () => MembershipComplete.empty(),
  );
}

int getPosition(MemberComplete member, AssociationComplete association) {
  final membership = getMembershipForAssociation(member, association);
  return membership.memberOrder;
}

List<MemberComplete> sortedMembers(
  List<MemberComplete> members,
  AssociationComplete association,
) {
  return [...members]..sort(
    (a, b) =>
        getPosition(a, association).compareTo(getPosition(b, association)),
  );
}

int _byName(AssociationComplete a, AssociationComplete b) =>
    removeDiacritics(a.name)
        .toLowerCase()
        .compareTo(removeDiacritics(b.name).toLowerCase());

List<AssociationComplete> sortedAssociationByKind(
  List<AssociationComplete> associations,
  List<AssociationGroupement> groupements,
) {
  Map<String, List<AssociationComplete>> sortedByGroupement = {
    for (var groupement in groupements) groupement.id: [],
  };
  // An association whose groupement is missing from the catalog (deleted
  // server-side, or created before any groupement existed) used to take the
  // whole phonebook down on the `!` below. It goes in a bucket of its own,
  // appended after the known groupements, so the card still renders.
  final ungrouped = <AssociationComplete>[];
  for (AssociationComplete association in associations) {
    final bucket = sortedByGroupement[association.groupementId];
    if (bucket == null) {
      ungrouped.add(association);
    } else {
      bucket.add(association);
    }
  }
  for (List<AssociationComplete> list in sortedByGroupement.values) {
    list.sort(_byName);
  }
  ungrouped.sort(_byName);
  // Flatten the sorted map values into a single list, orphans last.
  return [...sortedByGroupement.values.expand((list) => list), ...ungrouped];
}
