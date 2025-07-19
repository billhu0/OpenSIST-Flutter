import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opensist_alpha/models/models.dart';
import '../models/opensist_api.dart' as api;
import 'error_dialog.dart';

class ProgramSearchDelegate extends SearchDelegate<void> {
  final Map<String, List<ProgramData>> programsMap;
  final Map<String, String> univFullNames;
  final Map<String, int> ranks;

  ProgramSearchDelegate({
    required this.programsMap,
    required this.univFullNames,
    required this.ranks,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final lower = query.toLowerCase();
    final filtered = programsMap.entries.where((e) {
      final abbr = e.key.toLowerCase();
      final full = (univFullNames[e.key] ?? '').toLowerCase();
      final programName = e.value.map((program) => program.Program.toLowerCase());
      return abbr.contains(lower) || full.contains(lower) || programName.contains(lower) ;
    });

    return buildProgramsList(context, filtered.toList(), univFullNames, ranks);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  bool _loading = false;
  String? _errorMessage;

  Map<String, List<ProgramData>> _programsMap = {};
  Map<String, String> _univFullNames = {};
  Map<String, int> _univCsRank = {};

  @override
  void initState() {
    super.initState();
    _loadUniversityNames();
    _fetchPrograms();
  }

  Future<void> _loadUniversityNames() async {
    final jsonStr = await rootBundle.loadString('assets/json/UnivList.json');
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    final Map<String, String> names = {
      for (var item in list) item['abbr'] as String: item['fullName'] as String,
    };
    final Map<String, int> csRanks = {
      for (var item in list) item['abbr'] as String: item['cs_rank'] as int,
    };
    setState(() {
      _univFullNames = names;
      _univCsRank = csRanks;
    });
  }

  Future<void> _fetchPrograms() async {
    setState(() => _loading = true);
    try {
      final result = await api.fetchPrograms();
      setState(() => _programsMap = result);
    } catch (err) {
      setState(() => _errorMessage = err.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String tmp = _errorMessage!;
        setState(() => _errorMessage = null);
        showErrorDialog(context, tmp, _fetchPrograms);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProgramSearchDelegate(
                  programsMap: _programsMap,
                  univFullNames: _univFullNames,
                  ranks: _univCsRank,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : buildProgramsList(context, _programsMap.entries.toList(), _univFullNames, _univCsRank),
      ),
    );
  }
}

Widget _regionEmoji(List<RegionEnum> regions) {
  if (regions.isEmpty) return const SizedBox.shrink();
  String text = "";
  for (final region in regions) {
    switch (region) {
      case RegionEnum.US: text += '🇺🇸';
      case RegionEnum.CA: text += '🇨🇦';
      case RegionEnum.EU: text += '🇪🇺';
      case RegionEnum.UK: text += '🇬🇧';
      case RegionEnum.HK: text += '🇭🇰';
      case RegionEnum.SG: text += '🇸🇬';
      default: break;
    }
  }
  return Text(text);
}

Widget buildProgramsList(
  BuildContext context,
  List<MapEntry<String, List<ProgramData>>> programsMap,
  Map<String, String> univFullNames,
  Map<String, int> univRanking,
) {
  // sort by ranking
  programsMap.sort((a, b) => (univRanking[a.key] ?? 10000).compareTo(univRanking[b.key] ?? 10000));

  return ListView(
    children: programsMap.map((entry) {
      final uni = entry.key;
      final list = entry.value;
      return ExpansionTile(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(uni),
            Expanded(child: const SizedBox(),),
            _regionEmoji(list.first.Region),
          ],
        ),
        subtitle: Text(univFullNames[uni] ?? 'University Full Name unknown'),
        children: list.map((prog) {
          return Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      title: Text(prog.Program),
                      subtitle: Text(prog.TargetApplicantMajor.join(', ')),
                      onTap: () {
                        Navigator.of(context).pushNamed('/opensist_program', arguments: prog);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }).toList(),
  );
}
