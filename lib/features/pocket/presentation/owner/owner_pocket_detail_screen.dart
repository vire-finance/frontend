import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/export_service.dart';
import '../../data/pocket_repository.dart';
import 'owner_card_detail_screen.dart';
import 'owner_card_form.dart';
import 'owner_card_form_screen.dart';

class OwnerPocketDetailScreen extends StatelessWidget {
  const OwnerPocketDetailScreen({required this.pocket, super.key});

  final VirePocketData pocket;

  @override
  Widget build(BuildContext context) {
    final repository = PocketRepository.instance;
    final cards = repository.cardsForPocket(pocket.id);
    final colors = vireCardThemes[pocket.themeIndex % vireCardThemes.length];
    final used = pocket.limit <= 0
        ? 0.0
        : (pocket.balance / pocket.limit).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8FF),
        foregroundColor: const Color(0xFF18346F),
        elevation: 0,
        centerTitle: true,
        title: const Text('Pocket Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colors.last, const Color(0xFF47CBE6)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(pocket.name, style: const TextStyle(color: Color(0xFF333333), fontSize: 23, fontWeight: FontWeight.w600))),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          tooltip: 'Pocket settings',
                          onPressed: () => _showPocketInfo(context),
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF444444), size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(formatIdr(pocket.balance), style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly limit', style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text(formatIdr(pocket.limit), style: const TextStyle(color: Color(0xFF18346F), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: used, minHeight: 14, backgroundColor: const Color(0xFFEAEAEA), valueColor: const AlwaysStoppedAnimation(Color(0xFF39BF4A))),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _PocketAction(label: 'See Analysis', onTap: () => _showAnalysis(context, pocket))),
                      const SizedBox(width: 12),
                      Expanded(child: _PocketAction(label: 'Download Report', onTap: () => _downloadReport(context, pocket))),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Card in This Pocket', style: TextStyle(color: Color(0xFF18346F), fontSize: 17, fontWeight: FontWeight.w700)),
                  OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerCardFormScreen(pocketId: pocket.id))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Card', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2453C5), side: const BorderSide(color: Color(0xFF2453C5))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? const Center(child: Text('No cards in this pocket yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        final cardColors = vireCardThemes[card.themeIndex % vireCardThemes.length];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerCardDetailScreen(card: card))),
                          child: Row(
                            children: [
                              Container(
                                width: 132,
                                height: 144,
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(gradient: LinearGradient(colors: cardColors), borderRadius: BorderRadius.circular(12)),
                                child: Text(card.lastFour, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.name, style: const TextStyle(color: Color(0xFF3260CD), fontSize: 17, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(formatIdr(card.balance), style: const TextStyle(color: Color(0xFF18346F), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 14),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Monthly limit', style: TextStyle(fontSize: 11)), Text(formatIdr(card.limit), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
                                    const SizedBox(height: 6),
                                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: card.limit <= 0 ? 0 : (card.balance / card.limit).clamp(0.0, 1.0).toDouble(), minHeight: 12, backgroundColor: const Color(0xFFEAEAEA), valueColor: const AlwaysStoppedAnimation(Color(0xFF39BF4A)))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPocketInfo(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Text('${pocket.name}\nAvailable balance: ${formatIdr(pocket.balance)}'))),
      );

  void _showMessage(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _showAnalysis(BuildContext context, VirePocketData pocket) async {
    try {
      final result = await PocketRepository.instance.pocketAnalysis(pocket.id);
      if (!context.mounted) return;
      final monthly = result['monthly_spending'] as List<dynamic>? ?? const [];
      final cards = result['spending_by_card'] as List<dynamic>? ?? const [];
      final counts = result['transaction_status_counts'] as Map? ?? const {};
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: Text('${pocket.name} Analysis'),
        content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: [
          const Text('Monthly spending', style: TextStyle(fontWeight: FontWeight.w700)),
          if (monthly.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No transactions recorded yet.')),
          for (final item in monthly) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('${item['month']}'), trailing: Text(formatIdr(item['amount'] is num ? (item['amount'] as num).round() : 0))),
          const Divider(),
          Text('Transactions: ${counts.values.fold<int>(0, (sum, value) => sum + (value is num ? value.toInt() : 0))}'),
          Text('Cards with spending: ${cards.length}'),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
    } catch (error) {
      if (context.mounted) _showMessage(context, apiErrorMessage(error));
    }
  }

  Future<void> _downloadReport(BuildContext context, VirePocketData pocket) async {
    try {
      await ExportService.instance.shareBackendFile('/pockets/${pocket.id}/report.csv', fileName: 'pocket-${pocket.id}.csv');
    } catch (error) {
      if (context.mounted) _showMessage(context, apiErrorMessage(error));
    }
  }
}

class _PocketAction extends StatelessWidget {
  const _PocketAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.9), foregroundColor: const Color(0xFF3260CD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      );
}
