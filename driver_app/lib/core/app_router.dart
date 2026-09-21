import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/registration_flow.dart';
import '../widgets/main_shell.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/payout_screen.dart';
import '../screens/wallet/bank_accounts_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/about_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/support_screen.dart';

class AppRouter {
  static const String auth = '/auth';
  static const String register = '/register';
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String payout = '/payout';
  static const String bankAccounts = '/bank_accounts';
  static const String onboarding = '/onboarding';
  static const String editProfile = '/edit_profile';
  static const String about = '/about';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String support = '/support';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(settings: settings, builder: (_) => const OnboardingScreen());
      case auth:
        return MaterialPageRoute(settings: settings, builder: (_) => const AuthScreen());
      case register:
        return MaterialPageRoute(settings: settings, builder: (_) => const RegistrationFlow());
      case home:
        return MaterialPageRoute(settings: settings, builder: (_) => const MainShell());
      case wallet:
        return MaterialPageRoute(settings: settings, builder: (_) => const WalletScreen());
      case payout:
        return MaterialPageRoute(settings: settings, builder: (_) => const PayoutScreen());
      case bankAccounts:
        return MaterialPageRoute(settings: settings, builder: (_) => const BankAccountsScreen());
      case editProfile:
        final driver = settings.arguments as DriverModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EditProfileScreen(driver: driver),
        );
      case about:
        return MaterialPageRoute(settings: settings, builder: (_) => const DriverAboutScreen());
      case terms:
        return MaterialPageRoute(settings: settings, builder: (_) => const DriverTermsScreen());
      case privacy:
        return MaterialPageRoute(settings: settings, builder: (_) => const DriverPrivacyPolicyScreen());
      case support:
        return MaterialPageRoute(settings: settings, builder: (_) => const DriverSupportScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
