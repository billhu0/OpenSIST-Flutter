

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

class Toefl {
  final int total, s, r, l, w;
  Toefl({
    required this.total,
    required this.s,
    required this.r,
    required this.l,
    required this.w,
  });

  @override
  String toString() {
    return 'TOEFL(total: $total, speaking: $s, reading: $r, listening: $l, writing: $w)';
  }
}

class Ielts {
  final double total, s, r, l, w;
  Ielts({
    required this.total,
    required this.s,
    required this.r,
    required this.l,
    required this.w,
  });

  @override
  String toString() {
    return 'IELTS(total: $total, speaking: $s, reading: $r, listening: $l, writing: $w)';
  }
}

class Gre {
  final double total, v, q, aw;
  Gre({
    required this.total,
    required this.v,
    required this.q,
    required this.aw,
  });

  @override
  String toString() {
    return 'GRE(total: $total, verbal: $v, quantitative: $q, analytic writing: $aw)';
  }
}

class Applicant {
  final String applicantID;
  final String gender;
  final String currentDegree;
  final int applicationYear;
  final String major;
  final double gpa;
  final String ranking;
  final Gre? gre;
  final Toefl? toefl;
  final Ielts? ielts;

  Applicant({
    required this.applicantID,
    required this.gender,
    required this.currentDegree,
    required this.applicationYear,
    required this.major,
    required this.gpa,
    required this.ranking,
    this.gre,
    this.toefl,
    this.ielts,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) => Applicant(
    applicantID: json['ApplicantID'] as String,
    gender: json['Gender'] as String,
    currentDegree: json['CurrentDegree'] as String,
    applicationYear: json['ApplicationYear'] as int,
    major: json['Major'] as String,
    gpa: (json['GPA'] as num).toDouble(),
    ranking: json['Ranking'] as String,
    gre: json['GRE'] != null
        ? Gre(
            total: (json['GRE']['Total'] as num).toDouble(),
            v: (json['GRE']['V'] as num).toDouble(),
            q: (json['GRE']['Q'] as num).toDouble(),
            aw: (json['GRE']['AW'] as num).toDouble(),
          )
        : null,
    toefl: json['EnglishProficiency']['TOEFL'] != null
        ? Toefl(
            total: json['EnglishProficiency']['TOEFL']['Total'] as int,
            s: json['EnglishProficiency']['TOEFL']['S'] as int,
            r: json['EnglishProficiency']['TOEFL']['R'] as int,
            l: json['EnglishProficiency']['TOEFL']['L'] as int,
            w: json['EnglishProficiency']['TOEFL']['W'] as int,
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'ApplicantID': applicantID,
    'Gender': gender,
    'CurrentDegree': currentDegree,
    'ApplicationYear': applicationYear,
    'Major': major,
    'GPA': gpa,
    'Ranking': ranking,
    'GRE': gre != null ? {
      'Total': gre!.total,
      'V': gre!.v,
      'Q': gre!.q,
      'AW': gre!.aw,
    } : null,
    'EnglishProficiency': {
      'Toefl': toefl != null ? {
        'Total': toefl!.total,
        'S': toefl!.s,
        'R': toefl!.r,
        'L': toefl!.l,
        'W': toefl!.w,
      } : null,
      'Ielts': ielts != null ? {
        'Total': ielts!.total,
        'S': ielts!.s,
        'R': ielts!.r,
        'L': ielts!.l,
        'W': ielts!.w,
      } : null,
    },
  };
}
