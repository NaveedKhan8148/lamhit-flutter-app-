import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const String _privacyPolicyUrl =
      'https://naveedkhan8148.github.io/Lamhti-Privacy-Policy/';

  static const String _termsUrl =
      'https://naveedkhan8148.github.io/Lamhti-Privacy-Policy/';

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = min(900.0, screenWidth * 0.94);

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to Lamhti App!",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Lamhti is a platform where users can upload and purchase "
                    "high-quality images. Our goal is to provide a simple, secure, "
                    "and rewarding experience for creators and buyers.",
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Our Mission",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "To empower photographers and artists by allowing them to share "
                    "their work and earn through their creativity, while also giving "
                    "buyers access to exclusive content.",
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Data We Collect",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Lamhti collects the following data to provide its services:\n"
                    "• Email address (for account creation and notifications)\n"
                    "• Photos you choose to upload for sale\n"
                    "• Payment transaction records (processed securely via Apple In-App Purchase)\n"
                    "• Device information for app functionality\n\n"
                    "We do not sell your personal data to third parties.",
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Third-Party Services",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Lamhti uses the following third-party services:\n"
                    "• Firebase (Google) — authentication and data storage\n"
                    "• Apple In-App Purchase — payment processing on iOS\n"
                    "• Stripe — payment processing on Android\n"
                    "• HuggingFace — image content moderation\n\n"
                    "Each service has its own privacy policy governing data use.",
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Contact Us",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Email: lamhti.firebase@gmail.com\nInstagram: @lamhti",
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 30.h),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 10.h),
                  _LegalTile(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    subtitle: "How we collect and use your data",
                    onTap: () => _launchUrl(context, _privacyPolicyUrl),
                  ),
                  SizedBox(height: 8.h),
                  _LegalTile(
                    icon: Icons.description_outlined,
                    title: "Terms of Service",
                    subtitle: "Rules and guidelines for using Lamhti",
                    onTap: () => _launchUrl(context, _termsUrl),
                  ),
                  SizedBox(height: 30.h),
                  Center(
                    child: Text(
                      "Lamhti v1.1.0\n© 2026 Lamhti. All rights reserved.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 24),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}