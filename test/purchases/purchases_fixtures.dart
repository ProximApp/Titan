import 'package:titan/generated/openapi.models.swagger.dart';

/// The scannable ticket generator every scan-flow fixture embeds in its
/// product; two files carried identical copies.
GenerateTicketComplete generator() => GenerateTicketComplete.empty().copyWith(
  id: 'gen-1',
  name: 'Soirée des clubs',
  maxUse: 10,
  expiration: DateTime(2100),
);

/// The member's own ticket. [scanLeft] and the attached [productVariant]
/// are the two axes the pages under test differ on: the ticket page shows a
/// variant-bound ticket with 9 scans left, the admin entry a nearly
/// exhausted one.
AppModulesCdrSchemasCdrTicket myTicket({
  int scanLeft = 9,
  AppModulesCdrSchemasCdrProductVariantComplete? productVariant,
}) => AppModulesCdrSchemasCdrTicket.empty().copyWith(
  id: 't-1',
  name: 'Soirée des clubs',
  scanLeft: scanLeft,
  expiration: DateTime(2100),
  productVariant: productVariant,
);
