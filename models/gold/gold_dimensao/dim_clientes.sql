select 
      sc.cliente_id,
      sc.nome,
      sc.primeiro_nome,
      sc.cidade,
      sc.UF,
      sc.faixa_risco ,
      sc.renda_mensal ,
      sc.data_cadastro ,
      sc.provedor_email 
from {{ref('silver_clientes')}} as sc 