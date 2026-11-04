# Timesheets #62 / PR #77 — developer evidence

Source candidate: `1d271de3c6d501926f52de172b74bf705d9be280` on `feat/timesheets62-pending-approval-reginn`.
Andvari (worker-5), 4 November 2026. Original Reginn/worker-8/worker-10 private source and checkpoints remain preserved.

Product + test + Default product compile: 0 errors / 0 warnings. Downloaded installed product/test package hashes match the compiled files. COSMO `f04ee182ab06`, worker-5, BC W1 `28.5.54151.57488`; Foundation `28.0.11.665`, Timesheets/test `28.0.0.0`. This owned dependency differs from the separately recorded GitHub CI dependency; neither substitutes for the other.

Full configured native suite: **142 executed, 142 passed, 0 failed, 0 skipped**, raw JUnit independently counted. Changed units 95612/95630/95633: **33/33 twice consecutively**. No tests disabled, assertions weakened or new warning suppressions/exclusions introduced.

Actual origo MCP: **42 query/refusal scenarios + 1 bilingual help-policy scenario = 43 passed**, 0 failed/skipped. English chapters are identical under 1033/1039; catalogue and actual refusals are Icelandic under 1039. Test-only seed and cleanup each completed successfully; these 2 fixture operations are separate from the 43 acceptance scenarios. Self-created 2 resources, 2 headers, 4 lines and 8 details. Independent snapshots confirm no mutation during queries or UI; native cleanup and independent reads confirm zero remaining rows.

Playwright MCP: **4 final scenarios passed** (manager list/review card at 1033 and 1039), 0 failed/skipped. Manager sees only TS62-A: total35/open19/submitted16. Review card project3+4=7, absence4+5=9. Actual Icelandic language setting, shell, native captions/actions, dates and weekdays verified. Preparation errors and recoveries are retained in verification-preparation.json; no preparation attempt is counted as an acceptance pass.

Guard comparison: ContractParameterKeys481 before/481 after (0 added); MixedLanguageLabels0/0; XLF sync passes before/after; 282 main XLF units preserved identically plus20queryunits. HelpLinks has the same one missing-directory prerequisite error before/after; no pages are introduced, and public documentation for unreleased Timesheets is deferred by the [Claude/Gunnar ruling](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/pull/77#issuecomment-6626911774). Full HelpLinks is not claimed passed.

Owned cleanup: fixture rows0; container DELETE204, GET404, absent from inventory; prior local connection restored without requests to it. No foreign/shared/customer/UAT resources or licensing/backend/consent state modified.

Paired CI, independent Claude verification, Grok clearance, approval, Architect merge/deployment and same-SHA UAT are separate stages; this artifact is developer evidence, not issue delivery or clearance. Refer to the actual PR current state for current CI/handoff status.
