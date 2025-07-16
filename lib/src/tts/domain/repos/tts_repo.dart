import 'dart:typed_data';

import 'package:motor_mouth/core/utils/typedefs.dart';

abstract interface class TTSRepo {
  ResultFuture<JobStatusResponse> checkStatus(String jobId);

  ResultFuture<Uint8List?> fetchAudio(String jobId);

  ResultFuture<List<String>> fetchSpeakers();

  ResultFuture<SynthesizeAsyncResponse> synthesizeAsync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  });

  ResultFuture<Uint8List?> synthesizeSync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  });
}
