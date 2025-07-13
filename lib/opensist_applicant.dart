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
  Applicant? applicant;
  ApplicantPage({super.key, required this.applicantId, this.applicant});

  @override
  State<ApplicantPage> createState() => _ApplicantPageState(
      applicantId: applicantId,
      applicant: applicant,
  );
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
  String applicantId;
  Applicant? applicant;
  _ApplicantPageState({required this.applicantId, this.applicant});

  bool _loading = false;
  String? _errorMessage;
  List<Applicant> _applicants = [];

  @override
  void initState() {
    super.initState();
    if (this.applicant == null) {
      _fetchApplicants();
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

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(applicantId),
    );

    final loadingBody = const Center(child: CircularProgressIndicator());

    final bodyWithApplicant = SingleChildScrollView(
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
              value: 100 - double.parse(applicant!.ranking),
              max: 100,
              onChanged: (double value) {},
              label: "Ranks top ${applicant!.ranking}%",
              year2023: false,
            ),
          ),
          // applicant!.gre != null ? ListTile(
          //   title: Text("GRE"),
          //   subtitle: Text(applicant!.gre!.toString()),
          // ) : const SizedBox.shrink(),
          // applicant!.toefl != null ? ListTile(
          //   title: Text("TOEFL"),
          //   subtitle: Text(applicant!.toefl!.toString()),
          // ) : const SizedBox.shrink(),
          // applicant!.ielts != null ? ListTile(
          //   title: Text("IELTS"),
          //   subtitle: Text(applicant!.ielts!.toString()),
          // ) : const SizedBox.shrink(),
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

        ],
      )
    );



    final body = applicant != null ? bodyWithApplicant : const Center(child: Text("No applicant data found."));

    // final body = ListView.builder(
    //   itemCount: _applicants.length,
    //   itemBuilder: (context, index) {
    //     final applicant = _applicants[index];
    //     return ListTile(
    //       title: Row(
    //         children: [
    //           Text(applicant.applicantID),
    //           const SizedBox(width: 4),
    //           _genderToIcon(applicant.gender),
    //         ],
    //       ),
    //       subtitle: Text('Status: ${applicant.toJson().toString()}'),
    //     );
    //   },
    // );

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


