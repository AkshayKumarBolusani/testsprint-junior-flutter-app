import 'package:excel/excel.dart';

import '../../../core/constants/domain_constants.dart';

class ImportRowError {
  const ImportRowError({
    required this.row,
    required this.errorType,
    required this.field,
    required this.message,
  });

  final int row;
  final String errorType;
  final String field;
  final String message;
}

class QuestionExcelImport {
  static const headers = [
    'questionText',
    'questionType',
    'optionA',
    'optionB',
    'optionC',
    'optionD',
    'correctAnswer',
    'classLevel',
    'syllabus',
    'subjectId',
    'difficulty',
    'needsReview',
  ];

  static Excel buildTemplateWorkbook() {
    final book = Excel.createExcel();
    const targetSheet = 'Questions';
    var sheetName = book.getDefaultSheet() ?? book.tables.keys.first;
    if (sheetName != targetSheet) {
      book.rename(sheetName, targetSheet);
      sheetName = targetSheet;
    }
    final sheet = book[sheetName];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value =
          TextCellValue(headers[c]);
    }
    final sample = [
      'What is 5 + 7?',
      'MCQ',
      '10',
      '12',
      '14',
      '22',
      '12',
      '5th',
      'CBSE',
      'PASTE_SUBJECT_MONGO_ID',
      'easy',
      'false',
    ];
    for (var c = 0; c < sample.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1)).value =
          TextCellValue(sample[c]);
    }
    return book;
  }

  static String _cellText(Data? cell) {
    if (cell == null) return '';
    final v = cell.value;
    if (v == null) return '';
    if (v is TextCellValue) {
      return (v.value.text ?? v.toString()).trim();
    }
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is BoolCellValue) return v.value ? 'true' : 'false';
    return v.toString().trim();
  }

  static ({List<Map<String, dynamic>> items, List<ImportRowError> errors}) parseBytes(
    List<int> bytes,
  ) {
    final errors = <ImportRowError>[];
    Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (e) {
      return (
        items: <Map<String, dynamic>>[],
        errors: [
          ImportRowError(
            row: 0,
            errorType: 'PARSE',
            field: 'file',
            message: 'Could not read Excel file: $e',
          ),
        ],
      );
    }

    if (book.tables.isEmpty) {
      return (
        items: <Map<String, dynamic>>[],
        errors: [
          const ImportRowError(
            row: 0,
            errorType: 'PARSE',
            field: 'file',
            message: 'Workbook has no sheets.',
          ),
        ],
      );
    }

    final sheet = book.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty || rows.length < 2) {
      return (
        items: <Map<String, dynamic>>[],
        errors: [
          const ImportRowError(
            row: 0,
            errorType: 'FORMAT',
            field: 'file',
            message: 'Need a header row and at least one data row.',
          ),
        ],
      );
    }

    final headerRow = rows.first;
    final colIndex = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final name = _cellText(headerRow[i]).toLowerCase();
      if (name.isNotEmpty) colIndex[name] = i;
    }

    for (final required in headers) {
      if (!colIndex.containsKey(required.toLowerCase())) {
        errors.add(
          ImportRowError(
            row: 1,
            errorType: 'MISSING_COLUMN',
            field: required,
            message: 'Missing required column "$required".',
          ),
        );
      }
    }
    if (errors.isNotEmpty) {
      return (items: <Map<String, dynamic>>[], errors: errors);
    }

    String read(int row, String col) {
      final idx = colIndex[col.toLowerCase()];
      if (idx == null || idx >= rows[row].length) return '';
      return _cellText(rows[row][idx]);
    }

    final items = <Map<String, dynamic>>[];
    for (var r = 1; r < rows.length; r++) {
      final excelRow = r + 1;
      final questionText = read(r, 'questionText');
      final questionType = read(r, 'questionType').toUpperCase();
      if (questionText.isEmpty && questionType.isEmpty) continue;

      if (questionText.isEmpty) {
        errors.add(ImportRowError(
          row: excelRow,
          errorType: 'VALIDATION',
          field: 'questionText',
          message: 'Question text is required.',
        ));
        continue;
      }

      if (!DomainConstants.questionTypes.contains(questionType)) {
        errors.add(ImportRowError(
          row: excelRow,
          errorType: 'INVALID_TYPE',
          field: 'questionType',
          message: 'Must be MCQ, TRUE_FALSE, or SHORT_ANSWER (got "$questionType").',
        ));
        continue;
      }

      final classLevel = read(r, 'classLevel');
      final syllabus = read(r, 'syllabus');
      final subjectId = read(r, 'subjectId');
      final difficulty = read(r, 'difficulty').toLowerCase();
      final needsReviewRaw = read(r, 'needsReview').toLowerCase();

      if (!DomainConstants.classLevels.contains(classLevel)) {
        errors.add(ImportRowError(
          row: excelRow,
          errorType: 'VALIDATION',
          field: 'classLevel',
          message: 'Invalid class. Use: ${DomainConstants.classLevels.join(", ")}.',
        ));
        continue;
      }
      if (!DomainConstants.syllabi.contains(syllabus)) {
        errors.add(ImportRowError(
          row: excelRow,
          errorType: 'VALIDATION',
          field: 'syllabus',
          message: 'Invalid syllabus. Use: ${DomainConstants.syllabi.join(", ")}.',
        ));
        continue;
      }
      if (subjectId.isEmpty || subjectId.contains('PASTE')) {
        errors.add(ImportRowError(
          row: excelRow,
          errorType: 'VALIDATION',
          field: 'subjectId',
          message: 'subjectId must be a valid MongoDB Subject _id.',
        ));
        continue;
      }
      if (difficulty.isNotEmpty && !DomainConstants.difficulties.contains(difficulty)) {
        errors.add(ImportRowError(
          row: excelRow,
          errorType: 'VALIDATION',
          field: 'difficulty',
          message: 'difficulty must be easy, medium, or hard.',
        ));
        continue;
      }

      final item = <String, dynamic>{
        'questionText': questionText,
        'questionType': questionType,
        'classLevel': classLevel,
        'syllabus': syllabus,
        'subject': subjectId,
        'difficulty': difficulty.isEmpty ? 'medium' : difficulty,
      };

      final correctAnswer = read(r, 'correctAnswer');
      final optA = read(r, 'optionA');
      final optB = read(r, 'optionB');
      final optC = read(r, 'optionC');
      final optD = read(r, 'optionD');

      if (questionType == 'MCQ') {
        final opts = [optA, optB, optC, optD].where((o) => o.isNotEmpty).toList();
        if (opts.length < 2) {
          errors.add(ImportRowError(
            row: excelRow,
            errorType: 'VALIDATION',
            field: 'optionA',
            message: 'MCQ needs at least optionA and optionB.',
          ));
          continue;
        }
        if (!opts.contains(correctAnswer)) {
          errors.add(ImportRowError(
            row: excelRow,
            errorType: 'VALIDATION',
            field: 'correctAnswer',
            message: 'correctAnswer must match one of the options exactly.',
          ));
          continue;
        }
        item['options'] = opts;
        item['correctAnswer'] = correctAnswer;
      } else if (questionType == 'TRUE_FALSE') {
        final ca = correctAnswer.toLowerCase();
        if (ca != 'true' && ca != 'false') {
          errors.add(ImportRowError(
            row: excelRow,
            errorType: 'VALIDATION',
            field: 'correctAnswer',
            message: 'TRUE_FALSE correctAnswer must be True or False.',
          ));
          continue;
        }
        item['correctAnswer'] = ca == 'true' ? 'True' : 'False';
      } else {
        final needsReview = needsReviewRaw == 'true' || needsReviewRaw == 'yes' || needsReviewRaw == '1';
        if (needsReview || correctAnswer.isEmpty) {
          item['needsReview'] = true;
          item['reviewStatus'] = 'pending_review';
          item['correctAnswer'] = '';
        } else {
          item['correctAnswer'] = correctAnswer;
          item['reviewStatus'] = 'approved';
        }
      }

      items.add(item);
    }

    if (items.isEmpty && errors.isEmpty) {
      errors.add(const ImportRowError(
        row: 0,
        errorType: 'FORMAT',
        field: 'file',
        message: 'No data rows found below the header.',
      ));
    }

    return (items: items, errors: errors);
  }
}
