; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    void simple1(int *A) {
;      for (int i = 0; i < 10; i++)
;        A[i] = i;
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 9 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 9 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @simple1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, 10
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = trunc i64 %indvars.iv to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;
;    void simple2(int *A) {
;      for (int i = 2; i < 10; i++)
;        A[i] = i;
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 8 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 7 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 7 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @simple2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 2, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, 10
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = trunc i64 %indvars.iv to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;
;    void simple3(int *A, long N) {
;      for (int i = 0; i < N; i++)
;        A[i] = i;
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: [N] -> { [i0] -> [(1)] : (0 <= i0 <= N) or i0 = 0 } [for.cond]
; CHECK: [N] -> { [i0] -> [(1)] : 0 <= i0 < N } [for.body]
; CHECK: [N] -> { [i0] -> [(1)] : 0 <= i0 < N } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @simple3(i32* %A, i64 %N) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, %N
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = trunc i64 %indvars.iv to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;
;    void simple4(int *A, long I, long E) {
;      for (int i = I; i < E; i++)
;        A[i] = i;
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : (0 < i0 <= -I + E) or i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 < -I + E } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 < -I + E } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @simple4(i32* %A, i64 %I, i64 %E) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ %I, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, %E
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = trunc i64 %indvars.iv to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;
;    void simple5(int *A) {
;      int i = 0;
;      do {
;  S:    A[i] = i;
;      } while (i++ < 10);
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [do.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [S]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [do.cond]
; CHECK: { [] -> [(1)] } [do.end]
define void @simple5(i32* %A) {
entry:
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  br label %S

S:
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = trunc i64 %indvars.iv to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %do.cond

do.cond:                                          ; preds = %do.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp slt i64 %indvars.iv.next, 11
  br i1 %exitcond, label %do.body, label %do.end

do.end:                                           ; preds = %do.cond
  ret void
}
