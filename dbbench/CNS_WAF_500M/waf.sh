#!/bin/bash
input_file="LOG"  # 여기에 실제 파일 경로를 넣으세요

# 중복된 Data Units와 Physical 값을 저장하기 위한 배열
declare -A units_seen
declare -A physical_seen
declare -A valid_pairs

for log_file in $(ls "$base_dir"*/LOG | sort); do
#for log_file in $(ls "$base_dir"LOG | sort); do
    echo "Processing: $log_file"  # 현재 처리 중인 파일 출력
# DEBUG가 포함된 줄에서 nits가 포함된 내용을 찾고 처리
grep "DEBUG" "$log_file" | grep "Bytes" | while read -r line; do
    while [[ $line =~ Data\ Units\ ([0-9]+) ]]; do
        units=${BASH_REMATCH[1]}  # Data Units 숫자 추출
        line=${line#*"Data Units $units"}  # 이미 추출한 부분 제거
        
        # Physical 찾기
        if [[ $line =~ Physical\ ([0-9]+) ]]; then
            physical=${BASH_REMATCH[1]}  # Physical 숫자 추출
            
            # Data Units와 Physical이 각각 중복된 적이 있는지 확인
            if [[ -z "${units_seen[$units]}" && -z "${physical_seen[$physical]}" ]]; then
                # 중복이 없다면 배열에 추가
                units_seen[$units]=1
                physical_seen[$physical]=1
                valid_pairs["$units,$physical"]=1
                echo $units $physical
            fi
        fi
    done
done

# 결과 출력
for key in "${!valid_pairs[@]}"; do
    IFS=',' read -r units physical <<< "$key"
    echo "Data Units: $units, Physical: $physical"
done

done
