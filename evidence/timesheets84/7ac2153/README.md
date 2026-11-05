# Timesheets #84 developer evidence

Candidate: [7ac21537cf675069cb9b3e6118a8f9d73671b40e](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/commit/7ac21537cf675069cb9b3e6118a8f9d73671b40e).

Source branch: [codex/andvari/timesheets84-usage](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/tree/codex/andvari/timesheets84-usage). [PR #85](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/pull/85). Retained developer: Andvari (worker-5).

This evidence applies to the exact candidate above, deployed to worker-owned COSMO f073ff287f0d: BC 28.5 W1, Foundation 28.0.11.665, product and test apps 28.0.0.0. Downloaded deployed packages match the source commit and local SHA256 hashes.

- Product and test app compilation: 0 errors and 0 warnings.
- Full configured suite: 286/286 passed twice, 0 failed and 0 skipped, runner 130451, range 95600..95699, no exclusions. Actual native Item, Resource and Job posting, ledger/state tracking, deletion semantics, blocked-resource refusal, rejected resubmission and week/status filters are covered.
- MCP: 48/48 core scenarios and 3/3 supplemental scenarios passed, 0 failed and 0 skipped. The seven Timesheets.Usage messages and Data.Records.Set safety are exercised in LCIDs 1033/1039 with self-seeded fixtures. Supplemental cases cover the generic guard and both translated unknown-resource refusals. All 14 absence readbacks per core language verified cleanup.
- Playwright MCP Web Client: 2/2 scenarios passed, 0 failed and 0 skipped, LCIDs 1033/1039. The exact owned usage row, translated captions and zero editable business fields were verified. English was restored. UI cleanup has 13 zero-row readbacks; final native cleanup has 12.
- The two named older failed-test Projects, their tasks and exact empty templates/batches were removed after saved identity, provenance and dependency checks. Four fresh absence readbacks at this candidate are zero. The temporary cleanup extension was uninstalled and unpublished. No unrelated library/customer rows were deleted. The owned container is retained for separately tracked Timesheets #60 closure.

**AC13 remains pending explicit Claude Code/Architect disposition.** All new IDs fit unchanged assigned idRanges 10036785..10036884 using free per-type slots. No range extension or workbook row was fabricated. All original AC01–AC14 are preserved in acceptance-criteria-original.json and acceptance-matrix.json. This is not all-AC completion, independent verification, review clearance, merge, deployment or UAT.

Main #72 was merged normally, preserving both features' enum entries and role grants. The generated XLF order was repaired; all 624 unit IDs, source text, targets, notes and attributes are unchanged. The post-compile XLF guard passes. No .github or .AL-Go changes.

Standards snapshot 52ba4754cfd614e4a7c50af87b30149b18b313e3 was captured 2 November; no fresh-sync claim. Layer 1 scans 23 changed product AL files: 20/23 checks pass. The remaining matches are Locked identifiers, procedure parameter separators and a page name containing Today; Layer 2 documents these false positives. No scanner, allow-list, assertion or CI suppression was changed.

Current CI: [paired build 41935361083](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/actions/runs/41935361083), [Source Guards 41935360991](https://github.com/businesscentralal/bc-origo-bifrost-timesheets/actions/runs/41935360991). CI outcome is recorded separately; links alone are not a claimed pass. Earlier candidate attempts remain in verification-history.json.
## Verified CI result

Paired run 41935361083 completed successfully at source head 7ac21537cf675069cb9b3e6118a8f9d73671b40e. The downloaded TestResults artifact contains 286 executed / 286 passed / 0 failed / 0 skipped. Default and Test compiler outputs each contain 0 errors and 0 warnings. Default has no internalsVisibleTo entries; both builds published to physical container f09ca3d298e2 and Test republished the product. CI product/test version is 28.0.2147483647.181 with Foundation 28.0.11.670. Own-container version/provenance remains separately recorded above. See ci-verified-summary.json, compiler outputs and ci-TestResults.xml. Structural job skips are distinct from AL test skips. AC13 remains unresolved; CI success does not clear that hold or authorize review handoff/merge.
