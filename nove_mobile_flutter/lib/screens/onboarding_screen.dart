import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'A Calm Workspace',
      'body': 'NOVE is designed to remove distractions. A minimal, analogue-inspired environment for your best thoughts.',
      'icon': 'drafts',
    },
    {
      'title': 'Context-Aware',
      'body': 'Link your sticky notes to other apps. Your notes automatically float into view exactly when you need them.',
      'icon': 'all_out',
    },
    {
      'title': 'Offline First. Always.',
      'body': 'Your data never leaves your device. No cloud sync, no accounts, complete privacy.',
      'icon': 'lock_outline',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'drafts': return Icons.drafts_outlined;
      case 'all_out': return Icons.all_out_rounded;
      case 'lock_outline': return Icons.lock_outline_rounded;
      default: return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoveColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  HapticFeedback.lightImpact();
                  setState(() => _currentPage = idx);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: NoveColors.cardBg(context),
                            shape: BoxShape.circle,
                            boxShadow: NoveShadows.cardElevated(context),
                          ),
                          child: Icon(
                            _getIcon(page['icon']!), 
                            size: 64, 
                            color: NoveColors.terracotta
                          ),
                        ),
                        const SizedBox(height: 64),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: NoveColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['body']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.6,
                            color: NoveColors.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: NoveAnimation.fast,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? NoveColors.terracotta 
                              : NoveColors.warmGray300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (_currentPage == _pages.length - 1) {
                        widget.onDone();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), // FIXED
                        curve: NoveAnimation.smooth,
                          
                            
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NoveColors.accent(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}