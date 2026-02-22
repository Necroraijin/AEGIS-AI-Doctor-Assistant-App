import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ReportGenerator {
  static Future<void> generateAndOpenReport({
    required String doctorName,
    required String specialty,
    required String patientName,
    required String reportContent,
    required String date,
    String? patientFaceUrl,
    String? scanImageUrl,
  }) async {
    String scansHtml = "";
    if (scanImageUrl != null && scanImageUrl.isNotEmpty) {
      scansHtml =
          """
        <div class="section-title">ATTACHED CLINICAL IMAGING</div>
        <div class="image-container">
          <img src="$scanImageUrl" alt="Clinical Scan" />
        </div>
      """;
    }

    String faceHtml = "";
    if (patientFaceUrl != null && patientFaceUrl.isNotEmpty) {
      faceHtml =
          """<img src="$patientFaceUrl" style="width: 80px; height: 80px; border-radius: 40px; object-fit: cover; border: 2px solid #1B5AF0;" />""";
    }

    String htmlContent =
        """
      <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
      <head>
        <meta charset="utf-8">
        <title>Medical Report</title>
        <style>
          body { font-family: Arial, sans-serif; font-size: 11pt; line-height: 1.6; color: #1A1A1A; word-wrap: break-word; overflow-wrap: break-word; max-width: 100%; }
          .header { width: 100%; border-bottom: 2px solid #1B5AF0; padding-bottom: 10px; margin-bottom: 20px; }
          .header h1 { color: #1B5AF0; margin: 0; font-size: 24pt; }
          .details-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
          .details-table td { vertical-align: top; padding-right: 15px; }
          .label { font-size: 9pt; font-weight: bold; color: #7F8C8D; text-transform: uppercase; }
          .section-title { font-size: 12pt; font-weight: bold; color: #2C3E50; border-bottom: 1px solid #BDC3C7; padding-bottom: 5px; margin-top: 30px; margin-bottom: 15px; text-transform: uppercase; }
          .content { white-space: pre-wrap; text-align: justify; } 
          .image-container { text-align: center; margin-top: 20px; margin-bottom: 20px; }
          .image-container img { max-width: 100%; height: auto; border: 1px solid #BDC3C7; padding: 4px; }
          .signature-box { margin-top: 40px; text-align: right; }
          .footer { margin-top: 50px; font-size: 9pt; color: #95A5A6; text-align: center; border-top: 1px solid #ECF0F1; padding-top: 15px; }
        </style>
      </head>
      <body>
      
        <div class="header">
          <h1>CLINICAL REPORT</h1>
          <span style="font-size: 10pt; color: #7F8C8D;">Generated securely by Aegis Medical OS</span>
        </div>

        <table class="details-table">
          <tr>
            <td style="width: 60%;">
              <div class="label">Patient Details</div>
              <b>Name:</b> $patientName<br>
              <b>Date:</b> $date<br>
              <b>Report ID:</b> #${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}
            </td>
            <td style="width: 40%; text-align: right;">
              $faceHtml
            </td>
          </tr>
        </table>

        <div class="section-title">Clinical Findings & Summary</div>
        <div class="content">$reportContent</div>

        $scansHtml

        <div class="signature-box">
          <p style="font-size: 12pt; font-weight: bold; color: #2C3E50;">Attending Doctor - $doctorName</p>
          <p style="font-style: italic; color: #7F8C8D; font-size: 10pt;">$specialty</p>
        </div>

        <div class="footer">
          <p>CONFIDENTIAL: This document contains protected health information (PHI).<br>Aegis Medical Systems</p>
        </div>

      </body>
      </html>
    """;

    try {
      final directory = await getApplicationDocumentsDirectory();
      String safeName = patientName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final String filePath = "${directory.path}/Aegis_Report_${safeName}.doc";

      final File file = File(filePath);
      await file.writeAsString(htmlContent);
      await OpenFile.open(filePath);
    } catch (e) {
      print("Error generating report: $e");
    }
  }
}
