select
    transaction_id,
    user_id,
    purchase_timestamp,
    product_id,
    price_usd,
    is_first_purchase
from {{ source('raw', 'purchases') }}
