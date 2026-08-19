# Attendance Tracker

A simple terminal-based attendance tracker built with Python and SQLite.

The goal is to maintain a personal attendance record independently of the
college ERP and provide useful statistics and forecasting from that record.

## Features

- Store subject information
- Store weekly class schedules
- Record daily attendance
- Use `P`, `A`, and `N` status:
  - `P` = Present
  - `A` = Absent
  - `N` = Neutral / class not counted
- Automatically show the relevant subjects for the current day
- Support multiple classes of the same subject on the same day
- Support additional classes without changing the normal schedule
- Store attendance locally using SQLite
- Filter attendance by subject, week, month, or date range
- View subject-wise and overall attendance
- Forecast future attendance
- Calculate how many classes can be missed while maintaining the target
- Calculate how many classes need to be attended to recover attendance

## Design

The project intentionally uses a simple three-table model.

```text
subjects
   │
   ▼
schedule
   │
   ▼
attendance_logs
```

### Subjects

Stores relatively static information about each subject.

```text
id
name
code
frequency_per_week
expected_classes
```

### Schedule

Stores the normal weekly timetable.

```text
id
subject_id
day_of_week
start_time
end_time
```

The schedule is mainly used to make daily attendance entry convenient.

### Attendance Logs

Stores what actually happened.

```text
id
subject_id
date
time
status
```

Status:

```text
P = Present
A = Absent
N = Neutral
```

`N` does not contribute to conducted or attended classes.

Additional classes do not require a separate type or table. They are simply
additional attendance log entries.

## Daily Workflow

The intended interaction is simple.

For example, on Monday:

```text
Monday, 18 August

Today's Schedule
────────────────────────────

DSA   09:00 - 10:00   [P/A/N]
ML    10:00 - 11:00   [P/A/N]
CS    11:00 - 12:00   [P/A/N]

DSA > P
ML  > P
CS  > A

Attendance recorded.
```

The user only enters the attendance status. The program handles the date,
subject, and schedule automatically.

## Database

SQLite is used for local persistent storage.

The database is stored outside the source directory:

```text
attendance.db
```

The database schema is defined in:

```text
src/tracker/schema.sql
```

## Project Structure

```text
attendence_tracker/
├── README.md
├── attendance.db
└── src/
    └── tracker/
        ├── __init__.py
        ├── main.py
        └── schema.sql
```

## Goals

The project is intentionally terminal-based and locally stored.

The focus is on:

- Python
- SQLite
- SQL
- Data modeling
- File structure
- CLI design
- Statistics
- Forecasting

No web frontend is required for the initial version.
