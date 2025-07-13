import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opensist_alpha/models.dart';

class ApiString {
  static const root = "https://opensist.tech/";
  static const programList = "${root}api/list/programs";
  static const login = "${root}api/auth/login";
  static const getRecordsByRecordIds = "${root}api/query/by_records";
  static const applicantList = "${root}api/list/applicants";
}

// const PROGRAM_DESC = ROOT + "api/query/program_description";
// const ADD_MODIFY_PROGRAM = ROOT + "api/mutating/new_modify_program";
// const SEND_RESET_VERIFY_TOKEN = ROOT + "api/auth/forget";
// const RESET_PASSWORD = ROOT + "api/auth/forget_verify_reset";
// const SEND_VERIFY_TOKEN = ROOT + "api/auth/register";
// const REGISTER = ROOT + "api/auth/verify";
// const LOGIN = ROOT + "api/auth/login";
// const LOGOUT = ROOT + "api/my/logout";
// const REMOVE_PROGRAM = ROOT + "api/admin/remove_program";
// const MODIFY_PROGRAM_ID = ROOT + "api/admin/modify_program_id";
// const INBOX = ROOT + "api/admin/email/inbox";
// const TRASH = ROOT + "api/admin/email/trash";
// const GET_EMAIL_CONTENT = ROOT + "api/admin/email/fetch_one";
// const MOVE_TO_TRASH = ROOT + "api/admin/email/move_to_trash";
// const MOVE_BACK_INBOX = ROOT + "api/admin/email/move_back_inbox";
// const REMOVE_FROM_TRASH = ROOT + "api/admin/email/remove_from_trash";
// const ADD_MODIFY_APPLICANT = ROOT + "api/mutating/new_modify_applicant";
// const REMOVE_APPLICANT = ROOT + "api/mutating/remove_applicant";
// const APPLICANT_LIST = ROOT + "api/list/applicants";
//
// const ADD_MODIFY_RECORD = ROOT + "api/mutating/new_modify_record";
// const REMOVE_RECORD = ROOT + "api/mutating/remove_record";
// const UPLOAD_AVATAR = ROOT + "api/user/upload_avatar";
// const GET_DISPLAY_NAME = ROOT + "api/my/get_display_name";
// const GET_METADATA = ROOT + "api/user/get_metadata";
// const GET_AVATAR = ROOT + "api/user/get_avatar";
// const TOGGLE_NICKNAME = ROOT + "api/my/toggle_nickname";
// const UPDATE_CONTACT = ROOT + "api/user/update_contact";
//
// const FILE_LIST = ROOT + "api/list/files";
// const GET_FILE_CONTENT = ROOT + "api/query/file_content";
// const REMOVE_FILE = ROOT + "api/mutating/remove_file";
// const ADD_FILE = ROOT + "api/mutating/new_file";
// const MODIFY_FILE = ROOT + "api/mutating/modify_file";
//
// const COLLECT_PROGRAM = ROOT + "api/user/collect_program";
// const UNCOLLECT_PROGRAM = ROOT + "api/user/un_collect_program";
//
// // --- New Post/Comment API Endpoints ---
// const CREATE_POST_API = ROOT + "api/post/create_post";
// const CREATE_COMMENT_API = ROOT + "api/post/create_comment";
// const MODIFY_CONTENT_API = ROOT + "api/post/modify_content";
// const TOGGLE_LIKE_API = ROOT + "api/post/toggle_like";
// const LIST_POSTS_API = ROOT + "api/post/list_posts";
// const GET_CONTENT_API = ROOT + "api/post/get_content";
// const DELETE_CONTENT_API = ROOT + "api/post/delete_content";

const timeoutDuration = Duration(seconds: 10);
const timeoutErrorMessage = 'Timeout occurred while waiting for the server response.';

Future<http.Response> login(final String email, final String password) async {
  final http.Response res = await http.post(
    Uri.parse(ApiString.login),
    headers: {
      'Content-Type': 'application/json',
      'Connection': 'close',
      'X-Content-Type-Options': 'nosniff',
    },
    body: json.encode({'email': email, 'password': password}),
  ).timeout(timeoutDuration, onTimeout: () { throw TimeoutException(timeoutErrorMessage); });
  return res;
}

Future<http.Response> fetchPrograms(String cookie) async {
  final response = await http.post(
    Uri.parse(ApiString.programList),
    headers: {
      'Content-Type': 'application/json',
      'Connection': 'close',
      'X-Content-Type-Options': 'nosniff',
      'Cookie': cookie,
    },
    body: json.encode({}),
  ).timeout(timeoutDuration, onTimeout: () { throw TimeoutException(timeoutErrorMessage); });
  return response;
}

Future<List<Applicant>> fetchApplicants(String cookie) async {
  final response = await http.post(
    Uri.parse(ApiString.applicantList),
    headers: {
      'Content-Type': 'application/json',
      'Connection': 'close',
      'X-Content-Type-Options': 'nosniff',
      'Cookie': cookie,
    },
    body: json.encode({}),
  ).timeout(timeoutDuration, onTimeout: () { throw TimeoutException(timeoutErrorMessage); });

  if (response.statusCode != 200) {
    throw Exception('Failed to load applicants');
  }

  final body = json.decode(response.body) as Map<String, dynamic>;
  if (body['success'] == false) {
    throw Exception('Authentication failed');
  }

  final data = body['data'] as List<dynamic>;
  return data.map((e) => Applicant.fromJson(e as Map<String, dynamic>)).toList();
}

Future<List<RecordData>> fetchDataPoints(String cookie) async {
  final response = await fetchPrograms(cookie);
  if (response.statusCode != 200) {
    throw Exception('Failed to load programs');
  }

  final body = json.decode(response.body) as Map<String, dynamic>;
  if (body['success'] == false) {
    throw Exception('Authentication failed');
  }

  final bodyData = body['data'] as Map<String, dynamic>;

  List<String> idsToFetch = [];
  for (final listOfPrograms in bodyData.values) {
    for (final programEntry in listOfPrograms) {
      final programData = ProgramData.fromJson(programEntry as Map<String, dynamic>);
      for (final applicant in programData.Applicants) {
        // _rows.add({
        //   'ProgramID': programData.ProgramID,
        //   'Applicant': applicant,
        // });
        idsToFetch.add("$applicant|${programData.ProgramID}");
      }
    }
  }
  List<dynamic> recordDetailMaps = [];
  const batchSize = 100;
  for (int i = 0; i < idsToFetch.length; i += batchSize) {
    // slice the list "idsToFetch" into a batch starting at i and ends at min(i + batchSize, idsToFetch.length);
    final batch = idsToFetch.sublist(i, i + batchSize < idsToFetch.length ? i + batchSize : idsToFetch.length);
    final response = await http.post(
      Uri.parse(ApiString.getRecordsByRecordIds),
      headers: {
        'Content-Type': 'application/json',
        'Connection': 'close',
        'X-Content-Type-Options': 'nosniff',
        'Cookie': cookie,
      },
      body: json.encode({'IDs': batch}),
    ).timeout(timeoutDuration, onTimeout: () { throw TimeoutException(timeoutErrorMessage); });
    if (response.statusCode != 200) {
      throw Exception('Failed to load data points');
    }
    final responseBody = json.decode(response.body) as Map<String, dynamic>;
    if (responseBody['success'] == false) {
      throw Exception('Authentication failed');
    }
    final data = responseBody['data'] as Map<String, dynamic>;
    for (final entry in data.entries) {
      recordDetailMaps.add(RecordData.fromJson(entry.value as Map<String, dynamic>));
    }
  }
  return recordDetailMaps.map((e) => e as RecordData).toList();
}

