USE DATABASE AI_DATA_CORRECTNESS;
USE SCHEMA EXPERIMENT;

-- Config A: current-state semantic result
SELECT *
FROM SEMANTIC_VIEW(
    EXPENSES_CURRENT_STATE_SV
    METRICS expenses.total_expense_amount
    DIMENSIONS employees.department
);

-- Config B: historical attribution
SELECT *
FROM SEMANTIC_VIEW(
    EXPENSES_TEMPORAL_SV
    METRICS expenses.total_expense_amount
    DIMENSIONS employee_history.department_at_expense
);

-- Config B: current attribution
SELECT *
FROM SEMANTIC_VIEW(
    EXPENSES_TEMPORAL_SV
    METRICS expenses.total_expense_amount
    DIMENSIONS employee_current.current_department
);

-- Config C: historical attribution
SELECT *
FROM SEMANTIC_VIEW(
    AI_DATA_CORRECTNESS.EXPERIMENT.EXPENSES_ENRICHED_SV
    DIMENSIONS expenses.department_at_expense
    METRICS expenses.total_expense_amount
)
ORDER BY department_at_expense;

-- Config C: current attribution
SELECT *
FROM SEMANTIC_VIEW(
    AI_DATA_CORRECTNESS.EXPERIMENT.EXPENSES_ENRICHED_SV
    DIMENSIONS expenses.current_department
    METRICS expenses.total_expense_amount
)
ORDER BY current_department;
