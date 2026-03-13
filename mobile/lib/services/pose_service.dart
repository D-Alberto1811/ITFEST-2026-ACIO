import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// On-device pose detection - 100% local, GDPR compliant.
/// All processing happens on the phone, no data leaves the device.
class PoseService {
  late PoseDetector _detector;
  bool _isProcessing = false;

  PoseService() {
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  Future<List<Pose>> processCameraImage(CameraImage image, InputImageRotation rotation) async {
    if (_isProcessing) return [];
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image, rotation);
      if (inputImage == null) return [];
      return await _detector.processImage(inputImage);
    } catch (e) {
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image, InputImageRotation rotation) {
    try {
      if (Platform.isIOS) {
        return _convertForIOS(image, rotation);
      }
      return _convertForAndroid(image, rotation);
    } catch (_) {
      return null;
    }
  }

  InputImage? _convertForIOS(CameraImage image, InputImageRotation rotation) {
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.bgra8888,
      bytesPerRow: plane.bytesPerRow,
    );
    return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
  }

  InputImage? _convertForAndroid(CameraImage image, InputImageRotation rotation) {
    if (image.planes.length == 1) {
      final plane = image.planes.first;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    }

    final yuvBytes = _yuv420ToNv21(image);
    if (yuvBytes == null) return null;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.width,
    );
    return InputImage.fromBytes(bytes: yuvBytes, metadata: metadata);
  }

  Uint8List? _yuv420ToNv21(CameraImage image) {
    if (image.planes.length < 3) return null;
    final y = image.planes[0].bytes;
    final u = image.planes[1].bytes;
    final v = image.planes[2].bytes;
    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final nv21 = Uint8List(image.width * image.height * 3 ~/ 2);
    var idx = 0;
    for (var i = 0; i < image.height; i++) {
      for (var j = 0; j < image.width; j++) {
        nv21[idx++] = y[i * yRowStride + j];
      }
    }
    for (var i = 0; i < image.height ~/ 2; i++) {
      for (var j = 0; j < image.width; j += 2) {
        nv21[idx++] = v[i * uvRowStride + j * uvPixelStride];
        nv21[idx++] = u[i * uvRowStride + j * uvPixelStride];
      }
    }
    return nv21;
  }

  void dispose() {
    _detector.close();
  }
}
