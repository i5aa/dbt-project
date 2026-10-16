with genomescore as(
    select *
    from NETFLIX.RAW.RAW_GENOME_SCORES
)
select movieId as movie_id, relevance, tagid as tag_id
from genomescore