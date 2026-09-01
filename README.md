# Court Case Management Data Quality: Missing Court Date Query

## Overview

This project demonstrates a SQL-based data quality workflow for identifying active criminal cases in a case management system that are missing a next court date.

The query compares internal case records with external court-administration data and applies a series of logical checks to identify likely data-quality issues and recommend follow-up actions. The goal is to help users prioritize cases that require review while preserving human validation for ambiguous records.

The workflow was designed around common challenges in administrative court data, including:

- Missing next court dates
- Misaligned case appearance histories
- Case consolidation under indictment numbers
- Disposed or covered cases that remain open
- Attorney-transfer cases
- Duplicate docket numbers
- One-to-many matching issues in court-data feeds

## Workflow

The general process is:

1. Extract active cases with missing next court dates using SQL.
2. Compare internal case information against an external court-data feed.
3. Apply rule-based logic to classify likely error conditions.
4. Generate recommended checks for the user.
5. Validate cases against available court-administration sources.
6. Correct or close records where appropriate.

The SQL logic is intended to support review rather than automatically modify case records.

## Example Decision Logic

Examples of the rules used in the query include:

- If an external court feed indicates a dismissal or guilty plea, review the case for a final disposition or consolidation.
- If the external court feed contains a newer future appearance date, use that information as a starting point for validating the missing court date.
- If internal and external appearance dates disagree, flag the case for additional investigation.
- If multiple active matters appear to be associated with one indictment, review the cases for consolidation.
- If external updates stop after a change in representation, verify whether the case should be closed.
- If duplicate docket numbers exist, identify the record that should remain active and prevent duplicate case histories.

## Data Sources

The workflow may use information from public or administrative court sources such as:

- New York State Office of Court Administration data
- WebCrims
- DOCCS lookup tools
- Court calendars
- Other publicly available or authorized court-record systems

The repository does not contain confidential client data or proprietary organizational data.

## Technologies

- SQL
- Python / pandas for optional downstream reporting and data preparation
- Excel for review worksheets and quality-control outputs

## Design Approach

The project uses a human-in-the-loop approach.

Administrative court data often contains exceptions that cannot be resolved reliably through deterministic rules alone. The query therefore generates recommendations and supporting information rather than making irreversible case-management decisions automatically.

This approach is particularly useful where:

- multiple records may represent the same underlying case;
- court feeds contain delayed or incomplete updates;
- one-to-many ETL relationships create ambiguous matches; or
- disposition and consolidation rules require contextual review.

## Limitations

The logic is based on administrative data and should not be interpreted as a substitute for official court records.

External feeds may contain delays, missing values, or inconsistencies. Individual cases may also have procedural circumstances that are not represented in structured data.

For that reason, flagged records should be validated against authoritative sources before changes are made.

## Privacy and Data

All examples and field names in this repository are generalized or synthetic.

No confidential client information, proprietary database schema, internal credentials, or organization-specific system details are included.

## Purpose

This repository is intended as a portfolio example of applied data-quality work involving:

- SQL querying
- rule-based classification
- record reconciliation
- ETL troubleshooting
- administrative-data validation
- workflow design
- human-in-the-loop quality assurance
