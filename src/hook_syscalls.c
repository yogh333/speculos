#include <curl/curl.h>

#include "emulate.h"

#include "bolos_syscalls_1.6.h"

struct http_answer_s {
  unsigned long ret;
  int retid;
};

static CURL *curl = NULL;

static size_t cb(void *buffer, size_t size, size_t nmemb, void *userp)
{
   struct http_answer_s *answer = (struct http_answer_s *)userp;
   char data[4096] = { 0 };

   if (size * nmemb >= sizeof(buffer)) {
     fprintf(stderr, "unexpected http answer size");
     return -1;
   }

   memcpy(data, buffer, size * nmemb);

   fprintf(stderr, "http answer: \"%s\"", data);

   if (sscanf(data, "%lx %x", &answer->ret, &answer->retid) != 2) {
     fprintf(stderr, "unexpected http answer (\"%s\")", data);
   }

   fprintf(stderr, "ret = 0x%lx, retid = 0x%x", answer->ret, answer->retid);

   return 0;
}

static void http_request(unsigned long syscall, unsigned long *ret, int *retid)
{
  struct http_answer_s answer;
  char url[4096];
  CURLcode res;

  if (curl == NULL) {
    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
  }

  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, cb);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&answer);

  snprintf(url, sizeof(url), "http://127.0.0.1:8000/?syscall=0x%lx", syscall);
  curl_easy_setopt(curl, CURLOPT_URL, url);

  answer.ret = 0;
  answer.retid = 0;

  res = curl_easy_perform(curl);
  if (res != CURLE_OK) {
    fprintf(stderr, "curl_easy_perform() failed: %s\n",
            curl_easy_strerror(res));
  }

  curl_easy_cleanup(curl);

  *ret = answer.ret;
  *retid = answer.retid;
}

int hook_syscall(unsigned long syscall, unsigned long *parameters,
                 unsigned long *ret, bool verbose,
                 sdk_version_t sdk_version)
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
