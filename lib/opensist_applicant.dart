import 'package:flutter/material.dart';
import 'package:opensist_alpha/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'opensist_api.dart' as api;


Future<String> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie') ?? "";
}

class ApplicantPage extends StatefulWidget {
  final String applicantId;
  final Applicant? applicant;
  const ApplicantPage({super.key, required this.applicantId, this.applicant});

  @override
  State<ApplicantPage> createState() => _ApplicantPageState();
}

Icon _genderToIcon(String gender) {
  switch (gender) {
    case "Male":
      return const Icon(Icons.male, size: 18, color: Colors.blue,);
    case "Female":
      return const Icon(Icons.female, size: 18, color: Colors.pink,);
    default:
      return const Icon(Icons.transgender, size: 18);
  }
}

class _ApplicantPageState extends State<ApplicantPage> {
  late String applicantId;
  Applicant? applicant;

  bool _loading = true;
  String? _errorMessage;
  List<Applicant> _applicants = [];

  @override
  void initState() {
    super.initState();
    applicantId = widget.applicantId;
    applicant = widget.applicant;
    if (applicant == null) {
      _fetchApplicants();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchApplicants() async {
    setState(() => _loading = true);
    _applicants.clear();
    try {
      _applicants = await api.fetchApplicants(await getCookie());
      for (var app in _applicants) {
        if (app.applicantID == applicantId) {
          applicant = app;
          break;
        }
      }
    } catch (err) {
      setState(() { _errorMessage = err.toString(); });
    } finally {
      setState(() => _loading = false);
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
    if (applicant != null) {
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

    final body = applicant != null ? bodyWithApplicant! : loadingBody;

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
                    _fetchApplicants();
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


