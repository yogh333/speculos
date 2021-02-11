#include <stdio.h>

#include "emulate.h"
#define HTTP_IMPLEMENTATION
#include "http.h"

#include "bolos_syscalls_1.6.h"

struct http_answer_s {
  unsigned long ret;
  int retid;
};

static int http_request(unsigned long syscall, unsigned long *ret, int *retid)
{
  struct http_answer_s answer;
  char url[4096];

  snprintf(url, sizeof(url), "http://127.0.0.1:8000/?syscall=0x%lx", syscall);
  answer.ret = 0;
  answer.retid = 0;

  http_t *request = http_get(url, NULL);
  if (!request) {
    fprintf(stderr, "Invalid request.\n");
    return 1;
  }

  http_status_t status = HTTP_STATUS_PENDING;
  int prev_size = -1;
  while (status == HTTP_STATUS_PENDING) {
    status = http_process(request);
    if (prev_size != (int)request->response_size) {
      //fprintf(stderr, "%d byte(s) received.\n", (int)request->response_size);
      prev_size = (int)request->response_size;
    }
  }

  if (status == HTTP_STATUS_FAILED) {
    fprintf(stderr, "HTTP request failed (%d): %s.\n", request->status_code,
           request->reason_phrase);
    http_release(request);
    return -1;
  }

  const char *data = (const char *)request->response_data;
  //fprintf(stderr, "http data: [%s]\n", data);

  if (sscanf(data, "%lx %x", &answer.ret, &answer.retid) != 2) {
     fprintf(stderr, "unexpected http answer (\"%s\")", data);
     http_release(request);
     return -1;
   }

  http_release(request);

  fprintf(stderr, "ret = 0x%lx, retid = 0x%x\n", answer.ret, answer.retid);

  *ret = answer.ret;
  *retid = answer.retid;

  return 0;
}

int hook_syscall(unsigned long syscall, unsigned long *parameters,
                 unsigned long *ret, bool verbose, sdk_version_t sdk_version)
{
  int retid;

  switch (syscall) {
  case SYSCALL_os_global_pin_is_validated_ID_IN:
    http_request(syscall, ret, &retid);
    break;

  default:
    retid = emulate(syscall, parameters, ret, verbose, false, sdk_version);
    break;
  }

  return retid;
}
