# Y.hex — what's in it and how it was made

Your `.mat` is a MATLAB v7.3 file (HDF5-based). No HDF5 library or network
access was available in this environment, so I wrote a minimal pure-Python
HDF5 reader (`hdf5mini.py`) to pull the data out directly — that's what
`extract_Y_hex.py` uses. Rerun it any time you want a different frame.

## What I actually found in the file (not assumed)

- `RcvData{1}` is `int16`, MATLAB size **192000 samples × 64 channel-slots × 30 frames**.
  Only the first **32** channel-slots are populated (`Trans.numelements = 32`);
  the rest are unused buffer space, always zero.
- `TX` has **75** entries → **75 TX events**, not 8. (The "8 TX elements" in your
  message was a conceptual example — this dataset is a 75-event synthetic
  aperture acquisition on a 32-element array.)
- `Receive.startSample`/`endSample` show each of the 75 acquisitions is
  exactly **1536 samples**, back-to-back, restarting at sample 1 each frame
  (75 × 1536 = 115200 samples actually used per frame, out of the 192000 allocated).
- `Receive.Apod` for these events is all-ones over 32 channels → full-aperture receive.
- `Trans.Connector = [32, 31, ..., 1]` — **channel c in the data maps to physical
  element (33 − c)**, i.e. the channel order is reversed relative to element order.
  Y.hex is written in raw channel order (as stored); remap through this table
  if your beamformer indexes by physical element.

## Assumption I had to make

The file has **30 frames**; you didn't say which one you want, so `Y.hex`
uses **frame 1** only. Rerun `extract_Y_hex.py` with `FRAME_IDX = n` for
another frame, or concatenate several if your Vivado testbench needs more
than one.

## Y.hex format

- Plain text, one value per line, 4 hex digits, **signed 16-bit two's complement**
  (e.g. `-6` → `FFFA`) — directly loadable with Vivado's `$readmemh`.
- Flattened in the order **TX event (outer) → RX channel → time sample (inner)**,
  exactly as in your `Y[event][channel][sample]` description:
  - event = 0..74
  - channel = 0..31
  - sample = 0..1535
- Total lines: 75 × 32 × 1536 = **3,686,400**.
- Line index for `Y[e][c][s]` = `e*32*1536 + c*1536 + s` (0-indexed).

## Files

- `Y.hex` — the data.
- `extract_Y_hex.py` — regenerate for a different frame / channel count.
- `hdf5mini.py` — the minimal HDF5 reader `extract_Y_hex.py` depends on.
