import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opensist_alpha/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'opensist_api.dart' as api;

Future<String> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie') ?? "";
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
    setState(() {
      _univFullNames = names;
    });
  }

  Widget _regionEmoji(List<RegionEnum> regs) {
    if (regs.isEmpty) return const SizedBox.shrink();
    switch (regs.first) {
      case RegionEnum.US:
        return const Text('🇺🇸');
      case RegionEnum.CA:
        return const Text('🇨🇦');
      case RegionEnum.EU:
        return const Text('🇪🇺');
      case RegionEnum.UK:
        return const Text('🇬🇧');
      case RegionEnum.HK:
        return const Text('🇭🇰');
      case RegionEnum.SG:
        return const Text('🇸🇬');
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _fetchPrograms() async {
    setState(() => _loading = true);
    try {
      final result = await api.fetchPrograms(await getCookie());
      setState(() => _programsMap = result);
    } catch (err) {
      setState(() => _errorMessage = err.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programs'), backgroundColor: Theme.of(context).colorScheme.inversePrimary,),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text('Error: $_errorMessage'))
            : ListView(
          children: _programsMap.entries.map((entry) {
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
              subtitle: Text(_univFullNames[uni] ?? 'Full name placeholder'),
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
        ),
      ),
    );
  }
}