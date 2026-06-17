#!/usr/bin/env python3
"""Offline validation for ParentsHealth pure-logic tests (runs without Xcode)."""

import re
import sys
from dataclasses import dataclass

PASS = 0
FAIL = 0


def test(name: str, condition: bool):
    global PASS, FAIL
    if condition:
        PASS += 1
        print(f"  ✓ {name}")
    else:
        FAIL += 1
        print(f"  ✗ {name}")


# --- Health Score Logic ---
def health_score(metrics: list[tuple[bool, int]], within_days: int = 7) -> int:
  """metrics: list of (is_normal, days_ago)"""
  recent = [m for m in metrics if m[1] <= within_days]
  if not recent:
    return 75
  normal = sum(1 for n, _ in recent if n)
  ratio = normal / len(recent)
  return int(60 + ratio * 40)


print("HealthScoreCalculator")
test("empty metrics defaults to 75", health_score([]) == 75)
test("all normal gives 100", health_score([(True, 0), (True, 1), (True, 2)]) == 100)
test("all abnormal gives 60", health_score([(False, 0), (False, 1)]) == 60)
test("ignores old metrics", health_score([(False, 10), (True, 0)]) == 100)

# --- Medication Adherence ---
def adherence(reminder_hours: int, taken: int, days: int = 7) -> float:
  expected = reminder_hours * days
  if expected == 0:
    return 1.0
  return min(1.0, taken / expected)


print("\nMedicationAdherenceCalculator")
test("full adherence", abs(adherence(2, 14) - 1.0) < 0.001)
test("half adherence", abs(adherence(2, 7) - 0.5) < 0.001)
test("zero reminders", adherence(0, 0) == 1.0)

# --- Lab Report Parser (simplified mirror of Swift logic) ---
@dataclass
class ParsedResult:
  name: str
  value: float
  abnormal: bool


def parse_glucose(text: str) -> ParsedResult | None:
  m = re.search(r"glucose[:\s]+(\d+\.?\d*)", text, re.I)
  if not m:
    return None
  val = float(m.group(1))
  return ParsedResult("Glucose", val, val > 100 or val < 70)


def parse_hba1c(text: str) -> ParsedResult | None:
  m = re.search(r"hba1c[:\s]+(\d+\.?\d*)", text, re.I)
  if not m:
    return None
  val = float(m.group(1))
  return ParsedResult("HbA1c", val, val > 5.7)


print("\nLabReportParser")
sample = "Glucose: 142 mg/dL\nHbA1c: 6.8 %"
g = parse_glucose(sample)
a = parse_hba1c(sample)
test("parses glucose", g is not None and g.value == 142)
test("flags abnormal glucose", g is not None and g.abnormal)
test("parses hba1c", a is not None and a.value == 6.8)
test("flags abnormal a1c", a is not None and a.abnormal)
test("empty text", parse_glucose("") is None)

print(f"\n{'='*40}")
print(f"Results: {PASS} passed, {FAIL} failed")
sys.exit(1 if FAIL else 0)
