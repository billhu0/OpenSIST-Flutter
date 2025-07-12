// lib/programs_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';

import 'models.dart';
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
  bool _errorBecauseOfLogin = false;
  final List<Map<String, String>> _rows = [];
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    setState(() => _loading = true);
    _rows.clear();
    try {
      final res = await api.fetchPrograms(await getCookie());
      final body = json.decode(res.body) as Map<String, dynamic>;

      if (body['success'] == false) {
        print("Error authentication");
        setState(() { _errorBecauseOfLogin = true; });
        return;
      }

      // final data = json.decode(res.body)['data'] as Map<String, dynamic>;
      // final records = data
      //     .map((e) => AllPrograms.fromJson(e as Map<String, dynamic>))
      //     .toList();

      //
      // final records = AllPrograms.fromJson(body);
      // print(records.toString());
      //
      final bodyData = body['data'];

      // print(dataList as String?);
      // Expand each Program into one row per applicant
      for (final listOfPrograms in bodyData.values) {
        for (final programEntry in listOfPrograms) {
          final programData = ProgramData.fromJson(programEntry as Map<String, dynamic>);
          print(programData.toString());

          for (final applicant in programData.Applicants) {
            _rows.add({
              'ProgramID': programData.ProgramID,
              'Applicant': applicant,
            });
          }
        }
      }
    } catch (err) {
      // You might want to show a SnackBar or error widget here
      debugPrint('Error fetching programs: $err');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double programIdColWidth = 200;
    const double applicantColWidth = 200;
    final double totalWidth = programIdColWidth + applicantColWidth;

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('Programs'),
    );

    final loadingBody = const Center(child: CircularProgressIndicator());

    final body = LayoutBuilder(
      builder: (context, constraints) {
        // estimate your header height (or measure it)
        const double headerHeight = 48;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                // ─── Sticky Header ────────────────────────────
                Container(
                  height: headerHeight,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: programIdColWidth,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'ProgramID',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: applicantColWidth,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Applicant',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Scrollable Body ──────────────────────────
                SizedBox(
                  height: constraints.maxHeight - headerHeight,
                  child: ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Row(
                        children: [
                          SizedBox(
                            width: programIdColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(row['ProgramID']!),
                            ),
                          ),
                          SizedBox(
                            width: applicantColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(row['Applicant']!),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (_errorBecauseOfLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 弹窗后重置标志，避免重复弹出
        setState(() => _errorBecauseOfLogin = false);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to fetch programs. Have you logged in?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _fetchPrograms();
                  },
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/opensist_login');
                  },
                  child: const Text('Login'),
                ),
              ],
            );
          },
        );
      });
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: _loading ? loadingBody : body),
    );
  }

}
