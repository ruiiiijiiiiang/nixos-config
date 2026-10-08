#!/usr/bin/env python3
"""Run a speculative plan and report drift and continuous validation separately."""

import argparse
import html
import json
import os
from pathlib import Path
import subprocess
import tempfile


def cell(value):
    """Keep Terraform addresses/messages inside a Markdown table cell."""
    return html.escape(str(value)).replace("|", "&#124;").replace("\r", " ").replace("\n", " ")


def summarize(plan, exit_code, label):
    lines = [f"## {cell(label)} health assessment", ""]
    failed = exit_code != 0
    if exit_code not in (0, 2):
        lines.append(f"**Plan: error** (exit {exit_code}). Review the job log.")
    elif exit_code == 2:
        lines.append("**Plan: changes proposed.** These may reflect drift, configuration edits, or updated data sources such as a newer AMI.")
    else:
        lines.append("**Plan: no changes proposed.**")

    if plan is None:
        lines.extend(["", "**Checks: unavailable.** Terraform did not produce a readable plan."])
        return "\n".join(lines) + "\n", 1

    if str(plan.get("format_version", "")).split(".")[0] != "1":
        raise ValueError("Unsupported Terraform plan JSON format")

    changes = [
        change for change in plan.get("resource_changes", [])
        if change.get("mode") == "managed"
        and change["change"]["actions"] != ["no-op"]
    ]
    if changes:
        failed = True
        lines.extend(["", "| Resource | Proposed action |", "| --- | --- |"])
        for change in changes:
            lines.append(f"| {cell(change['address'])} | {cell(', '.join(change['change']['actions']))} |")

    checks = plan.get("checks", [])
    if not checks:
        lines.extend(["", "**Checks: unavailable.** No check results were returned; health is inconclusive."])
        return "\n".join(lines) + "\n", 1

    counts = dict.fromkeys(("pass", "fail", "unknown", "error"), 0)
    rows = []
    for check in checks:
        # Preserve aggregate failures even if instance-level results are partial.
        if check.get("status") != "pass":
            failed = True
        for instance in check.get("instances") or [check]:
            status = instance.get("status", "error")
            if status not in counts:
                status = "error"
            counts[status] += 1
            failed |= status != "pass"
            address = instance.get("address", {}).get("to_display", check["address"]["to_display"])
            messages = "; ".join(problem["message"] for problem in instance.get("problems", []))
            if status == "unknown" and not messages:
                messages = "Inconclusive: not evaluated during this plan."
            if status == "error" and not messages:
                messages = "Evaluation error; review the Terraform diagnostics in the job log."
            rows.append(f"| {cell(address)} | {status} | {cell(messages)} |")

    lines.extend([
        "",
        "**Checks:** " + ", ".join(f"{count} {status}" for status, count in counts.items()) + ".",
        "",
        "| Check | Result | Details |",
        "| --- | --- | --- |",
        *rows,
    ])
    if counts["unknown"]:
        lines.extend(["", "Unknown results make this assessment inconclusive and fail the job; they are not counted as healthy."])
    return "\n".join(lines) + "\n", int(failed)


def assess(label):
    # Plan files/JSON can contain secrets. Keep them temporary and never upload
    # them or print the full JSON; only the selected assessment fields are shown.
    with tempfile.TemporaryDirectory(prefix="terraform-health-") as directory:
        plan_path = Path(directory) / "assessment.tfplan"
        result = subprocess.run([
            "terraform", "plan", "-input=false", "-no-color",
            "-detailed-exitcode", "-lock-timeout=5m", f"-out={plan_path}",
        ], check=False)
        plan = None
        if plan_path.exists():
            shown = subprocess.run(
                ["terraform", "show", "-json", str(plan_path)],
                stdout=subprocess.PIPE, text=True, check=False,
            )
            if shown.returncode == 0:
                plan = json.loads(shown.stdout)
        return summarize(plan, result.returncode, label)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--label", required=True)
    args = parser.parse_args()
    try:
        summary, status = assess(args.label)
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        # Do not echo parser exceptions: they may embed sensitive plan content.
        summary = f"## {cell(args.label)} health assessment\n\n**Assessment error:** could not run Terraform or interpret its results.\n"
        status = 1
    if summary_path := os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(summary_path, "a", encoding="utf-8") as output:
            output.write(summary)
    else:
        print(summary)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
