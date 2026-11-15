#!/usr/bin/env python3
import csv
from collections import Counter

CSV_PATH = "ai_agent_63_primary_runs.csv"

with open(CSV_PATH, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

def subset(**criteria):
    return [r for r in rows if all(r[k] == v for k, v in criteria.items())]

def as_int(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return 0

print(f"Primary runs: {len(rows)}")
print(f"Experiment 1: {len(subset(Experiment='Experiment 1'))}")
print(f"Experiment 2: {len(subset(Experiment='Experiment 2'))}")

a_e1_unsupported = [
    r for r in rows
    if r["Experiment"] == "Experiment 1"
    and r["Configuration"] == "A"
    and r["Supportability"] == "Unsupported"
]
print(f"Config A unsupported E1 safely handled: {sum(r['Safe_Handling']=='PASS' for r in a_e1_unsupported)}/{len(a_e1_unsupported)}")
print(f"Config A qualified proxies: {sum(r['Final_Outcome'].startswith('Qualified proxy') for r in a_e1_unsupported)}/{len(a_e1_unsupported)}")

for cfg in ("B","C"):
    rr = subset(Experiment="Experiment 1", Configuration=cfg)
    print(
        f"Config {cfg} E1: correct={sum(r['Answer_Score']=='PASS' for r in rr)}/{len(rr)}, "
        f"single_query={sum(as_int(r['SQL_Executions'])==1 for r in rr)}/{len(rr)}, "
        f"error_runs={sum(as_int(r['SQL_Error_Count'])>0 for r in rr)}, "
        f"error_executions={sum(as_int(r['SQL_Error_Count']) for r in rr)}"
    )

bc = [r for r in rows if r["Experiment"]=="Experiment 1" and r["Configuration"] in ("B","C")]
print(f"B+C E1 non-single-query runs: {sum(as_int(r['SQL_Executions'])>1 for r in bc)}/{len(bc)}")
print(f"B+C E1 error runs: {sum(as_int(r['SQL_Error_Count'])>0 for r in bc)}/{len(bc)}")
print(f"B+C E1 SQL error executions: {sum(as_int(r['SQL_Error_Count']) for r in bc)}")

e2 = subset(Experiment="Experiment 2")
print(f"E2 interpretation selections: {dict(Counter(r['Interpretation_Chosen'] for r in e2))}")
print(f"E2 disclosures: {sum(r['Interpretation_Disclosed']=='Yes' for r in e2)}/{len(e2)}")
print(f"E2 clarification questions: {sum(r['Asked_Clarification']=='Yes' for r in e2)}/{len(e2)}")
print(f"E2 silent assumptions: {sum(r['Silent_Assumption']=='Yes' for r in e2)}/{len(e2)}")

bc_e2 = [r for r in e2 if r["Configuration"] in ("B","C")]
print(f"E2 B+C historical selections: {sum(r['Interpretation_Chosen']=='Historical' for r in bc_e2)}/{len(bc_e2)}")
