import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaStorageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from Camera or Gallery with automatic compression to save space & bandwidth
  static Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 80, // Generates clean, crisp image (~30KB-80KB)
      );
      return picked;
    } catch (e) {
      debugPrint('⚠️ Error picking image: $e');
      return null;
    }
  }

  /// Upload member profile photo.
  /// First attempts Firebase Cloud Storage (free tier).
  /// If offline or unconfigured, seamlessly falls back to Base64 Data URL
  /// so it saves directly into Firestore with 0 setup!
  static Future<String?> uploadProfilePhoto({
    required String memberId,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      storagePath: 'profiles/$memberId.jpg',
      file: imageFile,
    );
  }

  /// Upload wish goal / reward photo.
  static Future<String?> uploadWishGoalPhoto({
    required String goalId,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      storagePath: 'wish_goals/$goalId.jpg',
      file: imageFile,
    );
  }

  /// Upload family avatar / icon photo (Firebase Storage with seamless Base64 Firestore fallback).
  static Future<String?> uploadFamilyPhoto({
    required String familyId,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      storagePath: 'families/$familyId/avatar.jpg',
      file: imageFile,
    );
  }

  /// Upload daily activity custom photo (Firebase Storage with seamless Base64 Firestore fallback).
  static Future<String?> uploadActivityPhoto({
    required String activityId,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      storagePath: 'activities/$activityId.jpg',
      file: imageFile,
    );
  }

  /// Upload shared family goal reward photo (Firebase Storage with seamless Base64 Firestore fallback).
  static Future<String?> uploadFamilyGoalPhoto({
    required String goalId,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      storagePath: 'family_goals/$goalId.jpg',
      file: imageFile,
    );
  }

  /// Renders the family's custom photo in a squircle frame matching EratBrandLogo,
  /// or falls back cleanly to [fallback] when no custom photo is set.
  static Widget buildFamilyAvatar({
    required String? photoPath,
    double size = 42,
    required Widget fallback,
  }) {
    if (photoPath == null || photoPath.trim().isEmpty) {
      return fallback;
    }
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFFE5CEC2),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(109, 76, 65, 0.16),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1.2),
        child: buildAdaptiveImage(
          photoPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: fallback,
        ),
      ),
    );
  }

  static Future<String?> _uploadFile({
    required String storagePath,
    required XFile file,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      // 1. Try Firebase Cloud Storage if Firebase is ready
      if (Firebase.apps.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance.ref().child(storagePath);
          final uploadTask = await storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          debugPrint('✅ Uploaded to Firebase Storage: $downloadUrl');
          return downloadUrl;
        } catch (storageError) {
          debugPrint(
            'ℹ️ Firebase Storage bucket rule pending/offline: $storageError. Using Base64 Firestore storage.',
          );
        }
      }

      // 2. Fallback: Base64 Data URL (Saves directly to Firestore with $0 cost and zero external storage!)
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('⚠️ Error uploading image: $e');
      return null;
    }
  }

  /// Universal Image Widget that cleanly renders:
  /// - Base64 Data URLs (data:image/jpeg;base64,...)
  /// - Firebase Cloud Storage URLs (https://...)
  /// - Asset paths (assets/images/...)
  /// - Local file paths
  static Widget buildAdaptiveImage(
    String? imagePathOrUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (imagePathOrUrl == null || imagePathOrUrl.trim().isEmpty) {
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_outlined, color: Colors.grey),
          );
    }

    final trimmed = imagePathOrUrl.trim();

    // 1. Base64 Data URL
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Data =
            commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              placeholder ?? const Icon(Icons.broken_image_rounded),
        );
      } catch (_) {
        return placeholder ?? const Icon(Icons.broken_image_rounded);
      }
    }

    // 2. HTTPS / Firebase Storage Network Image
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            placeholder ?? const Icon(Icons.broken_image_rounded),
      );
    }

    // 3. Asset Image
    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ?? const Icon(Icons.broken_image_rounded),
      );
    }

    // 4. Local File Image
    if (!kIsWeb) {
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                placeholder ?? const Icon(Icons.broken_image_rounded),
          );
        }
      } catch (_) {}
    }

    return placeholder ?? const Icon(Icons.image_outlined);
  }
}
