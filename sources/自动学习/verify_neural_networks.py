"""Deterministic checks for 32_神经网络严谨方法卡.md.

This script uses only NumPy. It verifies mathematical identities and code/formula
consistency; it does not make any empirical performance claim.
"""

from __future__ import annotations

import json
import math

import numpy as np


def sigmoid_stable(x: np.ndarray) -> np.ndarray:
    x = np.asarray(x, dtype=float)
    out = np.empty_like(x)
    pos = x >= 0
    out[pos] = 1.0 / (1.0 + np.exp(-x[pos]))
    ex = np.exp(x[~pos])
    out[~pos] = ex / (1.0 + ex)
    return out


def softmax_stable(x: np.ndarray, axis: int = -1) -> np.ndarray:
    x = np.asarray(x, dtype=float)
    shifted = x - np.max(x, axis=axis, keepdims=True)
    ex = np.exp(shifted)
    return ex / np.sum(ex, axis=axis, keepdims=True)


def unpack(theta: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    w1 = theta[:6].reshape(3, 2)
    b1 = theta[6:9]
    w2 = theta[9:12].reshape(1, 3)
    b2 = theta[12:13]
    return w1, b1, w2, b2


def mlp_loss_and_grad(
    theta: np.ndarray, x: np.ndarray, y: np.ndarray
) -> tuple[float, np.ndarray]:
    """Two-layer tanh MLP with a stable binary cross-entropy-from-logits loss."""
    w1, b1, w2, b2 = unpack(theta)
    z1 = x @ w1.T + b1
    a1 = np.tanh(z1)
    logits = a1 @ w2.T + b2
    loss = float(np.mean(np.logaddexp(0.0, logits) - y * logits))

    # D2 includes the batch mean, matching the method card's convention.
    d2 = (sigmoid_stable(logits) - y) / x.shape[0]
    gw2 = d2.T @ a1
    gb2 = d2.sum(axis=0)
    d1 = (d2 @ w2) * (1.0 - a1**2)
    gw1 = d1.T @ x
    gb1 = d1.sum(axis=0)
    grad = np.concatenate([gw1.ravel(), gb1, gw2.ravel(), gb2])
    return loss, grad


def central_difference(
    theta: np.ndarray, x: np.ndarray, y: np.ndarray, eps: float = 1e-6
) -> np.ndarray:
    grad = np.empty_like(theta)
    for j in range(theta.size):
        plus = theta.copy()
        minus = theta.copy()
        plus[j] += eps
        minus[j] -= eps
        lp, _ = mlp_loss_and_grad(plus, x, y)
        lm, _ = mlp_loss_and_grad(minus, x, y)
        grad[j] = (lp - lm) / (2.0 * eps)
    return grad


def valid_cross_correlation_2d(x: np.ndarray, kernel: np.ndarray) -> np.ndarray:
    h_out = x.shape[0] - kernel.shape[0] + 1
    w_out = x.shape[1] - kernel.shape[1] + 1
    out = np.empty((h_out, w_out), dtype=float)
    for i in range(h_out):
        for j in range(w_out):
            patch = x[i : i + kernel.shape[0], j : j + kernel.shape[1]]
            out[i, j] = np.sum(patch * kernel)
    return out


def conv_output_size(
    size: int, kernel: int, padding: int, stride: int, dilation: int
) -> int:
    return math.floor(
        (size + 2 * padding - dilation * (kernel - 1) - 1) / stride + 1
    )


def clip_by_global_norm(g: np.ndarray, threshold: float) -> np.ndarray:
    norm = np.linalg.norm(g)
    if norm <= threshold:
        return g.copy()
    return g * (threshold / norm)


def main() -> None:
    results: dict[str, object] = {}

    logits = np.array([[1000.0, 1001.0, 999.0], [-1000.0, -999.0, -1001.0]])
    p = softmax_stable(logits)
    p_shifted = softmax_stable(logits + 12345.0)
    softmax_sum_error = float(np.max(np.abs(p.sum(axis=1) - 1.0)))
    softmax_shift_error = float(np.max(np.abs(p - p_shifted)))
    assert softmax_sum_error < 1e-15
    assert softmax_shift_error < 1e-12
    results["softmax_max_sum_error"] = softmax_sum_error
    results["softmax_max_shift_error"] = softmax_shift_error

    x = np.array([[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]])
    y = np.array([[0.0], [1.0], [1.0], [0.0]])
    theta = np.linspace(-0.35, 0.40, 13)
    loss, analytic = mlp_loss_and_grad(theta, x, y)
    numeric = central_difference(theta, x, y)
    max_abs = float(np.max(np.abs(analytic - numeric)))
    rel = float(
        np.linalg.norm(analytic - numeric)
        / max(1.0, np.linalg.norm(analytic), np.linalg.norm(numeric))
    )
    assert max_abs < 1e-8
    assert rel < 1e-8
    results["mlp_initial_loss"] = loss
    results["mlp_gradient_max_abs_error"] = max_abs
    results["mlp_gradient_relative_error"] = rel

    # The prose uses z as the retention gate; Algorithm 17.8 reverses the weights.
    z = 0.8
    h_old = 0.5
    h_candidate = -0.5
    gru_prose = z * h_old + (1.0 - z) * h_candidate
    gru_algorithm_17_8 = (1.0 - z) * h_old + z * h_candidate
    assert not np.isclose(gru_prose, gru_algorithm_17_8)
    results["gru_prose_value"] = gru_prose
    results["gru_algorithm_17_8_value"] = gru_algorithm_17_8

    image = np.arange(1.0, 10.0).reshape(3, 3)
    kernel = np.array([[1.0, 0.0], [0.0, -1.0]])
    cross_corr = valid_cross_correlation_2d(image, kernel)
    mathematical_conv = valid_cross_correlation_2d(image, np.flip(kernel))
    assert np.array_equal(cross_corr, np.full((2, 2), -4.0))
    assert np.array_equal(mathematical_conv, np.full((2, 2), 4.0))
    results["cross_correlation_output"] = cross_corr.tolist()
    results["kernel_flipped_convolution_output"] = mathematical_conv.tolist()

    shape_cases = [
        (5, 3, 0, 1, 1, 3),
        (5, 3, 1, 1, 1, 5),
        (7, 3, 1, 2, 1, 4),
        (9, 3, 2, 2, 2, 5),
    ]
    for size, kernel_size, padding, stride, dilation, expected in shape_cases:
        assert conv_output_size(size, kernel_size, padding, stride, dilation) == expected
    results["conv_output_size_cases"] = len(shape_cases)

    g = np.array([3.0, 4.0])
    clipped = clip_by_global_norm(g, 2.0)
    assert np.isclose(np.linalg.norm(clipped), 2.0)
    assert np.allclose(clipped, np.array([1.2, 1.6]))
    results["clipped_gradient"] = clipped.tolist()

    # Valid LSTM gates can be arbitrarily close to one, so repeated additions can
    # make c_t large even though h_t remains bounded by tanh and the output gate.
    f = float(sigmoid_stable(np.array([20.0]))[0])
    i = float(sigmoid_stable(np.array([20.0]))[0])
    o = float(sigmoid_stable(np.array([20.0]))[0])
    candidate = math.tanh(20.0)
    cell = 0.0
    for _ in range(20):
        cell = f * cell + i * candidate
    hidden = o * math.tanh(cell)
    assert cell > 10.0
    assert abs(hidden) < 1.0
    results["lstm_cell_after_20_steps"] = cell
    results["lstm_hidden_after_20_steps"] = hidden

    print(json.dumps({"status": "PASS", "results": results}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
