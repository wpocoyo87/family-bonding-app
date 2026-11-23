import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Real microphone audio recorder & player with Firebase Cloud Storage upload
/// and seamless local-file fallback when offline or running in demo mode.
class VoiceAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  String? _activeRecordingPath;

  /// Requests microphone permission and starts real AAC-LC (.m4a) recording.
  /// Returns true if microphone recording started successfully.
  Future<bool> startRecording(String fileId) async {
    try {
      final permitted = await _recorder.hasPermission();
      if (!permitted) return false;

      String path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/erat_voice_$fileId.m4a';
      }
      _activeRecordingPath = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ VoiceAudioService.startRecording error: $e');
      return false;
    }
  }

  /// Stops active recording, uploads the .m4a file to Firebase Cloud Storage
  /// (`voice_notes/$familyId/$folder/$fileId.m4a`), and returns the HTTPS
  /// download URL (or local file path fallback if offline/unconfigured).
  Future<String?> stopAndUpload({
    required String familyId,
    required String folder,
    required String fileId,
  }) async {
    try {
      final recordedPath = await _recorder.stop() ?? _activeRecordingPath;
      _activeRecordingPath = null;
      if (recordedPath == null || recordedPath.isEmpty) return null;

      // Attempt Firebase Cloud Storage upload if Firebase is active
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        try {
          final file = File(recordedPath);
          if (await file.exists()) {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('voice_notes/$familyId/$folder/$fileId.m4a');
            final uploadTask = storageRef.putFile(
              file,
              SettableMetadata(contentType: 'audio/mp4'),
            );
            final snap = await uploadTask.timeout(const Duration(seconds: 12));
            final downloadUrl = await snap.ref.getDownloadURL();
            return downloadUrl;
          }
        } catch (e) {
          debugPrint(
            'ℹ️ Firebase Storage voice upload fallback to local file: $e',
          );
        }
      }

      // Return local file path (or web blob URL) so playback still works immediately
      return recordedPath;
    } catch (e) {
      debugPrint('⚠️ VoiceAudioService.stopAndUpload error: $e');
      return null;
    }
  }

  /// Cancels active recording and deletes the temporary audio file.
  Future<void> cancelRecording() async {
    try {
      final path = await _recorder.stop() ?? _activeRecordingPath;
      _activeRecordingPath = null;
      if (!kIsWeb && path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (_) {}
  }

  /// Plays a real audio URL (Firebase Storage HTTPS) or local .m4a file.
  Future<bool> play(
    String? audioUrlOrPath, {
    VoidCallback? onComplete,
  }) async {
    if (audioUrlOrPath == null || audioUrlOrPath.trim().isEmpty) return false;
    final src = audioUrlOrPath.trim();
    try {
      await _player.stop();
      await _completeSub?.cancel();
      if (onComplete != null) {
        _completeSub = _player.onPlayerComplete.listen((_) => onComplete());
      }

      if (src.startsWith('http://') ||
          src.startsWith('https://') ||
          src.startsWith('blob:')) {
        await _player.play(UrlSource(src));
        return true;
      }

      if (!kIsWeb) {
        final file = File(src);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(src));
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ VoiceAudioService.play error: $e');
      return false;
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _completeSub?.cancel();
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _completeSub?.cancel();
    await _recorder.dispose();
    await _player.dispose();
  }
}
