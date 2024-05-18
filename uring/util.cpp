#include <string>
#include <iostream>
#include <stdexcept>
#include <cstdint> // for uint16_t, uint32_t
 
uint64_t strToU64(const std::string& str) {
    try {
        unsigned long long ull = std::stoull(str);
        if (ull > std::numeric_limits<uint64_t>::max()) {
            throw std::out_of_range("Value out of range for uint64_t");
        }
        return static_cast<uint64_t>(ull);
    } catch (const std::invalid_argument& e) {
        std::cerr << "Invalid argument: " << e.what() << '\n';
        throw;
    } catch (const std::out_of_range& e) {
        std::cerr << "Out of range: " << e.what() << '\n';
        throw;
    }
}

uint16_t strToU16(const std::string& str) {
    try {
        unsigned long ul = std::stoul(str);
        if (ul > std::numeric_limits<uint16_t>::max()) {
            throw std::out_of_range("Value out of range for uint16_t");
        }
        return static_cast<uint16_t>(ul);
    } catch (const std::invalid_argument& e) {
        std::cerr << "Invalid argument: " << e.what() << '\n';
        throw;
    } catch (const std::out_of_range& e) {
        std::cerr << "Out of range: " << e.what() << '\n';
        throw;
    }
}

uint32_t strToU32(const std::string& str) {
    try {
        unsigned long ul = std::stoul(str);
        if (ul > std::numeric_limits<uint32_t>::max()) {
            throw std::out_of_range("Value out of range for uint32_t");
        }
        return static_cast<uint32_t>(ul);
    } catch (const std::invalid_argument& e) {
        std::cerr << "Invalid argument: " << e.what() << '\n';
        throw;
    } catch (const std::out_of_range& e) {
        std::cerr << "Out of range: " << e.what() << '\n';
        throw;
    }
}

int32_t strToI32(const std::string& str) {
    try {
        long val = std::stol(str);
        if (val < std::numeric_limits<int32_t>::min() || val > std::numeric_limits<int32_t>::max()) {
            throw std::out_of_range("Value out of range for int32_t");
        }
        return static_cast<int32_t>(val);
    } catch (const std::invalid_argument& e) {
        std::cerr << "Invalid argument: " << e.what() << '\n';
        throw;
    } catch (const std::out_of_range& e) {
        std::cerr << "Out of range: " << e.what() << '\n';
        throw;
    }
}

bool readFile(int fd, std::string& out, size_t num_bytes) {

  size_t soFar = 0; // amount of bytes successfully read

  // Obtain file size:
  struct stat buf;
  if (fstat(fd, &buf) == -1) {
    return false;
  }
  // Some files (notably under /proc and /sys on Linux) lie about
  // their size, so treat the size advertised by fstat under advise
  // but don't rely on it. In particular, if the size is zero, we
  // should attempt to read stuff. If not zero, we'll attempt to read
  // one extra byte.
  constexpr size_t initialAlloc = 1024 * 4;
  out.resize(std::min(
      buf.st_size > 0 ? (size_t(buf.st_size) + 1) : initialAlloc, num_bytes));

  while (soFar < out.size()) {
    const auto actual = readFull(fd, &out[soFar], out.size() - soFar);
    if (actual == -1) {
      return false;
    }
    soFar += actual;
    if (soFar < out.size()) {
      // File exhausted
      break;
    }
    // Ew, allocate more memory. Use exponential growth to avoid
    // quadratic behavior. Cap size to num_bytes.
    out.resize(std::min(out.size() * 3 / 2, num_bytes));
  }

  return true;
}

bool readFile(const char* file_name, std::string& out,
    size_t num_bytes) {

  const auto fd = openNoInt(file_name, O_RDONLY | O_CLOEXEC);
  if (fd == -1) {
    return false;
  }

  return readFile(fd, out, num_bytes);
}

void *smalloc(size_t size)
{
	unsigned int i, end_pool;

	if (size != (unsigned int) size)
		return NULL;

	i = last_pool;
	end_pool = nr_pools;

	do {
		for (; i < end_pool; i++) {
			void *ptr = smalloc_pool(&mp[i], size);

			if (ptr) {
				last_pool = i;
				return ptr;
			}
		}
		if (last_pool) {
			end_pool = last_pool;
			last_pool = i = 0;
			continue;
		}

		break;
	} while (1);

	log_err("smalloc: OOM. Consider using --alloc-size to increase the "
		"shared memory available.\n");
	smalloc_debug(size);
	return NULL;
}

void *scalloc(size_t nmemb, size_t size)
{
	return smalloc(nmemb * size);
}
