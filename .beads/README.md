# Beads task storage

This checkout uses local embedded Dolt. The actor is `codex`, and Dolt auto-commit is off. No Beads remote is configured.

The database in `.beads/embeddeddolt/` is the authority for mutable tasks, dependencies, work notes, and operational memory. Git excludes that database and local runtime files.

Run these commands before project work:

```bash
bd prime
bd ready
bd show <id>
bd update <id> --claim
```

Close an issue with `bd close <id>` only after its acceptance criteria and validation pass.

## Git snapshot

`.beads/issues.jsonl` is a passive issue export. It includes issue records, dependencies, and comments. It is not a second task authority or a full database backup. The default export excludes persistent memories and internal infrastructure records.

Refresh the snapshot before an authorized Git commit that includes task changes:

```bash
bd export -o .beads/issues.jsonl
```

A Git push publishes this snapshot. It does not synchronize the live Dolt database. Do not run Dolt remote synchronization or configure a Beads remote without explicit authorization.

Keep requirements, decisions, architecture, and release criteria in durable project documents. Keep secrets out of Beads and its exports.
