import 'package:dio/dio.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/media/image_upload.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_rate.dart';
import '../../domain/entities/court_schedule.dart';
import '../../domain/entities/court_time.dart';
import '../../domain/entities/week_day.dart';
import 'courts_data_source.dart';

/// Canchas del negocio en la API (`/business/courts`).
class CourtsApiDataSource implements CourtsDataSource {
  const CourtsApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/courts';

  @override
  Future<List<Court>> getCourts() async {
    final response = await apiCall(() => _dio.get<List<dynamic>>(_path));
    return [
      for (final item in response.data ?? const [])
        fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Court> create(CourtDraft draft) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(_path, data: toJson(draft)),
    );
    return fromJson(response.data!);
  }

  /// PATCH con todos los campos: `schedules` y `rates` reemplazan las
  /// listas completas en la API.
  @override
  Future<Court> update(String courtId, CourtDraft draft) async {
    final response = await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '$_path/$courtId',
        data: toJson(draft),
      ),
    );
    return fromJson(response.data!);
  }

  @override
  Future<Court> removePhoto(String courtId, CourtPhotoSlot slot) async {
    final response = await apiCall(
      () => _dio.delete<Map<String, dynamic>>(
        '$_path/$courtId/photos/${slot.apiCode}',
      ),
    );
    return fromJson(response.data!);
  }

  /// Multipart en el campo `image`, desde bytes para que funcione en web.
  @override
  Future<Court> uploadPhoto(
    String courtId,
    CourtPhotoSlot slot,
    ImageUpload image,
  ) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        image.bytes,
        filename: image.fileName,
        contentType: DioMediaType('image', image.isPng ? 'png' : 'jpeg'),
      ),
    });
    final response = await apiCall(
      () => _dio.put<Map<String, dynamic>>(
        '$_path/$courtId/photos/${slot.apiCode}',
        data: form,
      ),
    );
    return fromJson(response.data!);
  }

  static Map<String, dynamic> toJson(CourtDraft draft) => {
    'name': draft.name.trim(),
    'sport': draft.sport.apiCode,
    'isCovered': draft.isCovered,
    'isActive': draft.isActive,
    'currency': 'COP',
    'basePricePerHour': draft.basePricePerHour,
    'slotDuration': draft.slotDuration,
    'schedules': [
      for (final day in draft.schedules)
        {
          'dayOfWeek': day.day.apiCode,
          'isOpen': day.isOpen,
          if (day.isOpen) ...{
            'openTime': day.open!.label,
            'closeTime': day.close!.label,
          },
        },
    ],
    'rates': [
      for (final rate in draft.rates)
        {
          'name': rate.name.trim(),
          'pricePerHour': rate.pricePerHour,
          'days': [
            // En el orden de la semana, no en el que se marcaron.
            for (final day
                in rate.days.toList()
                  ..sort((a, b) => a.index.compareTo(b.index)))
              day.apiCode,
          ],
          'startTime': rate.start.label,
          'endTime': rate.end.label,
        },
    ],
    // null borra el dato en la API (el PATCH envía todos los campos).
    'surface': draft.specs.surface?.code,
    'lengthMeters': draft.specs.hasDimensions ? draft.specs.lengthMeters : null,
    'widthMeters': draft.specs.hasDimensions ? draft.specs.widthMeters : null,
    'playersPerSide': draft.specs.playersPerSide,
  };

  static Court fromJson(Map<String, dynamic> json) => Court(
    id: json['id'] as String,
    name: json['name'] as String,
    sport: Sport.fromApi(json['sport'] as String?),
    isActive: json['isActive'] as bool? ?? true,
    isComplete: json['isComplete'] as bool? ?? false,
    isBookable: json['isBookable'] as bool? ?? false,
    isCovered: json['isCovered'] as bool? ?? false,
    // COP sin centavos en la app (la API admite 2 decimales).
    basePricePerHour: (json['basePricePerHour'] as num? ?? 0).round(),
    slotDuration: (json['slotDuration'] as num? ?? 60).toInt(),
    schedules: [
      for (final item in (json['schedules'] as List<dynamic>? ?? const []))
        ?_schedule(item as Map<String, dynamic>),
    ],
    rates: [
      for (final item in (json['rates'] as List<dynamic>? ?? const []))
        ?_rate(item as Map<String, dynamic>),
    ],
    photos: {
      for (final photo in (json['photos'] as List<dynamic>? ?? const []))
        if (photo case {'slot': final String code, 'url': final String url})
          ?CourtPhotoSlot.fromApi(code): ApiConfig.secureUrl(url),
    },
    missingPhotos: [
      for (final code in (json['missingPhotos'] as List<dynamic>? ?? const []))
        ?CourtPhotoSlot.fromApi('$code'),
    ],
    specs: CourtSpecs(
      surface: switch (json['surface']) {
        {'code': final String code, 'name': final String name} =>
          CourtSurfaceRef(code: code, name: name),
        _ => null,
      },
      lengthMeters: (json['lengthMeters'] as num?)?.toDouble(),
      widthMeters: (json['widthMeters'] as num?)?.toDouble(),
      playersPerSide: (json['playersPerSide'] as num?)?.toInt(),
    ),
  );

  static DaySchedule? _schedule(Map<String, dynamic> json) {
    final day = WeekDay.fromApi(json['dayOfWeek'] as String? ?? '');
    if (day == null) return null;
    final open = CourtTime.tryParse(json['openTime'] as String?);
    final close = CourtTime.tryParse(json['closeTime'] as String?);
    if (json['isOpen'] == true && open != null && close != null) {
      return DaySchedule.open(day, open: open, close: close);
    }
    return DaySchedule.closed(day);
  }

  /// `null` si la tarifa trae datos que la app no entiende.
  static CourtRate? _rate(Map<String, dynamic> json) {
    final start = CourtTime.tryParse(json['startTime'] as String?);
    final end = CourtTime.tryParse(json['endTime'] as String?);
    final days = {
      for (final code in (json['days'] as List<dynamic>? ?? const []))
        ?WeekDay.fromApi('$code'),
    };
    if (start == null || end == null || days.isEmpty) return null;
    return CourtRate(
      name: json['name'] as String? ?? '',
      pricePerHour: (json['pricePerHour'] as num? ?? 0).round(),
      days: days,
      start: start,
      end: end,
    );
  }
}
