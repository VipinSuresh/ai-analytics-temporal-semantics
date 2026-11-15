USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE AI_DATA_CORRECTNESS;
USE SCHEMA EXPERIMENT;

CREATE OR REPLACE VIEW EMPLOYEE_CURRENT AS
SELECT
    EMPLOYEE_ID,
    DEPARTMENT
FROM EMPLOYEE_DIM_SCD2
WHERE IS_CURRENT = TRUE;

CREATE OR REPLACE SEMANTIC VIEW EXPENSES_CURRENT_STATE_SV

TABLES (
    expenses AS EXPENSE_FACT
        PRIMARY KEY (EXPENSE_ID)
        COMMENT = 'Employee expenses. EXPENSE_DATE is the date the expense was incurred.',

    employees AS EMPLOYEE_CURRENT
        PRIMARY KEY (EMPLOYEE_ID)
        COMMENT = 'Current employee department only. Historical department information is not available.'
)

RELATIONSHIPS (
    expenses_to_employees AS
        expenses (EMPLOYEE_ID) REFERENCES employees
)

DIMENSIONS (
    expenses.expense_id AS expenses.EXPENSE_ID
        COMMENT = 'Unique expense identifier',

    expenses.employee_id AS expenses.EMPLOYEE_ID
        COMMENT = 'Employee identifier',

    expenses.expense_date AS expenses.EXPENSE_DATE
        COMMENT = 'Date the expense was incurred',

    employees.department AS employees.DEPARTMENT
        COMMENT = 'Employee current department'
)

METRICS (
    expenses.total_expense_amount AS SUM(expenses.EXPENSE_AMOUNT)
        COMMENT = 'Total expense amount'
)

COMMENT = 'Configuration A: expenses joined only to the employee current-state representation';

CREATE OR REPLACE AGENT EXPENSE_CURRENT_STATE_AGENT
    COMMENT = 'Configuration A: AI analytics agent using current employee department only'
    PROFILE = '{"display_name":"Expense Current-State Agent"}'
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
      description: "Answers analytical questions about employee expenses using the current-state semantic view."

tool_resources:
  Expense_Analyst:
    semantic_view: "AI_DATA_CORRECTNESS.EXPERIMENT.EXPENSES_CURRENT_STATE_SV"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
      query_timeout: 60
$$;
