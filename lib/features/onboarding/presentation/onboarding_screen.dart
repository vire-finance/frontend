import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/login_screen.dart';
import '../presentation/widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    this.onFinished,
    super.key,
  });

  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      imagePath:
          'assets/images/Regular Images/Onboarding - Split 1.png',
      title: 'Track business expenses seamlessly',
      description:
          'Monitor everyday operational costs in real-time. Owners get full financial visibility, while employees can easily request and record card balances without the paperwork hassle.',
    ),
    OnboardingSlide(
      imagePath:
          'assets/images/Regular Images/Onboarding - Split 2.png',
      title: 'Smart funding at your fingertips',
      description:
          'Connect your main fund account securely. Owners can instantly allocate balances to team wallets, letting employees make secure business transactions anytime, anywhere.',
    ),
    OnboardingSlide(
      imagePath: 'assets/images/Regular Images/Onboarding Full.png',
      title: 'Grow your business together',
      description:
          'Say goodbye to manual reimbursement. Connect owners and teams in one synchronized workspace to keep your business moving faster and smarter.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => const LoginScreen(),
    ),
  );
}

  void _continue() {
    if (_currentPage < _slides.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    if (_currentPage < _slides.length - 1) {
      _goToPage(_slides.length - 1);
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.basicWhite,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _slides.length,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        itemBuilder: (context, index) {
          return OnboardingPage(
            slide: _slides[index],
            pageIndex: index,
            pageCount: _slides.length,
            onBack: () => _goToPage(index - 1),
            onSkip: _skip,
            onContinue: _continue,
          );
        },
      ),
    );
  }
}