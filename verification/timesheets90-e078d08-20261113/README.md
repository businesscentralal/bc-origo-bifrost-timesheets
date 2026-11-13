# PR #90 amendment verification

Candidate: `e078d08c894cc813e8cd4f7019a8a07baafaf53d`. Worker: Brokkr (`worker-2`). Local BC29 tenant: `w129-12`.

The amendment follows Claude Code’s 13 November ruling: five label edits, is-IS translation regeneration, four fill-help regressions and one existing recovery-text expectation. Runtime control flow, versions, Foundation source and CI files are unchanged in the Timesheets PR.

- App and test app: 0 errors, 0 warnings. The test compiler reports one existing informational AA0210.
- Full configured suite: 219 active test functions, 219 passed, 0 failed, 0 skipped, using codeunit isolation.
- Unchanged Foundation guard 98869: 1 passed, 0 failed, 0 skipped. The original custom-suite attempt selected zero tests and is retained as NOT_RUN.
- MCP: 14 complete help reads and 14 expected UnknownParameter refusals across seven affected message types at 1033/1039. Help/refusal calls need no business fixtures. Prior successful Approve/Reject runtime evidence carries forward.
- UI: four full-help JSON downloads for CopyFromPrevious/CreateFromPlanning across 1033/1039, parsed and checked for absence of the internal flag. Initial Icelandic virtualized-row selection timed out; corrected navigation passed. English restored. Screenshots stay private.
- Cleanup: verification apps uninstalled with deleteExtensionData and unpublished. Seven native fixture tables have zero rows modified since run start. No live providers called. Current-main locally compiled Foundation retained for reuse on the permanent owned tenant.
- Licence paths: NOT_RUN per PR policy.

`verification-summary.json` records the full head, source hashes, artifact hashes and all results. `full-suite.json` includes actual runner totals; its long stdout preview is truncated by the MCP tool. Six empty legacy codeunits have Skipped headings but no active test functions. No active test was skipped.
