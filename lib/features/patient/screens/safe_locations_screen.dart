import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeLocationsScreen extends StatelessWidget {
  const SafeLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessibility: Large fonts, high contrast
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PLACES', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFCC00), // High contrast Yellow
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _LocationCard(
            label: 'HOME',
            icon: Icons.home,
            address: '123 Sweet Home Ave',
            color: Colors.lightGreenAccent,
          ),
          SizedBox(height: 16),
          _LocationCard(
            label: 'HOSPITAL',
            icon: Icons.local_hospital,
            address: 'City General Hospital',
            color: Colors.redAccent,
          ),
          SizedBox(height: 16),
          _LocationCard(
            label: 'PARK',
            icon: Icons.park,
            address: 'Central Park',
            color: Colors.lightBlueAccent,
          ),
          SizedBox(height: 16),
          _LocationCard(
            label: 'SHOP',
            icon: Icons.shopping_cart,
            address: 'Market Street',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String address;
  final Color color;

  const _LocationCard({
    required this.label,
    required this.icon,
    required this.address,
    required this.color,
  });

  Future<void> _openMap() async {
    // TODO: Use actual coordinates from Firestore later
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openMap,
      child: Container(
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 64, color: Colors.black87),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    label,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.directions, size: 48, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
