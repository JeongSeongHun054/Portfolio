select
    session_id,
    user_id,
    session_start,
    session_end,
    timestamp_diff(session_end, session_start, second) as session_length_sec,
    day_since_install
from {{ source('raw', 'sessions') }}
