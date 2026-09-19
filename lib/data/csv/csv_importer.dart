import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'csv_parser.dart';

class PickedCsvFile {
  const PickedCsvFile({required this.filename, required this.bytes});

  final String filename;
  final Uint8List bytes;
}

class ImportFileOutcome {
  const ImportFileOutcome({
    required this.filename,
    required this.topicName,
    required this.imported,
    required this.duplicates,
    required this.skipped,
    this.error,
  });

  final String filename;
  final String topicName;
  final int imported;
  final int duplicates;
  final int skipped;
  final String? error;

  bool get ok => error == null;
}

class ImportSummary {
  const ImportSummary({required this.outcomes});

  final List<ImportFileOutcome> outcomes;

  int get filesOk => outcomes.where((o) => o.ok).length;
  int get cardsImported => outcomes.fold(0, (sum, o) => sum + o.imported);
  int get duplicates => outcomes.fold(0, (sum, o) => sum + o.duplicates);
}

class CsvImporter {
  Future<List<PickedCsvFile>?> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = <PickedCsvFile>[];
    for (final file in result.files) {
      final name = file.name;
      var bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (_) {
          bytes = null;
        }
      }
      if (bytes == null || bytes.isEmpty) continue;
      picked.add(
        PickedCsvFile(filename: name, bytes: Uint8List.fromList(bytes)),
      );
    }
    return picked;
  }

  CsvParseResult parseFile(PickedCsvFile file) {
    final text = CsvParser.decodeBytes(file.bytes);
    return CsvParser.parseCards(text);
  }
}
