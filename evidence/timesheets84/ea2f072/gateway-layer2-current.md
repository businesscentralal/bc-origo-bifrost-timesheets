# Layer 2 review, work in progress

The Layer 1 scan ran from the pinned standards snapshot 52ba4754cfd614e4a7c50af87b30149b18b313e3. Its initial Linux run failed because USERPROFILE was unset; the same unmodified script ran successfully with USERPROFILE=/home/node.

Its three reported checks require these adjudications, without changing the scanner or allow-lists:

- Today vs WorkDate: all three findings are existing permission references to the page named "Phone Today Cust Part ori", not calls to Today(). No execution date was introduced.
- Caption translation: the 52 findings are Locked message-type identifier captions. These are immutable identifiers, not translated business text. The new descriptions, keywords, selection descriptions, labels, captions and tooltips carry Icelandic comments/targets. The repository XLF and keyword guards independently check them.
- One statement per line: all listed new manager findings are semicolon-separated AL procedure parameter declarations, not executable statements. Executable statements remain one per line.

Actual findings from native/MCP execution were retained and repaired rather than dismissed as scanner false positives: the direct generic interface test needed the public dispatcher; the Resource posting fixture lacked its own General Product Posting Group; Job Journal validation requires a Bill-to Customer, so the project fixtures now seed their own Customer; `related` chapters require typed RelatedEntry objects. The native suite and MCP must be rerun at each changed candidate before any pass is claimed.

This is not PR clearance. AC13 range/workbook disposition, current-tip full native repetition, live MCP/UI, remaining acceptance families and owned cleanup remain separately tracked in the acceptance matrix/checkpoint.

Continuation at89b9caa: Layer1 scans23 changed product files;20/23checks pass. Findings:3page identifier Today matches,53Locked identifier captions,13procedure parameter separator matches. These are scanner false positives; source assertions, allow-lists and scanner unchanged. Paired compiler0errors0warnings. Current full native/MCP/UI remains pending. AC13 disposition remains explicitly unverified; no range or workbook entry manufactured. All original AC01–AC14 remain authoritative.
