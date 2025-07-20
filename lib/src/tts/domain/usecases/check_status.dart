import 'package:motor_mouth/core/usecase/usecase.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';

class CheckStatus implements UsecaseWithParams<JobStatusResponse, String> {
  const CheckStatus(this._repo);

  final TTSRepo _repo;

  @override
  ResultFuture<JobStatusResponse> call(String params) {
    return _repo.checkStatus(params);
  }
}
