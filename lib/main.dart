import 'dart:html' as html;
import 'dart:typed_data';
import 'resource.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for rootBundle
import 'package:pdf/pdf.dart' as pdfLib;
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfPdf;
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

import 'signpdf.dart';

void main() {
  runApp(
    // Wrap the app with ChangeNotifierProvider to provide Resource globally
    ChangeNotifierProvider(
        create: (context) => resource(), child: StudentMarksheetApp()),
  );
}

class StudentMarksheetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Digital Sign App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: MarksheetHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MarksheetHomePage extends StatefulWidget {
  @override
  _MarksheetHomePageState createState() => _MarksheetHomePageState();
}

class _MarksheetHomePageState extends State<MarksheetHomePage> {
  String studentId = '';
  Map<String, dynamic>? studentData;
  Uint8List? excelBytes;
  Uint8List? pdfBytes;
  int permissionAttempts = 0;
  final int maxAttempts = 3;
  final String correctPermissionKey = "1234";

  Future<void> loadExcelFromAssets() async {
    // Load the file from assets
    ByteData data = await rootBundle.load('assets/yash.xlsx');

    // Convert to Uint8List
    excelBytes = data.buffer.asUint8List();

    // Decode the Excel
    var excel = Excel.decodeBytes(excelBytes!);

    // Print Excel content
    for (var table in excel.tables.keys) {
      print('Table: $table');
      for (var row in excel.tables[table]!.rows) {
        print(row.map((cell) => cell?.value)); // Print each row
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadExcelFromAssets();
  }

  void fetchData() {
    if (excelBytes == null || studentId.isEmpty) return;
    final excel = Excel.decodeBytes(excelBytes!);
    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      for (var row in rows.skip(1)) {
        if (row.isNotEmpty &&
            row[0]?.value.toString().trim() == studentId.trim()) {
          setState(() {
            studentData = {
              'ID': row[0]?.value.toString(),
              'Name': row[1]?.value.toString(),
              'Subject1': row[2]?.value.toString(),
              'Subject2': row[3]?.value.toString(),
              'Subject3': row[4]?.value.toString(),
              'Subject4': row[5]?.value.toString(),
              'Subject5': row[6]?.value.toString(),
              'Subject6': row[7]?.value.toString(),
              'Average': row[8]?.value.toString(),
            };
          });
          return;
        }
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Student ID not found')));
  }

  void generatePDF() async {
    if (studentData == null) return;

    final pdf = pw.Document();
    print("Generating PDF for student");

    // Load the signature image as Uint8List
    final imageData = await rootBundle.load('assets/signature.jpg');
    final signatureImage = pw.MemoryImage(imageData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: pdfLib.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "Student Marksheet",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: pdfLib.PdfColors.indigo,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "ID: ${studentData!['ID']}",
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  "Name: ${studentData!['Name']}",
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Subject 1: ${studentData!['Subject1']}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Subject 2: ${studentData!['Subject2']}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Subject 3: ${studentData!['Subject3']}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Subject 4: ${studentData!['Subject4']}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Subject 5: ${studentData!['Subject5']}",
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.Text(
                  "Subject 6: ${studentData!['Subject6']}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Average: ${studentData!['Average']}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "✉ Digitally Signed",
                    style: pw.TextStyle(
                      color: pdfLib.PdfColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                // Signature image at the bottom right
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Image(signatureImage, width: 100, height: 50),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save the PDF as bytes
    final pdfBytes = await pdf.save();
    Provider.of<resource>(
      context,
      listen: false,
    ).setpdfdetails(pdfBytes);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DigitalSignaturePage()),
    );

    // Download the PDF in Flutter web
    //  final blob = html.Blob([pdfBytes]);
    //   final url = html.Url.createObjectUrlFromBlob(blob);
    //   html.AnchorElement(href: url)
    //     ..setAttribute("download", "signed_file.pdf")
    //     ..click();
    //   html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Digital Sign App'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 137, 147, 203),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25),
            Text(
              'Enter Defualt Student ID as 1001 to Fetch Data',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Student ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => studentId = value,
            ),
            SizedBox(height: 16),
            ElevatedButton(
                onPressed: fetchData,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.indigo.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Fetch Data')),
            SizedBox(height: 20),
            if (studentData != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${studentData!['ID']}'),
                      Text('Name: ${studentData!['Name']}'),
                      Text('Subject 1: ${studentData!['Subject1']}'),
                      Text('Subject 2: ${studentData!['Subject2']}'),
                      Text('Subject 3: ${studentData!['Subject3']}'),
                      Text('Subject 4: ${studentData!['Subject4']}'),
                      Text('Subject 5: ${studentData!['Subject5']}'),
                      Text('Subject 6: ${studentData!['Subject6']}'),
                      Text('Average: ${studentData!['Average']}'),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: generatePDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Go To Download File',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
