import 'package:flutter/material.dart';
import 'package:opensist_alpha/components/error_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/opensist_api.dart' as api;

class DatapointsPage extends StatefulWidget {
  const DatapointsPage({super.key});

  @override
  State<DatapointsPage> createState() => _DatapointsPageState();
}

class _DatapointsPageState extends State<DatapointsPage> {
  bool _loading = false;

  // 1. Add a state variable for the setting
  bool _showTimelineDates = true; // Default to true

  int _completed = 0;
  int _total = 1;  // avoid div/0

  String? _errorMessage;
  List<RecordData> _records = [];
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchDataPoints();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Read the setting, defaulting to true if not found
    _showTimelineDates = prefs.getBool('showTimelineDates') ?? true;
    
    // Now fetch the data points
    _fetchDataPoints();
  }

  Future<void> _fetchDataPoints() async {
    setState(() {
      _loading = true;
      _completed = 0;
    });
    _records.clear();
    try {
      final records = await api.fetchAllRecords(
        onProgress: (done, total) {
          setState(() {
            _completed = done;
            _total = total;
          });
        }
      );
      setState(() { _records = records; });
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
    const double programIdColWidth = 175;
    const double applicantColWidth = 175;
    const double statusColWidth = 90;
    const double finalColWidth = 70;
    const double seasonWidth = 100;
    const double timelineDecisionWidth = 120;
    const double timelineInterviewWidth = 120;
    const double timelineApplicationWidth = 120;
    const double detailWidth = 300;
    double totalWidth = (
      programIdColWidth + applicantColWidth + statusColWidth + finalColWidth + seasonWidth + detailWidth
    );
    if (_showTimelineDates) {
      totalWidth +=
        timelineDecisionWidth + timelineInterviewWidth + timelineApplicationWidth;
    }

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

    final loadingBody = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            _completed > 0
                ? '$_completed / $_total application records loaded'
                : 'Connecting…',
          ),
        ],
      ),
    );

    final columns = _showTimelineDates ? 
      ['ProgramID', 'Applicant', 'Status', 'Final', 'Season', 'Decision', 'Interview', 'Application', 'Details'] :
      ['ProgramID', 'Applicant', 'Status', 'Final', 'Season', 'Details'];

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
                    children:
                      columns.map((title) => SizedBox(
                        width: title == 'ProgramID' ? programIdColWidth :
                               title == 'Applicant' ? applicantColWidth :
                               title == 'Status' ? statusColWidth :
                               title == 'Final' ? finalColWidth :
                               title == 'Season' ? seasonWidth :
                               title == 'Decision' ? timelineDecisionWidth :
                               title == 'Interview' ? timelineInterviewWidth :
                               title == 'Application' ? timelineApplicationWidth : detailWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            title,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )).toList()
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
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/opensist_program', arguments: record.programID);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).highlightColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record.programID,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: applicantColWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/opensist_applicant', arguments: record.applicantID);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).highlightColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record.applicantID,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                                  ),
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
                              child: Text(record.finalDecision ? 'Yes' : ''),
                            ),
                          ),
                          SizedBox(
                            width: seasonWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${record.semester.name} ${record.programYear}'),
                            ),
                          ),
                          if (_showTimelineDates) ...[
                            SizedBox(
                              width: timelineDecisionWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(record.timeline.decision ?? ''),
                              ),
                            ),
                            SizedBox(
                              width: timelineInterviewWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(record.timeline.interview ?? ''),
                              ),
                            ),
                            SizedBox(
                              width: timelineApplicationWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(record.timeline.submit ?? ''),
                              ),
                            ),
                          ],
                          SizedBox(
                            width: detailWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(record.detail ?? ''),
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
        String tmp = _errorMessage!;
        setState(() => _errorMessage = null);
        showErrorDialog(context, tmp, _fetchDataPoints);
      });
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: _loading ? loadingBody : body),
    );
  }

}
