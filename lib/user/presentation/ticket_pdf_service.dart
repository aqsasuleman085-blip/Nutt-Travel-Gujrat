import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:nutt/admin_side/models/booking_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ticket_qr_data.dart';

class TicketPdfResult {
  final bool success;
  final String message;
  final String? filePath;

  TicketPdfResult({required this.success, required this.message, this.filePath});
}

/// Generates a downloadable PDF for a reservation - one page per seat,
/// covering the root booking plus every "Add More Seats" addon linked to
/// it, each page carrying that seat's own QR code and the shared
/// passenger/payment details. Saves directly to device storage (no
/// share-sheet), requesting storage permission first where needed.
class TicketPdfService {
  static const _emerald = PdfColor.fromInt(0xff10B981);

  /// Renders a QR code to PNG bytes so it can be embedded in the PDF (the
  /// `pdf` package can't draw Flutter widgets directly, so the QR has to
  /// be rasterized first via qr_flutter's painter).
  Future<Uint8List> _qrToPngBytes(String data, {double size = 300}) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    final picData = await painter.toImageData(size);
    return picData!.buffer.asUint8List();
  }

  /// Builds and saves the PDF. [bookings] should be the full reservation
  /// (root + addons) - one page is generated per individual seat across
  /// all of them.
  Future<TicketPdfResult> generateAndSave(List<BookingModel> bookings) async {
    try {
      // Request storage permission on Android (harmless no-op on newer
      // Android/iOS where it's not required for app-accessible dirs, but
      // needed on older Android to write to shared storage).
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final pdf = pw.Document();

      // Every seat across the root + all addon bookings becomes its own
      // page, all sharing the same passenger/payment details.
      for (final booking in bookings) {
        final seats = booking.seatNumber.split(',').map((s) => s.trim());
        for (final seat in seats) {
          final qrData = buildTicketQrData(booking, seat: seat);
          final qrBytes = await _qrToPngBytes(qrData);
          final qrImage = pw.MemoryImage(qrBytes);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a5,
              margin: const pw.EdgeInsets.all(24),
              build: (context) => _buildTicketPage(booking, seat, qrImage),
            ),
          );
        }
      }

      final bytes = await pdf.save();

      // Save to a public/downloads-accessible directory.
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) {
        return TicketPdfResult(
          success: false,
          message: 'Could not access device storage.',
        );
      }

      final bookingNumber = bookings.first.bookingNumber.isNotEmpty
          ? bookings.first.bookingNumber
          : bookings.first.id.substring(0, 6);
      final fileName = 'NuttTravel_Ticket_$bookingNumber.pdf';
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return TicketPdfResult(
        success: true,
        message: 'Ticket saved to ${file.path}',
        filePath: file.path,
      );
    } catch (e) {
      return TicketPdfResult(
        success: false,
        message: 'Failed to generate PDF: $e',
      );
    }
  }

  pw.Widget _buildTicketPage(
    BookingModel booking,
    String seat,
    pw.MemoryImage qrImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header strip
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const pw.BoxDecoration(color: _emerald),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'NUTT TRAVEL',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    booking.bookingNumber.isNotEmpty
                        ? booking.bookingNumber
                        : 'Ticket ${booking.id.substring(0, 6).toUpperCase()}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'Seat $seat',
                  style: pw.TextStyle(
                    color: _emerald,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // QR code, centered
        pw.Center(
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Image(qrImage, width: 130, height: 130),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Scan to verify this ticket',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 18),

        _sectionTitle('PASSENGER INFORMATION'),
        _row('Passenger Name', booking.userName),
        _row('Phone', booking.phone),
        _row('CNIC', booking.cnic),
        _row('Gender', booking.gender.isEmpty ? 'N/A' : booking.gender),

        pw.SizedBox(height: 12),
        _sectionTitle('JOURNEY DETAILS'),
        _row('Route', '${booking.busFrom} -> ${booking.busTo}'),
        _row('Seat Number', seat),
        _row('Travel Date', booking.travelDate),
        _row('Departure Time', booking.time.isNotEmpty ? booking.time : 'N/A'),

        pw.SizedBox(height: 12),
        _sectionTitle('PAYMENT INFORMATION'),
        _row('Ticket Price', 'Rs ${booking.price.toStringAsFixed(0)}'),
        _row('Payment Method', booking.paymentMethod),
        if (booking.senderName.isNotEmpty)
          _row('Account Name', booking.senderName),
        if (booking.senderNumber.isNotEmpty)
          _row('Account Number', booking.senderNumber),

        pw.Spacer(),
        pw.Divider(color: PdfColors.grey300),
        pw.Center(
          child: pw.Text(
            'This is a computer-generated e-ticket. Present the QR code '
            'above when boarding.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
