import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data Privacy Rules',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update, color: Color(0xFF0277BD), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Last Updated: November 19, 2025',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0277BD),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('1. Introduction'),
            _buildParagraph(
              'WashLens AI ("we," "us," "our," "IamxFG," "BFFKING") is committed to protecting your privacy and ensuring the security of your personal information. '
              'This privacy policy explains how we collect, use, disclose, and safeguard your information when you use our WashLens AI mobile application ("the App"). '
              'By using the App, you agree to the collection and use of information in accordance with this policy. I, Vishnu (developer behind IamxFG, BFFKING, and WashLens AI), '
              'am fully responsible for maintaining these privacy standards.',
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('2. Information We Collect'),
            _buildParagraph(
              'We collect information you provide directly to us and information we obtain automatically when you use the App.',
            ),

            _buildSubsection('2.1 Information You Provide'),
            _buildBulletPoint('Account Information: Email address, username, and profile information'),
            _buildBulletPoint('Clothing Data: Images, item details, and wash entries you create'),
            _buildBulletPoint('Device Information: Camera permissions for photo capture'),
            _buildBulletPoint('User Preferences: Notification settings and app preferences'),

            _buildSubsection('2.2 Information Collected Automatically'),
            _buildBulletPoint('Device Information: Operating system, device model, and unique identifiers'),
            _buildBulletPoint('Usage Data: App usage patterns, feature interactions, and performance metrics'),
            _buildBulletPoint('Location Data: Approximate location (only for weather-based alert features)'),
            _buildBulletPoint('Camera Permissions: Temporary access only when taking photos'),

            const SizedBox(height: 16),
            _buildSectionTitle('3. How We Use Your Information'),
            _buildParagraph(
              'We use the collected information for the following purposes:',
            ),
            _buildBulletPoint('To provide and maintain the core laundry tracking functionality'),
            _buildBulletPoint('To analyze clothing items using AI photo recognition'),
            _buildBulletPoint('To send push notifications and laundry reminders'),
            _buildBulletPoint('To improve app performance and user experience'),
            _buildBulletPoint('To personalize weather-based drying alerts'),
            _buildBulletPoint('To sync your data across devices via cloud storage'),

            const SizedBox(height: 16),
            _buildSectionTitle('4. Data Storage and Security'),
            _buildParagraph(
              'Your data security is our top priority. As Vishnu (IamxFG, BFFKING), I personally ensure:'
            ),
            _buildBulletPoint('All photos are processed locally on your device whenever possible'),
            _buildBulletPoint('Cloud storage uses end-to-end encryption (Supabase)'),
            _buildBulletPoint('Data is backed up securely to prevent loss'),
            _buildBulletPoint('Regular security audits and updates'),
            _buildBulletPoint('No selling or sharing of personal data with third parties'),

            const SizedBox(height: 16),
            _buildSectionTitle('5. Data Retention'),
            _buildParagraph(
              'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this privacy policy, unless a longer retention period is required by law.'
            ),
            _buildBulletPoint('Account data is retained while your account is active'),
            _buildBulletPoint('Wash entries are kept indefinitely unless you delete them'),
            _buildBulletPoint('Backup data is retained for 30 days after account deletion'),
            _buildBulletPoint('You can request complete data deletion at any time'),

            const SizedBox(height: 16),
            _buildSectionTitle('6. Your Rights and Choices'),
            _buildParagraph(
              'You have the following rights regarding your personal information:'
            ),
            _buildBulletPoint('Access: Request a copy of all your personal data'),
            _buildBulletPoint('Correction: Update or correct inaccurate information'),
            _buildBulletPoint('Deletion: Request complete removal of your account and data'),
            _buildBulletPoint('Portability: Export your data in a machine-readable format'),
            _buildBulletPoint('Opt-out: Disable notifications or specific features anytime'),

            const SizedBox(height: 16),
            _buildSectionTitle('7. Data Sharing and Disclosure'),
            _buildParagraph(
              'We do not sell, trade, or otherwise transfer your personal information to third parties, except in the following limited circumstances:'
            ),
            _buildBulletPoint('With your explicit consent'),
            _buildBulletPoint('To comply with legal obligations or court orders'),
            _buildBulletPoint('To protect our rights, property, or safety'),
            _buildBulletPoint('Service providers (Supabase, Firebase) under strict confidentiality'),
            _buildBulletPoint('Never shared for marketing or advertising purposes'),

            const SizedBox(height: 16),
            _buildSectionTitle('8. Children\'s Privacy'),
            _buildParagraph(
              'Our App is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. '
              'If we discover that we have collected information from a child under 13, we will delete it immediately.'
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('9. International Data Transfers'),
            _buildParagraph(
              'Your data may be stored and processed in data centers located in various countries. '
              'We ensure that such transfers comply with applicable data protection laws and maintain the same level of protection regardless of location.'
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('10. Cookies and Tracking'),
            _buildParagraph(
              'We may use cookies and similar tracking technologies solely for app functionality and performance monitoring. '
              'We do not use tracking for advertising purposes.'
            ),

            const SizedBox(height: 16),
            _buildSectionTitle('11. Changes to This Privacy Policy'),
            _buildParagraph(
              'We may update this privacy policy from time to time. We will notify you of any changes by:'
            ),
            _buildBulletPoint('Posting the new policy within the app'),
            _buildBulletPoint('Sending you an in-app notification'),
            _buildBulletPoint('Requesting acceptance of updated terms'),

            const SizedBox(height: 16),
            _buildSectionTitle('12. Contact Us'),
            _buildParagraph(
              'If you have any questions about this privacy policy or our data practices, please contact us:'
            ),
            _buildContactInfo(),

            const SizedBox(height: 16),
            _buildSectionTitle('13. Compliance and Certifications'),
            _buildParagraph(
              'This privacy policy is designed to comply with:'
            ),
            _buildBulletPoint('General Data Protection Regulation (GDPR)'),
            _buildBulletPoint('California Consumer Privacy Act (CCPA)'),
            _buildBulletPoint('App Store and Google Play Store privacy guidelines'),
            _buildBulletPoint('International privacy standards and best practices'),

            const SizedBox(height: 24),
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Developed by Vishnu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(IamxFG, BFFKING - Creator of WashLens AI)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy and data security are our top priorities.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildSubsection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF475569),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Contact Information',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'privacy@washlens.ai',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'Developer: Vishnu (IamxFG, BFFKING)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
