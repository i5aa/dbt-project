with genome_tags as(
    select * 
    from {{ref('src_genomescore')}}
)

select tag_id, INITCAP(TRIM(tag)) as tag_name
from genome_tags