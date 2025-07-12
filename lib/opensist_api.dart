import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiString {
  static const String root = "https://opensist.tech/";
  static const String programList = "${root}api/list/programs";
  static const String login  = "${root}api/auth/login";
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
// const GET_RECORD_BY_RECORD_IDs = ROOT + "api/query/by_records";
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

Future<http.Response> login(final String email, final String password) async {
  final http.Response res = await http.post(
    Uri.parse(ApiString.login),
    headers: {
      'Content-Type': 'application/json',
      'Connection': 'close',
      'X-Content-Type-Options': 'nosniff',
    },
    body: json.encode({'email': email, 'password': password})
  );
  return res;
}

