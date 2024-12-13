# Makefile for building uring_test using liburing

# 컴파일러 설정
CXX = g++
CXXFLAGS = -Wall -O2 -std=c++17 -g
INCLUDES = -I/usr/local/include

# liburing 라이브러리 설정
LDFLAGS = -L/usr/local/lib
LDLIBS = -luring

# 소스 파일과 타겟 파일 설정
#SRCS = fdpnvme.cpp util.cpp uring_cmd.cpp io_test.cpp
#HEADERS = fdpnvme.h util.h uring_cmd.h flexfs.h io_test.h
#OBJS = $(SRCS:.cpp=.o)
#TARGET = io_test
SRCS = uring_test.cpp fdpnvme.cpp util.cpp uring_cmd.cpp
HEADERS = uring_test.h fdpnvme.h util.h uring_cmd.h flexfs.h
OBJS = $(SRCS:.cpp=.o)
TARGET = uring_test

# 빌드 규칙
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -g -O0 -o $(TARGET) $(LDFLAGS) $(LDLIBS)

%.o: %.cpp $(HEADERS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# 클린 규칙
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean install

