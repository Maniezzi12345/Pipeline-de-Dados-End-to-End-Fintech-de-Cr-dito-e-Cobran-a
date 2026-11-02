   {{ config(
       materialized='table',
       schema='silver'
   ) }}

   select
       parcela_id,
       status_parcela,
       valor_parcela
   from {{ ref('stg_cobranca__parcelas') }}