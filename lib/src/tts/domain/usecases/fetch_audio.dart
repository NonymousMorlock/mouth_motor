import 'dart:typed_data';

import 'package:motor_mouth/core/usecase/usecase.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';

class FetchAudio implements UsecaseWithParams<Uint8List?, String> {
  const FetchAudio(this._repo);

  final TTSRepo _repo;

  @override
  ResultFuture<Uint8List?> call(String params) => _repo.fetchAudio(params);
}
