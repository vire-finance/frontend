import '../../../../shared/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'bank_option_tile.dart';
import '../../data/fund_sources.dart';

class SetupStepFrame extends StatelessWidget {
  const SetupStepFrame({
    required this.step,
    required this.title,
    required this.description,
    required this.content,
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.showArrow = false,
    super.key,
  });

  final int step;
  final String title;
  final String description;
  final Widget content;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String continueLabel;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;
          final panelTop = compact ? constraints.maxHeight * 0.24 : 235.0;
          final pageWidth =
              constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: pageWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: panelTop + 19,
                    child: Image.asset(
                      'assets/images/Regular Images/Soft Pattern Background.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned(
                    top: panelTop * 0.45,
                    left: 0,
                    right: 0,
                    height: compact ? 58 : 76,
                    child: Image.asset(
                      'assets/images/Regular Images/Logo - VIRE.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned.fill(
                    top: panelTop,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            compact ? 12 : 18,
                            20,
                            compact ? 12 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Step $step of 4',
                                  style: AppTextStyles.l3.semiBold.copyWith(
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 4 : 7),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.h4.bold.copyWith(
                                  color: AppColors.blue400,
                                ),
                              ),
                              SizedBox(height: compact ? 6 : 10),
                              Text(
                                description,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.p2.copyWith(
                                  color: AppColors.grey800,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 20),
                              Expanded(child: content),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: compact ? 44 : 48,
                                      child: TextButton(
                                        onPressed: onBack,
                                        style: TextButton.styleFrom(
                                          backgroundColor: AppColors.blue50,
                                          foregroundColor: AppColors.blue500,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Back',
                                          style: AppTextStyles.l2.semiBold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: compact ? 44 : 48,
                                      child: ElevatedButton(
                                        onPressed: onContinue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.blue400,
                                          foregroundColor: AppColors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              continueLabel,
                                              style: AppTextStyles.l2.semiBold
                                                  .copyWith(
                                                color: AppColors.white,
                                              ),
                                            ),
                                            if (showArrow) ...[
                                              const SizedBox(width: 7),
                                              const Icon(
                                                Icons.arrow_forward,
                                                size: 18,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PairAccountStep extends StatefulWidget {
  const PairAccountStep({
    required this.selectedSource,
    required this.onSelected,
    super.key,
  });

  final String? selectedSource;
  final ValueChanged<String> onSelected;

  @override
  State<PairAccountStep> createState() => _PairAccountStepState();
}

class _PairAccountStepState extends State<PairAccountStep> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showBanks = true;

  static const _banks = FundSources.banks;
  static const _wallets = FundSources.wallets;

  @override
  void initState() {
    super.initState();
    _showBanks = FundSources.find(widget.selectedSource ?? '')?.accountType !=
        'E_WALLET';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = (_showBanks ? _banks : _wallets)
        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: AppSearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              hint: 'Search bank or e-wallet...'),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _tab('Banks', selected: _showBanks, onTap: () {
                setState(() => _showBanks = true);
              }),
              _tab('E-Wallets', selected: !_showBanks, onTap: () {
                setState(() => _showBanks = false);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final option = options[index];
              final asset = option.logoPath;

              return BankOptionTile(
                name: option.name,
                logoPath: asset,
                icon: Icons.account_balance_wallet_outlined,
                selected: widget.selectedSource == option.name,
                onTap: () => widget.onSelected(option.name),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tab(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.blue400 : AppColors.white,
          foregroundColor: selected ? AppColors.white : AppColors.grey300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: AppTextStyles.l2.semiBold),
      ),
    );
  }
}
