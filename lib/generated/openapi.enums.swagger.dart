// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

enum AccountType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('student')
  student('student'),
  @JsonValue('former_student')
  formerStudent('former_student'),
  @JsonValue('staff')
  staff('staff'),
  @JsonValue('association')
  association('association'),
  @JsonValue('external')
  $external('external'),
  @JsonValue('other_school_student')
  otherSchoolStudent('other_school_student'),
  @JsonValue('demo')
  demo('demo');

  final String? value;

  const AccountType(this.value);
}

enum ActivationFormField {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('nickname')
  nickname('nickname'),
  @JsonValue('birthdate')
  birthdate('birthdate'),
  @JsonValue('phone')
  phone('phone'),
  @JsonValue('promotion')
  promotion('promotion'),
  @JsonValue('floor')
  floor('floor');

  final String? value;

  const ActivationFormField(this.value);
}

enum AmapSlotType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('midi')
  midi('midi'),
  @JsonValue('soir')
  soir('soir');

  final String? value;

  const AmapSlotType(this.value);
}

enum CdrStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('pending')
  pending('pending'),
  @JsonValue('online')
  online('online'),
  @JsonValue('onsite')
  onsite('onsite'),
  @JsonValue('closed')
  closed('closed');

  final String? value;

  const CdrStatus(this.value);
}

enum Decision {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('approved')
  approved('approved'),
  @JsonValue('declined')
  declined('declined'),
  @JsonValue('pending')
  pending('pending');

  final String? value;

  const Decision(this.value);
}

enum DeliveryStatusType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('creation')
  creation('creation'),
  @JsonValue('orderable')
  orderable('orderable'),
  @JsonValue('locked')
  locked('locked'),
  @JsonValue('delivered')
  delivered('delivered'),
  @JsonValue('archived')
  archived('archived');

  final String? value;

  const DeliveryStatusType(this.value);
}

enum Difficulty {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('discovery')
  discovery('discovery'),
  @JsonValue('sports')
  sports('sports'),
  @JsonValue('expert')
  expert('expert');

  final String? value;

  const Difficulty(this.value);
}

enum DocumentSignatureType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('material')
  material('material'),
  @JsonValue('numeric')
  numeric('numeric');

  final String? value;

  const DocumentSignatureType(this.value);
}

enum DocumentType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('idCard')
  idcard('idCard'),
  @JsonValue('medicalCertificate')
  medicalcertificate('medicalCertificate'),
  @JsonValue('studentCard')
  studentcard('studentCard'),
  @JsonValue('raidRules')
  raidrules('raidRules'),
  @JsonValue('parentAuthorization')
  parentauthorization('parentAuthorization');

  final String? value;

  const DocumentType(this.value);
}

enum DocumentValidation {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('pending')
  pending('pending'),
  @JsonValue('accepted')
  accepted('accepted'),
  @JsonValue('refused')
  refused('refused'),
  @JsonValue('temporary')
  temporary('temporary');

  final String? value;

  const DocumentValidation(this.value);
}

enum HistoryType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('transfer')
  transfer('transfer'),
  @JsonValue('received')
  received('received'),
  @JsonValue('given')
  given('given'),
  @JsonValue('refund_credited')
  refundCredited('refund_credited'),
  @JsonValue('refund_debited')
  refundDebited('refund_debited');

  final String? value;

  const HistoryType(this.value);
}

enum ListType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Serio')
  serio('Serio'),
  @JsonValue('Pipo')
  pipo('Pipo'),
  @JsonValue('Blank')
  blank('Blank');

  final String? value;

  const ListType(this.value);
}

enum MeetingPlace {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('centrale')
  centrale('centrale'),
  @JsonValue('bellecour')
  bellecour('bellecour'),
  @JsonValue('anyway')
  anyway('anyway');

  final String? value;

  const MeetingPlace(this.value);
}

enum NewsStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('waiting_approval')
  waitingApproval('waiting_approval'),
  @JsonValue('rejected')
  rejected('rejected'),
  @JsonValue('published')
  published('published');

  final String? value;

  const NewsStatus(this.value);
}

enum PaymentType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('cash')
  cash('cash'),
  @JsonValue('check')
  check('check'),
  @JsonValue('HelloAsso')
  helloasso('HelloAsso'),
  @JsonValue('card')
  card('card'),
  @JsonValue('archived')
  archived('archived');

  final String? value;

  const PaymentType(this.value);
}

enum PlantState {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('en attente')
  enAttente('en attente'),
  @JsonValue('récupérée')
  rCupRE('récupérée'),
  @JsonValue('consommée')
  consommE('consommée');

  final String? value;

  const PlantState(this.value);
}

enum PropagationMethod {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('bouture')
  bouture('bouture'),
  @JsonValue('graine')
  graine('graine');

  final String? value;

  const PropagationMethod(this.value);
}

enum RaffleStatusType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('creation')
  creation('creation'),
  @JsonValue('open')
  open('open'),
  @JsonValue('lock')
  lock('lock');

  final String? value;

  const RaffleStatusType(this.value);
}

enum Size {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('XS')
  xs('XS'),
  @JsonValue('S')
  s('S'),
  @JsonValue('M')
  m('M'),
  @JsonValue('L')
  l('L'),
  @JsonValue('XL')
  xl('XL'),
  @JsonValue('None')
  none('None');

  final String? value;

  const Size(this.value);
}

enum SpeciesType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('Plantes aromatiques')
  plantesAromatiques('Plantes aromatiques'),
  @JsonValue('Plantes potagères')
  plantesPotagRes('Plantes potagères'),
  @JsonValue('Plante d intérieur')
  planteDIntRieur('Plante d intérieur'),
  @JsonValue('Plantes fruitières')
  plantesFruitiRes('Plantes fruitières'),
  @JsonValue('Cactus et succulentes')
  cactusEtSucculentes('Cactus et succulentes'),
  @JsonValue('Plantes ornementales')
  plantesOrnementales('Plantes ornementales'),
  @JsonValue('Plantes grasses')
  plantesGrasses('Plantes grasses'),
  @JsonValue('Autre')
  autre('Autre');

  final String? value;

  const SpeciesType(this.value);
}

enum StatusType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('waiting')
  waiting('waiting'),
  @JsonValue('open')
  open('open'),
  @JsonValue('closed')
  closed('closed'),
  @JsonValue('counting')
  counting('counting'),
  @JsonValue('published')
  published('published');

  final String? value;

  const StatusType(this.value);
}

enum TokenResponseTokenType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('bearer')
  bearer('bearer');

  final String? value;

  const TokenResponseTokenType(this.value);
}

enum TransactionStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('confirmed')
  confirmed('confirmed'),
  @JsonValue('canceled')
  canceled('canceled'),
  @JsonValue('refunded')
  refunded('refunded'),
  @JsonValue('pending')
  pending('pending');

  final String? value;

  const TransactionStatus(this.value);
}

enum TransactionType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('direct')
  direct('direct'),
  @JsonValue('request')
  request('request'),
  @JsonValue('refund')
  refund('refund');

  final String? value;

  const TransactionType(this.value);
}

enum TransferType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('hello_asso')
  helloAsso('hello_asso');

  final String? value;

  const TransferType(this.value);
}

enum WalletDeviceStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('inactive')
  inactive('inactive'),
  @JsonValue('active')
  active('active'),
  @JsonValue('revoked')
  revoked('revoked');

  final String? value;

  const WalletDeviceStatus(this.value);
}

enum WalletType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('user')
  user('user'),
  @JsonValue('store')
  store('store');

  final String? value;

  const WalletType(this.value);
}
