import 'package:flutter/material.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/theme/app_colors.dart';

/// Ícono y color de acento de cada deporte.
extension SportStyle on Sport {
  IconData get icon => switch (this) {
    Sport.futbol => Icons.sports_soccer,
    Sport.padel => Icons.sports_tennis,
    Sport.baloncesto => Icons.sports_basketball,
    Sport.voleibol => Icons.sports_volleyball,
  };

  Color get color => switch (this) {
    Sport.futbol => AppColors.emerald600,
    Sport.padel => AppColors.brandTeal,
    Sport.baloncesto => AppColors.orange500,
    Sport.voleibol => AppColors.amber500,
  };
}
