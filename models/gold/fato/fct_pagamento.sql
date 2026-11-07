WITH nome AS (
    SELECT
        pagamento_id,
        parcela_id,
        valor_pago,
        dias_atraso,
        data_pagamento,
        forma_pagamento
    FROM {{ ref('silver_pagamentos') }}
),

cte1 AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY parcela_id
            ORDER BY data_pagamento DESC
        ) AS rn
    FROM nome 
),

cte2 as (
    select 
          parcela_id,
          contato_id,
          cliente_id,
          data_vencimento
    from {{ ref('fct_parcela')}}
)

SELECT *
FROM cte1 
JOIN cte2 
on cte1.parcela_id = cte2.parcela_id where rn = 1