import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8 encoding
import 'face_detector.dart';
import 'database_helper.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  CameraController? _cameraController;
  late FaceDetectorService _faceDetectorService;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _isDisposed = false; // Track if the widget has been disposed

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _faceDetectorService = FaceDetectorService();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Select the front camera
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);

      await _cameraController?.initialize();
      if (_isDisposed) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController?.startImageStream((CameraImage image) async {
        if (_isDisposed) return;

        if (_isDetecting) return;

        _isDetecting = true;
        final faces = await _faceDetectorService.detectFaces(image, _cameraController!.description.lensDirection);

        if (faces.isNotEmpty && !_isDisposed) {
          final faceData = faces.first;
          await _verifyFaceData(faceData);
        }

        _isDetecting = false;
      });
    } catch (e) {
      print("Error initializing camera: $e");
      if (!_isDisposed) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _verifyFaceData(Face face) async {
    try {
      final faceDataHash = _hashFaceData(face.boundingBox); // Create hash
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getUserByFaceDataHash(faceDataHash); // Update this method

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Welcome back, ${user['name']}!"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Face not recognized. Please register first."),
        ));
      }
    } catch (e) {
      print("Error during face verification: $e");
    }
  }

  String _hashFaceData(Rect faceData) {
    final ByteData byteData = ByteData(16);
    byteData.setFloat32(0, faceData.left);
    byteData.setFloat32(4, faceData.top);
    byteData.setFloat32(8, faceData.right);
    byteData.setFloat32(12, faceData.bottom);
    final bytes = byteData.buffer.asUint8List();
    return sha256.convert(bytes).toString(); // Create a hash of the face data
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark the widget as disposed
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
