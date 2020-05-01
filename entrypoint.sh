#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

npm install ${INPUT_NPM_INSTALL_ARGS}
node_modules/.bin/eslint --version

result_file=$(mktemp)

if [ "${INPUT_REPORTER}" == 'github-pr-review' ]; then
  # Use jq and github-pr-review reporter to format result to include link to rule page.
  (node_modules/.bin/eslint -f="json" ${INPUT_ESLINT_FLAGS:-'.'}; echo $? > $result_file) \
    | jq -r '.[] | {filePath: .filePath, messages: .messages[]} | "\(.filePath):\(.messages.line):\(.messages.column):\(.messages.message) [\(.messages.ruleId)](https://eslint.org/docs/rules/\(.messages.ruleId))"' \
    | reviewdog -efm="%f:%l:%c:%m" -name="eslint" -reporter=github-pr-review -level="${INPUT_LEVEL}"
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  (node_modules/.bin/eslint -f="stylish" ${INPUT_ESLINT_FLAGS:-'.'}; echo $? > $result_file) \
    | reviewdog -f="eslint" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}"
fi

exit $(cat $result_file)
