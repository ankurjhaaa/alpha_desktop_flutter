import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'snackbar_helper.dart';

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

      pw.MemoryImage? logoImage;
      try {
        final imageBytes = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
      } catch (e) {
        // Fallback if logo cannot be loaded
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

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) {
            // Determine Grade
            String grade = 'F';
            if (percentage >= 90) grade = 'A+';
            else if (percentage >= 80) grade = 'A';
            else if (percentage >= 70) grade = 'B+';
            else if (percentage >= 60) grade = 'B';
            else if (percentage >= 50) grade = 'C';

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Region
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover),
                        ),
                      )
                    else
                      pw.Container(width: 60, height: 60),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ALPHA GRAPHICS',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'STATEMENT OF MARKS',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Student Details Rounded Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailRow('Student Name:', finalStudentName.toUpperCase()),
                          _buildDetailRow('Registration No:', finalAdmissionNo.isNotEmpty ? finalAdmissionNo : 'N/A'),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailRow('Examination:', 'Computer Based Test (CBT)'),
                          _buildDetailRow('Date:', examDate),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Minimalist Marksheet Table
                pw.Text(
                  'ACADEMIC PERFORMANCE',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      // Table Header
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(flex: 3, child: pw.Text('Subject', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Expanded(flex: 1, child: pw.Text('Max', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Expanded(flex: 1, child: pw.Text('Pass', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Expanded(flex: 1, child: pw.Text('Obtained', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Expanded(flex: 1, child: pw.Text('Grade', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                          ],
                        ),
                      ),
                      pw.Divider(height: 1, color: PdfColors.grey300),
                      // Data Row
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: pw.Row(
                          children: [
                            pw.Expanded(flex: 3, child: pw.Text(paperTitle, style: const pw.TextStyle(fontSize: 12))),
                            pw.Expanded(flex: 1, child: pw.Text(total.toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
                            pw.Expanded(flex: 1, child: pw.Text((total * 0.5).toInt().toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
                            pw.Expanded(flex: 1, child: pw.Text(score.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                            pw.Expanded(flex: 1, child: pw.Text(grade, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isPass ? PdfColors.green700 : PdfColors.red700))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Overall Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: isPass ? PdfColors.green50 : PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Overall Percentage', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('${percentage.toStringAsFixed(2)}%', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Final Status', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            isPass ? "PASS" : "FAIL",
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: isPass ? PdfColors.green700 : PdfColors.red700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 8),
                        pw.Text(examDate, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                        pw.Text('Date', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 8),
                        pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Sanitize title for filename
      final safeTitle = paperTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = '${safeTitle}_Result.pdf';

      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PDF Document', extensions: ['pdf']),
        ],
      );

      if (result != null) {
        final file = File(result.path);
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

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey900),
        ),
      ),
    );
  }
}
