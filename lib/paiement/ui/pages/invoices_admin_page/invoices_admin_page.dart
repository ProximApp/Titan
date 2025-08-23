import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/paiement/class/structure.dart';
import 'package:titan/paiement/providers/invoice_list_provider.dart';
import 'package:titan/paiement/providers/structure_list_provider.dart';
import 'package:titan/paiement/ui/pages/invoices_admin_page/invoice_card.dart';
import 'package:titan/paiement/ui/paiement.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/builders/async_child.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';
import 'package:tuple/tuple.dart';

class InvoicesAdminPage extends HookConsumerWidget {
  const InvoicesAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useScrollController();
    final page = useState(1);
    final pageSize = useState(20);
    final structure = useState<Structure?>(null);
    final invoices = ref.watch(invoiceListProvider);
    final structures = ref.watch(structureListProvider);
    final invoicesNotifier = ref.read(invoiceListProvider.notifier);

    final localizeWithContext = AppLocalizations.of(context)!;

    void refreshInvoices() {
      invoicesNotifier.getInvoices(page: page.value, pageLimit: pageSize.value);
    }

    return PaymentTemplate(
      child: Refresher(
        onRefresh: () async {
          refreshInvoices();
        },
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Async2Children(
            values: Tuple2(invoices, structures),
            builder: (context, invoices, structures) {
              return Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: HeroIcon(HeroIcons.arrowLeft),
                        onPressed: page.value <= 1
                            ? null
                            : () {
                                page.value--;
                                refreshInvoices();
                              },
                        color: ColorConstants.onTertiary,
                        disabledColor: ColorConstants.background,
                      ),
                      DropdownButton<int>(
                        items: [1, 20, 50, 100]
                            .map(
                              (size) => DropdownMenuItem<int>(
                                value: size,
                                child: Text(size.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            pageSize.value = value;
                            refreshInvoices();
                          }
                        },
                        value: pageSize.value,
                      ),
                      IconButton(
                        icon: HeroIcon(HeroIcons.arrowRight),
                        onPressed: invoices.length < pageSize.value
                            ? null
                            : () {
                                page.value++;
                                refreshInvoices();
                              },
                        color: ColorConstants.onTertiary,
                        disabledColor: ColorConstants.background,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListItem(
                    title: localizeWithContext.paiementCreateInvoice,
                    onTap: () => showCustomBottomModal(
                      context: context,
                      modal: BottomModalTemplate(
                        title: localizeWithContext.paiementCreateInvoice,
                        child: Column(
                          children: [
                            DropdownButton<Structure>(
                              value: structure.value,
                              items: structures
                                  .map(
                                    (structure) => DropdownMenuItem(
                                      value: structure,
                                      child: Text(structure.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (selected) =>
                                  structure.value = selected,
                              // value: structure,
                            ),
                            Button(
                              text: localizeWithContext.paiementCreate,
                              onPressed: () {
                                if (structure.value == null) return;
                                invoicesNotifier.createInvoice(
                                  structure.value!,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      ref: ref,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...invoices.map(
                    (invoice) => InvoiceCard(invoice: invoice, isAdmin: true),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
