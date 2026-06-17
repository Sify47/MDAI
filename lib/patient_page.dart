import 'package:flutter/material.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  List<List<String>> patients = [
    ['John Doe', '30', 'Flu'],
    ['Jane Smith', '25', 'Cold'],
    ['Alice Johnson', '40', 'Diabetes'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Page')),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return ListTile(
            title: Text(patient[0]),
            subtitle: Text('Age: ${patient[1]}, Condition: ${patient[2]}'),
          );
        },
      ),
    );
  }
}
