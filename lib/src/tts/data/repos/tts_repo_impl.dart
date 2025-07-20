import 'dart:typed_data';

import 'package:motor_mouth/core/utils/repo_impl_guard.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/data/datasources/tts_remote_data_src.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';

final class TTSRepoImpl implements TTSRepo {
  const TTSRepoImpl({
    required TTSRemoteDataSrc remoteDataSrc,
    required RepoImplGuard guard,
  }) : _remoteDataSrc = remoteDataSrc,
       _guard = guard;

  final TTSRemoteDataSrc _remoteDataSrc;
  final RepoImplGuard _guard;

  @override
  ResultFuture<JobStatusResponse> checkStatus(String jobId) async {
    return _guard(() => _remoteDataSrc.checkStatus(jobId));
  }

  @override
  ResultFuture<Uint8List?> fetchAudio(String jobId) async {
    return _guard(() => _remoteDataSrc.fetchAudio(jobId));
  }

  @override
  ResultFuture<List<String>> fetchSpeakers() async {
    return _guard(_remoteDataSrc.fetchSpeakers);
  }

  @override
  ResultFuture<SynthesizeAsyncResponse> synthesizeAsync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  }) async {
    return _guard(() {
      return _remoteDataSrc.synthesizeAsync(
        text: text,
        speaker: speaker,
        speed: speed,
        ssml: ssml,
      );
    });
  }

  @override
  ResultFuture<Uint8List?> synthesizeSync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  }) async {
    return _guard(() {
      return _remoteDataSrc.synthesizeSync(
        text: text,
        speaker: speaker,
        speed: speed,
        ssml: ssml,
      );
    });
  }
}
