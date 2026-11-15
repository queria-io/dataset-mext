{# 取得したファイルの記録 (data/school_codes/source_file.parquet、pipelines/source_file.py が書く)。取得したままの形 #}

select * from read_parquet('data/school_codes/source_file.parquet')
