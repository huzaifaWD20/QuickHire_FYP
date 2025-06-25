import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/bottom_nav_bar.dart';
import '../controllers/bottom_nav_bar_controller.dart';

// Import your actual screen widgets here
import 'jobseeker_swipe.dart';
import 'js_dashboard.dart';
import 'chat_list_screen.dart';
import 'emp_dashboard.dart';
import 'joblisting_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainWrapper extends StatefulWidget {
  static const String id = 'main_wrapper';
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final BottomNavController controller = Get.find();
  String userRole = "jobseeker"; // Default role
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_role') ?? "jobseeker";
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Different pages based on user role
    final List<Widget> jobSeekerPages = [
      const ProfileScreen(),         // Profile tab (left)
      const JsDashboard(),           // Dashboard tab (second)
      const JobSeekerSwipeScreen(),  // Jobs/Swipe screen (third)
      ChatListScreen(),              // Messages (right)
    ];

    final List<Widget> employerPages = [
      const ProfileScreen(),         // Profile tab (left)
      const EmpDashboard(),          // Dashboard tab (second)
      const JobListingScreen(),      // Job listings (third)
      ChatListScreen(),              // Messages (right)
    ];

    // Select the appropriate pages based on user role
    final List<Widget> pages = userRole == "employer" ? employerPages : jobSeekerPages;

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: pages,
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
