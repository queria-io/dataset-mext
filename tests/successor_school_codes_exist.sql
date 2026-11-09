-- 移行後の学校コードが一覧にあるかを見る。元の一覧に、一覧に無いコードを指す行があるので (2026-05-01 時点で 3 件)、警告にとどめる
{{ config(severity='warn') }}

select s.school_code, successor
from {{ ref('schools') }} as s, unnest(s.successor_school_codes) as t(successor)
where successor not in (select school_code from {{ ref('schools') }})
