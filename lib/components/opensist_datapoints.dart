import 'package:flutter/material.dart';
import 'package:opensist_alpha/components/error_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/opensist_api.dart' as api;


final statusColor = {
  Status.Admit: Colors.green,
  Status.Reject: Colors.red,
  Status.Defer: Colors.orange,
  Status.Waitlist: Colors.grey,
};
class DatapointsPage extends StatefulWidget {
  const DatapointsPage({super.key});

  @override
  State<DatapointsPage> createState() => _DatapointsPageState();
}

class _DatapointsPageState extends State<DatapointsPage> {
  bool _loading = true;

  // 1. Add a state variable for the setting
  bool _showTimelineDates = true; // Default to true

  int _completed = 0;
  int _total = 1;  // avoid div/0

  String? _errorMessage;
  List<RecordData> _records = [];
  List<RecordData> _filteredRecords = [];
  // 1. Add controllers and state variables for filters
  final _programIdFilterController = TextEditingController();
  final _applicantFilterController = TextEditingController();
  final _seasonFilterController = TextEditingController();
  String _statusFilter = 'All';
  String _finalFilter = 'All';

  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to apply filters on change
    _programIdFilterController.addListener(_applyFilters);
    _applicantFilterController.addListener(_applyFilters);
    _seasonFilterController.addListener(_applyFilters);

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
      setState(() { _records = records; _filteredRecords = _records; });
    } catch (err) {
      setState(() { _errorMessage = err.toString(); });
    } finally {
      setState(() => _loading = false);
    }
  }

  // 2. Create the filtering logic
  void _applyFilters() {
    List<RecordData> tempRecords = List.from(_records);

    final programIdQuery = _programIdFilterController.text.toLowerCase().trim();
    if (programIdQuery.isNotEmpty) {
      tempRecords = tempRecords.where((r) => r.programID.toLowerCase().contains(programIdQuery)).toList();
    }

    final applicantQuery = _applicantFilterController.text.toLowerCase().trim();
    if (applicantQuery.isNotEmpty) {
      tempRecords = tempRecords.where((r) => r.applicantID.toLowerCase().contains(applicantQuery)).toList();
    }

    final seasonQuery = _seasonFilterController.text.toLowerCase().trim();
    if (seasonQuery.isNotEmpty) {
      tempRecords = tempRecords.where((r) {
        final seasonString = '${r.semester.name} ${r.programYear}${r.semester.name}'.toLowerCase();
        return seasonString.contains(seasonQuery);
      }).toList();
    }
    
    if (_statusFilter != 'All') {
      tempRecords = tempRecords.where((r) => r.status.name == _statusFilter).toList();
    }

    if (_finalFilter != 'All') {
      final finalBool = _finalFilter == 'Yes';
      tempRecords = tempRecords.where((r) => r.finalDecision == finalBool).toList();
    }

    setState(() {
      _filteredRecords = tempRecords;
    });
  }

  void _clearFilters() {
    // Clear the text controllers. This will trigger their listeners.
    _programIdFilterController.clear();
    _applicantFilterController.clear();
    _seasonFilterController.clear();

    // Reset the dropdown state variables
    setState(() {
      _statusFilter = 'All';
      _finalFilter = 'All';
    });

    // Re-apply filters to update the list with the cleared state
    _applyFilters();
  }

  bool get _isFilterActive {
    return _programIdFilterController.text.isNotEmpty ||
        _applicantFilterController.text.isNotEmpty ||
        _seasonFilterController.text.isNotEmpty ||
        _statusFilter != 'All' ||
        _finalFilter != 'All';
  }

  @override
  void dispose() {
    _horizontalController.dispose();

    // Important: dispose controllers and remove listeners
    _programIdFilterController.removeListener(_applyFilters);
    _applicantFilterController.removeListener(_applyFilters);
    _seasonFilterController.removeListener(_applyFilters);
    _programIdFilterController.dispose();
    _applicantFilterController.dispose();
    _seasonFilterController.dispose();

    super.dispose();
  }

  static const filterBarHeight = 50.0;

  // 3. Create a widget for the filter bar
  Widget _buildFilterBar(Map<String, double> colWidths) {
    return Container(
      height: filterBarHeight,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
      child: Row(
        children: [
          // ProgramID Filter
          SizedBox(
            width: colWidths['ProgramID'],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
              child: TextField(
                controller: _programIdFilterController,
                decoration: const InputDecoration(isDense: true, hintText: 'Filter...'),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
          // Applicant Filter
          SizedBox(
            width: colWidths['Applicant'],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
              child: TextField(
                controller: _applicantFilterController,
                decoration: const InputDecoration(isDense: true, hintText: 'Filter...'),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
          // Status Filter
          SizedBox(
            width: colWidths['Status'],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: DropdownButtonFormField<String>(
                isDense: true,
                value: _statusFilter,
                items: ['All', 'Admit', 'Reject', 'Waitlist', 'Defer']
                  .map((val) => DropdownMenuItem(
                    value: val, 
                    child: Container(
                      padding: val != "All" ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8) : null,
                      decoration: val != "All" ? BoxDecoration(
                        color: statusColor[Status.values.byName(val)] ?? Colors.grey ,
                        borderRadius: BorderRadius.circular(12),
                      ) : null,
                      child: Text(
                        val,
                        style: val != "All" ? const TextStyle(color: Colors.white, fontSize: 12) : null,
                        textAlign: TextAlign.center,
                      ),
                    ),)
                  )
                  .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() { _statusFilter = value; });
                    _applyFilters(); // Re-apply filters on change
                  }
                },
              ),
            ),
          ),
          // Final Filter
          SizedBox(
            width: colWidths['Final'],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: DropdownButtonFormField<String>(
                isDense: true,
                value: _finalFilter,
                items: ['All', 'Yes', 'No']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() { _finalFilter = value; });
                    _applyFilters();
                  }
                },
              ),
            ),
          ),
          // Season Filter
          SizedBox(
            width: colWidths['Season'],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
              child: TextField(
                controller: _seasonFilterController,
                decoration: const InputDecoration(isDense: true, hintText: 'Filter...'),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final colWidths = {
      'ProgramID': 175.0,
      'Applicant': 175.0,
      'Status': 100.0,
      'Final': 70.0,
      'Season': 100.0,
      'Decision': 120.0,
      'Interview': 120.0,
      'Application': 120.0,
      'Details': 300.0,
    };

    const double programIdColWidth = 175;
    const double applicantColWidth = 175;
    const double statusColWidth = 100;
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

    // Show current filteredRecords / Records count in the title bar
    String countsToDisplay = _loading ? "" : (
      _filteredRecords.length == _records.length ? '(${_records.length})' : '(${_filteredRecords.length}/${_records.length})'
    );

    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text('DataPoints $countsToDisplay'),
      actions: [
        IconButton(
          onPressed: _isFilterActive ? _clearFilters : null, 
          icon: const Icon(Icons.filter_alt_off),
          tooltip: "Remove all filters",
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              _loading = true;
            });
            api.clearCache();
            _loadSettings();
            _fetchDataPoints();
          },
          tooltip: "Refresh",
        ),
      ],
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

                _buildFilterBar(colWidths),

                // ─── Scrollable Body ──────────────────────────
                SizedBox(
                  height: constraints.maxHeight - headerHeight - filterBarHeight,
                  child: ListView.separated(
                    itemCount: _filteredRecords.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
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
