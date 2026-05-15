import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/domain_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/admin_page_scaffold.dart';
import 'question_excel_import.dart';

class BulkImportQuestionsScreen extends ConsumerStatefulWidget {
  const BulkImportQuestionsScreen({super.key});

  @override
  ConsumerState<BulkImportQuestionsScreen> createState() => _BulkImportQuestionsScreenState();
}

class _BulkImportQuestionsScreenState extends ConsumerState<BulkImportQuestionsScreen> {
  var _loading = false;
  String? _pickedName;
  List<ImportRowError> _parseErrors = [];
  List<Map<String, dynamic>>? _parsedItems;

  Future<void> _downloadSample() async {
    try {
      final book = QuestionExcelImport.buildTemplateWorkbook();
      final bytes = book.encode();
      if (bytes == null) throw Exception('Could not build template');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/questions_import_template.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'TestSprint question import template',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _pickExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read file bytes')));
      }
      return;
    }

    final parsed = QuestionExcelImport.parseBytes(bytes);
    setState(() {
      _pickedName = file.name;
      _parseErrors = parsed.errors;
      _parsedItems = parsed.errors.isEmpty ? parsed.items : null;
    });

    if (mounted && parsed.errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${parsed.errors.length} formatting error(s) — fix the sheet and re-upload')),
      );
    }
  }

  Future<void> _upload() async {
    final items = _parsedItems;
    if (items == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a valid Excel file with no row errors first')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.apiPost(ApiEndpoints.questionsBulk, data: {'items': items});
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      final data = Map<String, dynamic>.from(map['data'] as Map);
      final apiErrors = (data['errors'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import result'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Created: ${(data['created'] as List?)?.length ?? 0}'),
                  Text('Failed rows: ${apiErrors.length}'),
                  if (apiErrors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Server errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...apiErrors.map((e) {
                      final row = e['row'] ?? e['index'];
                      final type = e['errorType']?.toString() ?? 'ERROR';
                      final field = e['field']?.toString() ?? '-';
                      final msg = e['message']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Row $row • $type • $field\n$msg'),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );

      if (apiErrors.isEmpty && mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Bulk import (Excel)',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Download the sample Excel, fill in your questions (one row each), then upload the .xlsx file. '
            'Row errors are shown before anything is sent to the server.',
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _downloadSample,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download sample Excel'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickExcel,
            icon: const Icon(Icons.upload_file),
            label: Text(_pickedName == null ? 'Choose Excel file' : 'Selected: $_pickedName'),
          ),
          const SizedBox(height: 12),
          Text('Classes: ${DomainConstants.classLevels.join(", ")}'),
          Text('Syllabi: ${DomainConstants.syllabi.join(", ")}'),
          const SizedBox(height: 16),
          if (_parseErrors.isNotEmpty) ...[
            Text(
              'Formatting errors (${_parseErrors.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            ..._parseErrors.map(
              (e) => Card(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                child: ListTile(
                  dense: true,
                  title: Text('Row ${e.row} • ${e.errorType}'),
                  subtitle: Text('Field: ${e.field}\n${e.message}'),
                ),
              ),
            ),
          ],
          if (_parsedItems != null && _parseErrors.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ready to upload ${_parsedItems!.length} question(s)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Upload to cloud',
            isLoading: _loading,
            onPressed: _parsedItems != null && _parseErrors.isEmpty ? _upload : null,
          ),
        ],
      ),
    );
  }
}
