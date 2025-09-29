import 'package:dio/dio.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/models/api_response.dart';
import 'package:resiwash/core/network/dio_client.dart';
import 'package:resiwash/core/network/paths.dart';
import 'package:resiwash/features/area/data/models/area_model.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/core/errors/Failure.dart';

Dio http = DioClient.instance();

class AreaRemoteDatasource {
  Future<List<AreaEntity>> listAreas({List<String>? areaIds = const []}) async {
    try {
      appLog.d('[api] ListAreas');
      final Response<Map<String, dynamic>> response = await http.get(
        Paths.areas,
        queryParameters: {"areaIds[]": areaIds},
      );
      appLog.d('[api] ListAreas response: ${response.data}');
      final apiResponse = ApiResponse<List<AreaModel>>.fromJson(
        response.data!,
        (json) {
          return (json as List<dynamic>)
              .map((item) => AreaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      return apiResponse.data
          .map<AreaEntity>((item) => item.toEntity())
          .toList();
    } on DioException catch (e) {
      appLog.e('[api] ListAreas error: ${e.message}');
      return [];
    }
  }

  Future<List<AreaEntity>> listLocations({
    List<String>? areaIds = const [],
    List<String>? roomIds = const [],
  }) async {
    try {
      appLog.d('[api] ListLocations');
      final Response<Map<String, dynamic>> response = await http.get(
        Paths.locations,
        queryParameters: {"areaIds[]": areaIds, "roomIds[]": roomIds},
      );
      appLog.d('[api] ListLocations response: ${response.data}');
      final apiResponse = ApiResponse<List<AreaModel>>.fromJson(
        response.data!,
        (json) {
          return (json as List<dynamic>)
              .map((item) => AreaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      return apiResponse.data
          .map<AreaEntity>((item) => item.toEntity())
          .toList();
    } on DioException catch (e) {
      appLog.e('[api] ListLocations error: ${e.message}');
      return [];
    }
  }

  Future<AreaEntity> getAreaById({required String areaId}) async {
    try {
      appLog.d('[api] GetAreaById: $areaId');
      final Response<Map<String, dynamic>> response = await http.get(
        "/areas/$areaId",
      );
      appLog.d('[api] GetAreaById response: ${response.data}');
      final apiResponse = ApiResponse<AreaModel>.fromJson(
        response.data!,
        (json) => AreaModel.fromJson(json as Map<String, dynamic>),
      );

      return apiResponse.data.toEntity();
    } on DioException catch (e) {
      appLog.e('[api] GetAreaById error: ${e.message}');
      throw Failure(message: e.message ?? 'Unknown error');
    }
  }
}
