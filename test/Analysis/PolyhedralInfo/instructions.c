int *select_affine0(int *A, int *B) {
  return A ? A : B;
}

int select_affine1(int a, int b) {
  if (a > b)
    return a;
  return b;
}

float select_affine2(float a, float b) {
  if (a > b)
    return a;
  return b;
}

int select_non_affine0(int *A, int *B) {
  int x = 0;
  for (int i = 0; i < 100; i++)
    x += i * i > A[i] ? A[i] : B[i];
  return x;
}

int select_non_affine1(int *A) {
  int x = 0;
  for (int i = 0; i < 100; i++)
  if (A[i] < i *i)
    x += A[i];
  else
    x+= i*i;
  return x;
}
