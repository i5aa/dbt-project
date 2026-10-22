{{
    config(materialized='table')
}}

with fct_ratings as(
    select * from {{ref('fct_ratings')}}
),
seed_dates as(
    select * from {{ref('movie_release_date')}}
)

select f.*,
case 
    when d.release_date is Null then 'Unknown'
    else 'Known'
end as release_info_available
from fct_ratings f
left join seed_dates d
on s.movie_id = d.movie_id