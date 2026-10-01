import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/health_threshold.dart';
import '../models/user_profile.dart';
import '../models/vital_record.dart';

class PdfExportService {
  // Brand colors matched to AppColors
  static final PdfColor _primaryColor = PdfColor.fromInt(0xFF7C1334);
  static final PdfColor _normalColor = PdfColor.fromInt(0xFF2E7D32);
  static final PdfColor _warningColor = PdfColor.fromInt(0xFFF57F17);
  static final PdfColor _severeColor = PdfColor.fromInt(0xFFC62828);
  static final PdfColor _darkText = PdfColor.fromInt(0xFF212121);
  static final PdfColor _subText = PdfColor.fromInt(0xFF616161);
  static final PdfColor _cardBg = PdfColor.fromInt(0xFFF9F9F9);
  static final PdfColor _borderGrey = PdfColor.fromInt(0xFFE0E0E0);
  static final PdfColor _zebraBg = PdfColor.fromInt(0xFFFAFAFA);

  /// Generates the PDF document bytes for a specific user and their records
  static Future<Uint8List> generateReportBytes({
    required UserProfile? user,
    required List<VitalRecord> records,
    HealthThreshold? threshold,
    String filterLabel = 'All Records',
  }) async {
    final pdf = pw.Document(
      title: 'Vital Track Health Report - ${user?.fullName ?? "User"}',
      author: 'Vital Track System',
    );

    // Compute summary statistics
    final total = records.length;
    double avgTemp = 0;
    double avgSpo2 = 0;
    double avgHr = 0;
    int normalCount = 0;
    int warningCount = 0;
    int severeCount = 0;

    double minTemp = total > 0 ? records.first.temperature : 0;
    double maxTemp = total > 0 ? records.first.temperature : 0;
    double minSpo2 = total > 0 ? records.first.spo2 : 0;
    double maxSpo2 = total > 0 ? records.first.spo2 : 0;
    int minHr = total > 0 ? records.first.heartRate : 0;
    int maxHr = total > 0 ? records.first.heartRate : 0;

    if (total > 0) {
      double sumTemp = 0;
      double sumSpo2 = 0;
      int sumHr = 0;

      for (final r in records) {
        sumTemp += r.temperature;
        sumSpo2 += r.spo2;
        sumHr += r.heartRate;

        if (r.temperature < minTemp) minTemp = r.temperature;
        if (r.temperature > maxTemp) maxTemp = r.temperature;
        if (r.spo2 < minSpo2) minSpo2 = r.spo2;
        if (r.spo2 > maxSpo2) maxSpo2 = r.spo2;
        if (r.heartRate < minHr) minHr = r.heartRate;
        if (r.heartRate > maxHr) maxHr = r.heartRate;

        final sev = _getSeverity(r, threshold);
        if (sev == _RecordSeverity.severe) {
          severeCount++;
        } else if (sev == _RecordSeverity.warning) {
          warningCount++;
        } else {
          normalCount++;
        }
      }

      avgTemp = sumTemp / total;
      avgSpo2 = sumSpo2 / total;
      avgHr = sumHr / total;
    }

    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (pw.Context ctx) => _buildHeader(generatedAt),
        footer: (pw.Context ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) => [
          pw.SizedBox(height: 12),

          // User Information Card
          _buildUserCard(user, total, filterLabel),
          pw.SizedBox(height: 16),

          // Vitals Summary KPIs
          if (total > 0) ...[
            _buildSummaryKPIs(
              avgTemp: avgTemp,
              minTemp: minTemp,
              maxTemp: maxTemp,
              avgSpo2: avgSpo2,
              minSpo2: minSpo2,
              maxSpo2: maxSpo2,
              avgHr: avgHr,
              minHr: minHr,
              maxHr: maxHr,
              normalCount: normalCount,
              warningCount: warningCount,
              severeCount: severeCount,
            ),
            pw.SizedBox(height: 20),
          ],

          // Table Section Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'RECORDED VITALS LOG',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text(
                '$total record${total == 1 ? '' : 's'} listed',
                style: pw.TextStyle(fontSize: 10, color: _subText),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Detailed Records Table
          if (total == 0)
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'No vital records found for this period.',
                style: pw.TextStyle(fontSize: 13, color: _subText),
              ),
            )
          else
            _buildRecordsTable(records, threshold),

          pw.SizedBox(height: 20),

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _cardBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _borderGrey, width: 0.5),
            ),
            child: pw.Text(
              'Notice: This health log was exported directly from the user\'s Vital Track account. It is designed for personal wellness monitoring and tracking trends. Please consult a qualified medical professional for health evaluations and diagnosis.',
              style: pw.TextStyle(fontSize: 8.5, color: _subText, height: 1.3),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Opens the native layout / print / save dialog
  static Future<void> printOrSaveReport({
    required UserProfile? user,
    required List<VitalRecord> records,
    HealthThreshold? threshold,
    String filterLabel = 'All Records',
  }) async {
    final bytes = await generateReportBytes(
      user: user,
      records: records,
      threshold: threshold,
      filterLabel: filterLabel,
    );

    final fileName = 'vital_track_${user?.displayId ?? "report"}.pdf';
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }

  /// Shares the PDF file directly via platform share sheet
  static Future<void> shareReport({
    required UserProfile? user,
    required List<VitalRecord> records,
    HealthThreshold? threshold,
    String filterLabel = 'All Records',
  }) async {
    final bytes = await generateReportBytes(
      user: user,
      records: records,
      threshold: threshold,
      filterLabel: filterLabel,
    );

    final fileName = 'vital_track_${user?.displayId ?? "report"}.pdf';
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  // --- Sub-widgets for PDF ---

  static pw.Widget _buildHeader(DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VITAL TRACK',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Personal Health Monitoring Report',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _subText,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'CONFIDENTIAL MEDICAL REPORT',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${_formatDate(generatedAt)} ${_formatTime(generatedAt)}',
                style: pw.TextStyle(fontSize: 8.5, color: _subText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _borderGrey, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Vital Track Health System',
            style: pw.TextStyle(fontSize: 8, color: _subText),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _subText, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildUserCard(UserProfile? user, int totalRecords, String filterLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderGrey, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PATIENT INFORMATION',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _subText,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName : 'Vital Track User',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkText,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  user?.email ?? 'No email associated',
                  style: pw.TextStyle(fontSize: 9.5, color: _subText),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 1,
            height: 38,
            color: _borderGrey,
            margin: const pw.EdgeInsets.symmetric(horizontal: 14),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'USER ID CODE',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _subText,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  user?.displayId ?? 'N/A',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 1,
            height: 38,
            color: _borderGrey,
            margin: const pw.EdgeInsets.symmetric(horizontal: 14),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SCOPE / FILTER',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _subText,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  filterLabel,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkText,
                  ),
                ),
                pw.Text(
                  '$totalRecords scans',
                  style: pw.TextStyle(fontSize: 9.5, color: _subText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryKPIs({
    required double avgTemp,
    required double minTemp,
    required double maxTemp,
    required double avgSpo2,
    required double minSpo2,
    required double maxSpo2,
    required double avgHr,
    required int minHr,
    required int maxHr,
    required int normalCount,
    required int warningCount,
    required int severeCount,
  }) {
    return pw.Row(
      children: [
        _buildMetricBox(
          title: 'TEMPERATURE',
          avgValue: '${avgTemp.toStringAsFixed(1)} °C',
          range: 'Min: ${minTemp.toStringAsFixed(1)} | Max: ${maxTemp.toStringAsFixed(1)}',
          statusColor: _primaryColor,
        ),
        pw.SizedBox(width: 10),
        _buildMetricBox(
          title: 'BLOOD OXYGEN',
          avgValue: '${avgSpo2.toStringAsFixed(1)} %',
          range: 'Min: ${minSpo2.toStringAsFixed(0)}% | Max: ${maxSpo2.toStringAsFixed(0)}%',
          statusColor: _primaryColor,
        ),
        pw.SizedBox(width: 10),
        _buildMetricBox(
          title: 'HEART RATE',
          avgValue: '${avgHr.round()} BPM',
          range: 'Min: $minHr | Max: $maxHr',
          statusColor: _primaryColor,
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _cardBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _borderGrey, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HEALTH OVERVIEW',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _subText,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildOverviewRow('Normal', normalCount, _normalColor),
                _buildOverviewRow('Warning', warningCount, _warningColor),
                _buildOverviewRow('Severe', severeCount, _severeColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOverviewRow(String label, int count, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
              ),
              pw.SizedBox(width: 4),
              pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: _darkText)),
            ],
          ),
          pw.Text(
            count.toString(),
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricBox({
    required String title,
    required String avgValue,
    required String range,
    required PdfColor statusColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _cardBg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _borderGrey, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _subText,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              avgValue,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _darkText,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              range,
              style: pw.TextStyle(fontSize: 7.5, color: _subText),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildRecordsTable(List<VitalRecord> records, HealthThreshold? threshold) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: _borderGrey, width: 0.6),
        horizontalInside: pw.BorderSide(color: _borderGrey, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.6), // Timestamp
        1: pw.FlexColumnWidth(1.8), // Temperature
        2: pw.FlexColumnWidth(1.8), // SpO2
        3: pw.FlexColumnWidth(1.8), // Heart Rate
        4: pw.FlexColumnWidth(2.0), // Health Status
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryColor),
          children: [
            _buildTableHeaderCell('Date & Time'),
            _buildTableHeaderCell('Temperature'),
            _buildTableHeaderCell('SpO2'),
            _buildTableHeaderCell('Heart Rate'),
            _buildTableHeaderCell('Status'),
          ],
        ),
        // Data Rows
        ...records.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final isEven = i % 2 == 0;
          final severity = _getSeverity(r, threshold);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _zebraBg),
            children: [
              _buildTableCell(
                '${_formatDate(r.recordedAt)} ${_formatTime(r.recordedAt)}',
                isBold: false,
              ),
              _buildTableCell(
                '${r.temperature.toStringAsFixed(1)} °C',
                textColor: _getMetricColor(
                  r.temperature,
                  min: 36.5,
                  max: threshold?.maxTemp ?? 37.8,
                ),
              ),
              _buildTableCell(
                '${r.spo2.toStringAsFixed(1)} %',
                textColor: r.spo2 >= (threshold?.minSpo2 ?? 94.0)
                    ? _normalColor
                    : (r.spo2 >= 90.0 ? _warningColor : _severeColor),
              ),
              _buildTableCell(
                '${r.heartRate} BPM',
                textColor: (r.heartRate >= (threshold?.minHr ?? 50) &&
                        r.heartRate <= (threshold?.maxHr ?? 120))
                    ? _normalColor
                    : _severeColor,
              ),
              _buildStatusBadge(severity),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? _darkText,
        ),
      ),
    );
  }

  static pw.Widget _buildStatusBadge(_RecordSeverity severity) {
    PdfColor bg;
    PdfColor textCol;
    String label;

    switch (severity) {
      case _RecordSeverity.normal:
        bg = PdfColor.fromInt(0xFFE8F5E9);
        textCol = _normalColor;
        label = 'Normal';
        break;
      case _RecordSeverity.warning:
        bg = PdfColor.fromInt(0xFFFFF3E0);
        textCol = _warningColor;
        label = 'Attention';
        break;
      case _RecordSeverity.severe:
        bg = PdfColor.fromInt(0xFFFFEBEE);
        textCol = _severeColor;
        label = 'Critical';
        break;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: textCol,
          ),
        ),
      ),
    );
  }

  static _RecordSeverity _getSeverity(VitalRecord r, HealthThreshold? threshold) {
    final maxT = threshold?.maxTemp ?? 37.8;
    final minSp = threshold?.minSpo2 ?? 94.00;
    final minH = threshold?.minHr ?? 50;
    final maxH = threshold?.maxHr ?? 120;

    final isSevere = r.temperature < 35.0 ||
        r.temperature > (maxT + 0.7) ||
        r.spo2 < 90 ||
        r.heartRate < minH ||
        r.heartRate > maxH;

    if (isSevere) return _RecordSeverity.severe;

    final isWarning = (r.temperature >= 35.0 && r.temperature < 36.5) ||
        (r.temperature > 37.5 && r.temperature <= maxT) ||
        (r.spo2 >= 90 && r.spo2 < minSp) ||
        (r.heartRate >= minH && r.heartRate < minH + 10) ||
        (r.heartRate > maxH - 20 && r.heartRate <= maxH) ||
        !r.isNormal;

    if (isWarning) return _RecordSeverity.warning;
    return _RecordSeverity.normal;
  }

  static PdfColor _getMetricColor(double val, {required double min, required double max}) {
    if (val >= min && val <= max) return _normalColor;
    if (val > max + 0.7 || val < min - 1.5) return _severeColor;
    return _warningColor;
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    return '$d/$m/$y';
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final min = local.minute.toString().padLeft(2, '0');
    final p = local.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$min $p';
  }
}

enum _RecordSeverity { normal, warning, severe }
