import os
import re
from tabulate import tabulate


def parse_log_files(base_dir):
    # 중복 확인을 위한 세트 (Written Data Units, Physical 값만 저장)
    seen = set()

    # 최종 결과를 저장할 리스트
    result = []

    # 하위 폴더까지 포함한 모든 LOG 파일 경로 수집
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file == "LOG":
                log_path = os.path.join(root, file)

                # fillseq 무시
                if "fillseq" in log_path:
                    continue
                    # if "4" not in log_path:
                    # continue
                # 파일 열기
                with open(log_path, 'r') as f:
                    for line in f:
                        # Bytes가 포함된 라인만 처리
                        if "Bytes" in line:
                            # 정규식을 사용하여 숫자를 추출 (Written Data Units와 Physical 뒤의 숫자)
                            match = re.search(
                                r"Written Data Units (\d+) Physical (\d+)", line)
                            if match:
                                # 숫자 값 추출
                                written_data_unit = int(match.group(1))
                                physical = int(match.group(2))

                                # 중복 체크
                                if (written_data_unit, physical) not in seen:
                                    # 중복이 아닌 경우 결과에 추가하고, seen에 기록
                                    relative_path = os.path.relpath(
                                        log_path, base_dir)
                                    result.append(
                                        (relative_path, written_data_unit, physical))
                                    seen.add((written_data_unit, physical))

    # 중복 제거된 결과를 Written Data Units 값 기준으로 오름차순 정렬
    sorted_result = sorted(result, key=lambda x: x[1])

    # Written Data Units 및 Physical의 최소값 계산
    min_written_data_unit = sorted_result[0][1]
    min_physical = sorted_result[0][2]

    # 최종 결과 저장 리스트
    final_result = []

    # 각 항목에서 1) Written Data Unit, 2) Physical 차이값 및 3) 계산 결과를 저장
    for i, (relative_path, written_data_unit, physical) in enumerate(sorted_result):
        # 1) 현재 Written Data Unit에서 최소 Written Data Unit을 뺀 값
        written_data_diff = written_data_unit - min_written_data_unit

        # 2) 현재 Physical에서 최소 Physical을 뺀 값
        physical_diff = physical - min_physical

        # 3) Physical 차이값을 Written Data Unit 차이값으로 나눈 값
        if written_data_diff != 0:  # 나누기 0 방지
            ratio = physical_diff / written_data_diff
        else:
            ratio = 0  # 혹은 다른 처리 (예: None, -1 등)

        # 이전 Written Data Unit과 Physical 값과의 차이 계산 (i > 0일 때만)
        if i > 0:
            prev_written_data_unit = sorted_result[i - 1][1]
            prev_physical = sorted_result[i - 1][2]

            # 1) 현재 Written Data Unit에서 이전 Written Data Unit을 뺀 값
            written_data_diff_prev = written_data_unit - prev_written_data_unit

            # 2) 현재 Physical에서 이전 Physical을 뺀 값
            physical_diff_prev = physical - prev_physical

            # 3) Physical 차이값을 Written Data Unit 차이값으로 나눈 값
            if written_data_diff_prev != 0:
                previous_ratio = physical_diff_prev / written_data_diff_prev
            else:
                previous_ratio = 0
        else:
            # 첫 번째 항목은 이전 값이 없으므로 0 처리
            written_data_diff_prev = 0
            physical_diff_prev = 0
            previous_ratio = 0

        # 결과 저장 (파일 경로, 원래 값, 계산된 값들)
        final_result.append((
            relative_path, written_data_unit, physical,  # 원래 값
            written_data_diff, physical_diff, ratio,  # 최소값과 비교한 계산 결과
            written_data_diff_prev, physical_diff_prev, previous_ratio  # 이전 값과 비교한 계산 결과
        ))

    # 최종 결과 반환
    return final_result


# 현재 작업 디렉토리로 설정
base_dir = os.getcwd()
parsed_data = parse_log_files(base_dir)

# 테이블 형식으로 출력할 데이터 구성
table_headers = ["File", "Host Written", "Physical",
                 "Host Diff (min)", "Phy. Diff (min)", "WAF (min)",
                 "Host Diff (prev)", "Phy. Diff (prev)", "WAF (prev)"]

# tabulate를 사용하여 결과를 테이블 형식으로 출력
print(tabulate(parsed_data, headers=table_headers, tablefmt="plain"))
