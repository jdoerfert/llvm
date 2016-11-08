; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    void ud0(int *A, unsigned N) {
;      for (unsigned i = 0; i != N; i++)
;        A[i]++;
;    }
;
; CHECK: { [] -> [(1)] } [entry]

; Verify we have an invalid domain for "negative" values of N:
; CHECK: [N] -> { [i0] -> [(1)] : (0 <= i0 <= N) or i0 = 0 } [for.cond]
; CHECK-SAME: [ID: [N] -> { [i0] : N < 0 }]

; CHECK: [N] -> { [i0] -> [(1)] : (0 <= i0 < N) or (i0 = 0 and N < 0) } [for.body]
; CHECK: [N] -> { [i0] -> [(1)] : (0 <= i0 < N) or (i0 = 0 and N < 0) } [for.inc]
; CHECK: [N] -> { [] -> [(1)] : N >= 0 } [for.end]
;
define void @ud0(i32* %A, i32 %N) {
entry:
  %tmp = zext i32 %N to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp ne i64 %indvars.iv, %tmp
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}
