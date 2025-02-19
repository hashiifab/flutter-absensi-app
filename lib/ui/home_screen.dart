import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          SizedBox(
            height: 50,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.blueAccent,
                centerTitle: true,
                title: const Text(
                  "Attendance - Flutter App Admin",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  // efect when click
                  child: InkWell(
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                          image: AssetImage('assets/images/ic_absen.png'),
                          height: 100,
                          width: 100,
                        ),
                        Text(
                          "Attendance Record",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                          image: AssetImage('assets/images/ic_leave.png'),
                          height: 100,
                          width: 100,
                        ),
                        Text(
                          "Permission",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                          image: AssetImage('assets/images/ic_history.png'),
                          height: 100,
                          width: 100,
                        ),
                        Text(
                          "Attendance History",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          SizedBox(
            height: 50,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.blueAccent,
                centerTitle: true,
                title: const Text(
                  "IDN Boarding School Solo",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
