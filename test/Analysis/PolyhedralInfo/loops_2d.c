void c0(int *A) {
  for (int i = 0; i < 1000; i++)
    for (int j = 0; j < 500; j++)
      A[i]++;
}

void c1(int *A) {
  for (int i = 0; i < 1000; i++)
    for (int j = i; j < 500; j++)
      A[i]++;
}

void c2(int *A) {
  for (int i = 0; i < 1000; i++)
    for (int j = -i; j < i; j++)
      A[i]++;
}

void c3(int *A) {
  for (int i = 11; i < 1000; i+=2)
    for (int j = 13; j < i; j+=3)
      A[i]++;
}

void c4(int *A) {
  for (int i = 0; i < 1000; i++)
    for (int j = -i; j < i * i; j++)
      A[i]++;
}
