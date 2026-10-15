import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/business_account.dart';
import 'business_account_data_source.dart';

/// Cuenta del administrador en la API (`GET /business/account`).
class BusinessAccountApiDataSource implements BusinessAccountDataSource {
  const BusinessAccountApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<BusinessAccount> getAccount() async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>('/business/account'),
    );
    return fromJson(response.data!);
  }

  static BusinessAccount fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>;
    final subscription = json['subscription'] as Map<String, dynamic>?;
    return BusinessAccount(
      admin: AdminProfile(
        fullName: admin['fullName'] as String? ?? '',
        email: admin['email'] as String? ?? '',
        phone: admin['phone'] as String? ?? '',
        roleLabel: admin['roleLabel'] as String? ?? '',
        verified: admin['verified'] as bool? ?? false,
      ),
      subscription: subscription == null ? null : _subscription(subscription),
    );
  }

  static Subscription _subscription(Map<String, dynamic> json) => Subscription(
    planName: json['planName'] as String,
    monthlyPrice: (json['monthlyPrice'] as num).toInt(),
    since: DateTime.parse(json['since'] as String).toLocal(),
    nextPayment: DateTime.parse(json['nextPayment'] as String).toLocal(),
    courtLimit: (json['courtLimit'] as num).toInt(),
    courtsInUse: (json['courtsInUse'] as num).toInt(),
    benefits: [
      for (final benefit in json['benefits'] as List<dynamic>? ?? const [])
        PlanBenefit(
          title: (benefit as Map<String, dynamic>)['title'] as String,
          detail: benefit['detail'] as String? ?? '',
        ),
    ],
    isActive: json['isActive'] as bool? ?? false,
    autoBilling: json['autoBilling'] as bool? ?? false,
  );
}
