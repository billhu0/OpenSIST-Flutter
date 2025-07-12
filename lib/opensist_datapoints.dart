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

class DatapointsPage extends StatefulWidget {
  const DatapointsPage({super.key});

  @override
  State<DatapointsPage> createState() => _DatapointsPageState();
}

class _DatapointsPageState extends State<DatapointsPage> {
  bool _loading = false;
  String? _errorMessage;
  List<RecordData> _records = [];
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDataPoints();
  }

  Future<void> _fetchDataPoints() async {
    setState(() => _loading = true);
    _records.clear();
    try {
      final records = await api.fetchDataPoints(await getCookie());
      setState(() {
        _records = records;
      });
    } catch (err) {
      setState(() { _errorMessage = err.toString(); });
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
    const double programIdColWidth = 150;
    const double applicantColWidth = 150;
    const double statusColWidth = 90;
    const double finalColWidth = 70;
    const double seasonWidth = 100;
    final double totalWidth = (
      programIdColWidth + applicantColWidth + statusColWidth + finalColWidth + seasonWidth
    );

    final statusColor = {
      Status.Admit: Colors.green,
      Status.Reject: Colors.red,
      Status.Defer: Colors.orange,
      Status.Waitlist: Colors.grey,
    };

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('DataPoints'),
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
                      SizedBox(
                        width: statusColWidth,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: finalColWidth,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Final',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: seasonWidth,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Season',
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
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return Row(
                        children: [
                          SizedBox(
                            width: programIdColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(record.programID),
                            ),
                          ),
                          SizedBox(
                            width: applicantColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: InkWell(
                                onTap: () {
                                  // TODO: 点击 Applicant
                                  print("clicked applicant: ${record.applicantID}\n");
                                },
                                child: Text(
                                  record.applicantID,
                                  // style: const TextStyle(
                                  //   color: Colors.blue,
                                  //   decoration: TextDecoration.underline,
                                  // ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: statusColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: statusColor[record.status] ?? Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.status.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: finalColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(record.finalDecision ? 'Yes' : 'No'),
                            ),
                          ),
                          SizedBox(
                            width: seasonWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${record.semester.name} ${record.programYear}'),
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

    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 弹窗后重置标志，避免重复弹出
        String tmp = _errorMessage!;
        setState(() => _errorMessage = null);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to fetch programs. Error: $tmp'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _fetchDataPoints();
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
