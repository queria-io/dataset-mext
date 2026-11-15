{# 学校コード一覧 (data/school_codes/*.csv)。取得したままの形。
   CSV の 1 行目は表題と更新日、2 行目が見出しなので飛ばし、列名は見出しの順に付ける #}

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
