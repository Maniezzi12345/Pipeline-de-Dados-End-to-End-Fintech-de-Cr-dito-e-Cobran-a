select
    initcap(trim(mr.responsavel))                                     as responsavel,

    to_date(left(cast(mr.mes as text), 7), 'YYYY-MM')                 as mes_referencia,

    -- faixa de atraso: extrai os dois números, qualquer que seja o separador ("a", "-", "–")
    cast(substring(mr.faixa_atraso from '(\d+)') as integer)          as faixa_inicio_dias,
    cast(substring(mr.faixa_atraso from '\d+\D+(\d+)') as integer)    as faixa_fim_dias,
    substring(mr.faixa_atraso from '(\d+)')
        || coalesce('-' || substring(mr.faixa_atraso from '\d+\D+(\d+)'), '+')
                                                                      as faixa_atraso_dias,   -- 31-45 / 90+

    -- meta: tudo como taxa decimal entre 0 e 1 (85% -> 0.8500)
    case
        when nullif(regexp_replace(replace(cast(mr.meta_taxa_recuperacao as text), ',', '.'),
                                   '[^0-9.]', '', 'g'), '') is null
            then null
        when cast(regexp_replace(replace(cast(mr.meta_taxa_recuperacao as text), ',', '.'),
                                 '[^0-9.]', '', 'g') as numeric) > 1
            then round(cast(regexp_replace(replace(cast(mr.meta_taxa_recuperacao as text), ',', '.'),
                                           '[^0-9.]', '', 'g') as numeric) / 100, 4)
        else round(cast(regexp_replace(replace(cast(mr.meta_taxa_recuperacao as text), ',', '.'),
                                       '[^0-9.]', '', 'g') as numeric), 4)
    end                                                               as meta_taxa_recuperacao

from {{ source('cobranca', 'metas_recuperacao') }} mr