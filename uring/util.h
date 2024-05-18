#include <string>
#include <iostream>
#include <stdexcept>
#include <limits>
#include <cstdint> // for uint16_t, uint32_t

uint16_t strToU16(const std::string& str);
uint32_t strToU32(const std::string& str);
uint64_t strToU64(const std::string& str);

int32_t strToI32(const std::string& str);

/**
 * Swaps the file descriptors and ownership
 */
bool readFile(int fd, std::string& out,
    size_t num_bytes = std::numeric_limits<size_t>::max());

bool readFile(const char* file_name, std::string& out,
    size_t num_bytes = std::numeric_limits<size_t>::max());

template <typename T>
constexpr T constexpr_log2_(T a, T e) {
  return e == T(1) ? a : constexpr_log2_(a + T(1), e / T(2));
}

template <typename T>
constexpr T constexpr_log2_ceil_(T l2, T t) {
  return l2 + T(T(1) << l2 < t ? 1 : 0);
}


template <typename T>
constexpr T constexpr_log2(T t) {
  return constexpr_log2_(T(0), t);
}

template <typename T>
constexpr T constexpr_log2_ceil(T t) {
  return constexpr_log2_ceil_(constexpr_log2(t), t);
}

extern void *smalloc(size_t);
extern void *scalloc(size_t, size_t);
