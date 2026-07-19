-- 설치 주차별 코호트 x 경과일별 잔존율
with cohort as (
    select user_id, date_trunc(install_date, week) as install_week
    from {{ ref('stg_users') }}
),
cohort_size as (
    select install_week, count(*) as cohort_users
    from cohort
    group by install_week
),
activity as (
    select
        c.install_week,
        s.day_since_install,
        count(distinct s.user_id) as active_users
    from {{ ref('stg_sessions') }} s
    join cohort c on s.user_id = c.user_id
    where s.day_since_install <= 90
    group by c.install_week, s.day_since_install
)
select
    a.install_week,
    a.day_since_install,
    a.active_users,
    cs.cohort_users,
    safe_divide(a.active_users, cs.cohort_users) as retention_rate
from activity a
join cohort_size cs on a.install_week = cs.install_week
