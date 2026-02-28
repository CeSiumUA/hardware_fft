# samples_gen.py

Generate synthetic int16 IQ samples with a single complex tone for FPGA FFT verification.

Outputs interleaved `[I, Q, I, Q, ...]` little-endian int16 binary, matching the format produced by `slice_data.py` and consumed by the VHDL testbench (`fft_tb.vhd`).

## Usage

```
python samples_gen.py <length> <freq_offset> [options]
```

### Positional Arguments

| Argument | Description |
|---|---|
| `length` | Number of complex IQ samples to generate |
| `freq_offset` | Tone frequency offset from center in Hz (can be negative) |

### Options

| Flag | Default | Description |
|---|---|---|
| `-o`, `--output` | `gen_samples.bin` | Output binary file path |
| `--hex FILE` | — | Also write a hex text file (one `IIIIQQQQQ` pair per line) for FPGA simulation |
| `-fs`, `--sample-rate` | `40e6` (40 MHz) | Sample rate in Hz |
| `-a`, `--amplitude` | `0.9` | Tone amplitude as a fraction of full-scale int16 (0–1) |
| `-n`, `--noise` | `0.0` | Additive Gaussian noise std-dev as a fraction of full-scale |

## Examples

Generate 64 samples with a 5 MHz tone:

```bash
python samples_gen.py 64 5e6 -o tone_5mhz.bin
```

Generate 128 samples with a −2.5 MHz tone, 10% noise, plus a hex file for simulation:

```bash
python samples_gen.py 128 -2.5e6 -o tone_neg2p5.bin --hex tone_neg2p5.hex -n 0.1
```

Generate 32 samples at half amplitude for the FPGA testbench:

```bash
python samples_gen.py 32 10e6 -a 0.5 -o test_input.bin
```

## Output Format

- **Binary** (`.bin`): Interleaved int16 little-endian — each sample is 4 bytes (2 for I, 2 for Q).
- **Hex** (optional): One line per sample, format `IIIIQQQQQ` (16-bit two's complement hex, I then Q).

## Dependencies

- Python 3
- NumPy
- Matplotlib (for the FFT / time-domain plot displayed after generation)
