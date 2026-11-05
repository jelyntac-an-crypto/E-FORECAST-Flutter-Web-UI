import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

/// Navbar: logo, Home / Features / How It Works / About, Login, Get Started.
/// Collapses to a menu on narrow screens.
class LandingNavbar extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onFeaturesTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onAboutTap;

  const LandingNavbar({
    super.key,
    required this.onHomeTap,
    required this.onFeaturesTap,
    required this.onHowItWorksTap,
    required this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LandingColors.background.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: LandingColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 820;
                  final isCompact = constraints.maxWidth < 300;
                  return isDesktop
                      ? _desktop(context)
                      : _mobile(context, isCompact);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktop(BuildContext context) {
    return Row(
      children: [
        const LandingLogo(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _link('Home', onHomeTap),
              _link('Features', onFeaturesTap),
              _link('How It Works', onHowItWorksTap),
              _link('About', onAboutTap),
            ],
          ),
        ),
        TextButton(
          onPressed: () => openLogin(context, tab: 0),
          style: TextButton.styleFrom(
            foregroundColor: LandingColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'Login',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        LandingPrimaryButton(
          label: 'Get Started',
          large: false,
          onPressed: () => openLogin(context, tab: 1),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context, bool isCompact) {
    return Row(
      children: [
        const Flexible(child: LandingLogo()),
        const Spacer(),
        if (!isCompact) ...[
          LandingPrimaryButton(
            label: 'Get Started',
            large: false,
            onPressed: () => openLogin(context, tab: 1),
          ),
          const SizedBox(width: 4),
        ],
        _menu(context),
      ],
    );
  }

  Widget _link(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: LandingColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: Icon(
        Icons.menu_rounded,
        color: LandingColors.textPrimary,
        size: 24,
      ),
      offset: const Offset(0, 44),
      onSelected: (value) {
        switch (value) {
          case 'home':
            onHomeTap();
          case 'features':
            onFeaturesTap();
          case 'how':
            onHowItWorksTap();
          case 'about':
            onAboutTap();
          case 'login':
            openLogin(context, tab: 0);
          case 'start':
            openLogin(context, tab: 1);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'home', child: _MenuLabel('Home')),
        const PopupMenuItem(value: 'features', child: _MenuLabel('Features')),
        const PopupMenuItem(value: 'how', child: _MenuLabel('How It Works')),
        const PopupMenuItem(value: 'about', child: _MenuLabel('About')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'login', child: _MenuLabel('Login')),
        const PopupMenuItem(
          value: 'start',
          child: _MenuLabel('Get Started', accent: true),
        ),
      ],
    );
  }
}

class _MenuLabel extends StatelessWidget {
  final String text;
  final bool accent;
  const _MenuLabel(this.text, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: accent ? LandingColors.primary : LandingColors.textPrimary,
        fontSize: 14,
        fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
