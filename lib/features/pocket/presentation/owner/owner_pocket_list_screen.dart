import 'package:flutter/material.dart';

import '../../../../shared/widgets/bottom_nav_shell.dart';
import '../../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../../document/presentation/owner/owner_document_list_screen.dart';
import '../../../history/presentation/history_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../data/pocket_repository.dart';
import 'owner_card_form.dart';
import 'owner_card_detail_screen.dart';
import 'owner_card_form_screen.dart';
import 'owner_pocket_detail_screen.dart';
import 'owner_pocket_form_screen.dart';

class OwnerPocketListScreen extends StatefulWidget {
  const OwnerPocketListScreen({super.key});

  @override
  State<OwnerPocketListScreen> createState() => _OwnerPocketListScreenState();
}

class _OwnerPocketListScreenState extends State<OwnerPocketListScreen> {
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    PocketRepository.instance.load().catchError((error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = PocketRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        if (_filter > repo.pockets.length) _filter = 0;
        final cards = _filter == 0
            ? repo.cards
            : repo.cards.where((c) => c.pocketId == repo.pockets[_filter - 1].id).toList();
        return Scaffold(
        backgroundColor: const Color(0xFFF8F8FF),
        bottomNavigationBar: AppNavbar(
          items: vireNavigationItems,
          selectedIndex: 1,
          onDestinationSelected: (index) {
            if (index == 0) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const OwnerDashboardScreen(),
                ),
                (route) => false,
              );
            } else if (index == 2) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const OwnerDocumentListScreen(),
                ),
                (route) => false,
              );
            } else if (index == 3) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryScreen(),
                ),
                (route) => false,
              );
            } else if (index == 4) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const OwnerProfileScreen(),
                ),
                (route) => false,
              );
            }
          },
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Image.asset(
                'assets/images/Regular Images/Logo - V.png',
                width: 32,
                height: 32,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Pocket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const OwnerPocketFormScreen())),
                    icon: const Icon(Icons.add),
                    label: const Text('New Pocket'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (repo.pockets.isEmpty)
                const SizedBox(
                  height: 96,
                  child: Center(
                    child: Text(
                      'No pockets yet. Create a pocket to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF818181)),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final pocket in repo.pockets)
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => OwnerPocketDetailScreen(pocket: pocket),
                          )),
                          child: Container(
                            width: 216,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: vireCardThemes[pocket.themeIndex]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pocket.name, style: const TextStyle(color: Colors.white)),
                                const Spacer(),
                                Text('${repo.cardsForPocket(pocket.id).length} Cards',
                                    style: const TextStyle(color: Colors.white)),
                                Text(formatIdr(pocket.balance),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const OwnerCardFormScreen())),
                    icon: const Icon(Icons.add),
                    label: const Text('New Card'),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i <= repo.pockets.length; i++)
                    ChoiceChip(
                      label: Text(i == 0 ? 'All Cards' : repo.pockets[i - 1].name),
                      selected: _filter == i,
                      onSelected: (_) => setState(() => _filter = i),
                    ),
                ],
              ),
              if (cards.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'No cards yet. Create a pocket, then add a card.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF818181)),
                  ),
                ),
              for (final card in cards)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OwnerCardDetailScreen(card: card),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 118,
                          child: AspectRatio(
                            aspectRatio: 216 / 140,
                            child: Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: vireCardThemes[card.themeIndex]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(card.lastFour,
                                style: const TextStyle(color: Colors.white, fontSize: 20)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.name, style: const TextStyle(color: Color(0xFF3260CD), fontSize: 16)),
                              const SizedBox(height: 3),
                              Text(formatIdr(card.balance), style: const TextStyle(color: Color(0xFF818181), fontSize: 14)),
                              Text(repo.pocketById(card.pocketId)?.name ?? '', style: const TextStyle(color: Color(0xFF818181), fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF818181)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      },
    );
  }
}
