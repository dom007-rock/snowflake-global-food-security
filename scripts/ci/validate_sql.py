"""
Global Food Security & Nutrition Intelligence Platform
Phase 16 - CI/CD

Static SQL repository validator.

Purpose
-------
Perform lightweight CI checks on SQL files without requiring:
- Snowflake credentials
- a running warehouse
- database connectivity

This is not a replacement for Snowflake execution testing.
It is an early CI gate for obvious repository problems.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


# =============================================================================
# CONFIGURATION
# =============================================================================

PROJECT_ROOT = Path(__file__).resolve().parents[2]

SQL_ROOT = PROJECT_ROOT / "sql"


MERGE_CONFLICT_PATTERNS = {
    "merge conflict start": re.compile(
        r"(?m)^\s*<<<<<<<\s+.+$"
    ),
    "merge conflict separator": re.compile(
        r"(?m)^\s*=======\s*$"
    ),
    "merge conflict end": re.compile(
        r"(?m)^\s*>>>>>>>\s+.+$"
    ),
}

SENSITIVE_PATTERNS = {
    "hardcoded password": re.compile(
        r"""(?ix)
        \bpassword\s*=\s*
        ['"][^'"]+['"]
        """
    ),
    "AWS secret access key": re.compile(
        r"""(?ix)
        \bAWS_SECRET_ACCESS_KEY\b
        \s*=\s*
        ['"][^'"]+['"]
        """
    ),
    "private key literal": re.compile(
        r"""(?ix)
        \bPRIVATE_KEY\b
        \s*=\s*
        ['"][^'"]+['"]
        """
    ),
}


PLACEHOLDER_PATTERNS = {
    "unresolved YOUR_* placeholder": re.compile(
        r"\bYOUR_[A-Z0-9_]+\b"
    ),
    "unresolved REPLACE_ME placeholder": re.compile(
        r"\bREPLACE_ME\b",
        re.IGNORECASE,
    ),
}


# =============================================================================
# RESULT HELPERS
# =============================================================================

class ValidationResult:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(
        self,
        file_path: Path,
        message: str,
    ) -> None:
        relative = file_path.relative_to(PROJECT_ROOT)

        self.errors.append(
            f"{relative}: {message}"
        )

    def warning(
        self,
        file_path: Path,
        message: str,
    ) -> None:
        relative = file_path.relative_to(PROJECT_ROOT)

        self.warnings.append(
            f"{relative}: {message}"
        )


# =============================================================================
# SQL SCANNER
# =============================================================================

def balanced_parentheses(sql: str) -> bool:
    """
    Check parentheses while ignoring:

    - single quoted strings
    - double quoted identifiers
    - line comments
    - block comments
    - Snowflake $$ blocks

    This is intentionally lightweight and does not attempt
    to fully parse Snowflake SQL.
    """

    depth = 0
    i = 0
    length = len(sql)

    in_single_quote = False
    in_double_quote = False
    in_line_comment = False
    in_block_comment = False
    in_dollar_block = False

    while i < length:

        current = sql[i]

        next_char = (
            sql[i + 1]
            if i + 1 < length
            else ""
        )

        # ---------------------------------------------------------------------
        # Line comments
        # ---------------------------------------------------------------------

        if in_line_comment:

            if current == "\n":
                in_line_comment = False

            i += 1
            continue

        # ---------------------------------------------------------------------
        # Block comments
        # ---------------------------------------------------------------------

        if in_block_comment:

            if current == "*" and next_char == "/":
                in_block_comment = False
                i += 2
                continue

            i += 1
            continue

        # ---------------------------------------------------------------------
        # Snowflake $$ scripting blocks
        # ---------------------------------------------------------------------

        if in_dollar_block:

            if current == "$" and next_char == "$":
                in_dollar_block = False
                i += 2
                continue

            i += 1
            continue

        # ---------------------------------------------------------------------
        # Single quoted strings
        # ---------------------------------------------------------------------

        if in_single_quote:

            if current == "'":

                # Escaped SQL single quote: ''
                if next_char == "'":
                    i += 2
                    continue

                in_single_quote = False

            i += 1
            continue

        # ---------------------------------------------------------------------
        # Double quoted identifiers
        # ---------------------------------------------------------------------

        if in_double_quote:

            if current == '"':

                if next_char == '"':
                    i += 2
                    continue

                in_double_quote = False

            i += 1
            continue

        # ---------------------------------------------------------------------
        # Enter comment / string / scripting modes
        # ---------------------------------------------------------------------

        if current == "-" and next_char == "-":
            in_line_comment = True
            i += 2
            continue

        if current == "/" and next_char == "*":
            in_block_comment = True
            i += 2
            continue

        if current == "$" and next_char == "$":
            in_dollar_block = True
            i += 2
            continue

        if current == "'":
            in_single_quote = True
            i += 1
            continue

        if current == '"':
            in_double_quote = True
            i += 1
            continue

        # ---------------------------------------------------------------------
        # Parentheses
        # ---------------------------------------------------------------------

        if current == "(":
            depth += 1

        elif current == ")":
            depth -= 1

            if depth < 0:
                return False

        i += 1

    return depth == 0


# =============================================================================
# FILE VALIDATION
# =============================================================================

def validate_sql_file(
    file_path: Path,
    result: ValidationResult,
) -> None:

    try:
        sql = file_path.read_text(
            encoding="utf-8"
        )

    except UnicodeDecodeError:

        result.error(
            file_path,
            "file is not valid UTF-8",
        )
        return


    # -------------------------------------------------------------------------
    # Empty file
    # -------------------------------------------------------------------------

    if not sql.strip():

        result.error(
            file_path,
            "SQL file is empty",
        )
        return


    # -------------------------------------------------------------------------
    # Git merge conflicts
    # -------------------------------------------------------------------------

    for description, pattern in MERGE_CONFLICT_PATTERNS.items():

        if pattern.search(sql):

            result.error(
                file_path,
                f"contains Git {description}",
            )


    # -------------------------------------------------------------------------
    # NUL bytes
    # -------------------------------------------------------------------------

    if "\x00" in sql:

        result.error(
            file_path,
            "contains NUL bytes",
        )


    # -------------------------------------------------------------------------
    # Basic SQL terminator sanity check
    # -------------------------------------------------------------------------

    if ";" not in sql:

        result.warning(
            file_path,
            "contains no semicolon statement terminator",
        )


    # -------------------------------------------------------------------------
    # Parentheses
    # -------------------------------------------------------------------------

    if not balanced_parentheses(sql):

        result.error(
            file_path,
            "unbalanced parentheses detected",
        )


    # -------------------------------------------------------------------------
    # Sensitive values
    # -------------------------------------------------------------------------

    for description, pattern in SENSITIVE_PATTERNS.items():

        if pattern.search(sql):

            result.error(
                file_path,
                f"possible {description}",
            )


    # -------------------------------------------------------------------------
    # Unresolved placeholders
    # -------------------------------------------------------------------------

    for description, pattern in PLACEHOLDER_PATTERNS.items():

        if pattern.search(sql):

            result.error(
                file_path,
                description,
            )


    # -------------------------------------------------------------------------
    # Privileged-role usage
    #
    # ACCOUNTADMIN is not automatically invalid because platform-bootstrap
    # scripts may legitimately require it.
    # -------------------------------------------------------------------------

    if re.search(
        r"\bACCOUNTADMIN\b",
        sql,
        re.IGNORECASE,
    ):

        result.warning(
            file_path,
            "references ACCOUNTADMIN; verify elevated privileges are intentional",
        )


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:

    print("=" * 78)
    print("GFS SQL STATIC VALIDATION")
    print("=" * 78)

    if not SQL_ROOT.exists():

        print(
            f"ERROR: SQL directory does not exist: {SQL_ROOT}"
        )

        return 1


    sql_files = sorted(
        SQL_ROOT.rglob("*.sql")
    )


    if not sql_files:

        print(
            f"ERROR: no SQL files found under {SQL_ROOT}"
        )

        return 1


    result = ValidationResult()


    print(
        f"Scanning {len(sql_files)} SQL files..."
    )


    for file_path in sql_files:

        validate_sql_file(
            file_path,
            result,
        )


    # =========================================================================
    # WARNINGS
    # =========================================================================

    if result.warnings:

        print("\nWARNINGS")
        print("-" * 78)

        for warning in result.warnings:
            print(f"[WARN] {warning}")


    # =========================================================================
    # ERRORS
    # =========================================================================

    if result.errors:

        print("\nERRORS")
        print("-" * 78)

        for error in result.errors:
            print(f"[FAIL] {error}")


        print("\n" + "=" * 78)

        print(
            f"FAILED: "
            f"{len(result.errors)} error(s), "
            f"{len(result.warnings)} warning(s)"
        )

        print("=" * 78)

        return 1


    # =========================================================================
    # SUCCESS
    # =========================================================================

    print("\n" + "=" * 78)

    print(
        f"PASSED: "
        f"{len(sql_files)} SQL files validated, "
        f"{len(result.warnings)} warning(s)"
    )

    print("=" * 78)

    return 0


if __name__ == "__main__":
    sys.exit(main())