import 'package:equatable/equatable.dart';

import 'user_role.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final UserRole role;

  @override
  List<Object?> get props => [id, displayName, role];
}
