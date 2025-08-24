import 'package:dio/dio.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/models/api_response.dart';
import 'package:resiwash/core/network/dio_client.dart';
import 'package:resiwash/features/room/data/models/room_model.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';

Dio http = DioClient.instance();

class RoomRemoteDatasource {
  Future<RoomEntity> getRoomById({required String roomId}) async {
    try {
      final Response<dynamic> response = await http.get("/rooms/$roomId");

      final apiResponse = ApiResponse<RoomModel>.fromJson(
        response.data,
        (json) => RoomModel.fromJson(json as Map<String, dynamic>),
      );

      return apiResponse.data.toEntity();
    } on DioException catch (e) {
      throw Failure(message: e.message as String);
    } catch (e) {
      throw Exception();
    }
  }
}
