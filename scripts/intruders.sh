grep '@liferay-database-infra' .github/CODEOWNERS | awk '{print $1}' | while read -r folder; do
    commits=$(git log $1..HEAD --pretty=format:'%h %ae %s' -- "$folder" | grep -v -E 'brian.chan@liferay.com|istvan.dezsi@liferay.com|jorge.avalos@liferay.com|jorge.diaz@liferay.com|luis.ortiz@liferay.com|mariano.alvaro@liferay.com')
    if [ -n "$commits" ]; then
        echo "#### Intruders in $folder"
        echo "$commits"
        echo ""
    fi
done
