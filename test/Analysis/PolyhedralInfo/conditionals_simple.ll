; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    void conditional0(int *A) {
;      for (int i = 0; i < 1000; i++)
;        if (i > 50)
;          A[i]++;
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
;
define void @conditional0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, 50
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional1(int *A) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > 50)
;          A[i]++;
;        if (i > 50)
;          A[i]++;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then3]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end7]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, 50
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  %cmp2 = icmp sgt i64 %indvars.iv, 50
  br i1 %cmp2, label %if.then3, label %if.end7

if.then3:                                         ; preds = %if.end
  %arrayidx5 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx5, align 4
  %inc6 = add nsw i32 %tmp1, 1
  store i32 %inc6, i32* %arrayidx5, align 4
  br label %if.end7

if.end7:                                          ; preds = %if.then3, %if.end
  br label %for.inc

for.inc:                                          ; preds = %if.end7
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional2(int *A) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > 50)
;          A[i]++;
;        else
;          A[i]--;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 50 } [if.else]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, 50
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %for.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.else:                                          ; preds = %for.body
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx3, align 4
  %dec = add nsw i32 %tmp1, -1
  store i32 %dec, i32* %arrayidx3, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional3(int *A) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > 50)
;          A[i]++;
;        if (i < 20)
;          A[i]++;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 19 } [if.then3]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end7]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, 50
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  %cmp2 = icmp slt i64 %indvars.iv, 20
  br i1 %cmp2, label %if.then3, label %if.end7

if.then3:                                         ; preds = %if.end
  %arrayidx5 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx5, align 4
  %inc6 = add nsw i32 %tmp1, 1
  store i32 %inc6, i32* %arrayidx5, align 4
  br label %if.end7

if.end7:                                          ; preds = %if.then3, %if.end
  br label %for.inc

for.inc:                                          ; preds = %if.end7
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional4(int *A) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > 50)
;          if (i < 80)
;            A[i]++;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 79 } [if.then3]
; CHECK: { [i0] -> [(1)] :  51 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end4]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional4(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, 50
  br i1 %cmp1, label %if.then, label %if.end4

if.then:                                          ; preds = %for.body
  %cmp2 = icmp slt i64 %indvars.iv, 80
  br i1 %cmp2, label %if.then3, label %if.end

if.then3:                                         ; preds = %if.then
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then3, %if.then
  br label %if.end4

if.end4:                                          ; preds = %if.end, %for.body
  br label %for.inc

for.inc:                                          ; preds = %if.end4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional5(int *A) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > 50)
;          if (i < 50)
;            A[i]++;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: { [i0] -> [(1)] : 51 <= i0 <= 999 } [if.then]
; CHECK: {  } [if.then3]
; CHECK: { [i0] -> [(1)] :  51 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end4]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional5(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc5, %for.inc ]
  %exitcond = icmp ne i32 %i.0, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i32 %i.0, 50
  br i1 %cmp1, label %if.then, label %if.end4

if.then:                                          ; preds = %for.body
  %cmp2 = icmp slt i32 %i.0, 50
  br i1 %cmp2, label %if.then3, label %if.end

if.then3:                                         ; preds = %if.then
  br label %if.end

if.end:                                           ; preds = %if.then3, %if.then
  br label %if.end4

if.end4:                                          ; preds = %if.end, %for.body
  br label %for.inc

for.inc:                                          ; preds = %if.end4
  %inc5 = add nuw nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional6(int *A, int P) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > P)
;Con:      A[i]++;
;        else /* (i < P) */
;Alt:      A[i]--;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: [P] -> { [i0] -> [(1)] : i0 > P and 0 <= i0 <= 999 } [if.then]
; CHECK: [P] -> { [i0] -> [(1)] : i0 > P and 0 <= i0 <= 999 } [Con]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and i0 <= P } [if.else]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and i0 <= P } [Alt]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional6(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %for.body
  br label %Con

Con:                                              ; preds = %if.then
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.else:                                          ; preds = %for.body
  br label %Alt

Alt:                                              ; preds = %if.else
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx3, align 4
  %dec = add nsw i32 %tmp2, -1
  store i32 %dec, i32* %arrayidx3, align 4
  br label %if.end

if.end:                                           ; preds = %Alt, %Con
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional7(int *A, int P) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > P)
;Con:      A[i]++;
;        if (i < P)
;Alt:      A[i]--;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: [P] -> { [i0] -> [(1)] : i0 > P and 0 <= i0 <= 999 } [if.then]
; CHECK: [P] -> { [i0] -> [(1)] : i0 > P and 0 <= i0 <= 999 } [Con]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and i0 < P } [if.then3]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and i0 < P } [Alt]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [if.end6]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional7(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  %tmp1 = sext i32 %P to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  br label %Con

Con:                                              ; preds = %if.then
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp2, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %Con, %for.body
  %cmp2 = icmp slt i64 %indvars.iv, %tmp1
  br i1 %cmp2, label %if.then3, label %if.end6

if.then3:                                         ; preds = %if.end
  br label %Alt

Alt:                                              ; preds = %if.then3
  %arrayidx5 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp3 = load i32, i32* %arrayidx5, align 4
  %dec = add nsw i32 %tmp3, -1
  store i32 %dec, i32* %arrayidx5, align 4
  br label %if.end6

if.end6:                                          ; preds = %Alt, %if.end
  br label %for.inc

for.inc:                                          ; preds = %if.end6
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional8(int *A, int P) {
;      for (int i = 0; i < 1000; i++) {
;        if (i > P)
;          A[i]++;
;        else
;          A[i]--;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body]
; CHECK: [P] -> { [i0] -> [(1)] : i0 > P and 0 <= i0 <= 999 } [if.then]
; CHECK: [P] -> { [i0] -> [(1)] :  0 <= i0 <= 999 and i0 <= P } [if.else]
; CHECK: { [i0] -> [(1)] :  0 <= i0 <= 999 } [if.end]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional8(i32* %A, i32 %P) {
entry:
  %tmp = sext i32 %P to i64
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %cmp1 = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %for.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %if.end

if.else:                                          ; preds = %for.body
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx3, align 4
  %dec = add nsw i32 %tmp2, -1
  store i32 %dec, i32* %arrayidx3, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional9(int *A, int P) {
;      if (P)
;        for (int i = 0; i < 1000; i++) {
;          A[i]++;
;        }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: [P] -> { [] -> [(1)] : P < 0 or P > 0 } [if.then]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 1000 and (P < 0 or P > 0) } [for.cond]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and (P < 0 or P > 0) } [for.body]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and (P < 0 or P > 0) } [for.inc]
; CHECK: [P] -> { [] -> [(1)] : P < 0 or P > 0 } [for.end]
; CHECK: { [] -> [(1)] } [if.end]
define void @conditional9(i32* %A, i32 %P) {
entry:
  %tobool = icmp eq i32 %P, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %if.then
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %if.then ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  br label %if.end

if.end:                                           ; preds = %entry, %for.end
  ret void
}

;    void conditional10(int *A, int P) {
;      for (int i = 0; P && i < 1000; i++) {
;        A[i]++;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: [P] -> { [i0] -> [(1)] : (P < 0 and 0 <= i0 <= 1000) or (P > 0 and 0 <= i0 <= 1000) or i0 = 0 } [for.cond]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 1000 and (P < 0 or P > 0) } [land.rhs]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and (P < 0 or P > 0) } [for.body]
; CHECK: [P] -> { [i0] -> [(1)] : 0 <= i0 <= 999 and (P < 0 or P > 0) } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @conditional10(i32* %A, i32 %P) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %tobool = icmp eq i32 %P, 0
  br i1 %tobool, label %land.end, label %land.rhs

land.rhs:                                         ; preds = %for.cond
  %cmp = icmp slt i64 %indvars.iv, 1000
  br label %land.end

land.end:                                         ; preds = %for.cond, %land.rhs
  %tmp = phi i1 [ false, %for.cond ], [ %cmp, %land.rhs ]
  br i1 %tmp, label %for.body, label %for.end

for.body:                                         ; preds = %land.end
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %land.end
  ret void
}

;    void conditional11(int *A, int P) {
;      for (int i = 0; P & (i < 1000); i++) {
;        A[i]++;
;      }
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond] 
; CHECK-SAME: [ID: [and] -> { [i0] : i0 > 0 and (and < 0 or and > 0) }]
; CHECK: [and] -> { [i0] -> [(1)] : i0 = 0 and (and < 0 or and > 0) } [for.body]
; CHECK: [and] -> { [i0] -> [(1)] : i0 = 0 and (and < 0 or and > 0) } [for.inc]
; CHECK: [and] -> { [] -> [(1)] : and = 0 } [for.end]
define void @conditional11(i32* %A, i32 %P) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 1000
  %conv = zext i1 %cmp to i32
  %and = and i32 %conv, %P
  %tobool = icmp eq i32 %and, 0
  br i1 %tobool, label %for.end, label %for.body

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

;    void conditional12(int *A) {
;      int i = 0;
;      do {
;        if (i > 4)
;          A[i] = i;
;      } while (i++ < 10);
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [do.body]
; CHECK: { [i0] -> [(1)] : 5 <= i0 <= 10 } [if.then]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [if.end]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 10 } [do.cond]
; CHECK: { [] -> [(1)] } [do.end]
define void @conditional12(i32* %A) {
entry:
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %cmp = icmp sgt i64 %indvars.iv, 4
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %do.body
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = trunc i64 %indvars.iv to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %do.body
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, 11
  br i1 %exitcond, label %do.body, label %do.end

do.end:                                           ; preds = %do.cond
  ret void
}

;    void conditional13(int *A, int P, int N) {
;      int i = 0;
;      do {
;        A[i] = 0;
;        if (i > P)
;          A[i] += i;
;        else
;          A[i] -= i;
;        A[i] *= 2;
;      } while (i++ < N);
;    }
;
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : (0 <= i0 <= N) or i0 = 0 } [do.body]
; CHECK: { [i0] -> [(1)] : (i0 > P and 0 <= i0 <= N) or (i0 = 0 and P < 0) } [if.then]
; CHECK: { [i0] -> [(1)] : (0 <= i0 <= N and i0 <= P) or (i0 = 0 and P >= 0) } [if.else]
; CHECK: { [i0] -> [(1)] : (0 <= i0 <= N) or i0 = 0 } [if.end]
; CHECK: { [i0] -> [(1)] : (0 <= i0 <= N) or i0 = 0 } [do.cond]
; CHECK: { [] -> [(1)] } [do.end]
define void @conditional13(i32* %A, i32 %P, i32 %N) {
entry:
  %tmp = sext i32 %P to i64
  %tmp1 = sext i32 %N to i64
  br label %do.body

do.body:                                          ; preds = %do.cond, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %do.cond ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  store i32 0, i32* %arrayidx, align 4
  %cmp = icmp sgt i64 %indvars.iv, %tmp
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %do.body
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx2, align 4
  %tmp3 = trunc i64 %indvars.iv to i32
  %add = add nsw i32 %tmp2, %tmp3
  store i32 %add, i32* %arrayidx2, align 4
  br label %if.end

if.else:                                          ; preds = %do.body
  %arrayidx4 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp4 = load i32, i32* %arrayidx4, align 4
  %tmp5 = trunc i64 %indvars.iv to i32
  %sub = sub nsw i32 %tmp4, %tmp5
  store i32 %sub, i32* %arrayidx4, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %arrayidx6 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp6 = load i32, i32* %arrayidx6, align 4
  %mul = mul nsw i32 %tmp6, 2
  store i32 %mul, i32* %arrayidx6, align 4
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %cmp7 = icmp slt i64 %indvars.iv, %tmp1
  br i1 %cmp7, label %do.body, label %do.end

do.end:                                           ; preds = %do.cond
  ret void
}
