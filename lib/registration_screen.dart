import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8 encoding
import 'face_detector.dart';
import 'database_helper.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  CameraController? _cameraController;
  late FaceDetectorService _faceDetectorService;
  bool _isDetecting = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isCameraInitialized = false;
  Face? _detectedFace; // Store detected face
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

        if (_isDisposed) return;

        if (faces.isNotEmpty) {
          if (mounted) {
            setState(() {
              _detectedFace = faces.first;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _detectedFace = null;
            });
          }
        }
        _isDetecting = false;
      });
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _saveFaceData(Face face, String name) async {
    try {
      final faceDataHash = _hashFaceData(face.boundingBox); // Create hash
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.insertUser({
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnFaceDataHash: faceDataHash, // Save hash instead of raw face data
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Face data saved successfully"),
      ));
      print("Face data saved successfully for user: $name");
    } catch (e) {
      print("Error saving face data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to save face data. Please try again."),
      ));
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

  void _onSavePressed() async {
    if (_nameController.text.isNotEmpty && _detectedFace != null) {
      await _saveFaceData(_detectedFace!, _nameController.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_detectedFace == null
            ? "No face detected. Please align your face within the frame."
            : "Please enter your name."),
      ));
    }
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
      appBar: AppBar(title: Text("Register")),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Enter your name",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _onSavePressed,
            child: Text("Save"),
          ),
        ],
      ),
    );
  }
}
