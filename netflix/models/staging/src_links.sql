with raw_links as(
    select *
    from NETFLIX.RAW.RAW_LINKS
)
select movieid as movie_id, imdbid as imdb_id, tmdbid as tmdb_id
from raw_links