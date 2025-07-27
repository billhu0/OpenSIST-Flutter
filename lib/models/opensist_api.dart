import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import './models.dart';

const _baseUrl = 'https://opensist.tech/api';
const _timeout = Duration(seconds: 10);
const _cacheTimeout = Duration(minutes: 10);
SharedPreferences? _prefs;

/// Ensures SharedPreferences is initialized
Future<SharedPreferences> get _storage async {
  return _prefs ??= await SharedPreferences.getInstance();
}

/// Retrieves saved session cookie (if any)
Future<String?> get _cookie async {
  final prefs = await _storage;
  return prefs.getString('cookie');
}

/// Persists session cookie
Future<void> _setCookie(String cookie) async {
  final prefs = await _storage;
  await prefs.setString('cookie', cookie);
}

/// Simple cache entry container
class _CacheEntry {
  final DateTime timestamp;
  final Map<String, dynamic> data;
  _CacheEntry(this.timestamp, this.data);
}

/// In-memory cache: URL+body JSON → response data
final Map<String, _CacheEntry> _cache = {};

void clearCache() {
  _cache.clear();
}

Map<String, String>? _univFullnames;
Map<String, int>? _ranks;

Future<Map<String, int>> _loadUniversityRank() async {
  final jsonStr = await rootBundle.loadString('assets/json/UnivList.json');
  final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
  return {
    for (var item in list) item['abbr'] as String: item['cs_rank'] as int,
  };
}

Future<Map<String, String>> _loadUniversityFullnames() async {
  final jsonStr = await rootBundle.loadString('assets/json/UnivList.json');
  final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
  return {
    for (var item in list) item['abbr'] as String: item['fullName'] as String,
  };
}

/// Low-level POST helper: handles timeouts, headers, JSON-decoding & error checks
/// Low-level POST helper with caching
Future<Map<String, dynamic>> _post(
    String path, {
      Map<String, dynamic>? body,
      bool includeCookie = true,
    }) async {
  final uri = Uri.parse('$_baseUrl$path');
  final String bodyJson = json.encode(body ?? {});
  final String cacheKey = '${uri.toString()}|$bodyJson';

  // 1) check cache
  final entry = _cache[cacheKey];
  if (entry != null && DateTime.now().difference(entry.timestamp) < _cacheTimeout) {
    return entry.data;
  } else if (entry != null) {
    // Cache entry is expired, remove it
    _cache.remove(cacheKey);
  }

  // 2) make the HTTP call
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Connection': 'close',
    'X-Content-Type-Options': 'nosniff',
  };
  if (includeCookie) {
    final c = await _cookie;
    if (c != null) headers['Cookie'] = c;
  }

  final response = await http
      .post(uri, headers: headers, body: bodyJson)
      .timeout(_timeout, onTimeout: () {
    throw TimeoutException('Request timed out after $_timeout');
  });

  if (response.statusCode != 200) {
    throw Exception(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}');
  }

  final decoded = json.decode(response.body) as Map<String, dynamic>;
  if (decoded['success'] == false) {
    throw Exception('API error: ${decoded['message'] ?? decoded}');
  }

  // 3) store in cache
  _cache[cacheKey] = _CacheEntry(DateTime.now(), decoded);
  return decoded;
}

/// Logs in, captures and stores the session cookie.
Future<void> login(String email, String password) async {
  final uri = Uri.parse('$_baseUrl/auth/login');
  final response = await http
    .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Connection': 'close',
        'X-Content-Type-Options': 'nosniff',
      },
      body: json.encode({'email': email, 'password': password}),
    )
    .timeout(
      _timeout,
      onTimeout: () {
        throw TimeoutException('Login timed out after $_timeout');
      },
    );

  if (response.statusCode != 200) {
    throw Exception('Login failed: HTTP ${response.statusCode}');
  }

  final rawCookie = response.headers['set-cookie'];
  if (rawCookie != null) {
    await _setCookie(rawCookie);
  }
}

/// Fetches all programs grouped by university
Future<Map<String, List<ProgramData>>> fetchPrograms() async {
  final data = (await _post('/list/programs'))['data'];
  return (data as Map<String, dynamic>).map(
    (univ, list) => MapEntry(
      univ,
      (list as List).map((e) => ProgramData.fromJson(e as Map<String, dynamic>)).toList(),
    ),
  );
}

/// Fetches description text for a given program
Future<String> fetchProgramDescription(String programId) async {
  final data = await _post(
    '/query/program_description',
    body: {'ProgramID': programId},
  );
  return data['description'] as String;
}

/// Retrieves the full list of applicants
Future<List<Applicant>> fetchApplicants() async {
  final data = (await _post('/list/applicants'))['data'];
  return (data as List)
    .map((e) => Applicant.fromJson(e as Map<String, dynamic>))
    .toList();
}

/// Get applicant's metadata
Future<ApplicantMetadata> fetchApplicantMetadata(String displayName) async {
  final result = (await _post('/user/get_metadata', body: {'display_name': displayName}))['result'];
  return ApplicantMetadata.fromJson(result);
}

/// Fetches record details for a batch of IDs
Future<List<RecordData>> fetchRecordsByIds(List<String> ids) async {
  final data = (await _post('/query/by_records', body: {'IDs': ids}))['data'];
  return (data as Map<String, dynamic>).values
    .map((e) => RecordData.fromJson(e as Map<String, dynamic>))
    .toList();
}

/// Convenience method: fetches every record across all programs and applicants in batches
Future<List<RecordData>> fetchAllRecords({
  int batchSize = 50,
  void Function(int completed, int total)? onProgress,
}) async {
  final programs = await fetchPrograms();
  // "programs" is of type Map<String, List<Program>>.
  // E.g. "ASU" maps to a LIST of objects. The objects looks like:
  // {
  //   "ProgramID": "CS PhD@ASU",
  //   "University": "ASU",
  //   "Program": "CS PhD",
  //   "Region": ["US"],
  //   "Degree": "PhD",
  //   "TargetApplicantMajor": ["CS"],
  //   "Applicants": ["applicant1@2024", "applicant2@2024"]
  // }
  List<String> ids = [];
  for (final listOfPrograms in programs.values) {
    for (final program in listOfPrograms) {
      for (final applicant in program.Applicants) {
        ids.add('$applicant|${program.ProgramID}');
      }
    }
  }

  final int total = ids.length;
  int processed = 0;
  final List<RecordData> records = [];
  for (var i = 0; i < ids.length; i += batchSize) {
    final slice = ids.sublist(i, (i + batchSize > ids.length) ? ids.length : i + batchSize);

    final newRecords = await fetchRecordsByIds(slice);
    records.addAll(newRecords);
    // update progress indicator
    processed += slice.length;
    if (onProgress != null) {
      onProgress(processed, total);
    }
  }
  _ranks ??= await _loadUniversityRank();
  records.sort((a, b) {
    // 1) Compare by university rank
    final rankA = _ranks![a.getUniversity()]!;
    final rankB = _ranks![b.getUniversity()]!;
    final rankCompare = rankA.compareTo(rankB);
    if (rankCompare != 0) {
      return rankCompare;
    }
    // 2) If same rank, fall back to ProgramID lex order
    return a.programID.compareTo(b.programID);
  });
  return records;
}

Future<List<RecordData>> fetchGivenRecords(List<String> ids) async {
  final data = (await _post('/query/by_records', body: {'IDs': ids}))['data'];
  return (data as Map<String, dynamic>).values
    .map((e) => RecordData.fromJson(e as Map<String, dynamic>))
    .toList();
}

Future<String> getUniversityFullName(String abbr) async {
  _univFullnames ??= await _loadUniversityFullnames();
  return _univFullnames![abbr]!;
}
