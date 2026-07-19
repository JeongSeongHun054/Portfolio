-- 유저별 요약 (총 세션/이벤트/매출, 이탈 플래그) - 대시보드와 ML 피처 테이블의 기반
with session_agg as (
    select
        user_id,
        count(*) as total_sessions,
        min(session_start) as first_session,
        max(session_start) as last_session,
        max(day_since_install) as max_day_since_install
    from {{ ref('stg_sessions') }}
    group by user_id
),
event_agg as (
    select user_id, count(*) as total_events
    from {{ ref('stg_events') }}
    group by user_id
),
purchase_agg as (
    select
        user_id,
        sum(price_usd) as total_revenue_usd,
        count(*) as total_purchases,
        min(purchase_timestamp) as first_purchase_at
    from {{ ref('stg_purchases') }}
    group by user_id
)
select
    u.user_id,
    u.install_datetime,
    u.country,
    u.platform,
    u.acquisition_channel,
    u.payer_segment,
    date_diff(current_date(), u.install_date, day) as days_since_install,
    coalesce(s.total_sessions, 0) as total_sessions,
    coalesce(e.total_events, 0) as total_events,
    s.first_session,
    s.last_session,
    s.max_day_since_install,
    coalesce(p.total_revenue_usd, 0.0) as total_revenue_usd,
    coalesce(p.total_purchases, 0) as total_purchases,
    p.first_purchase_at,
    date_diff(current_date(), date(s.last_session), day) as days_since_last_active,
    case when date_diff(current_date(), date(s.last_session), day) > 14 then true else false end as is_churned_14d
from {{ ref('stg_users') }} u
left join session_agg s on u.user_id = s.user_id
left join event_agg e on u.user_id = e.user_id
left join purchase_agg p on u.user_id = p.user_id
