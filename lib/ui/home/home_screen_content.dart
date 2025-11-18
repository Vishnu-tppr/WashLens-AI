import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';

/// Home Screen Content Widget
/// This is the same content from the original HomeScreen but extracted as a reusable widget
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  List<Map<String, dynamic>> _washEntries = [];
  bool _isLoadingEntries = true;

  @override
  void initState() {
    super.initState();
    _loadWashEntries();
  }

  Future<void> _loadWashEntries() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      final entries = await SupabaseService.getWashEntries(userProvider.currentUser!.id);
      if (mounted) {
        setState(() {
          _washEntries = entries;
          _isLoadingEntries = false;
        });
      }
    } else {
      setState(() => _isLoadingEntries = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC), // kBackgroundLight
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(),
              SizedBox(height: 24),
              _ReturnDueCard(),
              SizedBox(height: 24),
              _NewWashButton(),
              SizedBox(height: 24),
              _FeatureCards(),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. Header Section
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final userName = userProvider.userName;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFC7E6FF), // Light blue background
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Greeting Text
                Text(
                  "Hi, $userName",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(width: 4),
                // Hand Wave Emoji
                const Text(
                  "👋",
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
            // Notification Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }
}

// 2. Return Due Card
class _ReturnDueCard extends StatelessWidget {
  const _ReturnDueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22), // kBorderRadiusXl
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next Return & Missing Item Warning
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Next Return",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Color(0xFFDC2626), // missingItemRed
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "1 item missing!",
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Return Due Today
          Text(
            "Return Due Today",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          ),
          const SizedBox(height: 20),

          // Timer Countdown
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimerSegment(value: '00', label: 'Days'),
              _TimerSeparator(),
              _TimerSegment(value: '08', label: 'Hours'),
              _TimerSeparator(),
              _TimerSegment(value: '45', label: 'Minutes'),
            ],
          ),
          const SizedBox(height: 25),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/return-summary'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A6FFF), // kPrimary
                    side: const BorderSide(color: Color(0xFF4A6FFF), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Report Missing",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/return-summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6FFF), // kPrimary
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4, // Subtle elevation for the primary button
                  ),
                  child: const Text(
                    "Mark Returned",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Timer sub-widget
class _TimerSegment extends StatelessWidget {
  final String value;
  final String label;

  const _TimerSegment({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 32,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// Timer separator sub-widget (the dots)
class _TimerSeparator extends StatelessWidget {
  const _TimerSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        ":",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black26,
        ),
      ),
    );
  }
}

// 3. New Wash Button (Large Blue)
class _NewWashButton extends StatelessWidget {
  const _NewWashButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5773ff), // secondaryBlue
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          shadowColor: const Color(0xFF4A6FFF).withOpacity(0.5), // primaryBlue
          padding: EdgeInsets.zero,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              "New Wash",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Feature Cards
class _FeatureCards extends StatelessWidget {
  const _FeatureCards();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.history,
            iconColor: Colors.green,
            title: "Recent Activity",
            subtitle: "Anil Dhobi - 32 items",
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _FeatureCard(
            icon: Icons.auto_awesome,
            iconColor: Colors.amber,
            title: "Loss Prediction",
            subtitle: "Pro Feature",
          ),
        ),
      ],
    );
  }
}

// Feature Card sub-widget
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Use kBorderRadiusXl for consistency
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
