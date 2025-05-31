import 'dart:html' as html;
import 'dart:typed_data';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'resource.dart';

class DigitalSignaturePage extends StatefulWidget {
  @override
  _DigitalSignaturePageState createState() => _DigitalSignaturePageState();
}

class _DigitalSignaturePageState extends State<DigitalSignaturePage> {
  Uint8List? latestSignedFileBytes;
  Uint8List? pdfBytes;
  int permissionAttempts = 0;
  final int maxAttempts = 3;
  final String correctPermissionKey =
      "1234"; // Change this to your permission key

  Future<void> pickPDF() async {
    // pdfBytes = result.files.single.bytes!;
    setState(() {
      latestSignedFileBytes = null; // reset on new upload
      permissionAttempts = 0;
    });
    // Ask permission key
    _askPermissionKey();
  }

  Future<void> _askPermissionKey() async {
    while (permissionAttempts < maxAttempts) {
      String? enteredKey = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          String input = '';
          return AlertDialog(
            title: Text('Enter Permission Key'),
            content: TextField(
              autofocus: true,
              onChanged: (value) => input = value,
              decoration: InputDecoration(hintText: 'Permission Key'),
              obscureText: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(input),
                child: Text('Submit'),
              ),
            ],
          );
        },
      );

      if (enteredKey == null) {
        // User cancelled
        break;
      }

      if (enteredKey == correctPermissionKey) {
        // Permission granted - sign and download
        pdfBytes = Provider.of<resource>(context, listen: false).pdfBytes;
        await signAndDownloadPDF();
        return;
      } else {
        permissionAttempts++;
        if (permissionAttempts < maxAttempts) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Incorrect key. Attempts left: ${maxAttempts - permissionAttempts}')),
          );
        }
      }
    }

    // If here, attempts exceeded
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Permission denied. Please re-upload the file.')),
    );
    setState(() {
      pdfBytes = null; // reset pdfBytes to force re-upload
    });
  }

  Future<void> signAndDownloadPDF() async {
    if (pdfBytes == null) return;

    // Load PDF document
    PdfDocument document = PdfDocument(inputBytes: pdfBytes!);

    // Load the signature image
    ByteData imageData = await rootBundle.load('assets/signature.jpg');
    Uint8List imageBytes = imageData.buffer.asUint8List();
    PdfBitmap signatureImage = PdfBitmap(imageBytes);

    // Draw signature on first page
    document.pages[0].graphics.drawImage(
      signatureImage,
      Rect.fromLTWH(250, 700, 100, 50),
    );

    // Save signed PDF
    List<int> signedPdfBytes = await document.save();
    document.dispose();

    setState(() {
      latestSignedFileBytes = Uint8List.fromList(signedPdfBytes);
    });

    // Trigger download
    final blob = html.Blob([Uint8List.fromList(signedPdfBytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "signed_file.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Digital Signature Access')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickPDF,
              style: ElevatedButton.styleFrom(
                // backgroundColor: Colors.indigo.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Downlaod File with Permission Key',
                  style: TextStyle(fontSize: 14)),
            ),
            SizedBox(height: 30),
            if (latestSignedFileBytes != null) ...[
              Icon(Icons.check_circle, color: Colors.green, size: 40),
              SizedBox(height: 10),
              Text(
                "Signed PDF downloaded successfully!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
            if (pdfBytes == null) ...[
              SizedBox(height: 20),
              Text("Please upload a PDF file to start."),
            ],
          ],
        ),
      ),
    );
  }
}
