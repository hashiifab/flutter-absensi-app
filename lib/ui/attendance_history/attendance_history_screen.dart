import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  // Controller dan variabel untuk search & filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Entered', 'Late', 'Exited'];

  void _editData(String docId, Map<String, dynamic> docData) {
    TextEditingController nameController =
        TextEditingController(text: docData['name'] ?? '');
    TextEditingController descriptionController = TextEditingController(
        text: docData.containsKey('description') ? docData['description'] : '');
    TextEditingController datetimeController =
        TextEditingController(text: docData['datetime'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Data",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField("Name", nameController),
            const SizedBox(height: 10),
            _buildTextField("Description", descriptionController),
            const SizedBox(height: 10),
            _buildTextField("Datetime", datetimeController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await dataCollection.doc(docId).update({
                'name': nameController.text,
                'description': descriptionController.text,
                'datetime': datetimeController.text,
              });
              Navigator.pop(context);
              _showSnackbar("Data updated successfully!", Colors.green);
            },
            child: const Text("Save", style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _deleteData(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Data",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure want to delete this data?"),
        actions: [
          TextButton(
            onPressed: () async {
              await dataCollection.doc(docId).delete();
              Navigator.pop(context);
              _showSnackbar("Data deleted successfully!", Colors.red);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Widget untuk Search Bar dan Filter Dropdown
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search by name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _selectedFilter,
            items: _filterOptions
                .map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    ))
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
          ),
        ],
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
        elevation: 2,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Attendance History",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: dataCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                  
                  // Lakukan filtering berdasarkan search query
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name']?.toString().toLowerCase() ?? '';
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }
                  
                  // Lakukan filtering berdasarkan dropdown filter
                  if (_selectedFilter != 'All') {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final description = data.containsKey('description') ? data['description'] : '';
                      return description == _selectedFilter;
                    }).toList();
                  }
                  
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No data available!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Karena stream Firestore sudah realtime, cukup delay sejenak.
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var docId = docs[index].id;
                        var docData = docs[index].data() as Map<String, dynamic>;
                        var name = docData['name'] ?? 'No Name';
                        var description = docData.containsKey('description')
                            ? docData['description']
                            : 'No Description';
                        var datetime = docData['datetime'] ?? 'No Timestamp';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  backgroundColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '',
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Name: $name", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      Text("Description: $description", style: const TextStyle(fontSize: 14)),
                                      Text("Timestamp: $datetime", style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                      onPressed: () => _editData(docId, docData),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteData(docId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
