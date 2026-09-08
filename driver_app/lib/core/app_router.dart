import 'package:driver_app/models/driver_model.dart';
import 'package:flutter/material.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/registration_flow.dart';
import '../widgets/main_shell.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/payout_screen.dart';
import '../screens/wallet/bank_accounts_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

class AppRouter {
  static const String auth = '/auth';
  static const String register = '/register';
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String payout = '/payout';
  static const String bankAccounts = '/bank_accounts';
  static const String onboarding = '/onboarding';
  static const String editProfile = '/edit_profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegistrationFlow());
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      case payout:
        return MaterialPageRoute(builder: (_) => const PayoutScreen());
      case bankAccounts:
        return MaterialPageRoute(builder: (_) => const BankAccountsScreen());
      case editProfile:
        final driver = settings.arguments as DriverModel;
        return MaterialPageRoute(
            builder: (_) => EditProfileScreen(driver: driver));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
