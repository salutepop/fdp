import re
import pandas as pd

# 입력 텍스트 파일 경로
input_file = "input.txt"

# RUN-END 단위를 파싱하는 함수


def parse_run_end_blocks(file_content):
    blocks = re.findall(
        r"(\[RUN-[A-Z]+.*?\[END-[A-Z]+.*?\])", file_content, re.DOTALL)
    return blocks

# 숫자 데이터를 추출하는 함수


def extract_numeric_info(block):
    result = {}

    # 구분자 (Type) 추출
    type_match = re.search(r"\[RUN-([A-Z]+)\]", block)
    if type_match:
        result["Type"] = type_match.group(1)

    # 기본 정보 추출 (명령어, 스레드 등)
    header_match = re.search(
        r"\[RUN-[A-Z]+\] \[TIME (.*?)\] .*? (\w+) (\w+)", block)
    if header_match:
        result["Command"] = header_match.group(2)
        result["Thread"] = header_match.group(3)

    # 주요 수치 정보 추출
    ops_match = re.search(r"(\d+) operations;.*?(\d+\.\d+) MB/s", block)
    if ops_match:
        result["Operations"] = int(ops_match.group(1))
        result["Throughput (MB/s)"] = float(ops_match.group(2))

    # ops/sec 추출
    ops_sec_match = re.search(r"(\d+(?:\.\d+)?) ops/sec", block)
    if ops_sec_match:
        result["Ops/sec"] = float(ops_sec_match.group(1))

    # Percentiles 추출
    percentiles_match = re.findall(r"P(\d+): ([\d\.]+)", block)
    if percentiles_match:
        for p, val in percentiles_match:
            result[f"P{p}"] = float(val)

    return result


# 텍스트 파일 읽기
with open(input_file, "r") as file:
    content = file.read()

# RUN-END 블록 파싱
blocks = parse_run_end_blocks(content)

# 각 블록에서 숫자 정보 추출
parsed_data = [extract_numeric_info(block) for block in blocks]

# DataFrame 생성
df = pd.DataFrame(parsed_data)

# 그룹화된 데이터 처리
grouped_data = df.groupby(["Command", "Thread", "Type"], group_keys=False).apply(
    lambda x: x.mean(numeric_only=True)
).reset_index()

# 결과 출력
print(grouped_data.to_string(index=False))
