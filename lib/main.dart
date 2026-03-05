import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // REQUIRED IMPORT
import 'package:firebase_auth/firebase_auth.dart';

import 'ViewModel/pet_profile_view_model.dart';
import 'package:fyp_project/View/change_password_view.dart';
import 'View/home_view.dart';
import 'View/login_view.dart';
import 'View/register_view.dart';
import 'theme/app_theme.dart';
import 'View/admin_login_view.dart';
import 'View/admin_dashboard_view.dart';
import 'View/calendar_view.dart';
import 'View/notification_detail_view.dart';
import 'View/manage_accounts_view.dart';
import 'View/admin_feedback_list_view.dart';
import 'View/admin_feedback_detail_view.dart';
import 'View/analysis_record_list_view.dart';
import 'View/analysis_record_detail_view.dart';
import 'View/manage_faq_view.dart';
import 'View/admin_account_detail_view.dart';
import 'View/admin_manage_community_tips_view.dart';
import 'services/notification_service.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- UPDATE THIS MAIN FUNCTION ---
void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Initialize Notification Service
  await NotificationService().initialize(navigatorKey);

  // 4. Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PetProfileViewModel(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'PetCare Auth',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return const HomeView();
            }
            return const LoginView();
          },
        ),
        routes: {
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/home': (context) => const HomeView(),
          '/admin_login': (context) => const AdminLoginView(),
          '/admin_dashboard': (context) => const AdminDashboardView(),
          '/calendar': (context) => const CalendarView(),
          '/notification_detail': (context) => const NotificationDetailView(),
          '/manage_accounts': (context) => const ManageAccountsView(),
          '/admin/account-detail': (context) => const AdminAccountDetailView(),
          '/admin_feedback_list': (context) => const AdminFeedbackListView(),
          '/admin_feedback_detail': (context) =>
              const AdminFeedbackDetailView(),
          '/analysis_records': (context) => const AnalysisRecordListView(),
          '/analysis_record_detail': (context) =>
              const AnalysisRecordDetailView(),
          '/manage_faq': (context) => const ManageFAQView(),
          '/manage_community_tips': (context) =>
              const AdminManageCommunityTipsView(),
          '/change_password': (context) => const ChangePasswordView(),
        },
      ),
    );
  }
}
