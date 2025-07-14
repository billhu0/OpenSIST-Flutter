import 'package:flutter/material.dart';
import 'package:opensist_alpha/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'opensist_api.dart' as api;


class ApplicantSearchDelegate extends SearchDelegate<Applicant?> {
  final List<Applicant> applicants;
  ApplicantSearchDelegate({required this.applicants});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final lower = query.toLowerCase();
    final results = applicants.where((a) {
      final id = a.applicantID.toLowerCase();
      final year = a.applicationYear.toString().toLowerCase();
      return id.contains(lower) || year.contains(lower);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final applicant = results[index];
        return ListTile(
          title: Row(
            children: [
              Text(applicant.applicantID),
              const SizedBox(width: 4),
              _genderToIcon(applicant.gender),
            ],
          ),
          subtitle: Text('${applicant.applicationYear}'),
          onTap: () {
            Navigator.of(context).pushNamed(
              '/opensist_applicant',
              arguments: applicant,
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

Future<String> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie') ?? "";
}

class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
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

class _ApplicantsPageState extends State<ApplicantsPage> {
  bool _loading = false;
  String? _errorMessage;
  List<Applicant> _applicants = [];

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    setState(() => _loading = true);
    _applicants.clear();
    try {
      _applicants = await api.fetchApplicants(await getCookie());
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
      title: const Text('Applicants'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch<Applicant?>(
              context: context,
              delegate: ApplicantSearchDelegate(applicants: _applicants),
            );
          },
        ),
      ],
    );

    final loadingBody = const Center(child: CircularProgressIndicator());

    final body = ListView.builder(
      itemCount: _applicants.length,
      itemBuilder: (context, index) {
        final applicant = _applicants[index];
        return ListTile(
          title: Row(
            children: [
              Text(applicant.applicantID),
              const SizedBox(width: 4),
              _genderToIcon(applicant.gender),
            ],
          ),
          subtitle: Text('${applicant.applicationYear}'),
          onTap: () {
            Navigator.of(context).pushNamed('/opensist_applicant', arguments: applicant);
          },
          onLongPress: () {},
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


