; RUN: opt -polyhedral-access-function-info -analyze < %s | FileCheck %s
;
; void updatePositions(float *pos_x, float *pos_y, float *pos_z,
;                      const float *vel_x, const float *vel_y, const float *vel_z,
;                      float dt, int N) {
;
;   for (int id = 0; id < N; ++id) {
;     pos_x[id] += vel_x[id] * dt;
;     pos_y[id] += vel_y[id] * dt;
;     pos_z[id] += vel_z[id] * dt;
;   }
; }
;
; CHECK: Printing analysis 'Polyhedral value analysis' for function 'updatePositions':
;
; CHECK:     PACC summary
; CHECK:       Unknown reads: None
; CHECK:       Unknown writes: None
; CHECK:     Array infos:
; CHECK-DAG:   Base pointer: float* %vel_z
; CHECK-DAG:      MustRead: [N] -> { [i0] -> vel_z[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %vel_y
; CHECK-DAG:      MustRead: [N] -> { [i0] -> vel_y[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %vel_x
; CHECK-DAG:      MustRead: [N] -> { [i0] -> vel_x[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %pos_z
; CHECK-DAG:      MustRead: [N] -> { [i0] -> pos_z[i0] : 0 <= i0 < N }
; CHECK-DAG:     MustWrite: [N] -> { [i0] -> pos_z[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %pos_y
; CHECK-DAG:      MustRead: [N] -> { [i0] -> pos_y[i0] : 0 <= i0 < N }
; CHECK-DAG:     MustWrite: [N] -> { [i0] -> pos_y[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %pos_x
; CHECK-DAG:      MustRead: [N] -> { [i0] -> pos_x[i0] : 0 <= i0 < N }
; CHECK-DAG:     MustWrite: [N] -> { [i0] -> pos_x[i0] : 0 <= i0 < N }
;
;
; void updateSpeed(const float *masses, const float *pos_x, const float *pos_y,
;                  const float *pos_z, float *vel_x, float *vel_y, float *vel_z,
;                  float dt, float epsilon, int N) {
;
;   for (int id = 0; id < N; ++id) {
;
;     // the body's acceleration
;     float acc_x = 0;
;     float acc_y = 0;
;     float acc_z = 0;
;
;     // temporary register
;     float diff_x;
;     float diff_y;
;     float diff_z;
;     float norm;
;     int j;
;
;     for (j = 0; j < N; ++j) {
;       diff_x = pos_x[j] - pos_x[id];
;       diff_y = pos_y[j] - pos_y[id];
;       diff_z = pos_z[j] - pos_z[id];
;
;       // to ensure a certain order of execution we write
;       // the calculations in seperate lines. Keep in mind
;       // that opencl does not define an operator precedence,
;       // thus we have to ensure this by ourselves.
;       norm = diff_x * diff_x;
;       norm += diff_y * diff_y;
;       norm += diff_z * diff_z;
;       norm = sqrt(norm);
;       norm = norm * norm * norm;
;       norm = norm == 0 ? 0 : 1.0f / norm + epsilon;
;       norm *= masses[j];
;
;       acc_x += norm * diff_x;
;       acc_y += norm * diff_y;
;       acc_z += norm * diff_z;
;     }
;
;     vel_x[id] += acc_x * dt;
;     vel_y[id] += acc_y * dt;
;     vel_z[id] += acc_z * dt;
;   }
; }
;
; CHECK: Printing analysis 'Polyhedral value analysis' for function 'updateSpeed':
;
; CHECK:     PACC summary
; CHECK:       Unknown reads: None
; CHECK:       Unknown writes: None
; CHECK:     Array infos:
; CHECK-DAG:   Base pointer: float* %vel_x
; CHECK-DAG:      MustRead: [N] -> { [i0] -> vel_x[i0] : 0 <= i0 < N }
; CHECK-DAG:     MustWrite: [N] -> { [i0] -> vel_x[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %vel_z
; CHECK-DAG:      MustRead: [N] -> { [i0] -> vel_z[i0] : 0 <= i0 < N }
; CHECK-DAG:     MustWrite: [N] -> { [i0] -> vel_z[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %vel_y
; CHECK-DAG:      MustRead: [N] -> { [i0] -> vel_y[i0] : 0 <= i0 < N }
; CHECK-DAG:     MustWrite: [N] -> { [i0] -> vel_y[i0] : 0 <= i0 < N }
; CHECK-DAG:   Base pointer: float* %masses
; CHECK-DAG:      MustRead: [N] -> { [i0, i1] -> masses[i1] : 0 <= i0 < N and 0 <= i1 < N }
; CHECK-DAG:   Base pointer: float* %pos_y
; CHECK-DAG:      MustRead: [N] -> { [i0, i1] -> pos_y[i0] : 0 <= i0 < N and 0 <= i1 < N; [i0, i1] -> pos_y[i1] : 0 <= i0 < N and 0 <= i1 < N }
; CHECK-DAG:   Base pointer: float* %pos_x
; CHECK-DAG:      MustRead: [N] -> { [i0, i1] -> pos_x[i0] : 0 <= i0 < N and 0 <= i1 < N; [i0, i1] -> pos_x[i1] : 0 <= i0 < N and 0 <= i1 < N }
; CHECK-DAG:   Base pointer: float* %pos_z
; CHECK-DAG:      MustRead: [N] -> { [i0, i1] -> pos_z[i0] : 0 <= i0 < N and 0 <= i1 < N; [i0, i1] -> pos_z[i1] : 0 <= i0 < N and 0 <= i1 < N }

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

; Function Attrs: noinline nounwind ssp uwtable
define void @updatePositions(float* %pos_x, float* %pos_y, float* %pos_z, float* %vel_x, float* %vel_y, float* %vel_z, float %dt, i32 %N) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %id.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %id.0, %N
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %id.0 to i64
  %arrayidx = getelementptr inbounds float, float* %vel_x, i64 %idxprom
  %0 = load float, float* %arrayidx, align 4
  %mul = fmul float %0, %dt
  %idxprom1 = sext i32 %id.0 to i64
  %arrayidx2 = getelementptr inbounds float, float* %pos_x, i64 %idxprom1
  %1 = load float, float* %arrayidx2, align 4
  %add = fadd float %1, %mul
  store float %add, float* %arrayidx2, align 4
  %idxprom3 = sext i32 %id.0 to i64
  %arrayidx4 = getelementptr inbounds float, float* %vel_y, i64 %idxprom3
  %2 = load float, float* %arrayidx4, align 4
  %mul5 = fmul float %2, %dt
  %idxprom6 = sext i32 %id.0 to i64
  %arrayidx7 = getelementptr inbounds float, float* %pos_y, i64 %idxprom6
  %3 = load float, float* %arrayidx7, align 4
  %add8 = fadd float %3, %mul5
  store float %add8, float* %arrayidx7, align 4
  %idxprom9 = sext i32 %id.0 to i64
  %arrayidx10 = getelementptr inbounds float, float* %vel_z, i64 %idxprom9
  %4 = load float, float* %arrayidx10, align 4
  %mul11 = fmul float %4, %dt
  %idxprom12 = sext i32 %id.0 to i64
  %arrayidx13 = getelementptr inbounds float, float* %pos_z, i64 %idxprom12
  %5 = load float, float* %arrayidx13, align 4
  %add14 = fadd float %5, %mul11
  store float %add14, float* %arrayidx13, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %id.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @updateSpeed(float* %masses, float* %pos_x, float* %pos_y, float* %pos_z, float* %vel_x, float* %vel_y, float* %vel_z, float %dt, float %epsilon, i32 %N) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc46, %entry
  %id.0 = phi i32 [ 0, %entry ], [ %inc47, %for.inc46 ]
  %cmp = icmp slt i32 %id.0, %N
  br i1 %cmp, label %for.body, label %for.end48

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %acc_x.0 = phi float [ 0.000000e+00, %for.body ], [ %add29, %for.inc ]
  %acc_y.0 = phi float [ 0.000000e+00, %for.body ], [ %add31, %for.inc ]
  %acc_z.0 = phi float [ 0.000000e+00, %for.body ], [ %add33, %for.inc ]
  %j.0 = phi i32 [ 0, %for.body ], [ %inc, %for.inc ]
  %cmp2 = icmp slt i32 %j.0, %N
  br i1 %cmp2, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %idxprom = sext i32 %j.0 to i64
  %arrayidx = getelementptr inbounds float, float* %pos_x, i64 %idxprom
  %0 = load float, float* %arrayidx, align 4
  %idxprom4 = sext i32 %id.0 to i64
  %arrayidx5 = getelementptr inbounds float, float* %pos_x, i64 %idxprom4
  %1 = load float, float* %arrayidx5, align 4
  %sub = fsub float %0, %1
  %idxprom6 = sext i32 %j.0 to i64
  %arrayidx7 = getelementptr inbounds float, float* %pos_y, i64 %idxprom6
  %2 = load float, float* %arrayidx7, align 4
  %idxprom8 = sext i32 %id.0 to i64
  %arrayidx9 = getelementptr inbounds float, float* %pos_y, i64 %idxprom8
  %3 = load float, float* %arrayidx9, align 4
  %sub10 = fsub float %2, %3
  %idxprom11 = sext i32 %j.0 to i64
  %arrayidx12 = getelementptr inbounds float, float* %pos_z, i64 %idxprom11
  %4 = load float, float* %arrayidx12, align 4
  %idxprom13 = sext i32 %id.0 to i64
  %arrayidx14 = getelementptr inbounds float, float* %pos_z, i64 %idxprom13
  %5 = load float, float* %arrayidx14, align 4
  %sub15 = fsub float %4, %5
  %mul = fmul float %sub, %sub
  %mul16 = fmul float %sub10, %sub10
  %add = fadd float %mul, %mul16
  %mul17 = fmul float %sub15, %sub15
  %add18 = fadd float %add, %mul17
  %conv = fpext float %add18 to double
  %call = call double @sqrt(double %conv) #2
  %conv19 = fptrunc double %call to float
  %mul20 = fmul float %conv19, %conv19
  %mul21 = fmul float %mul20, %conv19
  %cmp22 = fcmp oeq float %mul21, 0.000000e+00
  br i1 %cmp22, label %cond.true, label %cond.false

cond.true:                                        ; preds = %for.body3
  br label %cond.end

cond.false:                                       ; preds = %for.body3
  %div = fdiv float 1.000000e+00, %mul21
  %add24 = fadd float %div, %epsilon
  br label %cond.end

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi float [ 0.000000e+00, %cond.true ], [ %add24, %cond.false ]
  %idxprom25 = sext i32 %j.0 to i64
  %arrayidx26 = getelementptr inbounds float, float* %masses, i64 %idxprom25
  %6 = load float, float* %arrayidx26, align 4
  %mul27 = fmul float %cond, %6
  %mul28 = fmul float %mul27, %sub
  %add29 = fadd float %acc_x.0, %mul28
  %mul30 = fmul float %mul27, %sub10
  %add31 = fadd float %acc_y.0, %mul30
  %mul32 = fmul float %mul27, %sub15
  %add33 = fadd float %acc_z.0, %mul32
  br label %for.inc

for.inc:                                          ; preds = %cond.end
  %inc = add nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond1
  %mul34 = fmul float %acc_x.0, %dt
  %idxprom35 = sext i32 %id.0 to i64
  %arrayidx36 = getelementptr inbounds float, float* %vel_x, i64 %idxprom35
  %7 = load float, float* %arrayidx36, align 4
  %add37 = fadd float %7, %mul34
  store float %add37, float* %arrayidx36, align 4
  %mul38 = fmul float %acc_y.0, %dt
  %idxprom39 = sext i32 %id.0 to i64
  %arrayidx40 = getelementptr inbounds float, float* %vel_y, i64 %idxprom39
  %8 = load float, float* %arrayidx40, align 4
  %add41 = fadd float %8, %mul38
  store float %add41, float* %arrayidx40, align 4
  %mul42 = fmul float %acc_z.0, %dt
  %idxprom43 = sext i32 %id.0 to i64
  %arrayidx44 = getelementptr inbounds float, float* %vel_z, i64 %idxprom43
  %9 = load float, float* %arrayidx44, align 4
  %add45 = fadd float %9, %mul42
  store float %add45, float* %arrayidx44, align 4
  br label %for.inc46

for.inc46:                                        ; preds = %for.end
  %inc47 = add nsw i32 %id.0, 1
  br label %for.cond

for.end48:                                        ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind readnone
declare double @sqrt(double) #1

attributes #0 = { noinline nounwind ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone }
