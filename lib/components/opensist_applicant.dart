import 'package:flutter/material.dart';
import 'package:opensist_alpha/components/error_dialog.dart';
import 'package:opensist_alpha/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/opensist_api.dart' as api;


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
              title: Text("Applicant ID"),
              subtitle: Text(applicant!.applicantID),
            ),
            ListTile(
              title: Text("Gender"),
              subtitle: Text(applicant!.gender),
            ),
            ListTile(
              title: Text("Degree"),
              subtitle: Text(applicant!.currentDegree),
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
                  ListTile(
                    title: const Text("HomePage"),
                    subtitle: Text(applicantMetadata!.applicantContactInfo.homepage!),
                  ),
                if (applicantMetadata!.applicantContactInfo.linkedin != null)
                  ListTile(
                    title: const Text("LinkedIn"),
                    subtitle: Text(applicantMetadata!.applicantContactInfo.linkedin!),
                  ),
                if (applicantMetadata!.applicantContactInfo.email != null)
                  ListTile(
                    title: const Text("Email"),
                    subtitle: Text(applicantMetadata!.applicantContactInfo.email!),
                  ),
                if (applicantMetadata!.applicantContactInfo.wechat != null)
                  ListTile(
                    title: const Text("WeChat"),
                    subtitle: Text(applicantMetadata!.applicantContactInfo.wechat!),
                  ),
                if (applicantMetadata!.applicantContactInfo.qq != null)
                  ListTile(
                    title: const Text("QQ"),
                    subtitle: Text(applicantMetadata!.applicantContactInfo.qq!),
                  ),
                if (applicantMetadata!.applicantContactInfo.otherLink != null)
                  ListTile(
                    title: const Text("Other Link"),
                    subtitle: Text(applicantMetadata!.applicantContactInfo.otherLink!),
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
              title: Text("Application Results"),
              children: applicant!.programs.entries.map((entry) =>
                  Chip(
                    label: Text("${entry.key} - ${entry.value.name}", style: TextStyle(color: Colors.white)),
                    backgroundColor: statusColor[entry.value] ?? Colors.grey,
                  )
              ).toList()
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


