// @app.route("/api/audio/<job_id>", methods=["GET"])
// def api_audio(job_id):
// job = jobs.get(job_id)
// if not job or job['status'] != 'complete':
// return jsonify({"error": "Job not found or not complete"}), 404
//
// file_path = job.get('file_path')
// if not file_path or not os.path.exists(file_path):
// return jsonify({"error": "Audio file not found"}), 404
//
// return send_file(file_path, mimetype="audio/wav")

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:motor_mouth/core/utils/typedefs.dart';

abstract interface class TTSRemoteDataSrc {
  Future<JobStatusResponse> checkStatus(String jobId);

  Future<Uint8List?> fetchAudio(String jobId);

  Future<List<String>> fetchSpeakers();

  Future<SynthesizeAsyncResponse> synthesizeAsync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  });

  Future<Uint8List?> synthesizeSync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  });
}

final class TTSRemoteDataSrcImpl implements TTSRemoteDataSrc {
  const TTSRemoteDataSrcImpl(this._httpClient);

  final http.Client _httpClient;

  @override
  Future<JobStatusResponse> checkStatus(String jobId) async {
    // TODO(Implementation): Implement checkStatus
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> fetchAudio(String jobId) async {
    // TODO(Implementation): Implement fetchAudio
    throw UnimplementedError();
  }

  @override
  Future<List<String>> fetchSpeakers() async {
    // TODO(Implementation): Implement fetchSpeakers
    throw UnimplementedError();
  }

  @override
  Future<SynthesizeAsyncResponse> synthesizeAsync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  }) async {
    // TODO(Implementation): Implement synthesizeAsync
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> synthesizeSync({
    required String text,
    String? speaker,
    double? speed,
    bool? ssml,
  }) async {
    // TODO(Implementation): Implement synthesizeSync
    throw UnimplementedError();
  }
}
