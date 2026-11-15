import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportFileResult {
  const ExportFileResult({
    required this.isSuccess,
    this.filePath,
    this.errorMessage,
    this.isCanceled = false,
  });

  final bool isSuccess;
  final String? filePath;
  final String? errorMessage;
  final bool isCanceled;
}

abstract interface class PlatformFileService {
  Future<String?> pickBackupJsonFile();
  Future<ExportFileResult> exportBackupFile({
    required String fileName,
    required String jsonContent,
  });
}

class PlatformFileServiceImpl implements PlatformFileService {
  @override
  Future<String?> pickBackupJsonFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (file == null) {
        return null; // User cancelled
      }

      return await file.xFile.readAsString();
    } catch (e) {
      throw Exception('Failed to read selected backup file: $e');
    }
  }

  @override
  Future<ExportFileResult> exportBackupFile({
    required String fileName,
    required String jsonContent,
  }) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(jsonContent));

      // On desktop platforms (Windows/Linux/macOS), prompt native Save File dialog
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final saveUri = await FilePicker.saveFile(
          dialogTitle: 'Save Attendly Backup',
          fileName: fileName,
          bytes: bytes,
          mimeType: 'application/json',
        );
        if (saveUri == null) {
          return const ExportFileResult(isSuccess: false, isCanceled: true);
        }
        return ExportFileResult(
          isSuccess: true,
          filePath: saveUri.scheme == 'file'
              ? saveUri.toFilePath()
              : saveUri.toString(),
        );
      }

      // On mobile platforms (Android/iOS), save to temp directory and open native share/save sheet
      final tempDir = await getTemporaryDirectory();
      final backupFilePath =
          '${tempDir.path}${Platform.pathSeparator}$fileName';
      final file = File(backupFilePath);
      await file.writeAsBytes(bytes, flush: true);

      final xFile = XFile(
        file.path,
        mimeType: 'application/json',
        name: fileName,
      );

      final shareResult = await Share.shareXFiles(
        [xFile],
        text: 'Attendly Attendance Backup',
        subject: fileName,
      );

      return ExportFileResult(
        isSuccess: true,
        filePath: file.path,
        isCanceled: shareResult.status == ShareResultStatus.dismissed,
      );
    } catch (e) {
      return ExportFileResult(isSuccess: false, errorMessage: e.toString());
    }
  }
}

final platformFileServiceProvider = Provider<PlatformFileService>((ref) {
  return PlatformFileServiceImpl();
});
