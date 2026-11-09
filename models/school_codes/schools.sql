{# 学校コード一覧 (data/school_codes/*.csv) を型付けする。1 行が 1 学校コード。
   CSV の 1 行目は表題と更新日、2 行目が見出しなので飛ばす。
   区分の列は「A1(幼稚園)」のようにコードと略称が並ぶので、括弧の前をコードとして取る #}

with source as (
    select *
    from read_csv(
        'data/school_codes/*.csv',
        header = false,
        skip = 2,
        quote = '"',
        filename = true,
        columns = {
            'school_code': 'VARCHAR',
            'school_type': 'VARCHAR',
            'prefecture': 'VARCHAR',
            'establishment': 'VARCHAR',
            'campus': 'VARCHAR',
            'name': 'VARCHAR',
            'address': 'VARCHAR',
            'postal_code': 'VARCHAR',
            'valid_from': 'VARCHAR',
            'valid_to': 'VARCHAR',
            'previous_survey_number': 'VARCHAR',
            'successor_school_code': 'VARCHAR'
        }
    )
),

file as (
    -- ファイル名は <基準日>_<provisional|final>_<連番>.csv
    select
        *,
        cast(strptime(split_part(parse_filename(filename), '_', 1), '%Y%m%d') as date) as as_of_date,
        split_part(parse_filename(filename), '_', 2) = 'final' as is_final
    from source
)

select
    school_code,
    regexp_extract(school_type, '^([A-H][0-9])', 1) as school_type_code,
    -- 学校種の名前は「学校コードの取り扱いについて」別添 1 の表記
    case regexp_extract(school_type, '^([A-H][0-9])', 1)
        when 'A1' then '幼稚園'
        when 'A2' then '幼保連携型認定こども園'
        when 'B1' then '小学校'
        when 'C1' then '中学校'
        when 'C2' then '義務教育学校'
        when 'D1' then '高等学校'
        when 'D2' then '中等教育学校'
        when 'E1' then '特別支援学校'
        when 'F1' then '大学'
        when 'F2' then '短期大学'
        when 'G1' then '高等専門学校'
        when 'H1' then '専修学校'
        when 'H2' then '各種学校'
    end as school_type_name,
    -- 一覧の略称。特別支援学校は 養護・特支聾・特支盲 に分かれる
    regexp_extract(school_type, '\((.*)\)', 1) as school_type_label,
    regexp_extract(prefecture, '^([0-9]{2})', 1) as prefecture_code,
    case regexp_extract(establishment, '^([0-9])', 1)
        when '1' then 'national'
        when '2' then 'public'
        when '3' then 'private'
    end as establishment,
    case regexp_extract(campus, '^([0-9])', 1)
        when '1' then 'main'
        when '2' then 'branch'
        when '9' then 'closed'
    end as campus,
    name,
    nullif(address, '') as address,
    -- 全角の数字が混ざる行と、桁の足りない行 (000 など) がある。半角にして 7 桁のものだけ残す
    case
        when regexp_full_match(translate(postal_code, '０１２３４５６７８９', '0123456789'), '[0-9]{7}')
            then translate(postal_code, '０１２３４５６７８９', '0123456789')
    end as postal_code,
    cast(nullif(valid_from, '') as date) as valid_from,
    cast(nullif(valid_to, '') as date) as valid_to,
    nullif(valid_to, '') is null as is_active,
    nullif(previous_survey_number, '') as previous_survey_number,
    -- 統合・分割で複数になると、読点やカンマ、改行で区切って並ぶ
    nullif(regexp_extract_all(successor_school_code, '[A-H][0-9]{12}'), []) as successor_school_codes,
    as_of_date,
    is_final
from file
