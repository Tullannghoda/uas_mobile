import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/user_model.dart';

class UserManagementState {
  final List<UserModel> helpdesks;
  final bool isLoading;
  final String? error;

  const UserManagementState({
    this.helpdesks = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<UserModel>? helpdesks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return UserManagementState(
      helpdesks: helpdesks ?? this.helpdesks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final Ref _ref;

  UserManagementNotifier(this._ref) : super(const UserManagementState());

  Future<void> loadHelpdesks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final list = await repo.getHelpdeskList();
      state = state.copyWith(helpdesks: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createHelpdesk({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.createHelpdeskAccount(
          name: name, email: email, password: password);
      await loadHelpdesks();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteHelpdesk(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.deleteUser(id);
      await loadHelpdesks();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier(ref);
});
