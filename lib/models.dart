

class Timeline {
  final String? decision;
  final String? interview;
  final String? submit;

  Timeline({this.decision, this.interview, this.submit});

  factory Timeline.fromJson(Map<String, dynamic> json) => Timeline(
    decision: json['Decision'] as String?,
    interview: json['Interview'] as String?,
    submit: json['Submit'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Decision': decision,
    'Interview': interview,
    'Submit': submit,
  };
}

enum Semester { Fall, Spring, Summer, Winter }
enum Status   { Admit, Reject, Defer, Waitlist }
enum RegionEnum { US, CA, EU, UK, HK, SG, Others}

class RecordData {
  final String   applicantID;
  final String   detail;
  final bool     finalDecision;
  final String   programID;
  final int      programYear;
  final String   recordID;
  final Semester semester;
  final Status   status;
  final Timeline timeline;

  RecordData({
    required this.applicantID,
    required this.detail,
    required this.finalDecision,
    required this.programID,
    required this.programYear,
    required this.recordID,
    required this.semester,
    required this.status,
    required this.timeline,
  });

  factory RecordData.fromJson(Map<String, dynamic> json) => RecordData(
    applicantID:   json['ApplicantID'] as String,
    detail:        json['Detail']      as String,
    finalDecision: json['Final']       as bool,
    programID:     json['ProgramID']   as String,
    programYear:   json['ProgramYear'] as int,
    recordID:      json['RecordID']    as String,
    semester:      Semester.values.byName(json['Semester'] as String),
    status:        Status.values.byName(json['Status']   as String),
    timeline:      Timeline.fromJson(json['TimeLine'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'ApplicantID': applicantID,
    'Detail':      detail,
    'Final':       finalDecision,
    'ProgramID':   programID,
    'ProgramYear': programYear,
    'RecordID':    recordID,
    'Semester':    semester.name,
    'Status':      status.name,
    'TimeLine':    timeline.toJson(),
  };
}

class ProgramData {
  final String ProgramID;
  final String University;
  final String Program;
  final String Degree;
  final List<RegionEnum> Region;
  final List<String> Applicants;
  final List<String> TargetApplicantMajor;

  ProgramData({
    required this.ProgramID,
    required this.University,
    required this.Program,
    required this.Degree,
    required this.Region,
    required this.Applicants,
    required this.TargetApplicantMajor,
  });

  factory ProgramData.fromJson(Map<String, dynamic> json) => ProgramData(
    ProgramID: json['ProgramID'] as String,
    University: json['University'] as String,
    Program: json['Program'] as String,
    Degree: json['Degree'] as String,
    Region: (json['Region'] as List<dynamic>)
        .map((e) => RegionEnum.values.byName(e as String))
        .toList(),
    Applicants: (json['Applicants'] as List<dynamic>).cast<String>(),
    TargetApplicantMajor: (json['TargetApplicantMajor'] as List<dynamic>).cast<String>(),
  );

  Map<String, dynamic> toMap() => {
    'ProgramID': ProgramID,
    'University': University,
    'Program': Program,
    'Degree': Degree,
    'Region': Region.map((e) => e.name).toList(),
    'Applicants': Applicants,
    'TargetApplicantMajor': TargetApplicantMajor,
  };

  @override
  String toString() {
    return toMap().toString();
  }
}

class AllPrograms {
  final Map<String, List<ProgramData>> data;

  AllPrograms({required this.data});

  factory AllPrograms.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((e) => ProgramData.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return AllPrograms(data: data);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((key, value) => MapEntry(
        key,
        value.map((e) => e.toMap()).toList(),
      )),
    };
  }
}
