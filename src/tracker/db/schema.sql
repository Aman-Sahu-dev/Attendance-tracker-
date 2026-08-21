-- Attendance Tracker — SQLite schema
-- logs is the single source of truth. daily_interaction is a rebuilt cache,
-- never written to directly (see recompute_stats in stats_cache.py).

PRAGMA foreign_keys = ON;

-- Static, per-term subject config. Set once, left alone.
CREATE TABLE IF NOT EXISTS master (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    subject             TEXT NOT NULL,
    subject_code        TEXT NOT NULL UNIQUE,
    expected_classes    INTEGER NOT NULL,
    freq_per_week       INTEGER NOT NULL
);

-- Weekly timetable. A subject can appear more than once per day
-- (lecture + lab). session_type labels the kind of session;
-- start_time/end_time give it an actual, orderable slot.
CREATE TABLE IF NOT EXISTS schedule (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    subject_id      INTEGER NOT NULL REFERENCES master(id),
    day             TEXT NOT NULL CHECK (day IN
                        ('monday','tuesday','wednesday','thursday','friday','saturday','sunday')),
    session_type    TEXT NOT NULL DEFAULT 'lecture',
    start_time      TEXT NOT NULL,      -- 24h "HH:MM"
    end_time        TEXT NOT NULL       -- 24h "HH:MM"
);

-- Composite index: the daily-prompt query is "give me subjects for day X",
-- so day leads (the filter), subject_id follows (what's selected).
CREATE INDEX IF NOT EXISTS idx_schedule_day_subject ON schedule(day, subject_id);

-- The event ledger. Single source of truth for all attendance facts.
-- A log entry does NOT require a matching schedule row — this is what
-- allows add-on/impromptu classes.
CREATE TABLE IF NOT EXISTS logs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    subject_id      INTEGER NOT NULL REFERENCES master(id),
    date            TEXT NOT NULL,      -- ISO 8601: YYYY-MM-DD
    status          TEXT NOT NULL CHECK (status IN ('present','absent','neutral'))
);

CREATE INDEX IF NOT EXISTS idx_logs_subject_id ON logs(subject_id);
CREATE INDEX IF NOT EXISTS idx_logs_date ON logs(date);

-- Rebuilt cache. Never written to directly — always fully wiped and
-- regenerated from logs by recompute_stats(subject_id).
CREATE TABLE IF NOT EXISTS daily_interaction (
    subject_id      INTEGER PRIMARY KEY REFERENCES master(id),
    total_counted   INTEGER NOT NULL DEFAULT 0,
    attended        INTEGER NOT NULL DEFAULT 0,
    percentage      REAL NOT NULL DEFAULT 0,
    makeup          INTEGER NOT NULL DEFAULT 0
);
