import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';  // 暂时禁用
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../features/diary/data/models/diary_entry.dart';
import '../../shared/widgets/diary_card.dart';

/// PDF 导出服务
class PdfExportService {
  /// 导出单篇日记为 PDF
  Future<Uint8List> exportDiaryToPdf(DiaryEntry diary) async {
    final pdf = await _createPdfDocument();
    final page = _buildDiaryPage(diary);
    pdf.addPage(page);
    return pdf.save();
  }

  /// 导出多篇日记为 PDF
  Future<Uint8List> exportDiariesToPdf(List<DiaryEntry> diaries) async {
    final pdf = await _createPdfDocument();

    for (final diary in diaries) {
      final page = _buildDiaryPage(diary);
      pdf.addPage(page);
    }

    return pdf.save();
  }

  /// 创建 PDF 文档
  Future<pw.Document> _createPdfDocument() async {
    return pw.Document(
      title: '留白日记',
      author: 'WhiteSpace App',
      creator: 'WhiteSpace',
    );
  }

  /// 构建日记页面
  pw.MultiPage _buildDiaryPage(DiaryEntry diary) {
    final mood = Mood.values[diary.moodIndex];
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        // 标题
        if (diary.title != null && diary.title!.isNotEmpty)
          pw.Text(
            diary.title!,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          )
        else
          pw.Text(
            '无标题',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),

        pw.SizedBox(height: 16),

        // 日期和心情
        pw.Row(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo100,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(
                dateFormat.format(diary.createdAt),
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.indigo800,
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber100,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(
                '${mood.emoji} ${mood.label}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.amber900,
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 8),

        // 天气
        if (diary.weatherIndex != null) ...[
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  '${Weather.values[diary.weatherIndex!].emoji} ${Weather.values[diary.weatherIndex!].label}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
        ],

        // 标签
        if (diary.tags.isNotEmpty) ...[
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: diary.tags.map((tag) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  '#$tag',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.green800,
                  ),
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 16),
        ],

        pw.Divider(color: PdfColors.grey300),

        pw.SizedBox(height: 16),

        // 内容
        pw.Text(
          diary.content,
          style: const pw.TextStyle(
            fontSize: 14,
            lineSpacing: 6,
            color: PdfColors.grey800,
          ),
        ),

        pw.SizedBox(height: 24),

        // 图片
        if (diary.images.isNotEmpty) ...[
          pw.Text(
            '图片',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: diary.images.map((path) {
              return _buildImageWidget(path);
            }).toList(),
          ),
        ],

        pw.SizedBox(height: 40),

        // 页脚
        pw.Divider(color: PdfColors.grey200),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            '留白日记 · 记录生活的美好',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建图片组件
  pw.Widget _buildImageWidget(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final image = pw.MemoryImage(bytes);
        return pw.Container(
          width: 150,
          height: 150,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(image, fit: pw.BoxFit.cover),
          ),
        );
      }
    } catch (e) {
      // 忽略错误
    }
    return pw.Container(
      width: 150,
      height: 150,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text('📷', style: const pw.TextStyle(fontSize: 32)),
      ),
    );
  }

  /// 打印日记
  /// 注意：printing 包已禁用，此功能暂时不可用
  Future<void> printDiary(DiaryEntry diary) async {
    throw UnimplementedError('打印功能已禁用');
  }

  /// 打印多篇日记
  /// 注意：printing 包已禁用，此功能暂时不可用
  Future<void> printDiaries(List<DiaryEntry> diaries) async {
    throw UnimplementedError('打印功能已禁用');
  }

  /// 分享日记 PDF
  Future<void> shareDiary(DiaryEntry diary) async {
    final bytes = await exportDiaryToPdf(diary);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/diary_${diary.id}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: diary.title ?? '日记',
    );
  }

  /// 分享多篇日记 PDF
  Future<void> shareDiaries(List<DiaryEntry> diaries) async {
    final bytes = await exportDiariesToPdf(diaries);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/diaries_$timestamp.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '日记导出',
    );
  }

  /// 保存日记 PDF 到文件
  Future<String?> saveDiaryPdf(DiaryEntry diary) async {
    final bytes = await exportDiaryToPdf(diary);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/diary_${diary.id}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}