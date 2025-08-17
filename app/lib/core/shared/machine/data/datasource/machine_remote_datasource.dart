import 'package:dio/dio.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/models/api_response.dart';
import 'package:resiwash/core/network/dio_client.dart';
import 'package:resiwash/core/network/paths.dart';
import 'package:resiwash/core/shared/machine/data/models/machine_model.dart';
import 'package:resiwash/core/shared/machine/domain/entities/machine_entity.dart';

Dio http = DioClient.instance();

class MachineRemoteDatasource {
  Future<List<MachineEntity>> getMachines({List<String>? roomIds}) async {
    try {
      appLog.d('[api] fetching machines with roomIds: $roomIds');
      final Response<Map<String, dynamic>> response = await http
          .get<Map<String, dynamic>>(
            Paths.machines,
            queryParameters: {"roomIds[]": roomIds},
          );

      final apiResponse = ApiResponse<List<MachineModel>>.fromJson(
        response.data!,
        (json) {
          return (json as List<dynamic>)
              .map(
                (item) => MachineModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        },
      );

      appLog.d('[api] ${response.data!['data']}');

      return apiResponse.data
          .map<MachineEntity>((item) => item.toEntity())
          .toList();

      // Use ApiResponse to parse the server's response structure
      // final apiResponse = ApiResponse<List<MachineModel>>.fromJson(
      //   response.data,
      //   (json) => (json as List<dynamic>)
      //       .map((item) => MachineModel.fromJson(item as Map<String, dynamic>))
      //       .toList(),
      // );

      // print("made it past the from json");

      // appLog.d("Machines: ${apiResponse.data}");
      // return apiResponse.data.map((model) => model.toEntity()).toList();
    } on DioException catch (e) {
      appLog.e('[api] error fetching machines: $e');
      throw Failure(message: e.message as String);
    } catch (e) {
      print('failed');
      throw Exception();
    }
  }

  Future<MachineEntity> getMachineById({required String machineId}) async {
    try {
      final Response<dynamic> response = await http.get(
        "${Paths.machines}/$machineId",
      );

      // Use ApiResponse for single machine response
      final apiResponse = ApiResponse<MachineModel>.fromJson(
        response.data,
        (json) => MachineModel.fromJson(json as Map<String, dynamic>),
      );

      return apiResponse.data.toEntity();
    } on DioException catch (e) {
      throw Failure(message: e.message as String);
    } catch (e) {
      throw Exception();
    }
  }
}
