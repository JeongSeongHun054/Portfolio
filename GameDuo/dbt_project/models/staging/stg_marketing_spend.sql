select
    date,
    channel,
    country,
    installs,
    spend_usd,
    clicks,
    impressions
from {{ source('raw', 'marketing_spend') }}
