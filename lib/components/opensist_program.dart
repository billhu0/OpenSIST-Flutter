import 'package:flutter/material.dart';
import 'package:opensist_alpha/components/record_table.dart';
import 'package:opensist_alpha/models/models.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/opensist_api.dart' as api;
import 'error_dialog.dart';

Widget _regionEmoji(List<RegionEnum> regs) {
  if (regs.isEmpty) return const SizedBox.shrink();
  switch (regs.first) {
    case RegionEnum.US: return const Text('🇺🇸');
    case RegionEnum.CA: return const Text('🇨🇦');
    case RegionEnum.EU: return const Text('🇪🇺');
    case RegionEnum.UK: return const Text('🇬🇧');
    case RegionEnum.HK: return const Text('🇭🇰');
    case RegionEnum.SG: return const Text('🇸🇬');
    default: return const SizedBox.shrink();
  }
}

class ProgramPage extends StatefulWidget {
  final String programName;
  final ProgramData? program;
  const ProgramPage({super.key, required this.programName, this.program});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  late String programName;
  ProgramData? _programData;
  String? _programDescriptionMarkdown;
  List<RecordData>? _records;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    programName = widget.programName;
    _programData = widget.program;
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    if (_programData == null) await _fetchProgram();
    if (_programDescriptionMarkdown == null) await _loadProgramDescription();
    if (_records == null) await _loadRecords();
    setState(() => _loading = false);
  }

  Future<void> _fetchProgram() async {
    try {
      final allPrograms = await api.fetchPrograms();
      for (var list in allPrograms.values) {
        for (var p in list) {
          if (p.ProgramID == programName) {
            _programData = p;
            break;
          }
        }
      }
    } catch (err) {
      _errorMessage = err.toString();
    }
  }

  Future<void> _loadProgramDescription() async {
    try {
      final desc = await api.fetchProgramDescription(programName);
      setState(() {
        _programDescriptionMarkdown = desc;
      });
    } catch (err) {
      setState(() {
        _errorMessage = 'Failed to load program description: $err';
      });
    }
  }

  Future<void> _loadRecords() async {
    try {
      final records = await api.fetchRecordsByIds(_programData!.Applicants.map((e) => '$e|$programName').toList());
      setState(() { _records = records; });
    } catch (err) {
      setState(() {
        _errorMessage = 'Failed to load records: $err';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = programName;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(programName),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String tmp = _errorMessage!;
        setState(() => _errorMessage = null);
        showErrorDialog(context, tmp, _fetchAll);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(programName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: const Text('Program ID'),
                subtitle: Text(_programData!.ProgramID),
              ),
              ListTile(
                title: const Text('Target Major(s)'),
                subtitle: Text(_programData!.TargetApplicantMajor.join(', ')),
              ),
              ListTile(
                title: const Text('Region(s)'),
                subtitle: _regionEmoji(_programData!.Region),
              ),
              ExpansionTile(
                initiallyExpanded: true,
                title: const Text('Program Description'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MarkdownBlock(data: _programDescriptionMarkdown ?? 'Loading...'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Applicants (${_programData!.Applicants.length})'),
                children: [recordTable(context, _records!, showProgramColumn: false)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}