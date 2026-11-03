import 'package:titan/generated/openapi.models.swagger.dart';

/// The product variant the ticket and scan pages bind their ticket to:
/// one demo variant, with [price] and the FR/EN descriptions as the two
/// axes the flows differ on (the scan product prices its variant, the
/// ticket page carries the copy).
AppModulesCdrSchemasCdrProductVariantComplete variant({
  int? price,
  String? descriptionFr,
  String? descriptionEn,
}) => AppModulesCdrSchemasCdrProductVariantComplete.empty().copyWith(
  id: 'var-1',
  productId: 'prod-1',
  nameFr: 'Demo',
  price: price,
  descriptionFr: descriptionFr,
  descriptionEn: descriptionEn,
);

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
