# Timesheets #84 developer evidence

Candidate: [ea2f07284edf798510497907e61ab43d0d5641e2](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/commit/ea2f07284edf798510497907e61ab43d0d5641e2).
Source branch: [codex/andvari/timesheets84-usage](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/tree/codex/andvari/timesheets84-usage). Owner: Andvari (worker-5).

Both app and test app compile with0errors/0warnings. Downloaded deployed packages match source commit and localSHA256. Own COSMO f073ff287f0d, BC28.5W1, Foundation28.0.11.665.

Full configured254-test suite passed twice:254/254 each,0failed/0skipped, runner130451, range95600..95699, no exclusions. Actual native Item/Resource/Job posting invokes standard RunWithCheck and asserts owned ledger/state; explicit Rejected submission, blocked-resource refusal and week/status intersection are included.

MCP:48/48planned scenarios plus1/1supplemental generic-write guard across1033/1039. Seven Timesheets.Usage types plus Data.Records.Set protected-field refusal. All fixtures self-seeded;14absence readbacks per MCP locale. English readback recovery replayed0writes.

WebClient via Playwright MCP:2final scenarios passed at1033/1039, exact owned row, localized captions and0editable business fields. English restored; UI fixture13absence readbacks. Initial stale-bookmark setup failure and restoration-locator retry are retained privately and disclosed in verification-history.json. Final native own-fixture12table readbacks0. Exact older2Projects/tasks and namedemptytemplates/batches cleared after savedGUID/provenance/dependency checks. Temporary cleanup extension uninstalled/unpublished. Container retained for separately trackedTimesheets60closure, not deleted.

**AC13 remains pending Claude Code/Architect disposition.** All new IDs fit unchanged assigned10036785..10036884range using free per-type slots. No range extension or workbook row fabricated. All originalAC01–AC14 remain in acceptance-criteria-original.json and acceptance-matrix.json. This evidence is not all-ACcompletion, independent Claude verification, Grok clearance, merge, deployment or UAT.

Standards snapshot52ba4754cfd614e4a7c50af87b30149b18b313e3, captured2November; no fresh-sync claim. Layer1scanned23productALfiles:20/23checks pass; three false-positive classes triaged in Layer2notes (Locked identifiers, procedure parameter separators, page name containingToday). No scanner/allow-list/assertion/CIchanges.
