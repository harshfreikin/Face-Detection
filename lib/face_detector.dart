import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceDetectorService {
  late FaceDetector _faceDetector;
  bool _isDetecting = false;

  FaceDetectorService() {
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableContours: true,
        enableClassification: true, // Optional: Enable classification if needed
        enableTracking: true, // Optional: Enable tracking if needed
      ),
    );
  }

  Future<List<Face>> detectFaces(CameraImage image, CameraLensDirection cameraLensDirection) async {
    if (_isDetecting) return [];

    _isDetecting = true;
    try {
      final inputImage = _convertCameraImage(image, cameraLensDirection);
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print("Error detecting faces: $e");
      return [];
    } finally {
      _isDetecting = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image, CameraLensDirection cameraLensDirection) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation imageRotation = _rotationIntToImageRotation(cameraLensDirection);

    final InputImageFormat inputImageFormat = InputImageFormatMethods.fromRawValue(image.format.raw) ?? InputImageFormat.NV21;

    final planeData = image.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  InputImageRotation _rotationIntToImageRotation(CameraLensDirection cameraLensDirection) {
    switch (cameraLensDirection) {
      case CameraLensDirection.front:
        return InputImageRotation.Rotation_270deg;
      case CameraLensDirection.back:
        return InputImageRotation.Rotation_0deg;
      default:
        return InputImageRotation.Rotation_0deg;
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
