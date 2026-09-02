"""Deterministic numerical checks for the EM/GMM knowledge card.

This script proves only formula/code consistency on small synthetic arrays. It
does not establish statistical performance on external data.
"""

from __future__ import annotations

import json
import math

import numpy as np


def logsumexp(a: np.ndarray, axis: int) -> np.ndarray:
    m = np.max(a, axis=axis, keepdims=True)
    return np.squeeze(m, axis=axis) + np.log(
        np.sum(np.exp(a - m), axis=axis)
    )


def log_normal_1d(x: np.ndarray, means: np.ndarray, variances: np.ndarray) -> np.ndarray:
    return -0.5 * (
        math.log(2.0 * math.pi)
        + np.log(variances)[None, :]
        + (x[:, None] - means[None, :]) ** 2 / variances[None, :]
    )


def log_joint(
    x: np.ndarray, weights: np.ndarray, means: np.ndarray, variances: np.ndarray
) -> np.ndarray:
    return np.log(weights)[None, :] + log_normal_1d(x, means, variances)


def e_step(
    x: np.ndarray, weights: np.ndarray, means: np.ndarray, variances: np.ndarray
) -> tuple[np.ndarray, float]:
    joint = log_joint(x, weights, means, variances)
    log_marginal = logsumexp(joint, axis=1)
    responsibilities = np.exp(joint - log_marginal[:, None])
    return responsibilities, float(np.sum(log_marginal))


def m_step(x: np.ndarray, responsibilities: np.ndarray) -> tuple[np.ndarray, ...]:
    effective_counts = responsibilities.sum(axis=0)
    weights = effective_counts / x.size
    means = (responsibilities * x[:, None]).sum(axis=0) / effective_counts
    variances = (
        responsibilities * (x[:, None] - means[None, :]) ** 2
    ).sum(axis=0) / effective_counts
    return weights, means, variances


def elbo_and_kl(
    x: np.ndarray,
    q: np.ndarray,
    weights: np.ndarray,
    means: np.ndarray,
    variances: np.ndarray,
) -> tuple[float, float, float]:
    joint = log_joint(x, weights, means, variances)
    log_marginal = logsumexp(joint, axis=1)
    posterior = np.exp(joint - log_marginal[:, None])
    elbo = float(np.sum(q * (joint - np.log(q))))
    kl = float(np.sum(q * (np.log(q) - np.log(posterior))))
    return float(np.sum(log_marginal)), elbo, kl


def degeneracy_loglik(scale: float) -> float:
    x = np.array([-2.0, 0.0, 2.0])
    weights = np.array([0.1, 0.9])
    means = np.array([0.0, 0.0])
    variances = np.array([scale**2, 4.0])
    return e_step(x, weights, means, variances)[1]


def main() -> None:
    x = np.array([-3.2, -2.7, -2.4, 2.0, 2.3, 2.8], dtype=float)
    weights = np.array([0.5, 0.5], dtype=float)
    means = np.array([-1.0, 1.0], dtype=float)
    variances = np.array([2.0, 2.0], dtype=float)

    _, initial_loglik = e_step(x, weights, means, variances)
    trajectory = [initial_loglik]
    max_row_sum_error = 0.0

    for _ in range(50):
        responsibilities, _ = e_step(x, weights, means, variances)
        max_row_sum_error = max(
            max_row_sum_error,
            float(np.max(np.abs(responsibilities.sum(axis=1) - 1.0))),
        )
        weights, means, variances = m_step(x, responsibilities)
        _, new_loglik = e_step(x, weights, means, variances)
        trajectory.append(new_loglik)
        if abs(trajectory[-1] - trajectory[-2]) <= 1e-12 * (
            1.0 + abs(trajectory[-2])
        ):
            break

    increments = np.diff(np.asarray(trajectory))
    posterior, final_loglik = e_step(x, weights, means, variances)
    identity_loglik, posterior_elbo, posterior_kl = elbo_and_kl(
        x, posterior, weights, means, variances
    )
    arbitrary_q = np.tile(np.array([0.4, 0.6]), (x.size, 1))
    arbitrary_loglik, arbitrary_elbo, arbitrary_kl = elbo_and_kl(
        x, arbitrary_q, weights, means, variances
    )

    swapped_loglik = e_step(
        x, weights[::-1], means[::-1], variances[::-1]
    )[1]
    scales = [1e-1, 1e-2, 1e-3]
    degeneracy = [degeneracy_loglik(scale) for scale in scales]

    checks = {
        "responsibilities_sum_to_one": max_row_sum_error < 1e-14,
        "observed_loglik_nondecreasing": bool(np.min(increments) >= -1e-12),
        "elbo_identity_arbitrary_q": abs(
            arbitrary_loglik - (arbitrary_elbo + arbitrary_kl)
        ) < 1e-10,
        "posterior_makes_elbo_tight": abs(
            identity_loglik - posterior_elbo
        ) < 1e-10
        and abs(posterior_kl) < 1e-10,
        "label_switching_preserves_likelihood": abs(
            final_loglik - swapped_loglik
        ) < 1e-12,
        "smaller_variance_can_raise_gmm_likelihood_without_bound": bool(
            np.all(np.diff(degeneracy) > 0.0)
        ),
        "weights_are_normalized": abs(float(weights.sum()) - 1.0) < 1e-14,
        "variances_are_positive_in_this_example": bool(np.all(variances > 0.0)),
    }

    result = {
        "scope": "deterministic formula/code checks; not an empirical benchmark",
        "iterations": len(trajectory) - 1,
        "initial_loglik": initial_loglik,
        "final_loglik": final_loglik,
        "minimum_loglik_increment": float(np.min(increments)),
        "max_responsibility_row_sum_error": max_row_sum_error,
        "final_weights": weights.tolist(),
        "final_means": means.tolist(),
        "final_variances": variances.tolist(),
        "arbitrary_q_identity_error": abs(
            arbitrary_loglik - (arbitrary_elbo + arbitrary_kl)
        ),
        "posterior_kl": posterior_kl,
        "label_swap_loglik_error": abs(final_loglik - swapped_loglik),
        "degeneracy_scales": scales,
        "degeneracy_loglik": degeneracy,
        "checks": checks,
        "all_checks_passed": all(checks.values()),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))

    if not result["all_checks_passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
