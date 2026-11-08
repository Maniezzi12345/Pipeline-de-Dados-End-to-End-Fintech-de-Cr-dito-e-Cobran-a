select
    scc.canal,
    scc.custo_unitario
from {{ ref('silver_custos_cobranca') }} scc