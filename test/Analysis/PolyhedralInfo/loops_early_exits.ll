; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    void lwe0(int *A, int P) {
;      for (int i = 0; i < 100; i++) {
;        A[i]++;
;        if (i > P)
;          return;
;        A[i]++;
;      }
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 100 and i0 <= 1 + P) or i0 = 0 } [for.cond]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 99 and i0 <= 1 + P) or i0 = 0 } [for.body]
; CHECK:  [P] -> { [] -> [(1)] : P <= 98 } [if.then]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 99 and i0 <= P } [if.end]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 99 and i0 <= P } [for.inc]
; CHECK:  [P] -> { [] -> [(1)] : P >= 99 } [for.end.loopexit]
; CHECK:  { [] -> [(1)] } [for.end]
define void @lwe0(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %for.body, label %for.end.loopexit

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  %cmp1 = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  br label %for.end

if.end:                                           ; preds = %for.body
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx3, align 4
  %inc4 = add nsw i32 %tmp2, 1
  store i32 %inc4, i32* %arrayidx3, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end.loopexit:                                 ; preds = %for.cond
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %if.then
  ret void
}

;    void lwe1(int *A, int P) {
;      int i = 0;
;      do {
;        A[i]++;
;        if (i > P)
;          return;
;        A[i]++;
;      } while (i++ < 100);
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 100 and i0 <= 1 + P) or i0 = 0 } [do.body]
; CHECK:  [P] -> { [] -> [(1)] : P <= 99 } [if.then]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 100 and i0 <= P } [if.end]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 100 and i0 <= P } [do.cond]
; CHECK:  [P] -> { [] -> [(1)] : P >= 100 } [do.end.loopexit]
; CHECK:  { [] -> [(1)] } [do.end]
define void @lwe1(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  %cmp = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %do.body
  br label %do.end

if.end:                                           ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp2, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp5 = icmp slt i64 %indvars.iv, 100
  br i1 %cmp5, label %do.body, label %do.end.loopexit

do.end.loopexit:                                  ; preds = %do.cond
  br label %do.end

do.end:                                           ; preds = %do.end.loopexit, %if.then
  ret void
}

;    void lwe2(int *A, int P) {
;      for (int i = 0; i < 100; i++) {
;        A[i]++;
;        if (i > P)
;          break;
;        A[i]++;
;      }
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 100 and i0 <= 1 + P) or i0 = 0 } [for.cond]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 99 and i0 <= 1 + P) or i0 = 0 } [for.body]
; CHECK:  [P] -> { [] -> [(1)] : P <= 98 } [if.then]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 99 and i0 <= P } [if.end]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 99 and i0 <= P } [for.inc]
; CHECK:  [P] -> { [] -> [(1)] : P >= 99 } [for.end.loopexit]
; CHECK:  { [] -> [(1)] } [for.end]
define void @lwe2(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %for.body, label %for.end.loopexit

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  %cmp1 = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  br label %for.end

if.end:                                           ; preds = %for.body
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx3, align 4
  %inc4 = add nsw i32 %tmp2, 1
  store i32 %inc4, i32* %arrayidx3, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end.loopexit:                                 ; preds = %for.cond
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %if.then
  ret void
}

;    void lwe3(int *A, int P) {
;      int i = 0;
;      do {
;        A[i]++;
;        if (i > P)
;          break;
;        A[i]++;
;      } while (i++ < 100);
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 100 and i0 <= 1 + P) or i0 = 0 } [do.body]
; CHECK:  [P] -> { [] -> [(1)] : P <= 99 } [if.then]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 100 and i0 <= P } [if.end]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 100 and i0 <= P } [do.cond]
; CHECK:  [P] -> { [] -> [(1)] : P >= 100 } [do.end.loopexit]
; CHECK:  { [] -> [(1)] } [do.end]
define void @lwe3(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  %cmp = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %do.body
  br label %do.end

if.end:                                           ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp2, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp5 = icmp slt i64 %indvars.iv, 100
  br i1 %cmp5, label %do.body, label %do.end.loopexit

do.end.loopexit:                                  ; preds = %do.cond
  br label %do.end

do.end:                                           ; preds = %do.end.loopexit, %if.then
  ret void
}

;    void lwe4(int *A, int P) {
;      for (int i = 0; i < 100; i++) {
;        A[i]++;
;        if (i > P)
;          abort();
;        A[i]++;
;      }
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 100 and i0 <= 1 + P) or i0 = 0 } [for.cond]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 99 and i0 <= 1 + P) or i0 = 0 } [for.body]
; CHECK:  [P] -> { [] -> [(1)] : P <= 98 } [if.then]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 99 and i0 <= P } [if.end]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 99 and i0 <= P } [for.inc]
; CHECK:  [P] -> { [] -> [(1)] : P >= 99 } [for.end]
define void @lwe4(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  %cmp1 = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  call void @abort()
  unreachable

if.end:                                           ; preds = %for.body
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx3, align 4
  %inc4 = add nsw i32 %tmp2, 1
  store i32 %inc4, i32* %arrayidx3, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

declare void @abort()

;    void lwe5(int *A, int P) {
;      int i = 0;
;      do {
;        A[i]++;
;        if (i > P)
;          abort();
;        A[i]++;
;      } while (i++ < 100);
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [P] -> { [i0] -> [(1)] : (0 <= i0 <= 100 and i0 <= 1 + P) or i0 = 0 } [do.body]
; CHECK:  [P] -> { [] -> [(1)] : P <= 99 } [if.then]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 100 and i0 <= P } [if.end]
; CHECK:  [P] -> { [i0] -> [(1)] : 0 <= i0 <= 100 and i0 <= P } [do.cond]
; CHECK:  [P] -> { [] -> [(1)] : P >= 100 } [do.end]
define void @lwe5(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  %cmp = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %do.body
  call void @abort()
  unreachable

if.end:                                           ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp2, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp5 = icmp slt i64 %indvars.iv, 100
  br i1 %cmp5, label %do.body, label %do.end

do.end:                                           ; preds = %do.cond
  ret void
}

;    void lwe6(int *A, int P) {
;      for (int i = 0; i < 100; i++) {
;        A[i]++;
;        if (f())
;          return;
;        A[i]++;
;      }
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 100) } [for.cond]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 99) } [for.body]
; CHECK:  [call] -> { [] -> [(1)] : call < 0 or call > 0 } [if.then]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 99 } [if.end]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 99 } [for.inc]
; CHECK:  [call] -> { [] -> [(1)] : call = 0 } [for.end.loopexit]
; CHECK:  { [] -> [(1)] } [for.end]
define void @lwe6(i32* %A, i32 %P) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %for.body, label %for.end.loopexit

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  %call = call i32 (...) @f()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %for.body
  br label %for.end

if.end:                                           ; preds = %for.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp1, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end.loopexit:                                 ; preds = %for.cond
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %if.then
  ret void
}

declare i32 @f(...)

;    void lwe7(int *A, int P) {
;      int i = 0;
;      do {
;        A[i]++;
;        if (f())
;          return;
;        A[i]++;
;      } while (i++ < 100);
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 100) } [do.body]
; CHECK:  [call] -> { [] -> [(1)] : call < 0 or call > 0 } [if.then]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 100 } [if.end]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 100 } [do.cond]
; CHECK:  [call] -> { [] -> [(1)] : call = 0 } [do.end.loopexit]
; CHECK:  { [] -> [(1)] } [do.end]
define void @lwe7(i32* %A, i32 %P) {
entry:
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  %call = call i32 (...) @f()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %do.body
  br label %do.end

if.end:                                           ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp1, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %do.body, label %do.end.loopexit

do.end.loopexit:                                  ; preds = %do.cond
  br label %do.end

do.end:                                           ; preds = %do.end.loopexit, %if.then
  ret void
}

;    void lwe8(int *A, int P) {
;      for (int i = 0; i < 100; i++) {
;        A[i]++;
;        if (f())
;          break;
;        A[i]++;
;      }
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 100) } [for.cond]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 99) } [for.body]
; CHECK:  [call] -> { [] -> [(1)] : call < 0 or call > 0 } [if.then]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 99 } [if.end]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 99 } [for.inc]
; CHECK:  [call] -> { [] -> [(1)] : call = 0 } [for.end.loopexit]
; CHECK:  { [] -> [(1)] } [for.end]
define void @lwe8(i32* %A, i32 %P) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %for.body, label %for.end.loopexit

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  %call = call i32 (...) @f()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %for.body
  br label %for.end

if.end:                                           ; preds = %for.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp1, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end.loopexit:                                 ; preds = %for.cond
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %if.then
  ret void
}

;    void lwe9(int *A, int P) {
;      int i = 0;
;      do {
;        A[i]++;
;        if (f())
;          break;
;        A[i]++;
;      } while (i++ < 100);
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 100) } [do.body]
; CHECK:  [call] -> { [] -> [(1)] : call < 0 or call > 0 } [if.then]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 100 } [if.end]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 100 } [do.cond]
; CHECK:  [call] -> { [] -> [(1)] : call = 0 } [do.end.loopexit]
; CHECK:  { [] -> [(1)] } [do.end]
define void @lwe9(i32* %A, i32 %P) {
entry:
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  %call = call i32 (...) @f()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %do.body
  br label %do.end

if.end:                                           ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp1, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %do.body, label %do.end.loopexit

do.end.loopexit:                                  ; preds = %do.cond
  br label %do.end

do.end:                                           ; preds = %do.end.loopexit, %if.then
  ret void
}

;    void lwe10(int *A, int P) {
;      for (int i = 0; i < 100; i++) {
;        A[i]++;
;        if (f())
;          abort();
;        A[i]++;
;      }
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 100) } [for.cond]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 99) } [for.body]
; CHECK:  [call] -> { [] -> [(1)] : call < 0 or call > 0 } [if.then]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 99 } [if.end]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 99 } [for.inc]
; CHECK:  [call] -> { [] -> [(1)] : call = 0 } [for.end]
define void @lwe10(i32* %A, i32 %P) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  %call = call i32 (...) @f()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %for.body
  call void @abort()
  unreachable

if.end:                                           ; preds = %for.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp1, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void lwe11(int *A, int P) {
;      int i = 0;
;      do {
;        A[i]++;
;        if (f())
;          abort();
;        A[i]++;
;      } while (i++ < 100);
;    }
;
; CHECK:  { [] -> [(1)] } [entry]
; CHECK:  [call] -> { [i0] -> [(1)] : i0 = 0 or (call = 0 and 0 <= i0 <= 100) } [do.body]
; CHECK:  [call] -> { [] -> [(1)] : call < 0 or call > 0 } [if.then]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 100 } [if.end]
; CHECK:  [call] -> { [i0] -> [(1)] : call = 0 and 0 <= i0 <= 100 } [do.cond]
; CHECK:  [call] -> { [] -> [(1)] : call = 0 } [do.end]
define void @lwe11(i32* %A, i32 %P) {
entry:
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  %call = call i32 (...) @f()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %do.body
  call void @abort()
  unreachable

if.end:                                           ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx2, align 4
  %inc3 = add nsw i32 %tmp1, 1
  store i32 %inc3, i32* %arrayidx2, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp = icmp slt i64 %indvars.iv, 100
  br i1 %cmp, label %do.body, label %do.end

do.end:                                           ; preds = %do.cond
  ret void
}
