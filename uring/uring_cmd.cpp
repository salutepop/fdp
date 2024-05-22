#include "uring_cmd.h"
#include <liburing.h>

Uring_cmd::Uring_cmd(uint32_t qd, uint32_t blocksize, uint32_t lbashift,
                     io_uring_params params)
    : qd_(qd), blocksize_(blocksize), lbashift_(lbashift) {
  initBuffer();
  initUring(params);
}

/* unused, 나중에 fixed buffer 적용 시 사용 예정 */
void Uring_cmd::initBuffer() {
  int err;
  void *buf;

  iovecs_ = (struct iovec *)calloc(qd_, sizeof(struct iovec));

  for (int i = 0; i < roundup_pow2(qd_); i++) {
    // std::cout << "POW i = " << i << std::endl;
    err = posix_memalign(&buf, PAGE_SIZE, blocksize_ * qd_);
    if (err) {
      std::cerr << "failed mem align, err= " << err << std::endl;
    }
    // std::cout << "i, buf= " << i << ", " << buf << std::endl;
    iovecs_[i].iov_base = buf;
    iovecs_[i].iov_len = BS;
  }
}

void Uring_cmd::initUring(io_uring_params &params) {
  // 모든 멤버가 0으로 초기화된 io_uring_params 구조체를 생성
  io_uring_params empty_params;
  memset(&empty_params, 0, sizeof(empty_params));

  // params가 비어 있는지 확인
  if (memcmp(&params, &empty_params, sizeof(io_uring_params)) == 0) {
    struct io_uring_params p;
    memset(&p, 0, sizeof(p));
    p.flags |= IORING_SETUP_SQE128;
    p.flags |= IORING_SETUP_CQE32;

    p.flags |= IORING_SETUP_CQSIZE;
    p.cq_entries = qd_;

    p.flags |= IORING_SETUP_COOP_TASKRUN;
    p.flags |= IORING_SETUP_SINGLE_ISSUER | IORING_SETUP_DEFER_TASKRUN;

    params_ = p;
  } else {
    params_ = params;
  }

  io_uring_queue_init_params(qd_, &ring_, &params_);
}

void Uring_cmd::prepUringCmd(struct io_uring_sqe *sqe, int fd, int ns,
                             bool is_read, off_t offset, size_t size, void *buf,
                             uint32_t dtype, uint32_t dspec) {
  struct nvme_uring_cmd *cmd;
  struct iovec iovec;
  iovec.iov_base = buf;
  iovec.iov_len = size;

  memset(sqe, 0, sizeof(*sqe));
  sqe->fd = fd;
  sqe->cmd_op = NVME_URING_CMD_IO_VEC;
  sqe->opcode = IORING_OP_URING_CMD;
  sqe->user_data = 0;

  cmd = (struct nvme_uring_cmd *)sqe->cmd;
  memset(cmd, 0, sizeof(struct nvme_uring_cmd));
  cmd->opcode = is_read ? nvme_cmd_read : nvme_cmd_write;
  __u64 slba;
  __u32 nlb;
  slba = offset >> lbashift_;
  if (size < blocksize_) {
    size = blocksize_;
  }
  nlb = (size >> lbashift_) - 1;

  // std::cout << "slba, nlba, lba_shift : " << slba << ", " << nlb << ", "
  //           << lbashift_ << std::endl;

  cmd->cdw10 = slba & 0xffffffff;
  cmd->cdw11 = slba >> 32;
  cmd->cdw12 = nlb;
  // cmd->cdw12 = (dtype & 0xFF) << 20 | nLb;
  // cmd->cdw13 = (dspec << 16);

  // cmd->addr = (__u64)(uintptr_t)iovecs[0].iov_base;
  // cmd->data_len = iovecs[0].iov_len;

  // cmd->addr = (__u64)(uintptr_t)iovecs;
  cmd->addr = (uint64_t)&iovec;
  cmd->data_len = 1;
  cmd->nsid = ns;
}

void Uring_cmd::UringCmdWrite(int fd, int ns, off_t offset, size_t size,
                              void *buf, int pid) {
  struct io_uring_sqe *sqe = io_uring_get_sqe(&ring_);
  struct io_uring_cqe *cqe;
  int err;

  prepUringCmdWrite(sqe, fd, ns, offset, size, buf, pid);
  LOG("FD", sqe->fd);
  LOG("NSID", ((struct nvme_uring_cmd *)sqe->cmd)->nsid);
  LOG("OPCODE", +((struct nvme_uring_cmd *)sqe->cmd)->opcode);
  LOG("FLAG", +((struct nvme_uring_cmd *)sqe->cmd)->flags);
  LOG("CDW10", ((struct nvme_uring_cmd *)sqe->cmd)->cdw10);
  LOG("CDW11", ((struct nvme_uring_cmd *)sqe->cmd)->cdw11);
  LOG("CDW12", ((struct nvme_uring_cmd *)sqe->cmd)->cdw12);
  err = io_uring_submit(&ring_);
  LOG("uring_submit", err);
  err = io_uring_wait_cqe(&ring_, &cqe);
  LOG("uring_wait_cqe", err);
  io_uring_cqe_seen(&ring_, cqe);
  if (cqe->res != 0) {
    std::cout << "cqe->res= " << cqe->res << std::endl;
  }
}

void Uring_cmd::UringCmdRead(int fd, int ns, off_t offset, size_t size,
                             void *buf) {
  struct io_uring_sqe *sqe = io_uring_get_sqe(&ring_);
  struct io_uring_cqe *cqe;
  int err;

  prepUringCmdRead(sqe, fd, ns, offset, size, buf);
  LOG("FD", sqe->fd);
  LOG("NSID", ((struct nvme_uring_cmd *)sqe->cmd)->nsid);
  LOG("OPCODE", +((struct nvme_uring_cmd *)sqe->cmd)->opcode);
  LOG("FLAG", +((struct nvme_uring_cmd *)sqe->cmd)->flags);
  LOG("CDW10", ((struct nvme_uring_cmd *)sqe->cmd)->cdw10);
  LOG("CDW11", ((struct nvme_uring_cmd *)sqe->cmd)->cdw11);
  LOG("CDW12", ((struct nvme_uring_cmd *)sqe->cmd)->cdw12);
  err = io_uring_submit(&ring_);
  LOG("uring_submit", err);
  err = io_uring_wait_cqe(&ring_, &cqe);
  LOG("uring_wait_cqe", err);
  io_uring_cqe_seen(&ring_, cqe);

  std::cout << "cqe->res= " << cqe->res << std::endl;
  std::cout << "Read iovec, " << std::string((char *)buf, size) << std::endl;
}

void Uring_cmd::UringRead(int fd, int ns, off_t offset, size_t size,
                          void *buf) {
  struct io_uring_sqe *sqe = io_uring_get_sqe(&ring_);
  struct io_uring_cqe *cqe;
  int err;

  struct iovec iov;
  iov.iov_base = buf;
  iov.iov_len = size;

  io_uring_prep_read(sqe, fd, iov.iov_base, iov.iov_len, 0);
  err = io_uring_submit(&ring_);
  LOG("uring_submit", err);
  err = io_uring_wait_cqe(&ring_, &cqe);
  LOG("uring_wait_cqe", err);
  io_uring_cqe_seen(&ring_, cqe);

  std::cout << "cqe->res= " << cqe->res << std::endl;
  if (cqe->res > 0) {
    std::cout << "Read iovec, " << std::string((char *)buf, cqe->res)
              << std::endl;
  }
}
