#include <stdio.h>
#include <string.h>
#include <time.h>
#include <assert.h>

#include <openssl/sha.h>
#include <openssl/evp.h>

#include <stdint.h>
#include <x86intrin.h>
#include <inttypes.h>

#define HASH_DIGEST_SIZE_BYTES (384 * 8)
#define MAX_INPUT_LEN_BYTES 530
#define NUM_OF_TESTS_PER_INPUT_LEN 1000

static inline uint64_t rdtscp()
{
    uint32_t aux;
    uint64_t res;
    res = __rdtscp(&aux);
    return res;
}

// Credit to https://stackoverflow.com/a/919375
void time_one_hash_call(int input_len)
{
  unsigned char input[MAX_INPUT_LEN_BYTES];
  FILE *f = fopen("/dev/urandom", "rb");
  fread(input, sizeof(char), MAX_INPUT_LEN_BYTES, f);
  fclose(f);

  unsigned char output[HASH_DIGEST_SIZE_BYTES];

  EVP_MD_CTX *mdctx;
	assert(mdctx = EVP_MD_CTX_new());
  assert(1 == EVP_DigestInit_ex(mdctx, EVP_sha256(), NULL));
  uint64_t start = rdtscp();
	int res = EVP_DigestUpdate(mdctx, input, input_len);
  uint64_t end = rdtscp();
  assert(1 == res);
  unsigned int digest_len = EVP_MD_size(EVP_sha256());
	res = EVP_DigestFinal_ex(mdctx, output, &digest_len);
  assert(1 == res);
	EVP_MD_CTX_free(mdctx);

  printf("%d\t%ld\n", input_len, end - start);
}

void main()
{
  srand(time(NULL));
  for (int i = 0; i < NUM_OF_TESTS_PER_INPUT_LEN * MAX_INPUT_LEN_BYTES; i++) {
      time_one_hash_call(rand() % MAX_INPUT_LEN_BYTES);
  }
}
