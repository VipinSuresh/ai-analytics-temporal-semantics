# "Expense by Department" Has Two Right Answers

**63 controlled Snowflake Cortex Agent runs comparing current-state data, runtime ASOF semantics, and upstream dbt enrichment.**

`Expense by department` sounds like a simple analytics question.

It isn't.

When employees change departments, the same expense data can support at least two legitimate interpretations:

- **Historical attribution:** assign each expense to the employee's department when the expense occurred.
- **Current attribution:** assign every expense to the employee's current department.

For this experiment, those interpretations produce different answers:

| Interpretation | Finance | Operations | Sales |
|---|---:|---:|---:|
| Historical | $900 | $1,300 | $300 |
| Current | $1,100 | $1,400 | $0 |

This project tests how the same Snowflake Cortex Agent behaves when those business semantics are exposed through three different data architectures.

---

## Three configurations

### Config A — Current state only

The agent sees:

- expense transactions
- each employee's current department

It does **not** have employee department history.

This configuration tests what happens when a user asks a historical question that the underlying model cannot legitimately answer.

### Config B — Runtime temporal semantics

The agent sees:

- expense transactions
- current employee department
- SCD Type 2 employee history

A Snowflake semantic-view **ASOF relationship** resolves the employee record that was effective on the expense date.

Historical attribution therefore happens at query time.

### Config C — Upstream dbt enrichment

dbt resolves the temporal relationship before the agent queries the data.

The resulting analytical model exposes:

- `department_at_expense`
- `current_department`

The agent can therefore query historical attribution without generating a runtime temporal join.

---

## Experiment design

Two experiments were run.

### Experiment 1 — Explicit temporal questions

Five questions explicitly specified the intended business meaning, including questions such as:

> What was total 2026 expense amount by the employee's department at the time the expense was incurred?

Each question was run three times against each configuration.

**45 primary runs.**

### Experiment 2 — Ambiguous business questions

Two questions deliberately omitted the temporal definition:

> What is 2026 expense amount by department?

> How much did Finance spend in 2026?

Each question was run three times against each configuration in fresh threads.

**18 primary runs.**

Experiment 2 was exploratory and was designed after reviewing Experiment 1.

**Total primary runs: 63.**

---

## Key results

| Finding | Result |
|---|---:|
| Config A unsupported historical runs safely handled | 12/12 |
| Config B Experiment 1 final answers correct | 15/15 |
| Config C Experiment 1 final answers correct | 15/15 |
| Config B + C Experiment 1 final answers correct | 30/30 |
| B + C runs with at least one SQL execution error | 5/30 |
| Ambiguous runs that disclosed their interpretation | 18/18 |
| Ambiguous runs that asked for clarification | 0/18 |
| B + C ambiguous runs choosing historical attribution | 12/12 |

### What stood out

**1. Missing semantics did not automatically produce fabricated history.**

Config A could not support historical department attribution. Across the 12 unsupported historical runs, the agent refused or qualified the answer rather than presenting unavailable historical information as fact.

**2. Both historical architectures worked.**

Config B and Config C both produced correct final answers across all 15 Experiment 1 runs.

This experiment does **not** establish a universal winner between runtime ASOF semantics and upstream dbt enrichment.

**3. The same ambiguous question produced different valid answers.**

For:

> How much did Finance spend in 2026?

Config A returned the current-department interpretation:

**$1,100**

Configs B and C selected historical attribution:

**$900**

In these runs, the agents disclosed which interpretation they used rather than silently hiding the assumption.

**4. Correct final answers did not always mean clean execution.**

Across Config B and Config C, all 30 Experiment 1 final answers were correct.

However, trace inspection showed that **5 of those 30 runs encountered at least one SQL execution error** before reaching the final answer.

That means final-answer accuracy alone would have hidden part of the execution behavior.

---

## Ground truth

The experiment uses a deliberately small synthetic dataset with SCD Type 2 employee department history.

Temporal validity follows:

```text
VALID_FROM <= expense_date < VALID_TO
```

This creates explicit boundary cases:

- Employee `101` changes from Finance to Operations on `2026-07-01`
- Employee `103` changes from Sales to Finance on `2026-04-01`

Expenses occurring exactly on those dates must therefore be attributed to the new department.

The complete deterministic reference queries are in:

```text
sql/05_ground_truth.sql
```

---

## Repository structure

```text
sql/
  01_base_data.sql
  02_config_a_current_state.sql
  03_config_b_temporal.sql
  04_config_c_enriched.sql
  05_ground_truth.sql
  06_validation_queries.sql
  07_observability_queries.sql

dbt/
  dbt_project.yml
  profiles.example.yml

  models/
    sources.yml

    marts/
      fct_expenses_enriched.sql
      fct_expenses_enriched.yml

  tests/
    assert_expense_amount_reconciliation.sql
    assert_expense_count_reconciliation.sql

data/
  primary_runs.csv
  results_summary.csv

analysis/
  compute_metrics.py

docs/
  methodology.md
  limitations.md
  SECURITY_NOTES.md
```

---

## Reproduce the experiment

### 1. Create the source data

Run:

```text
sql/01_base_data.sql
```

### 2. Create Config A

Run:

```text
sql/02_config_a_current_state.sql
```

### 3. Create Config B

Run:

```text
sql/03_config_b_temporal.sql
```

### 4. Build the Config C dbt model

Use:

```text
dbt/profiles.example.yml
```

as a template for your local dbt profile.

Then run:

```bash
dbt build
```

This creates and tests:

```text
FCT_EXPENSES_ENRICHED
```

The dbt project includes:

- column-level `not_null` tests
- `expense_id` uniqueness
- source-to-model row-count reconciliation
- source-to-model expense-amount reconciliation

### 5. Create Config C

Run:

```text
sql/04_config_c_enriched.sql
```

### 6. Validate the ground truth

Run:

```text
sql/05_ground_truth.sql
sql/06_validation_queries.sql
```

### 7. Run the experiment

Execute the frozen question set against:

```text
EXPENSE_CURRENT_STATE_AGENT
EXPENSE_TEMPORAL_AGENT
EXPENSE_ENRICHED_AGENT
```

The scoring structure used for the 63 primary runs is available in:

```text
data/primary_runs.csv
```

### 8. Reproduce the published counts

Run:

```bash
python analysis/compute_metrics.py
```

The script calculates the headline metrics directly from the primary-run dataset rather than relying on manually entered totals.

---

## Results data

For a quick overview:

```text
data/results_summary.csv
```

For the complete scored experiment:

```text
data/primary_runs.csv
```

The full dataset is provided for reproducibility; most readers only need the summary.

---

## Methodology and limitations

Detailed methodology:

```text
docs/methodology.md
```

Limitations:

```text
docs/limitations.md
```

This is a **small engineering case study**, not a statistically powered benchmark.

The results should not be interpreted as proving that:

- one temporal architecture is universally superior,
- analytics agents generally prefer historical attribution,
- runtime ASOF semantics cause more SQL errors,
- or disclosure is always sufficient when a business question has multiple valid meanings.

---

## Security

This repository intentionally excludes:

- Snowflake credentials
- programmatic access tokens
- private keys
- local `profiles.yml`
- account-specific secrets

See:

```text
docs/SECURITY_NOTES.md
```

Never commit credentials or authentication material to Git.