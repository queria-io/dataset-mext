"""文部科学省の学校コードのデータパイプライン。

1. school_codes: 最新の学校コード一覧 (CSV) を取り出す
2. dbt: dbt ビルド
"""

import logging

from dbt.cli.main import dbtRunner

from pipelines import plans
from pipelines.school_codes import download_school_codes

# dbt を読み込むとルートロガーが先に設定されるので、force で上書きする
logging.basicConfig(level=logging.INFO, format="%(message)s", force=True)
logger = logging.getLogger("pipelines")


def dbt_build():
    dbt = dbtRunner()
    for command in (["deps"], ["build"], ["docs", "generate"]):
        if not dbt.invoke(command).success:
            raise SystemExit(f"dbt {' '.join(command)} failed")


def main():
    logger.info("1/3: school_codes (学校コード一覧)")
    download_school_codes()

    logger.info("2/3: plans (行政事業レビューが挙げる計画・通知等)")
    plans.download_plans()
    plans.build_plans_parquet()

    logger.info("3/3: dbt build")
    dbt_build()


if __name__ == "__main__":
    main()
