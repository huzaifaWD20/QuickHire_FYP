import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickhire/screens/chat_screen.dart';
import '../screens/joblisting_screen.dart';
import 'controllers/bottom_nav_bar_controller.dart';
import 'screens/main_wrapper.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/decision_screen.dart';
import 'screens/emp_signup.dart';
import 'screens/forgot_password.dart';
import 'screens/js_dashboard.dart';
import 'screens/js_signup.dart';
import 'screens/lets_start.dart';
import 'screens/login.dart';
import 'screens/verify_otp.dart';
import 'screens/emp_dashboard.dart';
import 'screens/Meeting_Scheduling_Screen.dart';
import 'screens/create_jobListing_screen.dart';
import 'screens/jobseeker_swipe.dart';
import 'screens/chat_list_screen.dart';
import 'controllers/chat_controller.dart';
import 'services/service_chat.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/view_js_profile_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    null, // Replace null with an app icon if needed for notification
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
  );

  // Request notification permissions
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // Request permissions
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  // Initialize controllers
  Get.put(BottomNavController());

  // Initialize ChatService immediately
  final chatService = ChatService();
  Get.put(chatService);
  await chatService.init();
  
  // Initialize ChatController
  Get.put(ChatController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickHire',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: Login.id,
      routes: {
        Login.id: (context) => const Login(),
        LetsStart.id: (context) => const LetsStart(),
        DecisionScreen.id: (context) => const DecisionScreen(),
        ProfileScreen.id: (context) => const ProfileScreen(),
        EditProfileScreen.id: (context) => const EditProfileScreen(),
        JsSignup.id: (context) => const JsSignup(),
        JsDashboard.id: (context) => const JsDashboard(),
        EmpSignup.id: (context) => const EmpSignup(),
        EmpDashboard.id: (context) => const EmpDashboard(),
        ForgotPassword.id: (context) => const ForgotPassword(),
        VerifyOtp.id: (context) => const VerifyOtp(),
        Meeting_Scheduling_Screen.id: (context) => const Meeting_Scheduling_Screen(),
        CreateJobListingScreen.id: (context) => const CreateJobListingScreen(),
        JobSeekerSwipeScreen.id: (context) => const JobSeekerSwipeScreen(),
        EmployerApplicationsOverviewScreen.id: (context) => const EmployerApplicationsOverviewScreen(),
        JobSeekerProfileScreen.id: (context) => const JobSeekerProfileScreen(userId: ''),
        ChatListScreen.id: (context) => ChatListScreen(),
        JobListingScreen.id: (context) => const JobListingScreen(),
        ChatScreen.id: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatScreen(
            conversationId: args['conversationId'],
            roomName: args['roomName'],
            otherUserId: args['otherUserId'],
            projectId: args['projectId'],
            yourUserId: args['yourUserId'],
          );
        },
        '/main': (context) => const MainWrapper(),
      },
    );
  }
}
