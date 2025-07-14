// lib/opensist_program.dart
import 'package:flutter/material.dart';
import 'package:opensist_alpha/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'opensist_api.dart' as api;
import 'package:markdown_widget/markdown_widget.dart';

Future<String> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie') ?? "";
}

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
  ProgramData? program;
  bool _loading = true;
  String? _errorMessage;
  String? _programDescriptionMarkdown;

  @override
  void initState() {
    super.initState();
    programName = widget.programName;
    program = widget.program;
    if (program == null) {
      _fetchProgram();
    } else {
      _loading = false;
    }
    if (_programDescriptionMarkdown == null) {
      _loadProgramDescription();
    }
  }

  Future<void> _fetchProgram() async {
    setState(() => _loading = true);
    try {
      final all = await api.fetchPrograms(await getCookie());
      for (var list in all.values) {
        for (var p in list) {
          if (p.ProgramID == programName) {
            program = p;
            break;
          }
        }
        if (program != null) break;
      }
      if (program == null) {
        throw Exception('Program not found: $programName');
      }
    } catch (err) {
      _errorMessage = err.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProgramDescription() async {
    try {
      final desc = await api.fetchProgramDescription(programName, await getCookie());
      setState(() {
        _programDescriptionMarkdown = desc;
      });
    } catch (err) {
      setState(() {
        _errorMessage = 'Failed to load program description: $err';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = programName;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }
    // program 一定非空
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
                subtitle: Text(program!.ProgramID),
              ),
              ListTile(
                title: const Text('Target Major(s)'),
                subtitle: Text(program!.TargetApplicantMajor.join(', ')),
              ),
              ListTile(
                title: const Text('Region(s)'),
                subtitle: _regionEmoji(program!.Region),
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
                title: Text('Applicants (${program!.Applicants.length})'),
                children: program!.Applicants.map((id) =>
                    ListTile(
                      title: Text(id),
                      onTap: () {
                        Navigator.of(context).pushNamed('/opensist_applicant', arguments: id);
                      },
                    )
                ).toList(),
              ),

            ],
          ),
        ),
      ),
    );
  }
}