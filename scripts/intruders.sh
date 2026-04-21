#!/bin/bash

BASE="$1"

if [ -z "$BASE" ]; then
    echo "Usage: $0 <base-ref>" >&2
    exit 1
fi

TEAM_EMAILS='brian.chan@liferay.com|istvan.dezsi@liferay.com|jorge.avalos@liferay.com|jorge.diaz@liferay.com|luis.ortiz@liferay.com|mariano.alvaro@liferay.com'

COMPANY_THREAD_LOCAL_PATTERNS=(
    'set'
    'lock'
    'forEach'
)

grep '@liferay-database-infra' .github/CODEOWNERS | awk '{print $1}' | while read -r folder; do
    commits=$(git log "$BASE..HEAD" --pretty=format:'%h %ae %s' -- "$folder" | grep -v -E "$TEAM_EMAILS")
    if [ -n "$commits" ]; then
        echo "#### Intruders in $folder"
        echo "$commits"
        echo ""
    fi
done

scan_diff() {
    local method="$1"
    local mode="$2"
    git log "$BASE..HEAD" -p --pretty='format:@@COMMIT@@ %h %ae %s' \
        | LC_ALL=C awk -v method="$method" -v mode="$mode" '
            BEGIN {
                if (mode == "add") { hre="^\\+\\+\\+ "; bre="^\\+" }
                else               { hre="^--- ";       bre="^-"   }
            }
            /^@@COMMIT@@ / { header=substr($0, 12); shown=0; skip=0; pending=0; next }
            $0 ~ hre {
                file=$2
                sub(/^[ab]\//, "", file)
                skip=(tolower(file) ~ /test/)
                pending=0
                next
            }
            $0 ~ bre {
                if (skip || shown) { pending=0; next }
                line=substr($0, 2)
                inline="CompanyThreadLocal[.][[:space:]]*" method
                if (line ~ inline) { print header; shown=1; next }
                if (pending && line ~ ("^[[:space:]]*" method)) { print header; shown=1; next }
                pending=(line ~ /CompanyThreadLocal[.][[:space:]]*$/)
                next
            }
            { pending=0 }
        '
}

for pattern in "${COMPANY_THREAD_LOCAL_PATTERNS[@]}"; do
    added=$(scan_diff "$pattern" add | grep -v -E "$TEAM_EMAILS")
    removed=$(scan_diff "$pattern" del | grep -v -E "$TEAM_EMAILS")
    if [ -n "$added" ]; then
        echo "#### Added 'CompanyThreadLocal.$pattern'"
        echo "$added"
        echo ""
    fi
    if [ -n "$removed" ]; then
        echo "#### Removed 'CompanyThreadLocal.$pattern'"
        echo "$removed"
        echo ""
    fi
done
