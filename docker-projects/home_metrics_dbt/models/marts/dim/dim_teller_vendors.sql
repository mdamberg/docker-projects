  {{ config(
      materialized = 'table',
      schema = 'marts'
  ) }}

  with vendors as (
      select distinct
          vendor_key,
          vendor as vendor_name,
          teller_vendor_category as vendor_category,
          bool_or(is_recurring) as is_recurring_vendor
      from {{ ref('intmdt_transactions') }}
      where vendor_key is not null
      group by 1, 2, 3
  )

  select * from vendors