{{ config(
        materialized='table',
        schema='marts'
)}}


with date_spine as (
        select
                month_start_date  as period_start_date,
                month_end_date as period_end_date,
                'monthly' as period_type
        from {{ ref('dim_date') }}
        where is_bom_flag = 1
),

transactions as (
        select
                ds.period_start_date,
                ds.period_end_date,
                account_key,
                account_type,
                account_name,
                account_number,
                /* Income: exclude credit-card payment rows */
                sum(
                   case
                        when lower(st.transaction_type) = 'credit'
                         and not (
                                lower(st.account_type) = 'credit'
                                and lower(coalesce(st.transaction_name, '')) ilike '%payment%')
                        then st.transaction_amount
                        else 0 end)
                                as total_income,

                /* Expense: exclude credit-card payment rows (if they show up as Debit in your data) */
                sum(
                   case
                        when lower(st.transaction_type) = 'debit'
                         and not (
                                lower(st.account_type) = 'credit'
                                and lower(coalesce(st.transaction_name, '')) ilike '%payment%')
                        then st.transaction_amount
                        else 0 end)
                                        as total_expense,
                        /* Count: exclude those rows from transaction_count too */
                count(
                   case
                        when not (
                                lower(st.account_type) = 'credit'
                                and lower(coalesce(st.transaction_name, '')) ilike '%payment%')
                        then 1 end)
                                as transaction_count

        from date_spine ds
        join {{ ref('stg_transactions') }} st 
        on st.transaction_date between ds.period_start_date and ds.period_end_date 
        group by ds.period_start_date,
                ds.period_end_date,
                account_key,
                account_type,
                account_name,
                account_number
    )
    select 
        period_start_date,
        period_end_date,
        account_key,
        account_type,
        account_name,
	account_number,
	total_income,
	total_expense ,
	total_income + total_expense as net_income,
	transaction_count
    from transactions 
    order by period_start_date, account_name
                
