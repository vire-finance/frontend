import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pocket/presentation/owner/owner_card_form.dart';

class ChooseCardSheet extends StatelessWidget {
  const ChooseCardSheet({required this.cards, super.key});
  final List<VireCardData> cards;

  static Future<VireCardData?> show(
          BuildContext context, List<VireCardData> cards) =>
      showModalBottomSheet<VireCardData>(
        context: context,
        backgroundColor: AppColors.white,
        isScrollControlled: true,
        builder: (_) => ChooseCardSheet(cards: cards),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 18),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose Which Card to Pay With',
                    style: TextStyle(
                        color: AppColors.blue800,
                        fontSize: 17,
                        fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            if (cards.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text('No cards are connected yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey500)))
            else
              for (final card in cards)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.credit_card_outlined,
                      color: AppColors.blue500, size: 30),
                  title: Text(card.name,
                      style: const TextStyle(
                          color: AppColors.grey700,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text('Balance: IDR ${card.balance}',
                      style: const TextStyle(
                          color: AppColors.grey500, fontSize: 12)),
                  trailing: Text('•••• ${card.lastFour}',
                      style: const TextStyle(color: AppColors.grey500)),
                  onTap: () => Navigator.pop(context, card),
                ),
          ]),
        ),
      );
}
