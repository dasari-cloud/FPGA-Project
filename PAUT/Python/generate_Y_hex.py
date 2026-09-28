"""
Export one frame of Verasonics RcvData from a MATLAB v7.3 (.mat) file to a
Vivado $readmemh hex file.

Requires: numpy, h5py  (pip install h5py numpy)

Usage:
    python generate_Y_hex.py simulated3by3pointscattereratangle.mat Y.hex 1
"""
import sys
import h5py
import numpy as np


def generate_Y_hex(mat_path, out_path='Y.hex', frame_idx=1):
    """frame_idx is 1-based, matching MATLAB's Receive.framenum."""
    with h5py.File(mat_path, 'r') as f:
        # RcvData is a 1x1 cell -> dereference to the real int16 array.
        # h5py exposes it with dims reversed vs. MATLAB: (frames, channels, totalSamples)
        rcv_ref = f['RcvData'][0, 0]
        RcvData = f[rcv_ref]

        num_ch = int(f['Trans']['numelements'][0, 0])

        Receive = f['Receive']
        n_total = Receive['framenum'].shape[0]
        framenum = np.array([f[Receive['framenum'][i, 0]][()].item() for i in range(n_total)])
        startSample = np.array([f[Receive['startSample'][i, 0]][()].item() for i in range(n_total)])
        endSample = np.array([f[Receive['endSample'][i, 0]][()].item() for i in range(n_total)])

        evIdx = np.where(framenum == frame_idx)[0]
        assert len(evIdx) > 0, f'No Receive entries found for frame_idx={frame_idx}'
        starts = startSample[evIdx].astype(int)
        ends = endSample[evIdx].astype(int)
        samples_per_event = int(ends[0] - starts[0] + 1)
        assert np.all(ends - starts + 1 == samples_per_event), \
            'Acquisitions have unequal lengths - extend this script to handle that case.'
        num_events = len(evIdx)

        Y = np.zeros((num_events, num_ch, samples_per_event), dtype=np.int16)
        for e, (s0, s1) in enumerate(zip(starts, ends)):
            # RcvData dims are (frame, channel, sample); MATLAB is 1-indexed.
            Y[e] = RcvData[frame_idx - 1, :num_ch, s0 - 1:s1]

    # Flatten event -> channel -> sample (numpy's default C-order reshape
    # already varies the last axis fastest, which is what we want).
    flat = Y.reshape(-1)
    u16 = flat.view(np.uint16)  # reinterpret bits, preserves two's complement

    with open(out_path, 'w') as fh:
        fh.write('\n'.join(f'{v:04X}' for v in u16))
        fh.write('\n')

    print(f'Wrote {out_path}: {num_events} events x {num_ch} channels x '
          f'{samples_per_event} samples = {flat.size} lines')


if __name__ == '__main__':
    mat_path = sys.argv[1] if len(sys.argv) > 1 else 'simulated3by3pointscattereratangle.mat'
    out_path = sys.argv[2] if len(sys.argv) > 2 else 'Y.hex'
    frame_idx = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    generate_Y_hex(mat_path, out_path, frame_idx)
