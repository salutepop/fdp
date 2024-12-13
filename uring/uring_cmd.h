#pragma once

#include <liburing.h>
#include <linux/fs.h>
#include <linux/nvme_ioctl.h>
#include <sys/ioctl.h>

#include <mutex>
#include <unordered_map>

#include "util.h"

#define BS (4 * 1024)
#define PAGE_SIZE 4096
#define MAX_TRF_SIZE (BS * 64)  // 256KB

#define op_read true
#define op_write false

enum nvme_io_opcode {
  nvme_cmd_write = 0x01,
  nvme_cmd_read = 0x02,
  nvme_cmd_io_mgmt_recv = 0x12,
  nvme_cmd_io_mgmt_send = 0x1d,
};

class UringCmd {
 private:
  uint32_t qd_;
  uint32_t blocksize_;
  uint32_t lbashift_;

  uint32_t req_limitmax_;
  uint32_t req_limitlow_;
  uint32_t req_inflight_;

  io_uring_params params_;
  struct io_uring ring_;
  struct iovec *iovecs_;

  std::mutex mutex_;

  void *readbuf_;
  size_t max_trf_size_;
  std::unordered_map<uint64_t, int> requestedMap;

  void initBuffer();
  void initUring(io_uring_params &params);
  void prepUringCmd(int fd, int ns, bool is_read, off_t offset, size_t size,
                    void *buf, uint64_t userData = 0, uint32_t dtype = 0,
                    uint32_t dspec = 0);
  void prepUring(int fd, bool is_read, off_t offset, size_t size, void *buf);

 public:
  UringCmd() {};
  UringCmd(uint32_t qd, uint32_t blocksize, uint32_t lbashift,
           io_uring_params params);
  ~UringCmd() {
    // LOG("URING_CMD Destruction : Ring", &ring_);
    io_uring_queue_exit(&ring_);

    free(readbuf_);
    /*
//  iovecs_ 메모리 해제
if (iovecs_) {
  for (int i = 0; i < roundup_pow2(qd_); i++) {
    if (iovecs_[i].iov_base) {
      free(iovecs_[i].iov_base);
    }
  }
  free(iovecs_);
}
    */
    // LOG("Uring Destruction : Threads", std::this_thread::get_id());
  }
  int submitCommand(int nr_reqs = 0);
  int waitCompleted(int nr_reqs = 0);

  int uringRead(int fd, off_t offset, size_t size, void *buf);
  int uringWrite(int fd, off_t offset, size_t size, void *buf);
  int uringCmdRead(int fd, int ns, off_t offset, size_t size, void *buf);
  int uringCmdWrite(int fd, int ns, off_t offset, size_t size, void *buf,
                    uint32_t dspec);
  int uringFsync(int fd, int ns);
  int waitTargetCompleted(uint64_t user_data);
  int uringRequestPrefetch(int fd, int ns, off_t offset, size_t size, void *buf,
                           uint64_t userdata);
  int uringWaitPrefetch(uint64_t userdata);

  // Add a request to the map
  void addRequest(uint64_t userdata, int requested) {
    requestedMap[userdata] = requested;  // Store the value directly
  }

  // Decrement the value associated with the given key
  void decrementRequest(uint64_t userdata) {
    auto it = requestedMap.find(userdata);
    if (it != requestedMap.end()) {
      --(it->second);  // Decrement the value
    } else {
      std::cout << "Cant't find requested Map, userdata " << userdata
                << std::endl;
    }
  }

  // Delete an entry by key
  int deleteRequest(uint64_t userdata) {
    auto it = requestedMap.find(userdata);
    if (it != requestedMap.end()) {
      if (it->second != 0) {
        std::cout << "Error, mismatch completions, userdata : " << userdata
                  << " remain requested : " << it->second << std::endl;
      }
      requestedMap.erase(it);  // Remove the key-value pair
      return 0;                // Indicate successful deletion
    }
    return -EINVAL;  // Key not found
  }

  // Get a reference to the value for a key
  bool getNrRequested(uint64_t userdata, int *&requested) {
    auto it = requestedMap.find(userdata);
    if (it != requestedMap.end()) {
      requested = &(it->second);  // Return the address of the value
      return true;
    }
    requested = nullptr;
    return false;
  }

  // INFO:
  // fd : block fd (@fdp->bfd)
  // start, len : bytes
  // ex) uint64_t _offset = 0x20000;
  // ex) uint64_t _len = 0x1000 * 64;
  // ex) uring_cmd->uringDiscard(fdp->bfd(), _offset, _len);
  static inline int uringDiscard(int fd, uint64_t start, uint64_t len) {
    uint64_t range[2];
    uint64_t max_discard_byte = 3221225472;  // 3GB
    uint64_t discarded = 0;

    // 3GB 씩 나눠서 discard
    while (discarded < len) {
      uint64_t len_ = len - discarded;
      if (len_ > max_discard_byte) len_ = max_discard_byte;

      range[0] = start + discarded;
      range[1] = len_;

      if (ioctl(fd, BLKDISCARD, range)) return errno;

      discarded += len_;
    }
    return 0;
  }

  int isCqOverflow();
};
