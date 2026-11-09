# 文部科学省

文部科学省が公開するデータを SQL で検索できるテーブルにしたデータセットです。今は学校コードを収録しています。

## 学校コード（school_codes）

文部科学省が全国の学校に設定した[学校コード](https://www.mext.go.jp/b_menu/toukei/mext_01087.html)の一覧です。幼稚園・幼保連携型認定こども園から大学・専修学校・各種学校まで、学校コード・学校種・設置区分・学校名・所在地・郵便番号と、設定・廃止の年月日を収録します。毎月、最新の一覧を取得します。

## 出典と利用条件

[文部科学省 学校コード](https://www.mext.go.jp/b_menu/toukei/mext_01087.html)（文部科学省）の「最新の学校コード一覧」の CSV を取得して加工しています。学校コードの構成は[学校コードの取り扱いについて](https://www.mext.go.jp/content/20210128-mxt_chousa01-000011635_01.pdf)に従います。

- 文部科学省ウェブサイトのコンテンツは[公共データ利用規約（第1.0版）](https://www.digital.go.jp/resources/open_data/public_data_license_v1.0)に準拠した利用条件で提供されています（[利用規約](https://www.mext.go.jp/b_menu/1351168.htm)）
- 使うときは「文部科学省 学校コード（文部科学省）（https://www.mext.go.jp/b_menu/toukei/mext_01087.html）を加工して作成」のように、出典と加工したことを明記してください

## テーブル

| テーブル | 内容 |
| --- | --- |
| `school_codes.schools` | 1 行が 1 学校コード。廃止した学校も含みます |

- 学校コードは 13 桁で、学校種（2 桁）・都道府県番号（2 桁）・設置区分（1 桁）・学校番号（7 桁）・検査数字（1 桁）からなります
- 学校種・都道府県・設置区分が変わると新しい学校コードになり、元の行の `successor_school_codes` に移行後のコードが入ります

## 使い方

都道府県別・学校種別の現存する学校数:

```sql
SELECT prefecture_code, school_type_name, count(*) AS schools
FROM mext.school_codes.schools
WHERE is_active
GROUP BY ALL
ORDER BY ALL;
```

廃止した学校から移行後の学校を引く:

```sql
SELECT s.school_code, s.name, s.valid_to, t.school_code AS successor_code, t.name AS successor_name
FROM mext.school_codes.schools AS s, unnest(s.successor_school_codes) AS u(code)
JOIN mext.school_codes.schools AS t ON t.school_code = u.code
WHERE s.name LIKE '%布部%';
```

## 収録範囲の注意

- 一覧の基準日は毎年 5 月 1 日です（`as_of_date`）。5 月の時点では暫定版で（`is_final` が false）、12 月ごろに確定版に置き換わります
- 学校名・所在地・郵便番号は、文部科学省が都道府県などに確認して記載した値で、変更や誤りが含まれることがあります
- 郵便番号が 7 桁の数字でない行は、全角の数字を半角にしたうえで、なお 7 桁にならないものを NULL にしています
- 移行後の学校コードのうち、一覧に無いコードを指すものが少数あります

## ビルド

```bash
uv sync
uv run python main.py           # 取得して手元で dbt build（profiles.yml の環境変数が要る）
scripts/build.sh                # 取得・ビルドして Queria に公開する
```

`.github/workflows/sync.yml` が毎月 10 日に作り直します。
