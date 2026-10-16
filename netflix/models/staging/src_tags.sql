with raw_tags as(
    select *
    from NETFLIX.RAW.RAW_TAGS
)
select userId as user_id, movieId as movie_id, tag, to_timestamp_ltz(timestamp) as timestamp
from raw_tags