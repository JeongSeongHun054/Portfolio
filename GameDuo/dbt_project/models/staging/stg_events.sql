select
    event_id,
    user_id,
    session_id,
    event_timestamp,
    event_name,
    event_value
from {{ source('raw', 'events') }}
