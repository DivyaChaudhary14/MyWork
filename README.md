# MyWork

SQL Server and Power BI work from my role as a database administrator and analyst on **HIFIS**, the Government of Canada's homelessness case management system. The database is privacy-regulated and shared by many partner organizations, so everything here has been sanitized before publishing:

- No client data of any kind.
- Organization, program and cluster IDs, consent types and organization names are replaced with placeholders (`#`, `##`, `abc`).
- Queries show structure and technique, not real results.

---

## SQL code (`SQL CODE/`)

| Script | What it does | Techniques |
|---|---|---|
| **Anonymization script.sql** | Anonymizes personal information across 81 HIFIS tables so a copy of the database can be used safely outside production (testing, training, development). Replaces names, phone numbers, emails, notes, health, legal, financial and ID fields with realistic but fake values, and keeps dates usable (day of birth set to the 1st). | Set-based `UPDATE ... FROM` with joins to lookup tables, deterministic fake data from IDs (reproducible and searchable), 555 phone numbers and `@test.local` emails that can never reach a real person, NULL-preserving `CASE` logic |
| **Filtered Client Consent Summary.sql** | Finds the latest consent record for each active client and lists those with no signed consent document attached, optionally for one organization and from a start date. Used to follow up on missing consent paperwork. | CTE with `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`, optional parameters (`@FilterOrgID IS NULL OR ...`), multi-table joins |
| **Count of Clients Housed in a Specific Period.sql** | Counts clients moved into housing within a reporting period for one group of organizations. | Joins across placement, client and person tables, date-range filtering |
| **Filtered Program Details by Organization and Cluster.sql** | Lists programs with the organizations that run them, program type, active status and dates, excluding out-of-scope organizations and program combinations. | Five-table join, compound exclusion logic with `NOT (... AND ...)` |
| **Program and Organization Data Summary Query.sql** | Commented version of the program summary used for quarterly reporting. | Same as above, documented line by line |

---

## Dashboards (`Dashboards/`)

Power BI report pages. See [Dashboards/README.md](Dashboards/README.md).

---

## Tools

| Area | Tools |
|---|---|
| Database | SQL Server (T-SQL) |
| BI and reporting | Power BI (DAX, Power Query), Crystal Reports |
| Data privacy | Anonymization for non-production environments, PHIA-aware handling of personal health information |
