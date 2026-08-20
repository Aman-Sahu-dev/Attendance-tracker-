
# Attendance Tracker

A terminal-first, student-oriented attendance tracking tool — built to stop depending on the college ERP, because many teachers never bother registering attendance in it at all.

## Problem

College ERPs are an unreliable source of truth for attendance. Teachers frequently skip marking it, leaving students with no accurate record of where they actually stand — and no way to plan around it.

This tool puts the record-keeping in the student's own hands: log it yourself, trust the numbers, plan accordingly.

## Benefits

1. **Forecasting** — Calculate a safe "bunk margin." Given expected classes for the term (e.g. 42) and classes attended so far (e.g. 36), tell the student how many more they can safely miss while staying above the attendance threshold.

2. **Record keeping** — Daily logs: which subject, which date, and the outcome — present, absent, or *neutral* (class was cancelled or covered by someone else — doesn't count against or for the student).

3. **Dashboard view** — One place to see the full picture: today's schedule, overall %, subject-wise %, which subjects are below threshold, and how many classes are needed to climb back above it.

4. **Consistency checkout** — A side benefit of having logs: track how consistent attendance has been over weeks/months, as its own separate trend view.

## Design Philosophy

Optimizing for **clarity and separation of responsibility**, not speed or storage efficiency. Data volume for a single student, even across years, is trivial (well under 1GB) — so there's no cost to a design that favors simplicity and correctness over cleverness.

## Architecture

Four tables — three genuinely independent, one a controlled cache. No manually-synced duplicate state.

### `master`

Static subject configuration. Set once per term, rarely touched after.

| column           | purpose                                    |
| ---------------- | ------------------------------------------ |
| id               | primary key                                |
| subject          | subject name                               |
| subject_code     | subject code                               |
| expected_classes | max expected classes per academic calendar |
| freq_per_week    | how many times per week this subject meets |

### `schedule`

Which subjects run on which day, and what kind of session. A subject can appear more than once on the same day (e.g. lecture *and* lab).

| column       | purpose                     |
| ------------ | --------------------------- |
| id           | primary key                 |
| subject_id   | FK → master                 |
| day          | e.g. Monday, Tuesday        |
| session_type | e.g. lecture, lab, tutorial |

Used to drive the daily prompt: when Monday comes around, only ask about the subjects scheduled for Monday.

A scheduled class is not the only kind of class that can be logged. **Add-on classes** — extra, makeup, or impromptu classes — can be recorded directly in `logs` without requiring a matching `schedule` row. The schedule exists to drive the normal daily prompt; it is not a restriction on what attendance events are allowed to exist. Because apparently college timetables occasionally enjoy improvisation.

### `logs` — the single source of truth

The event ledger. Every attendance entry, ever. Nothing else stores counts or percentages directly — those are always computed from this table.

| column     | purpose                          |
| ---------- | -------------------------------- |
| id         | primary key                      |
| subject_id | FK → master                      |
| date       | date of the class                |
| status     | `present` / `absent` / `neutral` |

`neutral` covers cancelled or overtaken classes — it's still recorded (so the history is complete), but it's excluded from every attendance calculation, so it never moves the percentage in either direction.

The CLI may accept **P/A/N** as a convenience shortcut: `P` is stored as `present`, `A` as `absent`, and `N` as `neutral`. This is purely an input-layer convenience and does not change the schema or the stored status values.

### `daily_interaction` — cached snapshot, not independently maintained

Holds per-subject running totals for instant dashboard reads (no full-table aggregation on every view). The key rule: **this table is never written to directly.** It is only ever fully wiped and rebuilt from `logs` by a `recompute_stats(subject_id)` call, triggered on every log write (insert/edit/delete).

| column        | purpose                                                   |
| ------------- | --------------------------------------------------------- |
| subject_id    | FK → master                                               |
| total_counted | count of logs where status != neutral                     |
| attended      | count of logs where status = present                      |
| percentage    | attended / total_counted * 100                            |
| makeup        | classes needed to climb back above threshold, if below it |

```sql
-- Rebuild rule, not incremental update:
-- 1. DELETE FROM daily_interaction WHERE subject_id = ?
-- 2. Recount straight from logs, INSERT the fresh row
```

Because it's fully regenerated (never patched), it can never independently drift from `logs` — if it ever looks wrong, re-running the rebuild fixes it. `logs` remains the only table that's a true, independent source of data.

## Key Design Decisions

* **Single global attendance threshold** (e.g. 75%) applies across all subjects — not configurable per subject. Lives as a constant/config value, not a database column.
* **Schedule allows multiple sessions per subject per day** — `session_type` distinguishes lecture from lab from tutorial on the same day.
* **Add-on classes are allowed without a matching schedule row** — extra or impromptu classes are legitimate attendance events and can be logged directly in `logs`.
* **P/A/N are CLI input shortcuts** — `P`, `A`, and `N` expand to and are stored as `present`, `absent`, and `neutral`; this is a UX convenience, not a schema change.
* **Stack**: Python + SQLite for the first working version. A Rust TUI is a possible future direction once the core logic is proven out.

## Challenge: Synchronization (solved by design)

The original 4-table sketch stored running totals (`daily_interaction`) *alongside* the raw event log (`logs`) — two sources of truth for the same numbers, which risked drifting apart (crashes mid-write, manual edits to one but not the other, bugs).

**Fix:** `logs` is the only table anyone writes to directly for attendance facts. `daily_interaction` still exists as a real table (for fast dashboard reads), but it is never patched incrementally — every write to `logs` triggers a full wipe-and-rebuild of the affected subject's row in `daily_interaction`, recomputed straight from `logs`. Since it's always fully regenerated rather than independently edited, it can't silently drift — worst case, re-running the rebuild fixes it.

## Status

Design phase — schema finalized conceptually (4 tables: master, schedule, logs, daily_interaction-as-cache). Next: SQLite table creation + recompute_stats function, then the forecasting (safe-bunk) formula, then the Python CLI/TUI itself.

## Technologies

* **Python** — core application logic, CLI/TUI
* **SQLite** — embedded database (master, schedule, logs, daily_interaction tables)
* Possible future: **Rust** — for a more capable TUI, once core logic is proven in Python
