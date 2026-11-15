# GitHub reminders for semester milestones

The `Milestone reminders` workflow checks open milestone Issues in
`ATINS-Labs/atins-komis-template`. A milestone is an open Issue whose title
starts with `M` followed by a number, such as `M1 — ...`. Its deadline must be
written in the Issue body as a separate line:

```text
Termin: YYYY-MM-DD
```

Future milestone Issues are published by the separate
`Create milestone from instructor file` workflow. The instructor supplies the
complete task content in `.github/milestones/M<number>.md`; the workflow never
generates or edits the exercise's substantive content. It validates the
filename, matching Markdown title, exactly one valid deadline line, and
non-empty task content. It skips publication if an Issue for that milestone
number already exists. Student mentions are prepended as a separate line, and
the exact supplied Markdown content follows unchanged. The created Issue link
is saved in the workflow run summary.

The creation workflow runs when a milestone file is added or updated on
`main`, or can be started manually from **Actions → Create milestone from
instructor file**. Manual runs accept an ID such as `M2` or filename `M2.md`.
Publication is allowed only from `main`. Invalid or incomplete files fail
before an Issue is created.

The date in the Issue is authoritative. The workflow runs daily at 08:00 UTC.
Both workflows check out the repository and read `.github/atins-roster.json`.
Its `students` array is the sole source of student logins, and its `instructor`
field identifies the instructor; blank values and duplicate logins are removed
and the instructor is excluded from student mentions. An invalid or empty
roster stops the workflow with a clear error.

## Formal submission

A student submits work by commenting on the corresponding milestone Issue
using one of these forms:

```text
M1 — oddane do weryfikacji
Repo/branch: LOGIN_GITHUB
```

or:

```text
M1 — aktualny stan pracy przesłany
Repo/branch: LOGIN_GITHUB
```

The milestone identifier must match the Issue title. The comment author must
be listed in `.github/atins-roster.json`. Its GitHub timestamp is the formal
submission time; a commit timestamp is not treated as a submission time.

The workflow reminds only students who have not made a matching formal
submission:

- three days before the deadline;
- one day after the deadline.

Reminder comments include a date-specific hidden marker to prevent duplicate
comments. The post-deadline reminder states that missing GitHub evidence is not
proof that the work was not completed.

GitHub generates notifications according to each account's settings.
Notification emails depend on each student's individual GitHub Notifications
settings and are not guaranteed.

## Required repository configuration

No organization-read token or team-membership API access is required. Each
workflow uses the automatically provided `GITHUB_TOKEN` to read Issues and
comments and to create Issue content. Do not put tokens in repository files or
Issue text.

## Manual testing

In GitHub, open **Actions → Milestone reminders → Run workflow**:

1. Leave `dry_run` enabled (the default) to inspect planned mentions in the
   workflow log without creating comments.
2. Set `reference_date` to a test date in `YYYY-MM-DD` form to simulate the
   three-days-before or one-day-after trigger. For example, for an Issue whose
   deadline is `2026-11-14`, use `2026-11-11` or `2026-11-15`.
3. Keep `dry_run` enabled during tests. Disable it only when you intend to
   publish real reminder comments.

To test milestone creation, open **Actions → Create milestone from
instructor file → Run workflow**, enter an existing valid milestone file such
as `M2`, and run it only when actual Issue creation is intended. Publication
creates a real Issue; there is no dry-run mode for this workflow. Invalid
files and duplicate milestone IDs are not published.

Manual runs without a date override use the current UTC date. The daily
schedule is also evaluated in UTC. The workflow does not modify Issues that
lack a valid `Termin: YYYY-MM-DD` line; it reports them as warnings in the
Actions log.

Issue #7 currently needs a `Termin: YYYY-MM-DD` line before this workflow can
send M1 reminders. The workflow intentionally does not edit milestone Issues.

## Scope and limitations

- The workflow monitors open milestone Issues in the template repository, not
  student repositories.
- Student membership is read from `.github/atins-roster.json`; keep its
  `students` and `instructor` fields current.
- The workflow recognizes formal submission comments only when written by a
  listed student and matching the milestone identifier.
- Marker comments are date-specific; changing an Issue deadline creates a new
  reminder window with a different marker.
- This automation records reminder and submission comments; it does not assess
  the quality or completion of student work.
