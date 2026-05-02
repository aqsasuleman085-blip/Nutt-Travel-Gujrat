import 'package:flutter/material.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/providers/notification_provider.dart';
import 'package:nutt/admin_side/screens/notification/notification_screen.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/loading_widget.dart';
import 'booking/booking_screen.dart';
import 'buses/buses_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const BusesScreen(),
    const BookingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Buses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<DashboardProvider>(context, listen: false).refreshMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (Provider.of<NotificationProvider>(context).unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        Provider.of<NotificationProvider>(
                          context,
                        ).unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              authProvider.admin.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: dashboardProvider.isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : RefreshIndicator(
              onRefresh: () async {
                dashboardProvider.refreshMetrics();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.darkGreen,
                      ),
                    ),
                    Text(
                      authProvider.admin.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          DashboardCard(
                            title: 'Total Users',
                            value: dashboardProvider.totalUsers.toString(),
                            icon: Icons.people,
                            iconColor: Colors.blue,
                          ),
                          DashboardCard(
                            title: 'Total Earnings',
                            value:
                                'Rs. ${dashboardProvider.totalEarnings.toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            iconColor: Colors.green,
                          ),
                          DashboardCard(
                            title: 'Total Buses',
                            value: dashboardProvider.totalBuses.toString(),
                            icon: Icons.directions_bus,
                            iconColor: Colors.orange,
                          ),
                          DashboardCard(
                            title: 'Approved Bookings',
                            value: dashboardProvider.approvedBookingsCount.toString(),
                            icon: Icons.book_online,
                            iconColor: Colors.purple,
                          ),
                          DashboardCard(
                            title: 'Pending Requests',
                            value: bookingProvider.pendingBookings.length.toString(),
                            icon: Icons.pending_actions,
                            iconColor: Colors.orange,
                          ),
                          DashboardCard(
                            title: 'Total Bookings',
                            value: dashboardProvider.totalBookings.toString(),
                            icon: Icons.receipt_long,
                            iconColor: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
