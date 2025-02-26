import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_absensi_app/ui/home_screen.dart';

const Color primaryColor = Color(0xFF2D5D7C);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color secondaryBackgroundColor = Color(0xFFEBEBEB);

/// (Kode CameraScreen tetap tidak berubah)
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeCamera();
  }

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
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Camera",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
      body: _isCameraInitialized && _cameraController != null
          ? Stack(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
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
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                ),
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

/// AttendScreen: Halaman absensi dengan input nama dan pengambilan data real time
/// (waktu, lokasi, dan status absensi) untuk field description.
class AttendScreen extends StatefulWidget {
  const AttendScreen({super.key});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  // Variabel absensi
  String strAlamat = "";
  String strDate = "", strTime = "", strDateTime = "";
  // strStatus akan digunakan untuk menentukan nilai field description
  String strStatus = "Absen Masuk";
  bool isLoading = false;
  double dLat = 0.0, dLong = 0.0;
  int dateHours = 0, dateMinutes = 0;

  // Dropdown untuk memilih nama employee (diambil dari koleksi 'employees')
  String? selectedEmployee;

  // Variabel untuk foto absensi
  XFile? capturedImage;
  Uint8List? webImageBytes;
  String? _imageUrl;

  // Koleksi Firestore untuk absensi
  final CollectionReference attendanceCollection =
      FirebaseFirestore.instance.collection('attendance');

  @override
  void initState() {
    super.initState();
    handleLocationPermission();
    setDateTime();
    setStatusAbsen();
    if (capturedImage != null) {
      isLoading = true;
      getGeoLocationPosition();
    }
  }

  // Fungsi geolokasi
  Future<void> getGeoLocationPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    setState(() {
      isLoading = false;
    });
    getAddressFromLongLat(position);
  }

  Future<void> getAddressFromLongLat(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    setState(() {
      dLat = position.latitude;
      dLong = position.longitude;
      strAlamat =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
    });
  }

  // Fungsi untuk mengecek dan meminta izin lokasi
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white),
            SizedBox(width: 10),
            Text("Location services are disabled. Please enable the services.",
                style: TextStyle(color: Colors.white))
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 10),
              Text("Location permission denied.",
                  style: TextStyle(color: Colors.white))
            ],
          ),
          backgroundColor: Colors.redAccent,
          shape: StadiumBorder(),
          behavior: SnackBarBehavior.floating,
        ));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white),
            SizedBox(width: 10),
            Text("Location permission denied forever, we cannot access.",
                style: TextStyle(color: Colors.white))
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
      return false;
    }

    return true;
  }

  // Set waktu dan tanggal secara otomatis
  void setDateTime() {
    DateTime now = DateTime.now();
    setState(() {
      strDate = DateFormat('dd MMMM yyyy').format(now);
      strTime = DateFormat('HH:mm:ss').format(now);
      strDateTime = "$strDate | $strTime";
      dateHours = int.parse(DateFormat('HH').format(now));
      dateMinutes = int.parse(DateFormat('mm').format(now));
    });
  }

  // Tentukan status absensi (yang nantinya akan disimpan ke field description)
  void setStatusAbsen() {
    // Misalnya: Sebelum jam 08:30 = Absen Masuk, antara 08:31 s.d. 18:00 = Absen Telat, setelah 18:00 = Absen Keluar.
    if (dateHours < 8 || (dateHours == 8 && dateMinutes <= 30)) {
      strStatus = "Entered";
    } else if (dateHours >= 8 && dateHours < 18) {
      strStatus = "Late";
    } else {
      strStatus = "Exited";
    }
  }

  // Pilih sumber gambar (kamera atau gallery)
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
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                  if (result != null && result is XFile) {
                    if (kIsWeb) {
                      final bytes = await result.readAsBytes();
                      setState(() {
                        webImageBytes = bytes;
                        capturedImage = result;
                      });
                    } else {
                      setState(() {
                        capturedImage = result;
                      });
                    }
                    await _uploadCapturedImage(result);
                    getGeoLocationPosition();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          webImageBytes = bytes;
          capturedImage = pickedFile;
        });
      } else {
        setState(() {
          capturedImage = pickedFile;
        });
      }
      await _uploadCapturedImage(pickedFile);
      getGeoLocationPosition();
    }
  }

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

  Future<void> _uploadCapturedImage(XFile imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://flutter-absensi-app-c2b50.firebasestorage.app');
      final ref = storage.ref().child('attendance_images/$fileName.jpg');
      if (kIsWeb) {
        final bytes = await _getBytesFromXFile(imageFile);
        setState(() {
          webImageBytes = bytes;
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

  // UI helper: Dropdown untuk memilih nama employee (diambil dari koleksi 'employees')
  Widget _buildEmployeeDropdown() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('employees').get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<String> employeeNames =
              snapshot.data!.docs.map((doc) => doc['name'].toString()).toList();
          return DropdownButtonFormField<String>(
            value: selectedEmployee,
            decoration: InputDecoration(
              labelText: "Your Name",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            hint: const Text("Select your name"),
            onChanged: (value) {
              setState(() {
                selectedEmployee = value;
              });
            },
            items: employeeNames
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
          );
        } else if (snapshot.hasError) {
          return const Text("Error loading employees");
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildImagePreview() {
    if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          width: 200,
          height: 200,
        ),
      );
    } else if (capturedImage != null) {
      if (kIsWeb && webImageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            webImageBytes!,
            fit: BoxFit.cover,
            width: 200,
            height: 200,
          ),
        );
      } else if (!kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(capturedImage!.path),
            fit: BoxFit.cover,
            width: 200,
            height: 200,
          ),
        );
      }
    }
    return Container(
      alignment: Alignment.center,
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.add_photo_alternate,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildImageHolder() {
    bool hasImage = capturedImage != null ||
        _imageUrl != null ||
        (kIsWeb && webImageBytes != null);
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
              offset: const Offset(0, 2),
            )
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
                          capturedImage = null;
                          webImageBytes = null;
                          _imageUrl = null;
                        });
                      },
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your image",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
      ),
    );
  }

  // Submit data absensi dengan menyimpan nilai real time ke field description
  Future<void> submitAbsen() async {
    if (selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text("Please select your name!",
                  style: TextStyle(color: Colors.white))
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showLoaderDialog(context);
    try {
      await attendanceCollection.add({
        'name': selectedEmployee,
        'datetime': strDateTime,
        'alamat': strAlamat,
        // Simpan hasil logika status ke field description
        'description': strStatus,
        'imageUrl': _imageUrl,
        'created_at': FieldValue.serverTimestamp(),
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text("Yeay! Attendance Report Succeeded!",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                  child: Text("Ups, terjadi kesalahan: $e",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Loading dialog
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
                child: Text("Submitting Request...",
                    style: TextStyle(color: Colors.grey.shade700)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryBackgroundColor,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text("Attend Screen",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
      ),
      body: SingleChildScrollView(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: _buildImageHolder()),
                    const SizedBox(height: 16),
                    _buildEmployeeDropdown(),
                    const SizedBox(height: 16),
                    // Menampilkan lokasi (non-editable)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 5 * 24,
                        child: TextField(
                          enabled: false,
                          maxLines: 5,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            hintText: strAlamat.isNotEmpty ? strAlamat : 'Your Location',
                            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                            fillColor: Colors.transparent,
                            filled: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: submitAbsen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Absen Sekarang",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
