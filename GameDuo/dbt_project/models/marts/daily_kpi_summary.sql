-- 날짜별 핵심 KPI 요약 (DAU, 신규가입, 매출, ARPU/ARPPU)
with dau as (
    select
        date(session_start) as date,
        count(distinct user_id) as dau,
        count(*) as total_sessions
    from {{ ref('stg_sessions') }}
    group by date
),
new_users as (
    select install_date as date, count(*) as new_users
    from {{ ref('stg_users') }}
    group by date
),
revenue as (
    select
        date(purchase_timestamp) as date,
        sum(price_usd) as revenue_usd,
        count(*) as transactions,
        count(distinct user_id) as paying_users
    from {{ ref('stg_purchases') }}
    group by date
)
select
    d.date,
    d.dau,
    d.total_sessions,
    coalesce(n.new_users, 0) as new_users,
    coalesce(r.revenue_usd, 0.0) as revenue_usd,
    coalesce(r.transactions, 0) as transactions,
    coalesce(r.paying_users, 0) as paying_users,
    safe_divide(coalesce(r.revenue_usd, 0.0), d.dau) as arpu,
    safe_divide(coalesce(r.revenue_usd, 0.0), nullif(r.paying_users, 0)) as arppu
from dau d
left join new_users n on d.date = n.date
left join revenue r on d.date = r.date
