{%snapshot tags_snap%}
{{
    config(
        target_schema = 'snapshots',
        unique_key = ['user_id','movie_id','tag'],
        strategy='timestamp',
        updated_at = 'tag_timestamp',
        invalidate_hard_deletes=True
    )
}}

select {{dbt_utils.generate_surrogate_key(['user_id','movie_id','tag'])}} as s_key,
user_id,movie_id,tag, cast("TIMESTAMP" as timestamp_ntz) as tag_timestamp
from {{ref('src_tags')}}

{%endsnapshot%}