"""文部科学省の学校コード一覧 (CSV) を取り出す。

学校コードのページの「最新の学校コード一覧」にある CSV をすべて取る
(幼稚園〜各種学校の東日本・西日本と、大学・短期大学・高等専門学校)。
ファイルの URL は公開のたびに変わるので、ページからリンクを読み取る。

出力: data/school_codes/<基準日>_<provisional|final>_<連番>.csv

データソース: 文部科学省 学校コード
https://www.mext.go.jp/b_menu/toukei/mext_01087.html
"""

import logging
import re
import shutil
from pathlib import Path

from shared.fetch import fetch

logger = logging.getLogger("pipelines")

SITE = "https://www.mext.go.jp"
PAGE = f"{SITE}/b_menu/toukei/mext_01087.html"
USER_AGENT = "dataset-mext (+https://github.com/queria-io/dataset-school-codes)"
OUTPUT = Path("data/school_codes")
LATEST = re.compile(r"最新の学校コード一覧(.*?)過去の学校コード一覧", re.S)
AS_OF = re.compile(r"令和(\d+)年(\d+)月(\d+)日時点（(暫定|確定)版）")
CSV_LINK = re.compile(r'href="(/content/[^"]+\.csv)"')
HEADER = "学校コード,学校種,都道府県番号"
STATUS = {"暫定": "provisional", "確定": "final"}


def latest_files(page: str) -> tuple[str, list[str]]:
    """ページから、最新の一覧の基準日と状態 (例: 20260501_provisional) と CSV の URL を返す。"""
    section = LATEST.search(page)
    if not section:
        raise SystemExit("「最新の学校コード一覧」の節が見つからない")
    as_of = AS_OF.search(section.group(1))
    if not as_of:
        raise SystemExit("最新の学校コード一覧の基準日が読み取れない")
    era, month, day, status = as_of.groups()
    label = f"{2018 + int(era)}{int(month):02}{int(day):02}_{STATUS[status]}"
    return label, [SITE + path for path in CSV_LINK.findall(section.group(1))]


def download_school_codes() -> None:
    label, urls = latest_files(fetch(PAGE, user_agent=USER_AGENT).decode("utf-8"))
    if not urls:
        raise SystemExit("最新の学校コード一覧に CSV のリンクが無い")

    # 書き終わるまで前回の出力を残す。古い年のファイルが混ざらないよう、フォルダごと替える
    partial = OUTPUT.with_name(OUTPUT.name + ".part")
    shutil.rmtree(partial, ignore_errors=True)
    partial.mkdir(parents=True)
    for number, url in enumerate(urls, start=1):
        body = fetch(url, user_agent=USER_AGENT).decode("utf-8-sig")
        if HEADER not in body.splitlines()[1]:
            raise SystemExit(f"見出しの行が想定と違う: {url}")
        (partial / f"{label}_{number}.csv").write_text(body, encoding="utf-8")
        logger.info("  %s", url)
    shutil.rmtree(OUTPUT, ignore_errors=True)
    partial.rename(OUTPUT)
