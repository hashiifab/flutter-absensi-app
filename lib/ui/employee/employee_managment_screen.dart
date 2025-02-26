import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'package:flutter/services.dart';

/// Konstanta warna yang digunakan (sama dengan AbsentScreen)
const Color primaryColor = Color(0xFF2D5D7C);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color secondaryBackgroundColor = Color(0xFFEBEBEB);

/// CameraScreen: Menampilkan tampilan kamera dalam orientasi portrait dengan panduan wajah
class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    // Memaksa orientasi portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeCamera();
  }

  /// Inisialisasi kamera yang tersedia
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _selectedCameraIndex = 0;
      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  /// Mengganti kamera (jika perangkat memiliki lebih dari satu kamera)
  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _cameraController!.dispose();
    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  /// Mengambil foto dan mengembalikan hasilnya
  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      XFile picture = await _cameraController!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, picture);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error capturing photo: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    // Kembalikan orientasi agar bisa landscape bila diperlukan di halaman lain
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dengan judul
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
      body: _isCameraInitialized && _cameraController != null
          ? Stack(
              children: [
                // Tampilan kamera dalam mode portrait dengan rounded corners
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      // Mengatur aspect ratio portrait (misal 9:16)
                      aspectRatio: 9 / 16,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
                // Overlay panduan wajah: lingkaran di tengah layar
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                // Overlay atas dengan efek gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Panel bawah dengan tombol capture dan switch kamera
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tombol switch kamera (hanya tampil jika lebih dari 1 kamera)
                        if (_cameras != null && _cameras!.length > 1)
                          IconButton(
                            onPressed: _switchCamera,
                            icon: const Icon(
                              Icons.switch_camera,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                        else
                          const SizedBox(width: 50),
                        // Tombol capture foto dengan desain lingkaran
                        GestureDetector(
                          onTap: _capturePhoto,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        // Placeholder untuk menjaga keseimbangan layout
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                ),
                // Teks instruksi di bawah overlay panduan wajah
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Face Recognition",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// EmployeeManagementScreen: Form untuk input data karyawan beserta upload gambar
class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({Key? key}) : super(key: key);
  @override
  _EmployeeManagementScreenState createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Variabel untuk menyimpan gambar yang diambil/dipilih
  XFile? _capturedImage;
  Uint8List? _webImageBytes; // Untuk web
  String? _imageUrl;

  final CollectionReference employeeCollection =
      FirebaseFirestore.instance.collection('employees');

  // Mengambil gambar (menggunakan kamera sebagai contoh)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _capturedImage = pickedFile;
        });
      } else {
        setState(() {
          _capturedImage = pickedFile;
        });
      }
    }
  }

  // Helper: Mengembalikan byte data dari XFile (untuk web)
  Future<Uint8List> _getBytesFromXFile(XFile file) async {
    if (kIsWeb && file.path.startsWith('blob:')) {
      final request = await html.HttpRequest.request(file.path,
          responseType: 'arraybuffer');
      final ByteBuffer buffer = request.response;
      return buffer.asUint8List();
    } else {
      return await file.readAsBytes();
    }
  }

  // Upload gambar ke Firebase Storage
  Future<void> _uploadImage() async {
    if (_imageUrl != null) return;
    String fileName = idController.text.trim().isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : idController.text.trim();
    _imageUrl = fileName;
  }

  void showLoaderDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  "Submitting Data...",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      showLoaderDialog(context);
      await _uploadImage();
      try {
        await employeeCollection.add({
          'name': nameController.text.trim(),
          'employee_id': idController.text.trim(),
          'department': departmentController.text.trim(),
          'position': positionController.text.trim(),
          'contact': contactController.text.trim(),
          'email': emailController.text.trim(),
          'address': addressController.text.trim(),
          'image_url': _imageUrl,
          'created_at': FieldValue.serverTimestamp(),
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text("Employee Data Submitted Successfully!",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("Ups, terjadi kesalahan: $e",
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CameraScreen()),
                  );
                  if (result != null && result is XFile) {
                    if (kIsWeb) {
                      final bytes = await result.readAsBytes();
                      setState(() {
                        _webImageBytes = bytes;
                        _capturedImage = result;
                      });
                    } else {
                      setState(() {
                        _capturedImage = result;
                      });
                    }
                    await _uploadCapturedImage(result);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick Image'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadCapturedImage(XFile imageFile) async {
    String fileName = idController.text.trim().isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : idController.text.trim();
    try {
      final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://flutter-absensi-app-c2b50.firebasestorage.app');
      final ref = storage.ref().child('employee_images/$fileName.jpg');
      if (kIsWeb) {
        final bytes = await _getBytesFromXFile(imageFile);
        setState(() {
          _webImageBytes = bytes;
        });
        await ref.putData(bytes);
      } else {
        final file = File(imageFile.path);
        if (!file.existsSync()) return;
        await ref.putFile(file);
      }
      String downloadURL = await ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadURL;
      });
    } catch (e) {
      // Tangani error jika diperlukan
    }
  }

  Widget _buildImagePreview() {
    if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_imageUrl!,
            fit: BoxFit.cover, width: 200, height: 200),
      );
    } else if (_capturedImage != null) {
      if (kIsWeb && _webImageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_webImageBytes!,
              fit: BoxFit.cover, width: 200, height: 200),
        );
      } else if (!kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(_capturedImage!.path),
              fit: BoxFit.cover, width: 200, height: 200),
        );
      }
    }
    return Container(
      alignment: Alignment.center,
      width: 200,
      height: 200,
      child: Text("No Image Selected",
          style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _buildImageHolder() {
    bool hasImage = _capturedImage != null ||
        _imageUrl != null ||
        (kIsWeb && _webImageBytes != null);
    return GestureDetector(
      onTap: _showImageSourceSelection,
      child: Container(
        height: 200,
        width: 200,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: hasImage
            ? Stack(
                children: [
                  _buildImagePreview(),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _capturedImage = null;
                          _webImageBytes = null;
                          _imageUrl = null;
                        });
                      },
                    ),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text("Add your image",
                      style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumeric = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric
            ? TextInputType.number
            : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty)
            return "$label cannot be empty";
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
            return "Enter a valid email";
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text("Submit",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Employee Management",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      backgroundColor: secondaryBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _buildImageHolder()),
                        const SizedBox(height: 20),
                        // Full Name (full width)
                        _buildTextField(
                            nameController, "Full Name", Icons.person),
                        // Row: Employee ID & Department
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  idController, "Employee ID", Icons.badge,
                                  isNumeric: true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(departmentController,
                                  "Department", Icons.business),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Row: Contact Number & Position
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(contactController,
                                  "Contact Number", Icons.phone,
                                  isNumeric: true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(positionController,
                                  "Position", Icons.work),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Row: Email & Address
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  emailController, "Email", Icons.email,
                                  isEmail: true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(addressController,
                                  "Address", Icons.home),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
