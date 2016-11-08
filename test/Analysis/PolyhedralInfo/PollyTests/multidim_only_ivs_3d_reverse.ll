; RUN: opt -polyhedral-function-info -analyze < %s | FileCheck %s
; RUN: opt -polyhedral-access-function-info -analyze < %s | FileCheck %s --check-prefix=ACCESS
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

; This test case checks for array access functions where the order in which the
; loop ivs appear in the array subscript does not follow the order of the
; the loops in which they are defined. This (very) common case.
;
; void foo(long n, long m, long o, double A[n][m][o]) {
;
;   for (long i = 0; i < n; i++)
;     for (long k = 0; k < o; k++)
;       for (long j = 0; j < m; j++)
;         A[i][j][k] = 1.0;
; }

; CHECK: Domain of entry: { [] -> [(1)] }
; CHECK: Domain of for.i: [n] -> { [i0] -> [(1)] : (0 <= i0 < n) or i0 = 0 }
; CHECK: Domain of for.k: [n, o] -> { [i0, i1] -> [(1)] : (0 <= i0 < n and 0 <= i1 < o) or (i1 = 0 and 0 <= i0 < n) or (i0 = 0 and 0 <= i1 < o) or (i0 = 0 and i1 = 0) }
; CHECK: Domain of for.j: [n, o, m] -> { [i0, i1, i2] -> [(1)] : (i2 = 0 and 0 <= i0 < n and 0 <= i1 < o) or (i1 = 0 and i2 = 0 and 0 <= i0 < n) or (i0 = 0 and i2 = 0 and 0 <= i1 < o) or (i0 = 0 and i1 = 0 and i2 = 0) or (0 <= i0 < n and 0 <= i1 < o and 0 <= i2 < m) or (i1 = 0 and 0 <= i0 < n and 0 <= i2 < m) or (i0 = 0 and 0 <= i1 < o and 0 <= i2 < m) or (i0 = 0 and i1 = 0 and 0 <= i2 < m) }
; CHECK: Domain of for.j.inc: [n, o, m] -> { [i0, i1, i2] -> [(1)] : (0 <= i0 < n and 0 <= i1 < o and 0 <= i2 < m) or (i2 = 0 and 0 <= i0 < n and 0 <= i1 < o) or (i1 = 0 and 0 <= i0 < n and 0 <= i2 < m) or (i0 = 0 and 0 <= i1 < o and 0 <= i2 < m) or (i1 = 0 and i2 = 0 and 0 <= i0 < n) or (i0 = 0 and i2 = 0 and 0 <= i1 < o) or (i0 = 0 and i1 = 0 and 0 <= i2 < m) or (i0 = 0 and i1 = 0 and i2 = 0) }
; CHECK: Domain of for.k.inc: [n, o] -> { [i0, i1] -> [(1)] : (0 <= i0 < n and 0 <= i1 < o) or (i0 = 0 and 0 <= i1 < o) or (i1 = 0 and 0 <= i0 < n) or (i0 = 0 and i1 = 0) }
; CHECK: Domain of for.i.inc: [n] -> { [i0] -> [(1)] : (0 <= i0 < n) or i0 = 0 }
; CHECK: Domain of end: { [] -> [(1)] }
;
; ACCESS: PACC summary
; ACCESS:   Unknown reads: None
; ACCESS:   Unknown writes: None
; ACCESS: Array infos:
; ACCESS:   Base pointer: double* %A
; ACCESS:     MustWrite: [n, o, m] -> { [i0, i1, i2] -> A[i0, i2, i1] : 0 <= i0 < n and 0 <= i1 < o and 0 <= i2 < m; [0, i1, i2] -> A[0, i2, i1] : 0 <= i1 < o and 0 <= i2 < m; [i0, i1, 0] -> A[i0, 0, i1] : 0 <= i0 < n and 0 <= i1 < o; [i0, 0, i2] -> A[i0, i2, 0] : 0 <= i0 < n and 0 <= i2 < m; [0, i1, 0] -> A[0, 0, i1] : 0 <= i1 < o; [0, 0, i2] -> A[0, i2, 0] : 0 <= i2 < m; [i0, 0, 0] -> A[i0, 0, 0] : 0 <= i0 < n; [0, 0, 0] -> A[0, 0, 0] }

define void @foo(i64 %n, i64 %m, i64 %o, double* %A) {
entry:
  br label %for.i

for.i:
  %i = phi i64 [ 0, %entry ], [ %i.inc, %for.i.inc ]
  br label %for.k

for.k:
  %k = phi i64 [ 0, %for.i ], [ %k.inc, %for.k.inc ]
  br label %for.j

for.j:
  %j = phi i64 [ 0, %for.k ], [ %j.inc, %for.j.inc ]
  %subscript0 = mul i64 %i, %m
  %subscript1 = add i64 %j, %subscript0
  %subscript2 = mul i64 %subscript1, %o
  %subscript = add i64 %subscript2, %k
  %idx = getelementptr inbounds double, double* %A, i64 %subscript
  store double 1.0, double* %idx
  br label %for.j.inc

for.j.inc:
  %j.inc = add nsw i64 %j, 1
  %j.exitcond = icmp sge i64 %j.inc, %m
  br i1 %j.exitcond, label %for.k.inc, label %for.j

for.k.inc:
  %k.inc = add nsw i64 %k, 1
  %k.exitcond = icmp sge i64 %k.inc, %o
  br i1 %k.exitcond, label %for.i.inc, label %for.k

for.i.inc:
  %i.inc = add nsw i64 %i, 1
  %i.exitcond = icmp sge i64 %i.inc, %n
  br i1 %i.exitcond, label %end, label %for.i

end:
  ret void
}
