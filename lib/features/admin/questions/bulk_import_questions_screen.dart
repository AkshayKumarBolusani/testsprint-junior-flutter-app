import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/domain_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/admin_page_scaffold.dart';

/// Paste JSON array of question objects. See [_sampleJson] for shape.
class BulkImportQuestionsScreen extends ConsumerStatefulWidget {
  const BulkImportQuestionsScreen({super.key});

  @override
  ConsumerState<BulkImportQuestionsScreen> createState() => _BulkImportQuestionsScreenState();
}

class _BulkImportQuestionsScreenState extends ConsumerState<BulkImportQuestionsScreen> {
  final _controller = TextEditingController();
  var _loading = false;

  static const _sampleJson = '''
[
  {
    "questionText": "What is 2 + 2?",
    "questionType": "MCQ",
    "options": ["3", "4", "5", "22"],
    "correctAnswer": "4",
    "classLevel": "5th",
    "syllabus": "CBSE",
    "subject": "REPLACE_WITH_SUBJECT_MONGO_ID",
    "difficulty": "easy"
  },
  {
    "questionText": "The sun rises in the east.",
    "questionType": "TRUE_FALSE",
    "correctAnswer": "True",
    "classLevel": "5th",
    "syllabus": "CBSE",
    "subject": "REPLACE_WITH_SUBJECT_MONGO_ID",
    "difficulty": "easy"
  },
  {
    "questionText": "Name the capital of France.",
    "questionType": "SHORT_ANSWER",
    "correctAnswer": "",
    "needsReview": true,
    "classLevel": "5th",
    "syllabus": "CBSE",
    "subject": "REPLACE_WITH_SUBJECT_MONGO_ID",
    "difficulty": "medium"
  }
]

Rules:
• MCQ: at least 2 options; correctAnswer must equal one option string.
• TRUE_FALSE: correctAnswer is "True" or "False" (or boolean).
• SHORT_ANSWER: leave correctAnswer empty and set "needsReview": true for staff review; OR set correctAnswer and omit needsReview to approve immediately.
• subject: MongoDB _id of a Subject in the same classLevel + syllabus.
• questionType: MCQ | TRUE_FALSE | SHORT_ANSWER
''';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteSample() async {
    await Clipboard.setData(ClipboardData(text: _sampleJson.trim()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample format copied to clipboard — replace SUBJECT id')),
      );
    }
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste JSON first')));
      return;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid JSON: $e')));
      return;
    }
    if (decoded is! List) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Root JSON must be an array')));
      return;
    }
    final items = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(ApiEndpoints.questionsBulk, data: {'items': items});
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['success'] != true) {
        throw DioException(requestOptions: res.requestOptions, message: map['message']?.toString());
      }
      final data = Map<String, dynamic>.from(map['data'] as Map);
      final errs = data['errors'] as List<dynamic>? ?? [];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Done. ${errs.length} error row(s). See dialog for details.')),
      );
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bulk import result'),
          content: SingleChildScrollView(
            child: SelectableText(const JsonEncoder.withIndent('  ').convert(data)),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
      if (errs.isEmpty && mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Bulk import questions',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _pasteSample,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Icon(Icons.copy_all_outlined, size: 20),
                  Text('Copy sample format to clipboard'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Allowed classes: ${DomainConstants.classLevels.join(", ")}'),
          Text('Syllabi: ${DomainConstants.syllabi.join(", ")}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            maxLines: 18,
            decoration: const InputDecoration(
              labelText: 'JSON array (max 200 items)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Import', isLoading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
