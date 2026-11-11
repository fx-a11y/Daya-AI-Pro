# Daya AI Pro – yfinance US Screener integration

This package adds an **end-of-day US stock volume screener** to the existing Flutter app. Indonesia continues to use the existing Api.co.id path. No Railway, VPS, or yfinance API key is used.

## What was added

- `scripts/build_us_screener.py`: builds the US-listed symbol universe from Nasdaq Trader symbol directories, then downloads daily candles using `yfinance`.
- `.github/workflows/update-us-screener.yml`: scheduled weekday GitHub Actions job; writes `data/us_stocks.json` and commits it to `main`.
- `lib/main.dart`: adds a US screener panel that reads the JSON from the public raw GitHub URL and ranks the first 25 displayed names by RVOL.

The JSON includes `close`, `volume`, `avg_volume_20`, `rvol`, `change_pct`, and update timestamps.

## Install into your repository

1. Extract this ZIP.
2. Copy the contents of `daya_work/` into the root of `https://github.com/fx-a11y/Daya-AI-Pro`.
3. Ensure the Flutter entry point is `lib/main.dart` (not `lib/main.dart.txt`).
4. Keep your existing Android folder, build workflow, and any other project files. Do not delete them.
5. In GitHub, open **Settings → Actions → General → Workflow permissions** and allow **Read and write permissions**. The workflow needs this to commit the JSON.
6. Open **Actions → Update US stock screener data → Run workflow** once. Wait for the run to finish successfully.
7. Confirm `data/us_stocks.json` appears in the repository. The Flutter panel then reads it from the raw URL automatically.

## Important limits

- This is daily/EOD data, not real-time or intraday data. The scheduled run is not guaranteed to start at an exact minute.
- yfinance is an unofficial interface to Yahoo Finance; data coverage, availability, rate limits, and terms can change. Some directory symbols will be omitted if Yahoo does not return enough history.
- “All US stocks” here means common-stock-like symbols found in Nasdaq Trader's Nasdaq and other-listed directories after basic filtering. It is not a guarantee that every US-listed security has Yahoo data. Funds, ETFs, warrants, rights, units, and preferreds are filtered where metadata allows.
- The first complete universe refresh may take a long time and can hit Yahoo rate limits. If it fails, rerun later or reduce `BATCH_SIZE` to `40`. GitHub Actions has execution-time limits.
- Current IDX screener still scans only 18 BEI tickers per manual run because the existing Api.co.id free-tier limit is 500 hits/month. This integration does not silently change that quota.
- The Flutter code uses the repository's `main` branch raw URL. If your default branch is not `main`, update `USMarketService.dataUrl` accordingly.
