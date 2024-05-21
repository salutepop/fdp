# Makefile for building uring_test using liburing

# 컴파일러 설정
CXX = g++
CXXFLAGS = -Wall -O2 -std=c++17 -g
INCLUDES = -I/usr/local/include

# liburing 라이브러리 설정
LDFLAGS = -L/usr/local/lib
LDLIBS = -luring

# 소스 파일과 타겟 파일 설정
SRCS = uring_test.cpp fdpnvme.cpp
HEADERS = uring_test.h fdpnvme.h util.h
OBJS = $(SRCS:.cpp=.o)
TARGET = uring_test

# 빌드 규칙
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -o $(TARGET) $(LDFLAGS) $(LDLIBS)

%.o: %.cpp $(HEADERS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# 클린 규칙
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean install

