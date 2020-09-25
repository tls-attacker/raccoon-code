#include <stdio.h>
#include <string.h>
#include <time.h>

#include <openssl/sha.h>
#include <openssl/hmac.h>

#include <stdint.h>
#include <x86intrin.h>
#include <inttypes.h>

#define HASH_DIGEST_SIZE_BYTES (EVP_MAX_MD_SIZE)
#define MAX_INPUT_LEN_BYTES 530
#define DATA_LEN_BYTES 1024

enum hash_function_t {
  HASH_FUNCTION__SHA256,
  HASH_FUNCTION__SHA384
};

unsigned char data[DATA_LEN_BYTES];

static inline uint64_t rdtscp()
{
    uint32_t aux;
    uint64_t res;
    res = __rdtscp(&aux);
    return res;
}

// Credit to https://stackoverflow.com/a/919375
void time_one_hash_call(int key_len, enum hash_function_t hash_function)
{
  unsigned char key[MAX_INPUT_LEN_BYTES];
  FILE *f = fopen("/dev/urandom", "rb");
  fread(key, sizeof(char), MAX_INPUT_LEN_BYTES, f);
  fclose(f);

  unsigned char output[HASH_DIGEST_SIZE_BYTES];
  unsigned int md_len;
  uint64_t start, end;
  if (hash_function == HASH_FUNCTION__SHA256) {
    start = rdtscp();
    HMAC(EVP_sha256(), key, key_len, data, DATA_LEN_BYTES, output, &md_len);
    end = rdtscp();
  } else if (hash_function == HASH_FUNCTION__SHA384) {
    start = rdtscp();
    HMAC(EVP_sha384(), key, key_len, data, DATA_LEN_BYTES, output, &md_len);
    end = rdtscp();
  }
  printf("%d\t%ld\n", key_len, end - start);
}

void main(int argc, char *argv[])
{
  enum hash_function_t hash_function;
  if (!strcmp(argv[1], "sha256")) {
    hash_function = HASH_FUNCTION__SHA256;
  } else if (!strcmp(argv[1], "sha384")) {
      hash_function = HASH_FUNCTION__SHA384;
  } else {
    printf("Argument 1 should be either sha256 or sha384, bailing out.\n");
    exit(1);
  }

  int num_of_tests_per_input_len = atoi(argv[2]);

  srand(time(NULL));

  FILE *f = fopen("/dev/urandom", "rb");
  fread(data, sizeof(char), DATA_LEN_BYTES, f);
  fclose(f);

  for (int i = 0; i < num_of_tests_per_input_len * MAX_INPUT_LEN_BYTES; i++) {
      time_one_hash_call(rand() % MAX_INPUT_LEN_BYTES, hash_function);
  }
}
