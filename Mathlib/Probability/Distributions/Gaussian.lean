/-
Copyright (c) 2023 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lorenzo Luccioli, Rémy Degenne
-/
import Mathlib.Analysis.SpecialFunctions.Gaussian
import Mathlib.Probability.Notation

/-!
# Gaussian distributions over ℝ

We define a Gaussian measure over the reals.

## Main definitions

* `gaussianPdfReal`: the function `μ v x ↦ (1 / (sqrt (2 * pi * v))) * exp (- (x - μ)^2 / (2 * v))`,
  which is the probability density function of a Gaussian distribution with mean `μ` and
  variance `v` (when `v ≠ 0`).
* `gaussianPdf`: `ℝ≥0∞`-valued pdf, `gaussianPdf μ v x = ENNReal.ofReal (gaussianPdfReal μ v x)`.
* `gaussianReal`: a Gaussian measure on `ℝ`, parametrized by its mean `μ` and variance `v`.
  If `v = 0`, this is `dirac μ`, otherwise it is defined as the measure with density
  `gaussianPdf μ v` with respect to the Lebesgue measure.

-/

open scoped ENNReal NNReal Real

open MeasureTheory

local macro_rules | `($x ^ $y) => `(HPow.hPow $x $y) -- Porting note: See issue lean4#2220

namespace ProbabilityTheory

section GaussianPdf

/-- Probability density function of the gaussian distribution with mean `μ` and variance `v`. -/
noncomputable
def gaussianPdfReal (μ : ℝ) (v : ℝ≥0) (x : ℝ) : ℝ :=
  (Real.sqrt (2 * π * v))⁻¹ * rexp (- (x - μ)^2 / (2 * v))

lemma gaussianPdfReal_def (μ : ℝ) (v : ℝ≥0) :
    gaussianPdfReal μ v =
      fun x ↦ (Real.sqrt (2 * π * v))⁻¹ * rexp (- (x - μ)^2 / (2 * v)) := rfl

@[simp]
lemma gaussianPdfReal_zero_var (m : ℝ) : gaussianPdfReal m 0 = 0 := by
  ext1 x
  simp [gaussianPdfReal]

/-- The gaussian pdf is positive when the variance is not zero. -/
lemma gaussianPdfReal_pos (μ : ℝ) (v : ℝ≥0) (x : ℝ) (hv : v ≠ 0) : 0 < gaussianPdfReal μ v x := by
  rw [gaussianPdfReal]
  positivity

/--The gaussian pdf is nonnegative. -/
lemma gaussianPdfReal_nonneg (μ : ℝ) (v : ℝ≥0) (x : ℝ) : 0 ≤ gaussianPdfReal μ v x := by
  rw [gaussianPdfReal]
  positivity

/-- The gaussian pdf is measurable. -/
lemma measurable_gaussianPdfReal (μ : ℝ) (v : ℝ≥0) : Measurable (gaussianPdfReal μ v) :=
  (((measurable_id.add_const _).pow_const _).neg.div_const _).exp.const_mul _

/-- The gaussian pdf is strongly measurable. -/
lemma stronglyMeasurable_gaussianPdfReal (μ : ℝ) (v : ℝ≥0) :
    StronglyMeasurable (gaussianPdfReal μ v) :=
  (measurable_gaussianPdfReal μ v).stronglyMeasurable

lemma integrable_gaussianPdfReal (μ : ℝ) (v : ℝ≥0) :
    Integrable (gaussianPdfReal μ v) := by
  rw [gaussianPdfReal_def]
  by_cases hv : v = 0
  · simp [hv]
  let g : ℝ → ℝ := fun x ↦ (Real.sqrt (2 * π * v))⁻¹ * rexp (- x ^ 2 / (2 * v))
  have hg : Integrable g := by
    suffices g = fun x ↦ (Real.sqrt (2 * π * v))⁻¹ * rexp (- (2 * v)⁻¹ * x ^ 2) by
      rw [this]
      refine (integrable_exp_neg_mul_sq ?_).const_mul (Real.sqrt (2 * π * v))⁻¹
      simp [lt_of_le_of_ne (zero_le _) (Ne.symm hv)]
    ext x
    simp only [gt_iff_lt, zero_lt_two, zero_le_mul_left, NNReal.zero_le_coe, Real.sqrt_mul',
      mul_inv_rev, NNReal.coe_mul, NNReal.coe_inv, NNReal.coe_ofNat, neg_mul, mul_eq_mul_left_iff,
      Real.exp_eq_exp, mul_eq_zero, inv_eq_zero, Real.sqrt_eq_zero, NNReal.coe_eq_zero, hv,
      false_or]
    rw [mul_comm]
    left
    field_simp
  exact Integrable.comp_sub_right hg μ

/-- The gaussian distribution pdf integrates to 1 when the variance is not zero.  -/
lemma lintegral_gaussianPdfReal_eq_one (μ : ℝ) {v : ℝ≥0} (h : v ≠ 0) :
    ∫⁻ x, ENNReal.ofReal (gaussianPdfReal μ v x) = 1 := by
  rw [←ENNReal.toReal_eq_one_iff]
  have hfm : AEStronglyMeasurable (gaussianPdfReal μ v) volume :=
    (stronglyMeasurable_gaussianPdfReal μ v).aestronglyMeasurable
  have hf : 0 ≤ₐₛ gaussianPdfReal μ v := ae_of_all _ (gaussianPdfReal_nonneg μ v)
  rw [← integral_eq_lintegral_of_nonneg_ae hf hfm]
  simp only [gaussianPdfReal, gt_iff_lt, zero_lt_two, zero_le_mul_right, ge_iff_le, one_div,
    Nat.cast_ofNat, integral_mul_left]
  rw [integral_sub_right_eq_self (μ := volume) (fun a ↦ rexp (-a ^ 2 / ((2 : ℝ) * v))) μ]
  simp only [gt_iff_lt, zero_lt_two, zero_le_mul_right, ge_iff_le, div_eq_inv_mul, mul_inv_rev,
    mul_neg]
  simp_rw [←neg_mul]
  rw [neg_mul, integral_gaussian, ← Real.sqrt_inv, ←Real.sqrt_mul]
  · field_simp
    ring
  · positivity

/-- The gaussian distribution pdf integrates to 1 when the variance is not zero.  -/
lemma integral_gaussianPdfReal_eq_one (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) :
    ∫ x, gaussianPdfReal μ v x = 1 := by
  have h := lintegral_gaussianPdfReal_eq_one μ hv
  rw [← ofReal_integral_eq_lintegral_ofReal (integrable_gaussianPdfReal _ _)
    (ae_of_all _ (gaussianPdfReal_nonneg _ _)), ← ENNReal.ofReal_one] at h
  rwa [← ENNReal.ofReal_eq_ofReal_iff (integral_nonneg (gaussianPdfReal_nonneg _ _)) zero_le_one]

/-- The pdf of a Gaussian distribution on ℝ with mean `μ` and variance `v`. -/
noncomputable
def gaussianPdf (μ : ℝ) (v : ℝ≥0) (x : ℝ) : ℝ≥0∞ := ENNReal.ofReal (gaussianPdfReal μ v x)

lemma gaussianPdf_def (μ : ℝ) (v : ℝ≥0) :
    gaussianPdf μ v = fun x ↦ ENNReal.ofReal (gaussianPdfReal μ v x) := rfl

@[simp]
lemma gaussianPdf_zero_var (μ : ℝ) : gaussianPdf μ 0 = 0 := by
  ext
  simp [gaussianPdf]

lemma gaussianPdf_pos (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) (x : ℝ) : 0 < gaussianPdf μ v x := by
  rw [gaussianPdf, ENNReal.ofReal_pos]
  exact gaussianPdfReal_pos _ _ _ hv

@[measurability]
lemma measurable_gaussianPdf (μ : ℝ) (v : ℝ≥0) : Measurable (gaussianPdf μ v) :=
  (measurable_gaussianPdfReal _ _).ennreal_ofReal

@[simp]
lemma lintegral_gaussianPdf_eq_one (μ : ℝ) {v : ℝ≥0} (h : v ≠ 0) :
    ∫⁻ x, gaussianPdf μ v x = 1 :=
  lintegral_gaussianPdfReal_eq_one μ h

end GaussianPdf

section GaussianReal

/-- A Gaussian distribution on `ℝ` with mean `μ` and variance `v`. -/
noncomputable
def gaussianReal (μ : ℝ) (v : ℝ≥0) : Measure ℝ :=
  if v = 0 then Measure.dirac μ else volume.withDensity (gaussianPdf μ v)

lemma gaussianReal_of_var_ne_zero (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) :
    gaussianReal μ v = volume.withDensity (gaussianPdf μ v) := if_neg hv

@[simp]
lemma gaussianReal_zero_var (μ : ℝ) : gaussianReal μ 0 = Measure.dirac μ := if_pos rfl

instance instIsProbabilityMeasureGaussianReal (μ : ℝ) (v : ℝ≥0) :
    IsProbabilityMeasure (gaussianReal μ v) where
  measure_univ := by by_cases h : v = 0 <;> simp [gaussianReal_of_var_ne_zero, h]

lemma gaussianReal_apply (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) {s : Set ℝ} (hs : MeasurableSet s) :
    gaussianReal μ v s = ∫⁻ x in s, gaussianPdf μ v x := by
  rw [gaussianReal_of_var_ne_zero _ hv, withDensity_apply _ hs]

lemma gaussianReal_apply_eq_integral (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0)
    {s : Set ℝ} (hs : MeasurableSet s) :
    gaussianReal μ v s = ENNReal.ofReal (∫ x in s, gaussianPdfReal μ v x) := by
  rw [gaussianReal_apply _ hv hs, ofReal_integral_eq_lintegral_ofReal]
  · rfl
  · exact (integrable_gaussianPdfReal _ _).restrict
  · exact ae_of_all _ (gaussianPdfReal_nonneg _ _)

lemma gaussianReal_absolutelyContinuous (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) :
    gaussianReal μ v ≪ volume := by
  rw [gaussianReal_of_var_ne_zero _ hv]
  exact withDensity_absolutelyContinuous _ _

lemma gaussianReal_absolutelyContinuous' (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) :
    volume ≪ gaussianReal μ v := by
  rw [gaussianReal_of_var_ne_zero _ hv]
  refine withDensity_absolutelyContinuous' ?_ ?_ ?_
  · exact (measurable_gaussianPdf _ _).aemeasurable
  · exact ae_of_all _ (fun _ ↦ (gaussianPdf_pos _ hv _).ne')
  · exact ae_of_all _ (fun _ ↦ ENNReal.ofReal_ne_top)

lemma rnDeriv_gaussianReal (μ : ℝ) (v : ℝ≥0) :
    ∂(gaussianReal μ v)/∂volume =ₐₛ gaussianPdf μ v := by
  by_cases hv : v = 0
  · simp only [hv, gaussianReal_zero_var, gaussianPdf_zero_var]
    refine (Measure.eq_rnDeriv measurable_zero (mutuallySingular_dirac μ volume) ?_).symm
    rw [withDensity_zero, add_zero]
  · rw [gaussianReal_of_var_ne_zero _ hv]
    exact Measure.rnDeriv_withDensity _ (measurable_gaussianPdf μ v)

end GaussianReal

end ProbabilityTheory
