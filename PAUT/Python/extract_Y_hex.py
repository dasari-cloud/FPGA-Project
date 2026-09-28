"""
Regenerate Y.hex from simulated3by3pointscattereratangle.mat

This script was used to pull the RF data out of RcvData{1} (a MATLAB v7.3 /
HDF5 file) with no external HDF5 library available, and dump it to a
Vivado-readable $readmemh hex file.

Dependencies: numpy only (stdlib zlib for chunk decompression).
"""
import numpy as np
import zlib
from hdf5mini import HDF5Reader   # minimal pure-python HDF5/v7.3 reader written for this task

MAT_PATH   = 'simulated3by3pointscattereratangle.mat'
FRAME_IDX  = 0        # 0-indexed -> MATLAB frame 1. RcvData{1} has 30 frames total (dim3).
NUM_CH     = 32        # Trans.numelements (populated RX channels out of 64 allocated slots)
NUM_EVENTS = 75         # numel(TX) -- confirmed from TX.Apod / TX.focus dims in this file
SAMPLES_PER_EVENT = 1536  # from Receive(n).endSample - Receive(n).startSample + 1

def extract_frame(path=MAT_PATH, frame_idx=FRAME_IDX, num_ch=NUM_CH,
                   num_samples=NUM_EVENTS*SAMPLES_PER_EVENT):
    r = HDF5Reader(path)
    entries = dict(r.root_group_entries())

    # RcvData is a 1x1 cell -> dereference to the real int16 array
    rc_info = r.get_object_info(entries['RcvData'])
    ref = int.from_bytes(r.read_raw_data(rc_info)[:8], 'little')
    info = r.get_object_info(r.A(ref))
    assert info['attrs']['MATLAB_class'][3].startswith(b'int16')

    layout = info['layout']
    chunk_dims = layout['chunk_dims']          # HDF5-order: [frame, channel, sample]
    chunks = []
    r.read_chunked_btree(layout['btree_addr'], len(chunk_dims)+1, chunks)

    Fdim, Cdim, Sdim = chunk_dims
    out = bytearray(num_samples*num_ch*2)
    for offsets, csize, fmask, ptr in chunks:
        foff, choff, soff, _ = offsets
        if soff >= num_samples or choff >= num_ch:
            continue
        raw = r.data[ptr:ptr+csize]
        for fid, vals in info['filters']:
            if fid == 1:
                raw = zlib.decompress(raw)
        fl = frame_idx - foff
        if not (0 <= fl < Fdim):
            continue
        s_hi = min(soff+Sdim, num_samples)
        ch_hi = min(choff+Cdim, num_ch)
        for s in range(soff, s_hi):
            sl = s - soff
            for ch in range(choff, ch_hi):
                cl = ch - choff
                raw_off = ((fl*Cdim)+cl)*Sdim*2 + sl*2
                out_off = (s*num_ch + ch)*2
                out[out_off:out_off+2] = raw[raw_off:raw_off+2]

    d = np.frombuffer(bytes(out), dtype='<i2').reshape(num_samples, num_ch)
    return d

def to_Y_hex(d, out_path='Y.hex', num_events=NUM_EVENTS,
             samples_per_event=SAMPLES_PER_EVENT, num_ch=NUM_CH):
    Y = d.reshape(num_events, samples_per_event, num_ch)
    Y = np.transpose(Y, (0, 2, 1))          # -> [event, channel, sample]
    flat = Y.reshape(-1)
    uview = flat.view(np.uint16)
    with open(out_path, 'w') as f:
        f.write('\n'.join(format(v, '04X') for v in uview))
        f.write('\n')
    return Y

if __name__ == '__main__':
    d = extract_frame()
    to_Y_hex(d)
    print('wrote Y.hex')
