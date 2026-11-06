select
    p.parcela_id,
    p.contrato_id,
    c.cliente_id,                                  
    c.produto,                                     
    p.numero_parcela,
    p.data_vencimento,
    p.valor_parcela,
    p.status_parcela,
    pg.data_pagamento,
    pg.valor_pago,
    pg.forma_pagamento
from {{ ref('silver_parcelas') }} p
join {{ ref('silver_contratos') }} c
on p.contrato_id = c.contrato_id 
left join {{ ref('silver_pagamentos')}} pg 
on p.parcela_id = pg.parcela_id       