import 'package:go_router/go_router.dart';

import '../../features/booking/mvp_booking_flow.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create({required bool appwriteConfigValid}) {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return MvpBookingFlow(appwriteConfigValid: appwriteConfigValid);
          },
        ),
      ],
    );
  }
}
