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
