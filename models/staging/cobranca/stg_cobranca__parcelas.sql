   select
       parcela_id,
       status_parcela,
       valor_parcela
   from {{ source('cobranca', 'parcelas') }}