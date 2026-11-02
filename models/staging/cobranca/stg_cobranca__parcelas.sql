   select *
   from {{ source('cobranca', 'parcelas') }}