#!/usr/bin/env python3
"""Build end-of-day US equity screener JSON using yfinance.

Universe is sourced from Nasdaq Trader symbol directories (Nasdaq + other
US-listed securities). ETFs, test issues, warrants, units, rights, and
preferreds are excluded where the directory provides security metadata.
Yahoo Finance coverage and request availability are not guaranteed.
"""
from __future__ import annotations
import csv, io, json, os, re, time
from datetime import datetime, timezone
from urllib.request import Request, urlopen

import pandas as pd
import yfinance as yf

NASDAQ = "https://www.nasdaqtrader.com/dynamic/SymDir/nasdaqlisted.txt"
OTHER = "https://www.nasdaqtrader.com/dynamic/SymDir/otherlisted.txt"
OUT = "data/us_stocks.json"
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "80"))
PAUSE_SECONDS = float(os.getenv("PAUSE_SECONDS", "2"))

def fetch_text(url: str) -> str:
    req = Request(url, headers={"User-Agent": "Mozilla/5.0 DayaAIPro/1.0"})
    with urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8-sig", errors="replace")

def read_pipe(url: str) -> list[dict]:
    text = fetch_text(url)
    rows = list(csv.DictReader(io.StringIO(text), delimiter="|"))
    return [r for r in rows if not any(str(v).startswith("File Creation Time") for v in r.values())]

def valid_symbol(raw: str) -> str | None:
    s = (raw or "").strip().upper().replace("$", "-")
    if not s or s in {"TEST", "N/A"}: return None
    # Yahoo uses dash for share classes, e.g. BRK-B.
    if not re.fullmatch(r"[A-Z][A-Z0-9.-]{0,9}", s): return None
    return s

def universe() -> list[dict]:
    items = {}
    for row in read_pipe(NASDAQ):
        symbol = valid_symbol(row.get("Symbol", ""))
        name = (row.get("Security Name") or "").strip()
        if not symbol or row.get("Test Issue", "N").upper() == "Y": continue
        if row.get("ETF", "N").upper() == "Y": continue
        if any(x in name.lower() for x in ("warrant", "right", "unit", "depositary share", "preferred")): continue
        items[symbol] = {"symbol": symbol, "name": name}
    for row in read_pipe(OTHER):
        symbol = valid_symbol(row.get("ACT Symbol", ""))
        name = (row.get("Security Name") or "").strip()
        if not symbol: continue
        if row.get("ETF", "N").upper() == "Y": continue
        if any(x in name.lower() for x in ("warrant", "right", "unit", "depositary share", "preferred")): continue
        items.setdefault(symbol, {"symbol": symbol, "name": name})
    return sorted(items.values(), key=lambda x: x["symbol"])

def safe_num(value):
    try:
        n = float(value)
        return n if pd.notna(n) else 0.0
    except Exception:
        return 0.0

def main():
    symbols = universe()
    print(f"Universe directory: {len(symbols)} symbols")
    rows = []
    names = {x["symbol"]: x["name"] for x in symbols}
    tickers = list(names)
    for start in range(0, len(tickers), BATCH_SIZE):
        batch = tickers[start:start+BATCH_SIZE]
        try:
            data = yf.download(
                tickers=batch, period="3mo", interval="1d",
                group_by="ticker", auto_adjust=True, actions=False,
                progress=False, threads=True, timeout=30
            )
        except Exception as exc:
            print(f"Batch {start//BATCH_SIZE+1} failed: {exc}")
            time.sleep(PAUSE_SECONDS)
            continue
        for sym in batch:
            try:
                frame = data[sym].copy() if isinstance(data.columns, pd.MultiIndex) else data.copy()
                if frame.empty or "Close" not in frame or "Volume" not in frame: continue
                frame = frame.dropna(subset=["Close"])
                if len(frame) < 22: continue
                close = safe_num(frame["Close"].iloc[-1])
                prev = safe_num(frame["Close"].iloc[-2])
                volume = safe_num(frame["Volume"].iloc[-1])
                avg20 = safe_num(frame["Volume"].iloc[-21:-1].mean())
                if close <= 0 or avg20 <= 0: continue
                rvol = volume / avg20
                # Daily technical indicators for a short swing setup.
                highs = frame["High"].astype(float)
                lows = frame["Low"].astype(float)
                closes = frame["Close"].astype(float)
                prev_closes = closes.shift(1)
                true_range = pd.concat([
                    highs - lows,
                    (highs - prev_closes).abs(),
                    (lows - prev_closes).abs(),
                ], axis=1).max(axis=1)
                atr14 = safe_num(true_range.rolling(14).mean().iloc[-1])
                ema20 = safe_num(closes.ewm(span=20, adjust=False).mean().iloc[-1])
                ema50 = safe_num(closes.ewm(span=50, adjust=False).mean().iloc[-1])
                delta = closes.diff()
                gain = delta.clip(lower=0).rolling(14).mean()
                loss = (-delta.clip(upper=0)).rolling(14).mean()
                rs = gain / loss.replace(0, float("nan"))
                rsi14 = safe_num((100 - (100 / (1 + rs))).iloc[-1])
                if rsi14 == 0 and safe_num(loss.iloc[-1]) == 0 and safe_num(gain.iloc[-1]) > 0:
                    rsi14 = 100.0

                # Only publish an entry plan when trend, momentum and volatility data agree.
                setup = "NO TRADE"
                entry_low = entry_high = stop_loss = take_profit_1 = take_profit_2 = 0.0
                if atr14 > 0 and ema20 > ema50 and close > ema20 and 48 <= rsi14 <= 68 and rvol >= 0.8:
                    setup = "BUY SETUP"
                    entry_low = max(0.01, close - 0.50 * atr14)
                    entry_high = max(entry_low, close - 0.15 * atr14)
                    entry_mid = (entry_low + entry_high) / 2
                    stop_loss = max(0.01, entry_low - 1.20 * atr14)
                    risk = max(0.01, entry_mid - stop_loss)
                    take_profit_1 = entry_mid + 1.5 * risk
                    take_profit_2 = entry_mid + 2.0 * risk
                elif atr14 > 0 and ema20 > ema50 and close > ema20:
                    setup = "WAIT"

                last_session = pd.Timestamp(frame.index[-1]).date()
                # Five weekday sessions; exchange holidays are not excluded in this approximation.
                valid_until = (pd.Timestamp(last_session) + pd.offsets.BDay(5)).date().isoformat()
                rows.append({
                    "symbol": sym,
                    "name": names.get(sym, sym),
                    "close": round(close, 4),
                    "volume": int(volume),
                    "avg_volume_20": int(avg20),
                    "rvol": round(rvol, 3),
                    "change_pct": round(((close / prev) - 1) * 100, 3) if prev > 0 else 0,
                    "ema20": round(ema20, 4),
                    "ema50": round(ema50, 4),
                    "rsi14": round(rsi14, 2),
                    "atr14": round(atr14, 4),
                    "setup": setup,
                    "entry_low": round(entry_low, 4) if entry_low else None,
                    "entry_high": round(entry_high, 4) if entry_high else None,
                    "stop_loss": round(stop_loss, 4) if stop_loss else None,
                    "take_profit_1": round(take_profit_1, 4) if take_profit_1 else None,
                    "take_profit_2": round(take_profit_2, 4) if take_profit_2 else None,
                    "valid_until": valid_until,
                    "signal_basis_date": last_session.isoformat(),
                    "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds")
                })
            except Exception:
                continue
        print(f"Processed {min(start+BATCH_SIZE,len(tickers))}/{len(tickers)}; usable rows={len(rows)}")
        time.sleep(PAUSE_SECONDS)

    rows.sort(key=lambda x: x["rvol"], reverse=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    payload = {
        "market": "US",
        "source": "Yahoo Finance via yfinance; universe from Nasdaq Trader symbol directories",
        "interval": "1d",
        "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "universe_count": len(symbols),
        "returned_count": len(rows),
        "note": "End-of-day data, not real-time. Yahoo coverage/rate limits may omit symbols.",
        "stocks": rows
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Wrote {OUT}: {len(rows)} symbols")

if __name__ == "__main__":
    main()
