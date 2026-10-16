with genometags as(
    select *
    from NETFLIX.RAW.RAW_GENOME_TAGS
)
select tag, tagId as tag_id
from genometags