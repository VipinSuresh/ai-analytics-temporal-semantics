# Methodology

## Experiment 1: explicit temporal intent

Five frozen questions were run three times against each of three configurations.

- **Config A — Current state only:** expense fact joined to current employee department.
- **Config B — Runtime temporal semantics:** expense fact plus SCD2 history, resolved through a Snowflake semantic-view ASOF relationship.
- **Config C — Upstream dbt enrichment:** temporal attribution resolved upstream into `department_at_expense` and `current_department`.

The pinned orchestration model was `claude-sonnet-5-5`.

## Experiment 2: ambiguous wording

Two exploratory prompts were used without specifying current vs historical attribution:

1. `What is 2026 expense amount by department?`
2. `How much did Finance spend in 2026?`

Each prompt was run three times against each configuration in fresh threads.

Scoring focused on:
- interpretation selected,
- whether that interpretation was disclosed,
- whether clarification was requested,
- final numeric correctness for the selected interpretation.

## Ground truth

Historical attribution:
- Finance: 900
- Operations: 1300
- Sales: 300

Current-department attribution:
- Finance: 1100
- Operations: 1400

Total expense amount: 2500.

## Trace-audit scope

All 63 primary runs were scored for the behavior relevant to their experiment.

A deeper SQL/execution-trace audit was performed for the 30 Config B and Config C runs in Experiment 1. That audit recorded generated SQL behavior, execution count, execution errors, recovery, and whether the runtime ASOF relationship was used.

Config A and Experiment 2 were not subjected to the same systematic SQL-trace audit across every run.

## ASOF detection

Runtime ASOF usage was determined by reviewing the generated query path in Snowflake observability for the audited Experiment 1 runs.

It was not inferred solely from the semantic-view definition.

For the 12 explicitly historical Experiment 1 runs in each supported configuration:

- Config B: ASOF used in 12/12 runs
- Config C: ASOF used in 0/12 runs

## Cortex Analyst routing-mode limitation

Snowflake Cortex Analyst can route between semantic SQL and standard SQL depending on query generation and validation behavior.

This experiment did not separately classify semantic-SQL versus standard-SQL routing for every run.

Therefore, the study does not compare routing-mode behavior between Config B and Config C.

## Fresh-thread replacements

During initial Config C collection, two question pairs shared conversation threads:

- Q1 and Q2 in thread 312067716
- two Q4 runs in thread 312067744

Those four observations were removed from the primary dataset and replaced with fresh-thread runs before final analysis.

The replacements did not change any analytical outcome.

One replacement did change the execution-path statistics by encountering SQL execution errors before recovery.

The superseded observations and additional validation reruns are retained in `data/non_primary_runs.csv` for auditability.

## SQL error classification

The six failed SQL executions in the Config B + Config C Experiment 1 trace analysis were classified manually after reviewing the captured traces.

These categories are post-hoc analytical labels created for this study; they are not Snowflake-defined error classes.

The per-execution classification is published in `data/error_classification.csv`.

Observed categories:

- 4 failures: semantic metric name used against a physical/generated relation
- 1 failure: wrong logical field for the requested temporal meaning
- 1 failure: invalid relation/column qualification

All six failed executions were followed by successful recovery within the same run.
