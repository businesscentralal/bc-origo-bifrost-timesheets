# Timesheets #65 — retained verification evidence

Product PR: [#71](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/pull/71). Candidate: **c480240699d870c9825d2ac4049a62f9a826c26a**. Retained developer: **Alvíss (worker-4)**. This evidence branch does not change that PR head.

**NOT READY for review handoff.** AC08's Icelandic help assertion fails against Foundation's deliberate English-only contract policy. AC09's missing documentation and AC10's inherited full-guard findings also need explicit Claude/Architect disposition or their retained remediation. No acceptance criterion or test was removed.

| Verification at candidate | Actual result |
|---|---|
| Default product / Test product / test app | 0 errors, 0 warnings; product CodeCop/UICop/AppSourceCop, test CodeCop/UICop |
| Exact deployed packages | Product/test sourcecommit and SHA256 match local candidate artifacts |
| Owned full configured AL suite | 131 executed / 131 passed / 0 failed / 0 skipped |
| Paired GitHub CI41786512228 | Success; independent XML131 executed / 131 passed / 0 failed / 0 skipped |
| Functional Origo MCP, touched type `Timesheets.Absence.Register` | 22 executed / 22 passed / 0 failed / 0 skipped; LCIDs1033/1039 |
| Help language assertions | 2 executed / 1 passed / 1 failed; English passes, Icelandic parameter chapters remain English |
| Playwright MCP Web Client | 2 executed / 2 passed / 0 failed / 0 skipped; native time-sheet card in1033/1039, six cause-coded absence lines, weekday/Saturday hours, total18; English preference restored |
| Owned cleanup | Container f0c73a4f1444 DELETE204, GET404, absent from inventory; all fixtures removed and prior own local selection restored |

[Acceptance matrix](acceptance-matrix.json), [summary](execution-summary.json), [owned native suite](full-suite-summary.json), [CI XML counts](ci-junit-summary.json), [MCP cases and readback](mcp-summary.json), [UI](ui-summary-sanitized.json), [cleanup](cleanup-owned.json).

The owned W1 BC28.5 environment used product/test28.0.0.0, Foundation28.0.11.668 and the official Microsoft Icelandic language app. The product/test deployment source and hashes were read back. All data was self-created in the owned disposable environment. No EULA/trial/licence/backend/HTTP permission writes or guard changes.

Recovery history is preserved: management fixture invocation401 before execution; one initial MCP happy assertion failed because the fixture was absent, with no write. The separately published/compiled test-only [fixture driver](fixture-driver/) then invoked the existing candidate test fixture95618 once, with1setup test passed (separate from the131-test suite). The UI's first wait expected a collapsed sheetNo field; its captured page already showed the correct resource and lines. The corrected scenario waits on the visible resource plus exact filtered URL and checks all six cause-coded lines. Original failed attempts remain evidence; no successful business write was replayed.

Fresh XLF-sync, MixedLanguageLabels and permission-coverage guards pass. Full ContractParameterKeys has481findings on candidate and481on actual main d0e5c5fc415bb7dd00a50dc2418299aa51a974db;0introduced. The new type's6declared/read keys match. Documentation main b5cc1810a7356e45256a5fe170c91392bd3ec085 has no Timesheets files. PR gateway15/23 automated checks pass, with8sourcewide advisory categories disclosed. No suppressions or exclusions were added.

Independent Claude verification, Grok clearance and eligible approval follow an eventual valid handoff. Architect owns merge/deployment; Tester owns same-SHA UAT. This checkpoint is not issue delivery, review clearance or UAT proof.
