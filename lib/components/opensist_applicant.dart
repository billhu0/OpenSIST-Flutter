import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opensist_alpha/components/error_dialog.dart';
import 'package:opensist_alpha/components/opensist_applicants.dart';
import 'package:opensist_alpha/components/record_table.dart';
import 'package:opensist_alpha/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/opensist_api.dart' as api;

// Build a "click-to-copy" ListTile Tile.
Widget _buildCopyableTile(BuildContext context, {required String title, required String value}) {
  return ListTile(
    title: Text(title),
    subtitle: Text(value),
    // Add a trailing icon to indicate the tile is interactive
    trailing: Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade500),
    onTap: () {
      // Use the Clipboard API to set the data
      Clipboard.setData(ClipboardData(text: value));

      // Show a confirmation SnackBar to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title ($value) copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    },
    // Add a little visual feedback on tap
    splashColor: Colors.blue.withOpacity(0.1),
  );
}

Future<String> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie') ?? "";
}

class ApplicantPage extends StatefulWidget {
  final String applicantId;
  final Applicant? applicant;
  final ApplicantMetadata? applicantMetadata;
  const ApplicantPage({super.key, required this.applicantId, this.applicant, this.applicantMetadata});

  @override
  State<ApplicantPage> createState() => _ApplicantPageState();
}

class _ApplicantPageState extends State<ApplicantPage> {
  late String applicantId;
  Applicant? applicant;
  ApplicantMetadata? applicantMetadata;
  List<RecordData>? _records;

  bool _loading = true;
  String? _errorMessage;
  List<Applicant> _applicants = [];

  @override
  void initState() {
    super.initState();
    applicantId = widget.applicantId;
    applicant = widget.applicant;
    applicantMetadata = widget.applicantMetadata;
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    if (applicant == null) await _fetchApplicants();
    if (applicantMetadata == null) await _fetchApplicantMetadata();
    if (_records == null) await _loadRecords();
    setState(() => _loading = false);
  }

  Future<void> _fetchApplicants() async {
    _applicants.clear();
    try {
      _applicants = await api.fetchApplicants();
      for (var app in _applicants) {
        if (app.applicantID == applicantId) {
          applicant = app;
          break;
        }
      }
    } catch (err) {
      setState(() { _errorMessage = err.toString(); });
    }
  }

  Future<void> _fetchApplicantMetadata() async {
    try {
      applicantMetadata = await api.fetchApplicantMetadata(applicantId.split("@")[0]);
    } catch (err) {
      setState(() { _errorMessage = err.toString(); });
      rethrow;
    }
  }

  Future<void> _loadRecords() async {
    try {
      final records = await api.fetchRecordsByIds(applicant!.programs.entries.map((entry) => "$applicantId|${entry.key}").toList());
      setState(() { _records = records; });
    } catch (err) {
      setState(() {
        _errorMessage = 'Failed to load records: $err';
      });
    }
  }

  final statusColor = {
    Status.Admit: Colors.green,
    Status.Reject: Colors.red,
    Status.Defer: Colors.orange,
    Status.Waitlist: Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(applicantId),
    );

    final loadingBody = const Center(child: CircularProgressIndicator());

    Widget? bodyWithApplicant;
    if (applicant != null && applicantMetadata != null) {
      bodyWithApplicant = SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            ListTile(
              title: Text("Applicant Basic Info"),
              subtitle: Wrap(
                spacing: 8.0, // Horizontal gap between items
                // runSpacing: 4.0, // Vertical gap between lines
                crossAxisAlignment: WrapCrossAlignment.center, // To align items vertically
                children: [
                  Text(applicant!.applicantID),
                  Chip(
                    avatar: CircleAvatar(
                      child: genderToIcon(applicant!.gender),
                    ),
                    label: Text(genderToText(applicant!.gender)),
                  ),
                  Chip(
                    avatar: CircleAvatar(
                      child: Icon(Icons.school),
                    ),
                    label: Text(applicant!.currentDegree),
                  ),
                ],
              )
            ),
            ListTile(
              title: Text("Application Year"),
              subtitle: Text(applicant!.applicationYear.toString()),
            ),
            ListTile(
              title: Text("Major"),
              subtitle: Text(applicant!.major),
            ),
            ListTile(
              title: Text("GPA"),
              subtitle: Text(applicant!.gpa.toString()),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                showValueIndicator: ShowValueIndicator.always,
              ),
              child: Slider(
                value: 100 - double.parse(applicant!.ranking == '50+' ? '50' : applicant!.ranking),
                max: 100,
                onChanged: (double value) {},
                label: "Ranks top ${applicant!.ranking}%",
                year2023: false,
              ),
            ),
            ListTile(
              title: Text("Final Selection"),
              subtitle: Text(applicant!.finalSelection != "" ? applicant!.finalSelection : 'No data'),
            ),
            ExpansionTile(
              initiallyExpanded: true,
              title: Text("Contact Info (${applicantMetadata!.applicantContactInfo.length()})"),
              children: [
                if (applicantMetadata!.applicantContactInfo.homepage != null)
                  _buildCopyableTile(
                    context,
                    title: "HomePage",
                    value: applicantMetadata!.applicantContactInfo.homepage!,
                  ),
                if (applicantMetadata!.applicantContactInfo.linkedin != null)
                  _buildCopyableTile(
                    context,
                    title: "LinkedIn",
                    value: applicantMetadata!.applicantContactInfo.linkedin!,
                  ),
                if (applicantMetadata!.applicantContactInfo.email != null)
                  _buildCopyableTile(
                    context,
                    title: "Email",
                    value: applicantMetadata!.applicantContactInfo.email!,
                  ),
                if (applicantMetadata!.applicantContactInfo.wechat != null)
                  _buildCopyableTile(
                    context,
                    title: "WeChat",
                    value: applicantMetadata!.applicantContactInfo.wechat!,
                  ),
                if (applicantMetadata!.applicantContactInfo.qq != null)
                  _buildCopyableTile(
                    context,
                    title: "QQ",
                    value: applicantMetadata!.applicantContactInfo.qq!,
                  ),
                if (applicantMetadata!.applicantContactInfo.otherLink != null)
                  _buildCopyableTile(
                    context,
                    title: "Other Link",
                    value: applicantMetadata!.applicantContactInfo.otherLink!,
                  ),
              ],
            ),
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text("TOEFL/IELTS/GRE Test Scores"),
              children: [
                if (applicant!.gre != null)
                  ListTile(
                    title: const Text("GRE"),
                    subtitle: Text(applicant!.gre!.toString()),
                  ),
                if (applicant!.toefl != null)
                  ListTile(
                    title: const Text("TOEFL"),
                    subtitle: Text(applicant!.toefl!.toString()),
                  ),
                if (applicant!.ielts != null)
                  ListTile(
                    title: const Text("IELTS"),
                    subtitle: Text(applicant!.ielts!.toString()),
                  ),
              ],
            ),
            ExpansionTile(
              initiallyExpanded: true,
              title: Text("${applicant!.exchange?.length} 3+1 Exchange Experience"),
              children: applicant!.exchange?.map((exchange) => ListTile(
                title: Text("${exchange.university}, ${exchange.duration == "Year" ? '1 Year' : '1 Semester'}"),
                subtitle: Text((exchange.detail != "") ? exchange.detail : 'No details provided'),
              )).toList() ?? [],
            ),
            ExpansionTile(
              initiallyExpanded: true,
              title: Text("Research Experience: ${applicant!.research?.domestic.num} domestic, ${applicant!.research?.international.num} intl"),
              children: [
                ListTile(
                  title: Text('Focus'),
                  subtitle: Text(applicant!.research?.focus ?? 'No focus provided'),
                ),
                ListTile(
                  title: Text('${applicant!.research?.domestic.num} Domestic Research'),
                  subtitle: Text(applicant!.research?.domestic.detail ?? 'No domestic research details provided'),
                ),
                ListTile(
                  title: Text('${applicant!.research?.international.num} International Research'),
                  subtitle: Text(applicant!.research?.international.detail ?? 'No international research details provided'),
                ),
              ]
            ),
            applicant!.internship == null ? const SizedBox.shrink() :
            ExpansionTile(
              initiallyExpanded: true,
              title: Text("Internship Experience: ${applicant!.internship?.domestic.num} domestic, ${applicant!.internship?.international.num} intl"),
              children: [
                ListTile(
                  title: Text('${applicant!.internship?.domestic.num} Domestic internship'),
                  subtitle: Text(applicant!.internship?.domestic.detail ?? 'No domestic internship details provided'),
                ),
                ListTile(
                  title: Text('${applicant!.internship?.international.num} International internship'),
                  subtitle: Text(applicant!.internship?.international.detail ?? 'No international internship details provided'),
                ),
              ]
            ),
            ExpansionTile(
              initiallyExpanded: true,
              title: Text("Application Results (${applicant!.programs.length})"),
              children: [recordTable(context, _records!, showApplicantColumn: false)],
            ),
          ],
        )
      );
    }

    final body = bodyWithApplicant ?? loadingBody;

    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String tmp = _errorMessage!;
        setState(() => _errorMessage = null);
        showErrorDialog(context, tmp, _fetchAll);
      });
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: body),
    );
  }
}


