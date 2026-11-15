USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE AI_DATA_CORRECTNESS;
USE SCHEMA EXPERIMENT;

CREATE OR REPLACE SEMANTIC VIEW EXPENSES_TEMPORAL_SV

TABLES (
    expenses AS EXPENSE_FACT
        PRIMARY KEY (EXPENSE_ID)
        COMMENT = 'Employee expenses. EXPENSE_DATE is the date the expense was incurred.',

    employee_current AS EMPLOYEE_CURRENT
        PRIMARY KEY (EMPLOYEE_ID)
        COMMENT = 'Current employee department.',

    employee_history AS EMPLOYEE_DIM_SCD2
        UNIQUE (EMPLOYEE_ID, VALID_FROM)
        COMMENT = 'Historical employee department assignments with effective dates.'
)

RELATIONSHIPS (
    expenses_to_current_employee AS
        expenses (EMPLOYEE_ID)
        REFERENCES employee_current (EMPLOYEE_ID),

    expenses_to_employee_history AS
        expenses (EMPLOYEE_ID, EXPENSE_DATE)
        REFERENCES employee_history (EMPLOYEE_ID, ASOF VALID_FROM)
)

DIMENSIONS (
    expenses.expense_id AS expenses.EXPENSE_ID
        COMMENT = 'Unique expense identifier',

    expenses.employee_id AS expenses.EMPLOYEE_ID
        COMMENT = 'Employee identifier',

    expenses.expense_date AS expenses.EXPENSE_DATE
        COMMENT = 'Date the expense was incurred',

    employee_current.current_department AS employee_current.DEPARTMENT
        COMMENT = 'Employee current department',

    employee_history.department_at_expense AS employee_history.DEPARTMENT
        COMMENT = 'Employee department applicable at the expense date when reached through the temporal relationship',

    employee_history.valid_from AS employee_history.VALID_FROM
        COMMENT = 'Date this historical employee department assignment became effective'
)

METRICS (
    expenses.total_expense_amount AS SUM(expenses.EXPENSE_AMOUNT)
        COMMENT = 'Total expense amount'
)

COMMENT = 'Configuration B: supports both current department and historical department-at-expense-date analysis';

CREATE OR REPLACE AGENT EXPENSE_TEMPORAL_AGENT
    COMMENT = 'Configuration B: AI analytics agent with current and historical employee department semantics'
    PROFILE = '{"display_name":"Expense Temporal Agent"}'
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
      description: "Answers analytical questions about employee expenses using current and historical department semantics."

tool_resources:
  Expense_Analyst:
    semantic_view: "AI_DATA_CORRECTNESS.EXPERIMENT.EXPENSES_TEMPORAL_SV"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
      query_timeout: 60
$$;
