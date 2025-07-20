import 'package:motor_mouth/core/usecase/usecase.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';

class FetchSpeakers implements UsecaseWithoutParams<List<String>> {
  const FetchSpeakers(this._repo);

  final TTSRepo _repo;

  @override
  ResultFuture<List<String>> call() => _repo.fetchSpeakers();
}
