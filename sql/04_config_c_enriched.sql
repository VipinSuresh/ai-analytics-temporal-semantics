USE ROLE SYSADMIN;
USE DATABASE AI_DATA_CORRECTNESS;
USE SCHEMA EXPERIMENT;

-- Requires the dbt model FCT_EXPENSES_ENRICHED to exist first.

CREATE OR REPLACE SEMANTIC VIEW EXPENSES_ENRICHED_SV

TABLES (
    expenses AS FCT_EXPENSES_ENRICHED
        PRIMARY KEY (EXPENSE_ID)
        COMMENT = 'Expense-level analytical model with historical and current employee department already resolved upstream by dbt.'
)

DIMENSIONS (
    expenses.expense_id AS expenses.EXPENSE_ID
        COMMENT = 'Unique expense identifier',

    expenses.employee_id AS expenses.EMPLOYEE_ID
        COMMENT = 'Employee identifier',

    expenses.expense_date AS expenses.EXPENSE_DATE
        COMMENT = 'Date the expense was incurred',

    expenses.department_at_expense AS expenses.DEPARTMENT_AT_EXPENSE
        COMMENT = 'Employee department effective on the date the expense was incurred',

    expenses.current_department AS expenses.CURRENT_DEPARTMENT
        COMMENT = 'Employee current department'
)

METRICS (
    expenses.total_expense_amount AS SUM(expenses.EXPENSE_AMOUNT)
        COMMENT = 'Total expense amount'
)

COMMENT = 'Configuration C: temporal department attribution is resolved upstream in dbt before AI query execution';

CREATE OR REPLACE AGENT EXPENSE_ENRICHED_AGENT
COMMENT = 'Configuration C: employee historical and current department attribution is resolved upstream by dbt.'
PROFILE = '{"display_name":"Expense Enriched Agent"}'
FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-5-5

instructions:
  response: "Answer concisely. Format monetary amounts as currency."
  orchestration: "Use the Expense_Analyst tool for questions about employees, departments, expenses, expense dates, or expense amounts."

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "Expense_Analyst"
      description: "Answers analytical questions about employee expenses."

tool_resources:
  Expense_Analyst:
    semantic_view: "AI_DATA_CORRECTNESS.EXPERIMENT.EXPENSES_ENRICHED_SV"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
      query_timeout: 60
$$;
