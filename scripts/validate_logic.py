#!/usr/bin/env python3
"""Offline validation mirroring Swift unit test logic."""

import re
import sys

PASS = FAIL = 0

def test(name, cond):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  ✓ {name}")
    else:
        FAIL += 1
        print(f"  ✗ {name}")

def health_score(metrics, within_days=7):
    recent = [m for m in metrics if m[1] <= within_days]
    if not recent:
        return 75
    normal = sum(1 for n, _ in recent if n)
    return int(60 + (normal / len(recent)) * 40)

def adherence(hours, taken, days=7):
    expected = hours * days
    return 1.0 if expected == 0 else min(1.0, taken / expected)

def parse_glucose(text):
    m = re.search(r"glucose[:\s]+(\d+\.?\d*)", text, re.I)
    if not m:
        return None
    v = float(m.group(1))
    return v, v > 100 or v < 70

def trend_sorted(values):
    return sorted(values)

print("HealthScoreCalculator")
test("empty", health_score([]) == 75)
test("all normal", health_score([(True,0),(True,1)]) == 100)
test("all abnormal", health_score([(False,0),(False,1)]) == 60)

print("\nMedicationAdherence")
test("full", abs(adherence(2,14)-1) < 0.001)
test("half", abs(adherence(2,7)-0.5) < 0.001)

print("\nLabReportParser")
g = parse_glucose("Glucose: 142 mg/dL")
test("glucose parse", g and g[0] == 142)
test("glucose abnormal", g and g[1])

print("\nLabTrendService")
pts = trend_sorted([("2025-09",118),("2026-01",128),("2026-03",142)])
test("trend order", pts[0][1] < pts[-1][1])
test("rising glucose", pts[-1][1] > pts[0][1])

print(f"\n{'='*40}\nResults: {PASS} passed, {FAIL} failed")
sys.exit(1 if FAIL else 0)
