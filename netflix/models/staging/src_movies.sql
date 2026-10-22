with raw_movies as (
    select * 
    from {{sources('netflix','r_movies')}}
)
select movieId as movie_id, title, genres
from raw_movies