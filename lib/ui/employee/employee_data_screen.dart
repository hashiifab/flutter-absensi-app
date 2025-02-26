import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmployeeDataScreen extends StatefulWidget {
  const EmployeeDataScreen({super.key});

  @override
  State<EmployeeDataScreen> createState() => _EmployeeDataScreenState();
}

class _EmployeeDataScreenState extends State<EmployeeDataScreen> {
  final CollectionReference employeeCollection =
      FirebaseFirestore.instance.collection('employees');

  // Fungsi untuk menampilkan snackbar
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Fungsi untuk mengedit data employee
  void _editEmployeeData(String docId, String currentName, String currentEmployeeId,
      String currentDepartment, String currentPosition) {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    TextEditingController employeeIdController =
        TextEditingController(text: currentEmployeeId);
    TextEditingController departmentController =
        TextEditingController(text: currentDepartment);
    TextEditingController positionController =
        TextEditingController(text: currentPosition);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Employee Data",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("Name", nameController),
              const SizedBox(height: 10),
              _buildTextField("Employee ID", employeeIdController),
              const SizedBox(height: 10),
              _buildTextField("Department", departmentController),
              const SizedBox(height: 10),
              _buildTextField("Position", positionController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await employeeCollection.doc(docId).update({
                'name': nameController.text,
                'employee_id': employeeIdController.text,
                'department': departmentController.text,
                'position': positionController.text,
              });
              Navigator.pop(context);
              _showSnackbar("Employee data updated successfully!", Colors.green);
            },
            child: const Text("Save",
                style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menghapus data employee
  void _deleteEmployeeData(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Employee Data",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this data?"),
        actions: [
          TextButton(
            onPressed: () async {
              await employeeCollection.doc(docId).delete();
              Navigator.pop(context);
              _showSnackbar("Employee data deleted successfully!", Colors.red);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("No", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Widget untuk membangun TextField pada dialog edit
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2D5D7C);
    const Color backgroundColor = Color(0xFFF5F5F5);
    const Color secondaryBackgroundColor = Color(0xFFEBEBEB);

    return Scaffold(
      backgroundColor: secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Employee Data",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: employeeCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data!.docs;
            return data.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      var docId = data[index].id;
                      var name = data[index]['name'] ?? 'No Name';
                      var employeeId = data[index]['employee_id'] ?? 'No ID';
                      var department =
                          data[index]['department'] ?? 'No Department';
                      var position =
                          data[index]['position'] ?? 'No Position';

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: backgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.primaries[
                                    Random().nextInt(Colors.primaries.length)],
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Name: $name",
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    Text("ID: $employeeId",
                                        style: const TextStyle(fontSize: 14)),
                                    Text("Department: $department",
                                        style: const TextStyle(fontSize: 14)),
                                    Text("Position: $position",
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blueAccent),
                                    onPressed: () => _editEmployeeData(
                                      docId,
                                      name,
                                      employeeId,
                                      department,
                                      position,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteEmployeeData(docId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      "No employee data available!",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
