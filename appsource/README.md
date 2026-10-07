# AppSource offer: Bifrost Timesheets

Everything to enter in Partner Center for this offer, page by page, as Microsoft's offer pages ask
for it (Business Central offer, checked 06.10.2026). Built from the app's main branch and the
documentation. No message type names, as on the public site. Review before publishing.

## Files in this folder

| File | Use | Partner Center page |
|---|---|---|
| `logo-216.png` | Large logo, PNG, in the style of Bifrost Foundation's | Offer listing › Logos |
| `screenshots/*.png` | 4 screenshots, 1280 × 720 PNG (3 to 5 required) | Offer listing › Screenshots |
| `description.html` | Description with the allowed HTML tags | Offer listing › Description |
| `description.txt` | The same as plain text | (for review) |
| `product-sheet.pdf` | One-page marketing sheet (1 to 3 PDFs required) | Offer listing › Supporting documents |

## 1. Offer setup

| Field | Value |
|---|---|
| Offer alias | Bifrost Timesheets |
| Customer leads / listing option | Same as Bifrost Foundation |

## 2. Properties

| Field | Value | Subcategories |
|---|---|---|
| Primary category | Project Management | Project Time & Expense Reporting, Project Invoicing |
| Secondary category | Productivity | Workflow Automation |
| Industry | Professional Services | — |
| App version | The version of the `.app` you upload (the pipeline sets it) | |
| Terms and conditions (URL) | https://docs.bifrost.origo.is/en-us/licensing/eula/ | |

## 3. Offer listing

| Field | Value | Length / limit |
|---|---|---|
| Name | Bifrost Timesheets | 18 / 200 |
| Search results summary | Hours tracked in Clockify, posted in Business Central: Job Journal or Time Sheets. | 82 / 100 |
| Description | `description.html` | 1723 / 5,000 |
| Search keywords | Clockify, Time tracking, Timesheet | 3 / 3 |
| Products your app works with | Dynamics 365 Business Central, Clockify | 2 / 3 |
| Help link | https://docs.bifrost.origo.is/en-us/apps/ | must differ from Support URL |
| Privacy policy link | https://docs.bifrost.origo.is/en-us/licensing/privacy/ | |
| Support contact (name, e-mail, phone, URL) | Same as Bifrost Foundation; Support URL https://www.origo.is/ | not shown to customers |
| Engineering contact | Same as Bifrost Foundation | not shown to customers |
| Supporting documents | `product-sheet.pdf` | 1 to 3 PDFs |
| Logo | `logo-216.png` | PNG |
| Screenshots | see below | 3 to 5, 1280 × 720 PNG |
| Videos | optional; none yet | up to 4 |

Links use the documentation's own domain, docs.bifrost.origo.is. The app has no page of its own on the
site yet, so the help link goes to the app list; change it to the app's page once that is published.
The app's `app.json` still points to the old github.io address, which GitHub forwards to the new domain.

Microsoft's logo guidance says no text on the logo; Bifrost Foundation's logo has text, so this one
follows Foundation for a consistent family.

### Screenshots and captions

| File | Caption |
|---|---|
| `screenshots/00-claude.png` | Ask where the tracked Clockify hours stand before you post or invoice them. |
| `screenshots/01-integration-links.png` | Clockify projects, clients and tags linked to Business Central records. |
| `screenshots/02-setup.png` | Choose the Clockify workspace and where hours are posted. |
| `screenshots/03-project-journal.png` | Clockify hours arrive as project journal lines, ready to post. |

Order in Partner Center: `00-claude` first. It shows the app used from Claude, outside Business Central;
the others show the setup inside Business Central.

Taken in the Bifrost sandbox (CRONUS demo company, demo data), 06.10.2026; `00-claude` on 07.10.2026 with the Bifröst Origo connector. The company name, user
names, e-mail addresses and IDs were replaced before capture.

## 4. Availability

Markets: the same as Bifrost Foundation.

## 5. Technical configuration

Upload the app's `.app` file from the release build. Dependency: Bifrost Foundation.

## 6. Supplemental content

| Field | Value |
|---|---|
| Supported editions | Essentials and Premium |
| Key usage scenario, test accounts, test app | No longer used in validation (Microsoft); leave empty unless Partner Center requires it |

## Description (as in `description.txt`)

```
Hours tracked in Clockify, posted in Business Central.

Bifrost Timesheets connects Business Central to Clockify, the time-tracking service. Finished time entries become Job Journal lines or Time Sheet detail, without typing them in again. It is an add-on to Bifrost Foundation.

Who it is for
Professional services companies that track time in Clockify and bill or cost it in Business Central.

What it does
- Brings Clockify hours into the Job Journal: one entry, a date range, or every mapped user at once. An entry synced twice is not duplicated; a changed entry is posted as a correction.
- Or fills Time Sheets: the same entries into the resource's open Time Sheet.
- Runs the Time Sheet week: create, submit, approve, reject, post and archive.
- Keeps Clockify in step with your projects: clients, projects, tasks and tags.
- Syncs as it happens: with Clockify webhooks, new, changed and deleted entries arrive without waiting for a schedule.

Requirements and pricing
- Microsoft Dynamics 365 Business Central 28.0 or later, Essentials or Premium.
- Bifrost Foundation, available separately on AppSource.
- A Clockify account and API key. Clockify is a trademark of its owner; this app describes interoperability only.
- For prices, contact Origo (https://www.origo.is/) or your Business Central partner.
- If you are a partner, contact The App Channel (https://www.theappchannel.com/).

Bifrost Timesheets does not replace Business Central or its extensions. It makes their data and business logic available to the people, routines and AI platforms your organisation already uses.
```

---
Drafted with the help of Claude (Anthropic); review before publishing. Origo's AI policy (STE-0002):
the person who publishes is responsible for the content.
