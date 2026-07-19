-- 마케팅 채널별 성과 (CPI, ROAS, D7 리텐션)
with channel_users as (
    select
        u.acquisition_channel,
        u.country,
        count(*) as actual_installs,
        sum(us.total_revenue_usd) as total_revenue_usd
    from {{ ref('stg_users') }} u
    join {{ ref('user_summary') }} us on u.user_id = us.user_id
    group by u.acquisition_channel, u.country
),
d7_retained as (
    select
        u.acquisition_channel,
        u.country,
        count(distinct s.user_id) as d7_active_users
    from {{ ref('stg_users') }} u
    join {{ ref('stg_sessions') }} s
        on u.user_id = s.user_id and s.day_since_install = 7
    group by u.acquisition_channel, u.country
),
channel_spend as (
    select channel, country, sum(spend_usd) as total_spend_usd, sum(installs) as spend_installs
    from {{ ref('stg_marketing_spend') }}
    group by channel, country
)
select
    cu.acquisition_channel as channel,
    cu.country,
    cu.actual_installs,
    cs.total_spend_usd,
    cs.spend_installs,
    safe_divide(cs.total_spend_usd, cs.spend_installs) as cpi,
    cu.total_revenue_usd,
    safe_divide(cu.total_revenue_usd, nullif(cs.total_spend_usd, 0)) as roas,
    coalesce(d7.d7_active_users, 0) as d7_active_users,
    safe_divide(coalesce(d7.d7_active_users, 0), cu.actual_installs) as d7_retention
from channel_users cu
left join channel_spend cs
    on cu.acquisition_channel = cs.channel and cu.country = cs.country
left join d7_retained d7
    on cu.acquisition_channel = d7.acquisition_channel and cu.country = d7.country
