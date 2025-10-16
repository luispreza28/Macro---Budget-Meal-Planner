import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class IcsExportService {
  // Build a basic ICS file with events for each meal.
  // tz handling: we'll write floating local times; most calendars will interpret as local.
  Future<File> buildIcs({
    required String calendarName,
    required List<IcsEvent> events,
    String? filenameHint,
  }) async {
    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//MacroBudgetPlanner//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH');

    for (final e in events) {
      buf.writeln('BEGIN:VEVENT');
      buf.writeln('UID:${e.uid}');
      buf.writeln('DTSTAMP:${_fmtUtc(DateTime.now().toUtc())}');
      buf.writeln('DTSTART:${_fmtLocal(e.start)}');
      if (e.end != null) buf.writeln('DTEND:${_fmtLocal(e.end!)}');
      buf.writeln('SUMMARY:${_escape(e.summary)}');
      if (e.description != null) buf.writeln('DESCRIPTION:${_escape(e.description!)}');
      if (e.location != null) buf.writeln('LOCATION:${_escape(e.location!)}');
      buf.writeln('END:VEVENT');
    }

    buf.writeln('END:VCALENDAR');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${(filenameHint ?? calendarName).replaceAll(" ", "_")}.ics');
    await file.writeAsString(buf.toString());
    return file;
  }

  String _fmtUtc(DateTime d) => DateFormat("yyyyMMdd'T'HHmmss'Z'").format(d);
  String _fmtLocal(DateTime d) => DateFormat("yyyyMMdd'T'HHmmss").format(d);
  String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
}

class IcsEvent {
  final String uid; // unique per event
  final DateTime start;
  final DateTime? end;
  final String summary;
  final String? description;
  final String? location;
  const IcsEvent({required this.uid, required this.start, this.end, required this.summary, this.description, this.location});
}

