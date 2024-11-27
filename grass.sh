#!/bin/bash

# 초기 설정
START_DATE="2024-11-25"
END_DATE=$(date +"%Y-%m-%d")

# coreutils 설치 (필요한 경우)
if ! command -v gshuf &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "coreutils 패키지를 설치합니다..."
        brew install coreutils
        if [ $? -ne 0 ]; then
            echo "coreutils 설치에 실패했습니다."
            exit 1
        fi
    else
        echo "gshuf 명령어를 찾을 수 없습니다. coreutils 패키지를 수동으로 설치하세요."
        exit 1
    fi
fi

# 필수 변수 유효성 체크
if [ -z "$START_DATE" ]; then
    echo "필수 환경 변수가 설정되지 않았습니다. config.env 파일을 확인하세요."
    exit 1
fi

# 1. 현재 디렉토리에 Git 리포지토리가 있는지 확인
if [ ! -d .git ]; then
    echo "현재 디렉토리에 Git 리포지토리가 없습니다."
    exit 1
fi

# 커밋할 파일 배열 정의
FILES=("commit_history.txt")

# 커밋 메시지 및 내용 패턴 정의
COMMIT_PATTERNS=(
    "feature|Add new feature implementation in main.py"
    "feature|Refactor utility functions in utils.py"
    "bugfix|Fix bug related to edge case in main.py"
    "performance|Improve algorithm efficiency in utils.py"
    "test|Add unit tests for main.py"
    "docs|Update project documentation in README.md"
    "chore|Update dependencies in requirements.txt"
    "chore|Organize notes and TODOs in notes.txt"
)

# 2. 매일 커밋 생성 루프
generate_commits_for_day() {
    local current_date="$1"
    local day_of_week=$(date -j -f "%Y-%m-%d" "$current_date" +%u)
    if [ $? -ne 0 ]; then
        echo "날짜 변환에 실패했습니다: $current_date"
        exit 1
    fi
    local commit_count
    local patterns

    if [[ "$day_of_week" -gt 5 ]]; then
        commit_count=$((RANDOM % 3 + 3))  # 3~5개
        patterns=("docs" "chore")
    else
        commit_count=$((RANDOM % 3 + 2))  # 2~4개
        patterns=("feature" "bugfix" "performance" "test")
    fi

    for ((i = 1; i <= commit_count; i++)); do
        generate_commit "$current_date" "${patterns[@]}"
    done
}

generate_commit() {
    local current_date="$1"
    shift
    local patterns=("$@")
    local random_pattern=${patterns[$RANDOM % ${#patterns[@]}]}
    local selected_commit=$(printf "%s\n" "${COMMIT_PATTERNS[@]}" | grep "^$random_pattern" | gshuf -n 1)
    if [ $? -ne 0 ]; then
        echo "커밋 패턴 선택에 실패했습니다."
        exit 1
    fi
    local commit_message=$(echo $selected_commit | cut -d'|' -f2)
    local random_file=${FILES[$RANDOM % ${#FILES[@]}]}
    local random_hour=$((RANDOM % 23))
    local random_minute=$((RANDOM % 59))
    local random_second=$((RANDOM % 59))
    local commit_time="$current_date $random_hour:$random_minute:$random_second"

    echo "[$current_date] $commit_message" >> $random_file
    git add $random_file
    GIT_AUTHOR_DATE="$commit_time" GIT_COMMITTER_DATE="$commit_time" git commit -m "$commit_message"
    if [ $? -ne 0 ]; then
        echo "커밋 생성에 실패했습니다."
        exit 1
    fi
}

current_date="$START_DATE"
while [[ "$current_date" < "$END_DATE" ]]; do
    generate_commits_for_day "$current_date"
    current_date=$(date -j -v+1d -f "%Y-%m-%d" "$current_date" +"%Y-%m-%d")
    if [ $? -ne 0 ]; then
        echo "다음 날짜 계산에 실패했습니다: $current_date"
        exit 1
    fi
done

# 3. 원격 리포지토리 설정 및 푸시
if git remote | grep origin; then
    echo "원격 리포지토리가 이미 설정되어 있습니다."
else
    echo "원격 리포지토리가 설정되어 있지 않습니다. 원격 리포지토리를 수동으로 추가하세요."
    exit 1
fi

git push -u origin main
if [ $? -ne 0 ]; then
    echo "원격 리포지토리에 푸시하는 데 실패했습니다."
    exit 1
fi