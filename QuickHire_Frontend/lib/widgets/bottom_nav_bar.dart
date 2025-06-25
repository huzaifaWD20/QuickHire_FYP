// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bottom_nav_bar_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final BottomNavController controller = Get.find();
  String userRole = "jobseeker"; // Default role

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_role') ?? "jobseeker";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: controller.selectedIndex.value,
        onTap: controller.changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: [
          // Profile/Dashboard item (left)
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          // Dashboard tab (NEW)
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // Jobs item (middle) - changes based on user role
          userRole == "employer"
              ? const BottomNavigationBarItem(
                  icon: Icon(Icons.business_center),
                  label: 'Projects',
                )
              : const BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: 'Jobs',
                ),
          // Messages item (right)
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}
