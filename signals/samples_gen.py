#!/usr/bin/env python3
"""
Generate synthetic bladeRF-style Channel 1 IQ samples for FPGA FFT verification.

Outputs interleaved int16 [I, Q, I, Q, ...] binary, matching the slice_data.py format.
A single complex tone at a configurable frequency offset from center is generated,
so you can verify that your FPGA FFT places the bin in the correct location.
"""

import argparse
import numpy as np
import matplotlib.pyplot as plt


def generate_tone(num_samples, freq_offset, fs, amplitude=0.9, noise_std=0.0):
    """
    Generate a complex tone at *freq_offset* Hz from DC.

    Parameters
    ----------
    num_samples : int
        Number of complex IQ samples to produce.
    freq_offset : float
        Tone frequency offset from center in Hz (can be negative).
    fs : float
        Sample rate in Hz.
    amplitude : float
        Tone amplitude as a fraction of full-scale int16 (0..1).
    noise_std : float
        Optional additive Gaussian noise std-dev as a fraction of full-scale.

    Returns
    -------
    ch1_i, ch1_q : ndarray[int16]
        Raw I and Q arrays.
    ch1 : ndarray[complex128]
        Complex-valued samples for plotting.
    """
    t = np.arange(num_samples) / fs
    phase = 2.0 * np.pi * freq_offset * t
    iq = amplitude * np.exp(1j * phase)

    if noise_std > 0:
        noise = noise_std * (np.random.randn(num_samples) +
                             1j * np.random.randn(num_samples))
        iq += noise

    # Scale to int16 range (-32768 .. 32767)
    scale = 32767.0
    i_f = np.clip(iq.real * scale, -32768, 32767)
    q_f = np.clip(iq.imag * scale, -32768, 32767)

    ch1_i = np.round(i_f).astype(np.int16)
    ch1_q = np.round(q_f).astype(np.int16)

    ch1 = ch1_i.astype(np.float64) + 1j * ch1_q.astype(np.float64)
    return ch1_i, ch1_q, ch1


def save_samples(ch1_i, ch1_q, out_bin, out_hex=None):
    """
    Save IQ data as interleaved int16 binary (and optional hex text).
    """
    interleaved = np.empty(len(ch1_i) * 2, dtype=np.int16)
    interleaved[0::2] = ch1_i
    interleaved[1::2] = ch1_q
    interleaved.tofile(out_bin)
    print(f"Saved {len(ch1_i)} IQ samples to {out_bin}")

    if out_hex is not None:
        with open(out_hex, "w") as f:
            for i, q in zip(ch1_i, ch1_q):
                f.write(f"{i & 0xFFFF:04X}{q & 0xFFFF:04X}\n")
        print(f"Saved hex IQ pairs to {out_hex}")


def plot_fft(ch1, fs, freq_offset, title="Generated Tone FFT"):
    """
    Plot magnitude spectrum and time-domain waveform.
    """
    N = len(ch1)
    window = np.hanning(N)
    spectrum = np.fft.fftshift(np.fft.fft(ch1 * window))
    mag_db = 20 * np.log10(np.abs(spectrum) + 1e-12)
    freqs = np.fft.fftshift(np.fft.fftfreq(N, d=1.0 / fs))

    fig, axes = plt.subplots(2, 1, figsize=(14, 8))

    # --- magnitude spectrum ---
    axes[0].plot(freqs / 1e6, mag_db, linewidth=0.6)
    axes[0].axvline(x=freq_offset / 1e6, color='r', linestyle='--',
                    linewidth=1, alpha=0.7, label=f"Tone @ {freq_offset/1e6:.3f} MHz")
    axes[0].set_xlabel("Frequency (MHz)")
    axes[0].set_ylabel("Magnitude (dB)")
    axes[0].set_title(title)
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    # --- time-domain I/Q (show first 256 samples max for clarity) ---
    show = min(N, 256)
    t = np.arange(show) / fs * 1e6  # µs
    axes[1].plot(t, ch1[:show].real, linewidth=0.5, label="I", alpha=0.8)
    axes[1].plot(t, ch1[:show].imag, linewidth=0.5, label="Q", alpha=0.8)
    axes[1].set_xlabel("Time (µs)")
    axes[1].set_ylabel("Amplitude (int16)")
    axes[1].set_title(f"Time Domain (first {show} samples)")
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()


def main():
    parser = argparse.ArgumentParser(
        description="Generate synthetic int16 IQ samples with a single tone "
                    "for FPGA FFT verification."
    )
    parser.add_argument(
        "length",
        type=int,
        help="Number of complex IQ samples to generate.",
    )
    parser.add_argument(
        "freq_offset",
        type=float,
        help="Tone frequency offset from center in Hz (can be negative).",
    )
    parser.add_argument(
        "-o", "--output",
        default="gen_samples.bin",
        help="Output binary file (default: gen_samples.bin).",
    )
    parser.add_argument(
        "--hex",
        default=None,
        metavar="FILE",
        help="Also write a hex text file (one IQ pair per line) for FPGA sim.",
    )
    parser.add_argument(
        "-fs", "--sample-rate",
        type=float,
        default=40e6,
        help="Sample rate in Hz (default: 40 MHz).",
    )
    parser.add_argument(
        "-a", "--amplitude",
        type=float,
        default=0.9,
        help="Tone amplitude as fraction of full-scale (0..1, default: 0.9).",
    )
    parser.add_argument(
        "-n", "--noise",
        type=float,
        default=0.0,
        help="Additive Gaussian noise std-dev as fraction of full-scale (default: 0).",
    )

    args = parser.parse_args()

    print(f"Generating {args.length} samples, tone @ {args.freq_offset/1e6:.6f} MHz offset, "
          f"fs = {args.sample_rate/1e6:.1f} MHz ...")
    ch1_i, ch1_q, ch1 = generate_tone(
        args.length, args.freq_offset, args.sample_rate,
        amplitude=args.amplitude, noise_std=args.noise,
    )

    save_samples(ch1_i, ch1_q, args.output, args.hex)
    plot_fft(ch1, args.sample_rate, args.freq_offset,
             title=f"Generated Tone FFT – {args.length} samples, "
                   f"offset {args.freq_offset/1e6:.3f} MHz")


if __name__ == "__main__":
    main()
