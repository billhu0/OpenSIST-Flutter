import 'package:flutter/material.dart';
import '../models/models.dart';

const double programIdColWidth = 175;
const double applicantColWidth = 175;
const double statusColWidth = 90;
const double finalColWidth = 70;
const double seasonWidth = 100;
const double timelineDecisionWidth = 120;
const double timelineInterviewWidth = 120;
const double timelineApplicationWidth = 120;
const double detailWidth = 300;
final double totalWidth = (
    programIdColWidth + applicantColWidth + statusColWidth + finalColWidth + seasonWidth +
        timelineDecisionWidth + timelineInterviewWidth + timelineApplicationWidth + detailWidth
);
const double headerHeight = 48;

final statusColor = {
  Status.Admit: Colors.green,
  Status.Reject: Colors.red,
  Status.Defer: Colors.orange,
  Status.Waitlist: Colors.grey,
};

Widget recordTable(
    BuildContext context,
    List<RecordData> records, {
      bool showProgramColumn = true,
      bool showApplicantColumn = true,
      bool shrinkWrap = true,
    }) {
  // Recompute total width based on whether ProgramID is shown
  final double tableWidth =
      (showProgramColumn ? programIdColWidth : 0) +
          (showApplicantColumn ? applicantColWidth : 0) +
          statusColWidth +
          finalColWidth +
          seasonWidth +
          timelineDecisionWidth +
          timelineInterviewWidth +
          timelineApplicationWidth +
          detailWidth;

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: tableWidth,
      child: Column(
        children: [
          // ─── Sticky Header ────────────────────────────
          Container(
            height: headerHeight,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            child: Row(
              children: [
                if (showProgramColumn)
                  SizedBox(
                    width: programIdColWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'ProgramID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (showApplicantColumn)
                  SizedBox(
                    width: applicantColWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Applicant',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                SizedBox(
                  width: statusColWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: finalColWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Final',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: seasonWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Season',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: timelineDecisionWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Decision',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: timelineInterviewWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Interview',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: timelineApplicationWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Application',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: detailWidth,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Data Rows ─────────────────────────────────
          ListView.separated(
            shrinkWrap: shrinkWrap,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            itemBuilder: (context, index) {
              final record = records[index];
              return Row(
                children: [
                  if (showProgramColumn)
                    SizedBox(
                      width: programIdColWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/opensist_program',
                            arguments: record.programID,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).highlightColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              record.programID,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).appBarTheme.foregroundColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Applicant
                  if (showApplicantColumn)
                    SizedBox(
                      width: applicantColWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/opensist_applicant',
                            arguments: record.applicantID,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).highlightColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              record.applicantID,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).appBarTheme.foregroundColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Status
                  SizedBox(
                    width: statusColWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor[record.status] ?? Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.status.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  // Final
                  SizedBox(
                    width: finalColWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(record.finalDecision ? 'Yes' : 'No'),
                    ),
                  ),

                  // Season
                  SizedBox(
                    width: seasonWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${record.semester.name} ${record.programYear}',
                      ),
                    ),
                  ),

                  // Timeline Decision
                  SizedBox(
                    width: timelineDecisionWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(record.timeline.decision ?? ''),
                    ),
                  ),

                  // Timeline Interview
                  SizedBox(
                    width: timelineInterviewWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(record.timeline.interview ?? ''),
                    ),
                  ),

                  // Timeline Application
                  SizedBox(
                    width: timelineApplicationWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(record.timeline.submit ?? ''),
                    ),
                  ),

                  // Details
                  SizedBox(
                    width: detailWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(record.detail ?? ''),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
