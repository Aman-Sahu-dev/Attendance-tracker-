//using sqlLite 

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS subjects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    name TEXT NOT NULL,

    code TEXT NOT NULL UNIQUE,

    frequency_per_week INTEGER NOT NULL
        CHECK (frequency_per_week > 0),

    expected_classes INTEGER NOT NULL
        CHECK (expected_classes > 0)
);


CREATE TABLE IF NOT EXISTS schedule (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    subject_id INTEGER NOT NULL,

    day_of_week INTEGER NOT NULL
        CHECK (day_of_week BETWEEN 1 AND 7),

    start_time TEXT NOT NULL,

    end_time TEXT NOT NULL,

    FOREIGN KEY (subject_id)
        REFERENCES subjects(id)
        ON DELETE RESTRICT
);


CREATE TABLE IF NOT EXISTS attendance_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    subject_id INTEGER NOT NULL,

    date TEXT NOT NULL,

    time TEXT,

    status TEXT NOT NULL
        CHECK (status IN ('P', 'A', 'N')),

    FOREIGN KEY (subject_id)
        REFERENCES subjects(id)
        ON DELETE RESTRICT
);


CREATE INDEX IF NOT EXISTS idx_schedule_day
ON schedule(day_of_week);


CREATE INDEX IF NOT EXISTS idx_attendance_date
ON attendance_logs(date);


CREATE INDEX IF NOT EXISTS idx_attendance_subject
ON attendance_logs(subject_id);
