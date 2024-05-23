#pragma once

#include "util.h"
#include <liburing.h>
#include <linux/nvme_ioctl.h>

#define BS (4 * 1024)
#define PAGE_SIZE 4096

#define op_read true
#define op_write false

enum nvme_io_opcode {
  nvme_cmd_write = 0x01,
  nvme_cmd_read = 0x02,
  nvme_cmd_io_mgmt_recv = 0x12,
  nvme_cmd_io_mgmt_send = 0x1d,
};

class Uring_cmd {
private:
  uint32_t qd_;
  uint32_t blocksize_;
  uint32_t lbashift_;

  io_uring_params params_;
  struct io_uring ring_;
  struct iovec *iovecs_;

  void prepUringCmd(struct io_uring_sqe *sqe, int fd, int ns, bool is_read,
                    off_t offset, size_t size, void *buf, uint32_t dtype = 0,
                    uint32_t dspec = 0);
  void prepUringCmdRead(struct io_uring_sqe *sqe, int fd, int ns, off_t offset,
                        size_t size, void *buf) {
    prepUringCmd(sqe, fd, ns, op_read, offset, size, buf);
  }
  void prepUringCmdWrite(struct io_uring_sqe *sqe, int fd, int ns, off_t offset,
                         size_t size, void *buf, uint32_t dspec) {
    const uint32_t kPlacementMode = 2;
    prepUringCmd(sqe, fd, ns, op_write, offset, size, buf, kPlacementMode,
                 dspec);
  }
  void initBuffer();
  void initUring(io_uring_params &params);

public:
  Uring_cmd(){};
  Uring_cmd(uint32_t qd, uint32_t blocksize, uint32_t lbashift,
            io_uring_params params);
  // size = byte
  void UringCmdWrite(int fd, int ns, off_t offset, size_t size, void *buf,
                     int pid);
  void UringCmdRead(int fd, int ns, off_t offset, size_t size, void *buf);
  void UringWrite(int fd, int ns, off_t offset, size_t size, void *buf);
  void UringRead(int fd, int ns, off_t offset, size_t size, void *buf);
};
