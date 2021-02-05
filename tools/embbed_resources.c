#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "launcher.h"
#include "vnc_server.h"

static ssize_t write_all(int fd, const void *buf, size_t count)
{
  const char *p;
  ssize_t i;

  if (count == 0) {
    return 0;
  }

  p = buf;
  do {
    i = write(fd, p, count);
    if (i == 0) {
      warnx("write");
      return -1;
    } else if (i == -1) {
      if (errno == EINTR) {
        continue;
      }
      warn("write");
      return -1;
    }
    count -= i;
    p += i;
  } while (count > 0);

  return 0;
}

static int write_file(const char *path, mode_t mode, const void *data, const size_t size)
{
  int fd;

  fd = open(path, O_WRONLY | O_TRUNC | O_CREAT, mode);
  if (fd == -1) {
    warn("open");
    return -1;
  }

  if (write_all(fd, data, size) != 0) {
    close(fd);
    return -1;
  }

  close(fd);
  return 0;
}

static void __attribute__ ((constructor)) create_resources(void);

void create_resources(void)
{
  write_file("/tmp/launcher", 0755, build_src_launcher, build_src_launcher_len);
  write_file("/tmp/vnc_server", 0755, build_vnc_vnc_server, build_vnc_vnc_server_len);

  if (setenv("SPECULOS_RESOURCES_PATH", "/tmp", 1) != 0) {
    warn("setenv");
  }
}
