select
    parcela_id,
    contrato_id,
    numero_parcela,
    data_vencimento,
    valor_parcela,
    status_parcela
from {{ ref('silver_parcelas') }}