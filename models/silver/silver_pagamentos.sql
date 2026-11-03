select
    cast(p.pagamento_id as integer)                    as pagamento_id,
    cast(p.parcela_id as integer)                      as parcela_id,
    cast(nullif(
        case
            when cast(p.valor_pago as text) like '%,%'
                then replace(regexp_replace(cast(p.valor_pago as text), '[^0-9,]', '', 'g'), ',', '.')
            else regexp_replace(cast(p.valor_pago as text), '[^0-9.]', '', 'g')
        end, '') as numeric(12,2))                     as valor_pago,
    cast(p.dias_atraso as integer)                     as dias_atraso,

    -- data do pagamento: aceita formato brasileiro e internacional
    case
        when p.data_pagamento is null or trim(cast(p.data_pagamento as text)) = '' then null
        when cast(p.data_pagamento as text) ~ '^\d{2}/\d{2}/\d{4}'
            then to_date(left(cast(p.data_pagamento as text), 10), 'DD/MM/YYYY')
        else cast(left(cast(p.data_pagamento as text), 10) as date)
    end                                                as data_pagamento,

    -- forma de pagamento: normaliza rótulos diferentes para a mesma coisa
    case
        when translate(lower(trim(replace(cast(p.forma_pagamento as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') like 'boleto%'
            then 'Boleto'
        when translate(lower(trim(replace(cast(p.forma_pagamento as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') = 'pix'
            then 'Pix'
        when translate(lower(trim(replace(cast(p.forma_pagamento as text), '_', ' '))),
                       'áàãâéêíóôõúç', 'aaaaeeiooouc') = 'debito automatico'
            then 'Débito automático'
        when p.forma_pagamento is null or trim(cast(p.forma_pagamento as text)) = ''
            then null
        else 'Não identificado'
    end                                                as forma_pagamento
from {{ source('cobranca', 'pagamentos') }} p