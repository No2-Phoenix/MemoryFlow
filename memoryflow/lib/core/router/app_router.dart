import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/editor/story_creator_page_v2.dart';
import '../../features/extensions/contact_developer_page.dart';
import '../../features/extensions/feature_spotlight_page.dart';
import '../../features/home/home_page.dart';
import 'route_transitions.dart';

export 'route_transitions.dart';

class AppRoutes {
  static const String home = '/';
  static const String creator = '/creator';
  static const String map = '/map';
  static const String contactDeveloper = '/contact-developer';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: RouteTransitions.fade,
        ),
      ),
      GoRoute(
        path: AppRoutes.creator,
        name: 'creator',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: StoryCreatorPageV2(
            createNew: state.uri.queryParameters['mode'] == 'new',
          ),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: RouteTransitions.slideUp,
        ),
      ),
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FeatureSpotlightPage.map(),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: RouteTransitions.scale,
        ),
      ),
      GoRoute(
        path: AppRoutes.contactDeveloper,
        name: 'contactDeveloper',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ContactDeveloperPage(),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: RouteTransitions.slideUp,
        ),
      ),
    ],
  );
});
