select
    user_id,
    experiment_name,
    variant,
    assigned_at
from {{ source('raw', 'ab_test_assignment') }}
