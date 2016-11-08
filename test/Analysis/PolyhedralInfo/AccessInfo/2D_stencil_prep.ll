; RUN: opt -polyhedral-access-function-info -analyze < %s | FileCheck %s
;
; void stencil(int width, int height, float *grid_old, float *grid_new) {
;
;   const float gamma = 0.24;
;   float tmp;
;
;   for (int y = 1; y < height - 1; ++y) {
;     for (int x = 1; x < width - 1; ++x) {
;       int idx = x + y * width;
;
;       grid_new[idx] =
;           grid_old[idx] +
;           gamma * (-4 * grid_old[idx] + grid_old[idx + 1] + grid_old[idx - 1] +
;                    grid_old[idx + width] + grid_old[idx - width]);
;     }
;   }
; }
;
; CHECK:     PACC summary
; CHECK:       Unknown reads: None
; CHECK:       Unknown writes: None
; CHECK:     Array infos:
; CHECK-DAG:  Base pointer: float* %grid_new
; CHECK-DAG:    MustWrite: [height, width] -> { [i0, i1] -> grid_new[1 + i0, 1 + i1] : 0 <= i0 <= -3 + height and 0 <= i1 <= -3 + width }
; CHECK-DAG:  Base pointer: float* %grid_old
; CHECK-DAG:     MustRead: [height, width] -> { [i0, i1] -> grid_old[o0, o1] : 0 <= i0 <= -3 + height and 0 <= i1 <= -3 + width and o1 > i0 + i1 - o0 and -1 - i0 + i1 + o0 <= o1 <= 1 - i0 + i1 + o0 and o1 <= 3 + i0 + i1 - o0 }
;
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

; Function Attrs: noinline nounwind ssp uwtable
define void @stencil(i32 %width, i32 %height, float* %grid_old, float* %grid_new) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc31, %entry
  %y.0 = phi i32 [ 1, %entry ], [ %inc32, %for.inc31 ]
  %sub = sub nsw i32 %height, 1
  %cmp = icmp slt i32 %y.0, %sub
  br i1 %cmp, label %for.body, label %for.end33

for.body:                                         ; preds = %for.cond
  br label %for.cond3

for.cond3:                                        ; preds = %for.inc, %for.body
  %x.0 = phi i32 [ 1, %for.body ], [ %inc, %for.inc ]
  %sub4 = sub nsw i32 %width, 1
  %cmp5 = icmp slt i32 %x.0, %sub4
  br i1 %cmp5, label %for.body6, label %for.end

for.body6:                                        ; preds = %for.cond3
  %mul = mul nsw i32 %y.0, %width
  %add = add nsw i32 %x.0, %mul
  %idxprom = sext i32 %add to i64
  %arrayidx = getelementptr inbounds float, float* %grid_old, i64 %idxprom
  %0 = load float, float* %arrayidx, align 4
  %idxprom8 = sext i32 %add to i64
  %arrayidx9 = getelementptr inbounds float, float* %grid_old, i64 %idxprom8
  %1 = load float, float* %arrayidx9, align 4
  %mul10 = fmul float -4.000000e+00, %1
  %add11 = add nsw i32 %add, 1
  %idxprom12 = sext i32 %add11 to i64
  %arrayidx13 = getelementptr inbounds float, float* %grid_old, i64 %idxprom12
  %2 = load float, float* %arrayidx13, align 4
  %add14 = fadd float %mul10, %2
  %sub15 = sub nsw i32 %add, 1
  %idxprom16 = sext i32 %sub15 to i64
  %arrayidx17 = getelementptr inbounds float, float* %grid_old, i64 %idxprom16
  %3 = load float, float* %arrayidx17, align 4
  %add18 = fadd float %add14, %3
  %add19 = add nsw i32 %add, %width
  %idxprom20 = sext i32 %add19 to i64
  %arrayidx21 = getelementptr inbounds float, float* %grid_old, i64 %idxprom20
  %4 = load float, float* %arrayidx21, align 4
  %add22 = fadd float %add18, %4
  %sub23 = sub nsw i32 %add, %width
  %idxprom24 = sext i32 %sub23 to i64
  %arrayidx25 = getelementptr inbounds float, float* %grid_old, i64 %idxprom24
  %5 = load float, float* %arrayidx25, align 4
  %add26 = fadd float %add22, %5
  %mul27 = fmul float 0x3FCEB851E0000000, %add26
  %add28 = fadd float %0, %mul27
  %idxprom29 = sext i32 %add to i64
  %arrayidx30 = getelementptr inbounds float, float* %grid_new, i64 %idxprom29
  store float %add28, float* %arrayidx30, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body6
  %inc = add nsw i32 %x.0, 1
  br label %for.cond3

for.end:                                          ; preds = %for.cond3
  br label %for.inc31

for.inc31:                                        ; preds = %for.end
  %inc32 = add nsw i32 %y.0, 1
  br label %for.cond

for.end33:                                        ; preds = %for.cond
  ret void
}
