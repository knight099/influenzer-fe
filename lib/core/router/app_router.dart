import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/social_link_screen.dart';
import '../../features/auth/presentation/callback_screen.dart';
import '../../features/brand/presentation/brand_dashboard_screen.dart';
import '../../features/brand/presentation/create_campaign_screen.dart';
import '../../features/creator/presentation/creator_dashboard_screen.dart';
import '../../features/creator/presentation/submit_proposal_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/wallet/presentation/payment_screen.dart';
import '../../features/wallet/presentation/transaction_history_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/social-link',
        builder: (context, state) => const SocialLinkScreen(),
      ),
      GoRoute(
        path: '/brand-dashboard',
        builder: (context, state) => const BrandDashboardScreen(),
      ),
      GoRoute(
        path: '/create-campaign',
        builder: (context, state) => const CreateCampaignScreen(),
      ),
      GoRoute(
        path: '/creator-dashboard',
        builder: (context, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: '/submit-proposal',
        builder: (context, state) => const SubmitProposalScreen(),
      ),
      GoRoute(
        path: '/chat-room',
        builder: (context, state) => const ChatRoomScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) => CallbackScreen(queryParams: state.uri.queryParameters),
      ),
    ],
  );
}
