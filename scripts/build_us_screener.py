#!/usr/bin/env python3
"""Build daily US stock screener data using Twelve Data REST API.

Set TWELVE_DATA_API_KEY in the GitHub Actions repository secret.
The default universe is a curated liquid US watchlist to fit API quotas.
Override with US_SYMBOLS (comma-separated) when needed.
"""
from __future__ import annotations
import json
import os
import time
from datetime import datetime, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

import pandas as pd

OUT = "data/us_stocks.json"
API_KEY = os.getenv("TWELVE_DATA_API_KEY", "").strip()
PAUSE_SECONDS = float(os.getenv("PAUSE_SECONDS", "8.2"))
OUTPUTSIZE = int(os.getenv("OUTPUTSIZE", "250"))
DEFAULT_SYMBOLS = """
AAPL MSFT NVDA AMZN GOOGL META TSLA AVGO BRK.B JPM WMT LLY V XOM MA
COST ORCL NFLX JNJ PLTR ABBV BAC HD PG CVX KO AMD GE CAT MRK CSCO IBM
WFC CRM AMAT QCOM MU LIN MCD PM ABT TMO GS RTX DIS NOW ISRG TXN
PEP INTU UBER LOW VZ BKNG SPGI BLK SCHW UNH C AMGN HON COP ADI
ANET PANW LRCX KLAC SNPS CDNS UPS NKE SBUX T GT REGN MDT DE BA
SHOP ARM COIN HOOD SOFI MARA RIOT RBLX SNAP PINS F Ford GM FDX
"""
def symbols_to_scan():
    raw = os.getenv("US_SYMBOLS", "").strip()
    source = raw if raw else DEFAULT_SYMBOLS
    result = []
    for item in source.replace(",", " ").split():
        sym = item.strip().upper()
        if sym and sym not in result:
            result.append(sym)
    return result

def safe_num(value):
    try:
        n = float(value)
        return n if pd.notna(n) else 0.0
    except Exception:
        return 0.0

def fetch_daily(symbol: str) -> tuple[pd.DataFrame, dict]:
    params = urlencode({
        "symbol": symbol,
        "interval": "1day",
        "outputsize": OUTPUTSIZE,
        "apikey": API_KEY,
        "format": "JSON",
    })
    url = f"https://api.twelvedata.com/time_series?{params}"
    req = Request(url, headers={"User-Agent": "DayaAIPro/0.4.9"})
    try:
        with urlopen(req, timeout=35) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {body[:250]}") from exc
    except URLError as exc:
        raise RuntimeError(f"Network error: {exc}") from exc

    if payload.get("status") == "error" or "values" not in payload:
        message = payload.get("message") or payload.get("code") or "Unknown Twelve Data response"
        raise RuntimeError(str(message))
    values = payload.get("values") or []
    if not values:
        raise RuntimeError("Twelve Data returned no daily candles")
    frame = pd.DataFrame(values)
    for col in ("open", "high", "low", "close", "volume"):
        if col in frame:
            frame[col] = pd.to_numeric(frame[col], errors="coerce")
        else:
            frame[col] = 0
    frame["datetime"] = pd.to_datetime(frame["datetime"], errors="coerce")
    frame = frame.dropna(subset=["datetime", "close", "high", "low"])
    frame = frame.sort_values("datetime").reset_index(drop=True)
    return frame, payload.get("meta", {})

def rsi14(closes: pd.Series) -> float:
    delta = closes.diff()
    gain = delta.clip(lower=0).ewm(alpha=1/14, min_periods=14, adjust=False).mean()
    loss = (-delta.clip(upper=0)).ewm(alpha=1/14, min_periods=14, adjust=False).mean()
    g, l = safe_num(gain.iloc[-1]), safe_num(loss.iloc[-1])
    if l == 0:
        return 100.0 if g > 0 else 50.0
    return 100.0 - 100.0 / (1.0 + g/l)

def build_row(symbol: str, frame: pd.DataFrame, meta: dict) -> dict:
    if len(frame) < 55:
        raise RuntimeError(f"Insufficient daily candles: {len(frame)} (need >=55)")
    close_s = frame["close"].astype(float)
    high_s = frame["high"].astype(float)
    low_s = frame["low"].astype(float)
    volume_s = frame["volume"].fillna(0).astype(float)
    close = safe_num(close_s.iloc[-1])
    prev = safe_num(close_s.iloc[-2])
    volume = safe_num(volume_s.iloc[-1])
    avg20 = safe_num(volume_s.iloc[-21:-1].mean())
    rvol = volume / avg20 if avg20 > 0 else 0.0

    ema20 = safe_num(close_s.ewm(span=20, adjust=False).mean().iloc[-1])
    ema50 = safe_num(close_s.ewm(span=50, adjust=False).mean().iloc[-1])
    ema200 = safe_num(close_s.ewm(span=200, adjust=False).mean().iloc[-1]) if len(frame) >= 200 else 0.0
    delta = close_s.diff()
    tr = pd.concat([
        high_s-low_s,
        (high_s-close_s.shift(1)).abs(),
        (low_s-close_s.shift(1)).abs()
    ], axis=1).max(axis=1)
    atr = safe_num(tr.rolling(14).mean().iloc[-1])
    rsi = rsi14(close_s)
    macd_line = close_s.ewm(span=12, adjust=False).mean() - close_s.ewm(span=26, adjust=False).mean()
    macd_signal = macd_line.ewm(span=9, adjust=False).mean()
    macd = safe_num(macd_line.iloc[-1])
    macd_sig = safe_num(macd_signal.iloc[-1])
    macd_hist = macd - macd_sig

    change = ((close / prev) - 1) * 100 if prev > 0 else 0.0
    anti = ""
    if change >= 15:
        anti = "Kenaikan harian >=15%; hindari mengejar harga."
    elif atr > 0 and close > ema20 and close - ema20 >= 1.5 * atr:
        anti = "Harga terlalu jauh dari EMA20 dibanding ATR14; tunggu pullback."
    elif rsi >= 75:
        anti = "RSI14 >=75; kondisi jenuh beli, tunggu pendinginan."

    setup = "NO TRADE"
    entry_low = entry_high = stop = tp1 = tp2 = 0.0
    if not anti and atr > 0 and ema20 > ema50 and close > ema20 and 48 <= rsi <= 68 and rvol >= 0.8:
        setup = "BUY SETUP"
        entry_low = max(0.01, close - 0.50 * atr)
        entry_high = max(entry_low, close - 0.15 * atr)
        mid = (entry_low + entry_high) / 2
        stop = max(0.01, entry_low - 1.20 * atr)
        risk = max(0.01, mid - stop)
        tp1, tp2 = mid + 1.5*risk, mid + 2*risk
    elif not anti and atr > 0 and ema20 > ema50 and close > ema20:
        setup = "WAIT"

    last_date = frame["datetime"].iloc[-1].date()
    valid_until = (pd.Timestamp(last_date) + pd.offsets.BDay(5)).date().isoformat()
    return {
        "symbol": symbol,
        "name": meta.get("name") or meta.get("instrument_name") or symbol,
        "close": round(close, 4),
        "currency": meta.get("currency") or "USD",
        "volume": int(volume),
        "avg_volume_20": int(avg20),
        "rvol": round(rvol, 3),
        "change_pct": round(change, 3),
        "ema20": round(ema20, 4),
        "ema50": round(ema50, 4),
        "ema200": round(ema200, 4) if ema200 > 0 else None,
        "rsi14": round(rsi, 2),
        "atr14": round(atr, 4),
        "macd": round(macd, 5),
        "macd_signal": round(macd_sig, 5),
        "macd_histogram": round(macd_hist, 5),
        "candle_count": int(len(frame)),
        "indicator_status": "OK",
        "setup": setup,
        "anti_chase": bool(anti),
        "anti_chase_reason": anti,
        "entry_low": round(entry_low, 4) if entry_low else None,
        "entry_high": round(entry_high, 4) if entry_high else None,
        "stop_loss": round(stop, 4) if stop else None,
        "take_profit_1": round(tp1, 4) if tp1 else None,
        "take_profit_2": round(tp2, 4) if tp2 else None,
        "valid_until": valid_until,
        "signal_basis_date": last_date.isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "data_source": "Twelve Data"
    }

def main():
    if not API_KEY:
        raise SystemExit("TWELVE_DATA_API_KEY secret belum diatur di GitHub repository.")
    symbols = symbols_to_scan()
    rows, errors = [], []
    print(f"Twelve Data: scan {len(symbols)} symbols; interval=1day; outputsize={OUTPUTSIZE}")
    for index, symbol in enumerate(symbols, 1):
        try:
            frame, meta = fetch_daily(symbol)
            row = build_row(symbol, frame, meta)
            rows.append(row)
            print(f"[{index}/{len(symbols)}] {symbol}: OK ({row['candle_count']} candles)")
        except Exception as exc:
            errors.append({"symbol": symbol, "error": str(exc)})
            print(f"[{index}/{len(symbols)}] {symbol}: ERROR {exc}")
        if index < len(symbols):
            time.sleep(PAUSE_SECONDS)

    rows.sort(key=lambda x: x["rvol"], reverse=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    payload = {
        "market": "US",
        "source": "Twelve Data REST API",
        "interval": "1day",
        "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "universe_count": len(symbols),
        "returned_count": len(rows),
        "failed_count": len(errors),
        "note": "Daily candles/EOD; not real-time. Coverage and history depend on Twelve Data plan and symbol entitlement.",
        "errors": errors,
        "stocks": rows
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Wrote {OUT}: {len(rows)} usable symbols; {len(errors)} failed")
    if not rows:
        raise SystemExit("No valid US stocks returned. Check API key, plan coverage, and symbol permissions.")

if __name__ == "__main__":
    main()
