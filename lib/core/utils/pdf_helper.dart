import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'snackbar_helper.dart';
import '../services/settings_service.dart';
import 'package:http/http.dart' as http;

class PdfHelper {
  static Future<void> generateExamResultPdf({
    required BuildContext context,
    required String paperTitle,
    required Map<String, dynamic> resultData,
    List<dynamic>? questions,
    String? studentName,
    String? admissionNumber,
  }) async {
    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
      );

      // Extract result data
      final score = resultData['score'];
      final total = resultData['total_questions'];
      final percentage = double.tryParse(resultData['percentage'].toString()) ?? 0.0;
      final isPass = percentage >= 50.0;
      final studentAnswers = resultData['student_answers'] ?? {};
      final String examDateRaw = resultData['created_at']?.toString() ?? DateTime.now().toString();
      final String examDate = examDateRaw.split('T')[0].split(' ')[0];

      // Fetch global settings
      final settings = await SettingsService.getSettings();
      final String companyName = settings['company_name'] ?? 'ALPHA GRAPHICS';
      final String companyAddress = settings['company_address'] ?? '';
      final String companyPhone = settings['company_phone'] ?? '';
      final String logoUrl = settings['logo_url'] ?? '';
      final String signatureUrl = settings['signature_url'] ?? '';

      // Force load logo from assets
      pw.MemoryImage? logoImage;
      try {
        final imageBytes = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
      } catch (e) {
        print("Could not load logo.png: $e");
      }

      pw.MemoryImage? signatureImage;
      if (signatureUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(signatureUrl));
          if (response.statusCode == 200) {
            signatureImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {}
      }

      String finalStudentName = studentName 
          ?? resultData['user']?['name']?.toString()
          ?? resultData['student_name']?.toString()
          ?? 'STUDENT';

      String finalAdmissionNo = admissionNumber 
          ?? resultData['user']?['registration_id']?.toString()
          ?? resultData['registration_id']?.toString()
          ?? 'N/A';

      // Fallback for Student portal where studentName might not be passed
      if (finalStudentName == 'STUDENT' || finalAdmissionNo == 'N/A') {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (finalStudentName == 'STUDENT') {
            final prefName = prefs.getString('user_name');
            if (prefName != null && prefName.isNotEmpty) finalStudentName = prefName;
          }
        } catch (_) {}
      }

      // Ensure we extract course and batch if available
      final courseName = resultData['course']?['name']?.toString() ?? 'N/A';
      final batchName = resultData['batch']?['name']?.toString() ?? 'N/A';
      final batchTime = resultData['batch']?['schedule_time']?.toString() ?? 'N/A';
      final examTime = examDateRaw.contains('T') ? examDateRaw.split('T')[1].substring(0, 5) : (examDateRaw.contains(' ') ? examDateRaw.split(' ')[1].substring(0, 5) : '12:00');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context ctx) {
            // Determine Grade
            String grade = 'F';
            if (percentage >= 90) grade = 'A+';
            else if (percentage >= 80) grade = 'A';
            else if (percentage >= 70) grade = 'B+';
            else if (percentage >= 60) grade = 'B';
            else if (percentage >= 50) grade = 'C';

            String performanceText = 'POOR';
            if (grade == 'A+' || grade == 'A') performanceText = 'EXCELLENT';
            else if (grade == 'B+' || grade == 'B') performanceText = 'GOOD';
            else if (isPass) performanceText = 'AVERAGE';

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header Background
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 24),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFF5158D7), // A solid blue-purple
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 50,
                          height: 50,
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                      pw.Text(
                        companyName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFF3F44B2),
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          paperTitle.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Student Details Card
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFF161E38),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF161E38), width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // The Badge
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 8, left: 8, bottom: 8),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFF5158D7),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text('STUDENT DETAILS', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      // Table Data
                      pw.Table(
                        border: const pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: PdfColors.grey800),
                          top: pw.BorderSide(color: PdfColors.grey800),
                        ),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(150),
                          1: const pw.FlexColumnWidth(),
                        },
                        children: [
                          _buildTableRow('Student Name', finalStudentName),
                          _buildTableRow('Admission No.', finalAdmissionNo),
                          _buildTableRow('Father\'s Name', 'Not Provided'),
                          _buildTableRow('Course', courseName),
                          _buildTableRow('Date & Time', '$examDate at $examTime'),
                          _buildTableRow('Batch', batchName),
                          _buildTableRow('Batch Timing', batchTime),
                        ]
                      )
                    ],
                  )
                ),
                pw.SizedBox(height: 12),

                // Performance Summary
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFF161E38),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 8, left: 8, bottom: 8),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFF5158D7),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text('PERFORMANCE SUMMARY', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8, right: 8, bottom: 8),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 12),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBox('MAX MARKS', total.toString(), const PdfColor.fromInt(0xFF335889)),
                              _buildVerticalDivider(),
                              _buildStatBox('PASS MARKS', (total * 0.5).toInt().toString(), const PdfColor.fromInt(0xFF2E7B53)),
                              _buildVerticalDivider(),
                              _buildStatBox('OBTAINED MARKS', score.toString(), const PdfColor.fromInt(0xFF7044A3)),
                              _buildVerticalDivider(),
                              _buildStatBox('PERCENTAGE', '${percentage.toStringAsFixed(2)}%', const PdfColor.fromInt(0xFFD68A3A)),
                            ],
                          ),
                        )
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // PERFORMANCE BANNER
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 20),
                  decoration: pw.BoxDecoration(
                    color: isPass ? const PdfColor.fromInt(0xFF1E9B79) : const PdfColor.fromInt(0xFFD9534F),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('PERFORMANCE', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, letterSpacing: 1.5)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        performanceText,
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2),
                      )
                    ]
                  ),
                ),
                pw.SizedBox(height: 12),

                // ABOUT SECTION
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFF161E38),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('About This Test Series', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF5158D7), fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'The $companyName Test Series is designed to provide students with comprehensive assessment of their knowledge and skills. This result reflects your performance in the test, highlighting areas of strength and opportunities for improvement. We are committed to supporting your academic growth with detailed feedback and resources.',
                        style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10, lineSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),

                // FOOTER
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Developed by', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Brolytics Technologies', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF5158D7), fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Container(width: 150, height: 1, color: const PdfColor.fromInt(0xFF5158D7)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Sanitize title and reg number for filename
      final safeTitle = paperTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final safeReg = finalAdmissionNo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = '${safeTitle}_${safeReg}_Result.pdf';

      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PDF Document', extensions: ['pdf']),
        ],
      );

      if (result != null) {
        String finalPath = result.path;
        File file = File(finalPath);

        // Check if file exists and auto-append (1), (2), etc.
        if (await file.exists()) {
          int counter = 1;
          String dir = file.parent.path;
          String nameWithoutExt = file.path.split('/').last;
          if (nameWithoutExt.endsWith('.pdf')) {
            nameWithoutExt = nameWithoutExt.substring(0, nameWithoutExt.length - 4);
          }
          
          while (await file.exists()) {
            finalPath = '$dir/$nameWithoutExt ($counter).pdf';
            file = File(finalPath);
            counter++;
          }
        }

        await file.writeAsBytes(await pdf.save());
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'PDF saved to ${result.path}');
        }
      } else {
        // User canceled the picker
        return;
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Failed to generate PDF: $e');
      }
    }
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const PdfColor.fromInt(0xFF161E38),
          child: pw.Text(label, style: pw.TextStyle(color: PdfColors.white, fontSize: 11)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: PdfColors.white,
          child: pw.Text(value, style: pw.TextStyle(color: PdfColors.black, fontSize: 11)),
        ),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: const PdfColor.fromInt(0xFF161E38), fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(value, style: pw.TextStyle(fontSize: 22, color: color, fontWeight: pw.FontWeight.bold)),
        ],
      )
    );
  }

  static pw.Widget _buildVerticalDivider() {
    return pw.Container(
      width: 1,
      height: 40,
      color: PdfColors.grey300,
    );
  }
}
