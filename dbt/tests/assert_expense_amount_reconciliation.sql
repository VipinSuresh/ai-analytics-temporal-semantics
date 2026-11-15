with source_total as (

    select coalesce(sum(expense_amount), 0) as expense_amount
    from {{ source('experiment', 'expense_fact') }}

),

enriched_total as (

    select coalesce(sum(expense_amount), 0) as expense_amount
    from {{ ref('fct_expenses_enriched') }}

)

select
    source_total.expense_amount as source_expense_amount,
    enriched_total.expense_amount as enriched_expense_amount
from source_total
cross join enriched_total
where source_total.expense_amount <> enriched_total.expense_amount
