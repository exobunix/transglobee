import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'logistics_booking/logistics_booking_screen.dart';
import 'bus_booking_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: context.theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "All Services",
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      context.theme.primaryColor.withOpacity(0.2),
                      context.theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Icon(
                        Icons.grid_view_rounded,
                        size: 150,
                        color: context.theme.primaryColor.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    "Go Anywhere",
                    "Personal & group travel",
                  ),
                  const SizedBox(height: 16),
                  _buildServiceGrid(context, [
                    _ServiceItem(
                      "Daily Ride",
                      "Cabs & Autos",
                      Icons.local_taxi,
                      Colors.blue,
                      () => Navigator.pop(
                        context,
                      ), // Go back and trigger cab mode
                    ),
                    _ServiceItem(
                      "Intercity",
                      "City to city",
                      Icons.map_outlined,
                      Colors.purple,
                      () {},
                    ),
                    _ServiceItem(
                      "Shuttle",
                      "Bus travel",
                      Icons.directions_bus,
                      Colors.deepOrange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusBookingScreen(),
                        ),
                      ),
                    ),
                    _ServiceItem(
                      "Rental",
                      "By the hour",
                      Icons.timer_outlined,
                      Colors.teal,
                      () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    "Move Anything",
                    "Logistics & shipping",
                  ),
                  const SizedBox(height: 16),
                  _buildServiceGrid(context, [
                    _ServiceItem(
                      "Logistics",
                      "Trucks & LCVs",
                      Icons.local_shipping,
                      Colors.indigo,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogisticsBookingScreen(),
                        ),
                      ),
                    ),
                    _ServiceItem(
                      "Send Packages",
                      "Instant delivery",
                      Icons.inventory_2_outlined,
                      Colors.pink,
                      () {},
                    ),
                    _ServiceItem(
                      "Bikes",
                      "Quick delivery",
                      Icons.delivery_dining,
                      Colors.amber[800]!,
                      () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    "Financial Services",
                    "Wallets & payments",
                  ),
                  const SizedBox(height: 16),
                  _buildServiceGrid(context, [
                    _ServiceItem(
                      "Wallet",
                      "Instant pay",
                      Icons.account_balance_wallet_outlined,
                      Colors.green[700]!,
                      () {},
                    ),
                    _ServiceItem(
                      "Rewards",
                      "Earn coins",
                      Icons.monetization_on_outlined,
                      Colors.amber,
                      () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildServiceGrid(BuildContext context, List<_ServiceItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.theme.dividerColor.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
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
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ServiceItem(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
