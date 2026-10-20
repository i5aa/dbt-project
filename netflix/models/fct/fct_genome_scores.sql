with src_scores as(
    select * 
    from {{ref("src_genomescore")}}
)
select movie_id,tag_id, round(relevance,4) as relevance_score
from src_scores