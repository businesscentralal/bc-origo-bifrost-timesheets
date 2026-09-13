# Bifrost Timesheets Icelandic Translation Review

Date: 2026-09-13
Scope: `app/Translations/Bifrost Timesheets.is-IS.xlf`; test app excluded.

## Completed

- Reviewed all existing non-test translation units in the XLF.
- Corrected product-name translations so `Bifrost Timesheets` remains unchanged, per XLF technical rules.
- Aligned Finance/Projects terminology with the available NAB Icelandic glossary, including `Verkbók`, `Verkbókarsniðmát`, and `Verkbókarkeyrsla`.
- Corrected Icelandic agreement, case, reversal terminology, API-key compounds, webhook compounds, and Clockify integration wording.
- Preserved placeholders, punctuation, XML structure, and literal `\\n` sequences.

## Uncertain terms and decisions

| Term or source phrase | Decision | Reason / follow-up |
|---|---|---|
| `Webhook` | `vefkrókur` / compounds such as `Clockify-vefkrókur` | Existing project terminology uses `vefkrókur`; compound hyphenation was normalized for readability. Confirm against the official Icelandic UI resource if a working tree becomes available. |
| `Integration` in Clockify integration records | `tenging` / `Clockify-tenging` | Chosen to distinguish the connector link from generic synchronization. |
| `Job Journal Batch` | `Verkbókarkeyrsla` | Derived from the available official glossary entry `Journal Batch = Bókarkeyrsla`, specialized for Job Journal. Verify against the Finance/Projects resource before release. |
| `API key` | `API-lykill` | Icelandic compound spelling was normalized; the technical token `API` was preserved. |
| `Bifrost Timesheets` | Untranslated | Application name must not be translated in XLF targets. |
| Signing token / webhook receiver | `undirritunarlykill` / `vefkrókamóttakari` | Context-specific wording; retain the English configuration key `CLOCKIFY_WEBHOOK_SIGNATURES`. |

## Source reference limitation

`D:\Git\Public\bcapps-terminology` contains Git metadata but no checked-out working tree in this environment. Its local `origin/main` ref points to commit `9ee4ba5cbcace23b5d505f4b59bdde20bd263949`, but the official Finance/Projects files could not be read through the available workspace file tools. The NAB built-in `is-IS` glossary was used as the available official terminology reference; the terms above are marked for confirmation when the resource files are accessible.
