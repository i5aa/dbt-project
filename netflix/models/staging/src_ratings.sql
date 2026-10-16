with raw_ratings as(
    select *
    from NETFLIX.RAW.RAW_RATINGS
)
select userId as user_id, movieId as movie_id, rating, to_timestamp_ltz(timestamp) as rating_timestamp
from raw_ratings