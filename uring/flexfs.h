class Superblock {
  uint32_t magic_ = 0;
  char uuid_[37] = {0};
  uint32_t block_size_ = 0; /* in bytes */
  uint32_t ru_size_ = 0;    /* in blocks */
  uint32_t finish_treshold_ = 0;
  //  char reserved_[123] = {0};

public:
  Superblock() {}

  /* Create a superblock for a filesystem covering the entire zoned block device
   */
  Superblock(uint32_t finish_threshold = 0) {
    std::string uuid = "CHANGMIN!!";
    int uuid_len =
        std::min(uuid.length(),
                 sizeof(uuid_) - 1); /* make sure uuid is nullterminated */
    memcpy((void *)uuid_, uuid.c_str(), uuid_len);
    magic_ = MAGIC;
    magic_ = 0x58585858;
    finish_treshold_ = finish_threshold;
    block_size_ = 512;
    ru_size_ = 1024;
    // block_size_ = zbd->GetBlockSize();
    // zone_size_ = zbd->GetZoneSize() / block_size_;
  }

  const uint32_t MAGIC = 0x464C4558; /* FLEX */
  std::string GetUUID() { return std::string(uuid_); }
  uint32_t GetFinishTreshold() { return finish_treshold_; }
};
