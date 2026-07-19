-- 유저 마스터 원본을 그대로 노출하는 staging 뷰
select
    user_id,
    install_datetime,
    date(install_datetime) as install_date,
    country,
    platform,
    acquisition_channel,
    campaign_id,
    device_model,
    payer_segment
from {{ source('raw', 'users') }}
