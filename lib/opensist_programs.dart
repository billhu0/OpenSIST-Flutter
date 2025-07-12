// lib/programs_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';


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
  final List<Map<String, String>> _rows = [];
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('https://opensist.tech/api/list/programs'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'close',
          'X-Content-Type-Options': 'nosniff',
          'Cookie': await getCookie(),
        },
        body: json.encode({}),
      );

      final bodyJson = (json.decode(res.body) as Map<String, dynamic>)['data'];
      // final dataList = (bodyJson['data'] as Map<String, List<Map<String, dynamic>>>);

      // print(dataList as String?);
      // Expand each Program into one row per applicant
      _rows.clear();

      for (final listOfPrograms in bodyJson.values) {
        for (final programEntry in listOfPrograms) {
          for (final applicant in programEntry['Applicants']) {
            _rows.add({
              'ProgramID': programEntry['ProgramID'],
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
    const double headerHeight = 56;
    const double rowHeight    = 56;

    return Scaffold(
      appBar: AppBar(title: const Text('Programs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        // make sure the table background matches your scaffold
        color: Theme.of(context).scaffoldBackgroundColor,
        child: HorizontalDataTable(
          leftHandSideColumnWidth:  programIdColWidth,
          rightHandSideColumnWidth: applicantColWidth,
          isFixedHeader:            true,
          // enforce uniform heights
          // tableHeight: rowHeight,

          // ─── HEADER ─────────────────────────────────
          headerWidgets: [
            // left header
            Container(
              width: programIdColWidth,
              height: headerHeight,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.1),
              child: Text(
                'ProgramID',
                style: Theme.of(context)
                    .textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // right header
            Container(
              width: applicantColWidth,
              height: headerHeight,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.1),
              child: Text(
                'Applicant',
                style: Theme.of(context)
                    .textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],

          // ─── ROWS ────────────────────────────────────
          itemCount: _rows.length,

          leftSideItemBuilder: (context, index) {
            final row = _rows[index];
            return Container(
              width: programIdColWidth,
              height: rowHeight,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              child: Text(
                row['ProgramID']!,
                maxLines: 1,                    // single line
                overflow: TextOverflow.ellipsis, // ellipsis
                style: Theme.of(context)
                    .textTheme.headlineMedium
              ),
            );
          },

          rightSideItemBuilder: (context, index) {
            final row = _rows[index];
            return Container(
              width: applicantColWidth,
              height: rowHeight,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              child: Text(
                row['Applicant']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            );
          },

          // optional: a divider between each row
          rowSeparatorWidget: Divider(
            color: Theme.of(context).dividerColor,
            height: 1,
          ),
        ),
      ),
    );
  }
  // @override
  Widget build2(BuildContext context) {
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

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: _loading ? loadingBody : body),
    );
  }

}
