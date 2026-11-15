{{ config(
    materialized='table',
    alias='FCT_EXPENSES_ENRICHED'
) }}

with expenses as (

    select
        expense_id,
        employee_id,
        expense_date,
        expense_amount
    from {{ source('experiment', 'expense_fact') }}

),

employee_history as (

    select
        employee_id,
        department,
        valid_from,
        valid_to
    from {{ source('experiment', 'employee_dim_scd2') }}

),

employee_current as (

    select
        employee_id,
        department
    from {{ source('experiment', 'employee_dim_scd2') }}
    where is_current = true

),

enriched as (

    select
        x.expense_id,
        x.employee_id,
        x.expense_date,
        x.expense_amount,

        h.department as department_at_expense,
        c.department as current_department

    from expenses x

    join employee_history h
        on x.employee_id = h.employee_id
       and x.expense_date >= h.valid_from
       and x.expense_date < h.valid_to

    join employee_current c
        on x.employee_id = c.employee_id

)

select *
from enriched
