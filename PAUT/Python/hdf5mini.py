import struct, zlib

class HDF5Reader:
    def __init__(self, path):
        self.data = open(path, 'rb').read()
        self.base = self.data.find(b'\x89HDF\r\n\x1a\n')
        self._parse_superblock()

    def u(self, off, n):
        return int.from_bytes(self.data[off:off+n], 'little')

    def A(self, addr):
        """Translate a stored address (relative to base_addr) to an absolute file offset."""
        if addr == self.undef:
            return None
        return addr + self.base_addr

    def _parse_superblock(self):
        d = self.data
        b = self.base
        ver = d[b+8]
        assert ver == 0, f"superblock ver {ver} not supported"
        self.size_offsets = d[b+13]
        self.size_lengths = d[b+14]
        self.undef = (1 << (8*self.size_offsets)) - 1
        off = b+24
        self.base_addr = self.u(off, self.size_offsets); off+=self.size_offsets
        off += self.size_offsets  # freespace addr
        self.eof_addr = self.u(off, self.size_offsets); off+=self.size_offsets
        off += self.size_offsets  # driver addr
        self.root_link_name_offset = self.u(off, self.size_offsets); off+=self.size_offsets
        self.root_obj_header_addr = self.A(self.u(off, self.size_offsets)); off+=self.size_offsets

    # ---- Object header (version 1) ----
    def parse_object_header(self, addr):
        d = self.data
        off = addr
        version = d[off]; off+=1
        assert version == 1, f"obj header ver {version} at {hex(addr)}"
        off+=1
        nmsgs = self.u(off,2); off+=2
        off+=4  # object reference count
        header_size = self.u(off,4); off+=4
        off = addr + 16  # 12-byte prefix padded to 16 (relative to addr)
        messages = []
        self._read_messages(off, off+header_size, nmsgs, messages)
        return messages

    def _read_messages(self, off, end, nmsgs_target, messages):
        d = self.data
        while off < end and len(messages) < nmsgs_target:
            mtype = self.u(off,2); off+=2
            msize = self.u(off,2); off+=2
            off += 1  # flags
            off += 3  # reserved
            body = d[off:off+msize]
            if mtype == 0x0010:  # continuation
                cont_off = self.A(int.from_bytes(body[0:self.size_offsets],'little'))
                cont_len = int.from_bytes(body[self.size_offsets:self.size_offsets+self.size_lengths],'little')
                self._read_messages(cont_off, cont_off+cont_len, nmsgs_target, messages)
            else:
                messages.append((mtype, body))
            off += msize
        return messages

    # ---- Symbol table / local heap / B-tree v1 (group) ----
    def read_local_heap(self, addr):
        d = self.data
        assert d[addr:addr+4] == b'HEAP', d[addr:addr+4]
        off = addr+4+1+3
        off += self.size_lengths  # data segment size
        off += self.size_lengths  # freelist head offset
        dataaddr = self.A(self.u(off, self.size_offsets))
        return dataaddr

    def read_btree_group(self, addr, heap_data_addr, results):
        d = self.data
        assert d[addr:addr+4] == b'TREE', d[addr:addr+4]
        off = addr+4
        node_type = d[off]; off+=1
        node_level = d[off]; off+=1
        entries_used = self.u(off,2); off+=2
        off += self.size_offsets  # left sibling
        off += self.size_offsets  # right sibling
        off += self.size_lengths  # key0
        for i in range(entries_used):
            child_ptr = self.A(self.u(off, self.size_offsets)); off+=self.size_offsets
            off += self.size_lengths  # key
            if node_level == 0:
                self.read_snod(child_ptr, heap_data_addr, results)
            else:
                self.read_btree_group(child_ptr, heap_data_addr, results)

    def read_snod(self, addr, heap_data_addr, results):
        d = self.data
        assert d[addr:addr+4] == b'SNOD', d[addr:addr+4]
        off = addr+4+1+1
        nsyms = self.u(off,2); off+=2
        for i in range(nsyms):
            link_name_off = self.u(off, self.size_offsets); off+=self.size_offsets
            obj_hdr_addr = self.A(self.u(off, self.size_offsets)); off+=self.size_offsets
            off += 4 + 4 + 16  # cache type, reserved, scratch
            name = self.read_cstr(heap_data_addr + link_name_off)
            results.append((name, obj_hdr_addr))

    def read_cstr(self, addr):
        d = self.data
        end = d.find(b'\x00', addr)
        return d[addr:end].decode('utf-8', errors='replace')

    def list_group(self, obj_header_addr):
        messages = self.parse_object_header(obj_header_addr)
        btree_addr = heap_addr = None
        for mtype, body in messages:
            if mtype == 0x0011:  # Symbol Table message
                btree_addr = self.A(int.from_bytes(body[0:self.size_offsets],'little'))
                heap_addr = self.A(int.from_bytes(body[self.size_offsets:self.size_offsets*2],'little'))
        if btree_addr is None:
            return []
        heap_data_addr = self.read_local_heap(heap_addr)
        results = []
        self.read_btree_group(btree_addr, heap_data_addr, results)
        return results

    def root_group_entries(self):
        return self.list_group(self.root_obj_header_addr)

    # ---- message decoders ----
    def parse_dataspace(self, body):
        version = body[0]
        dimensionality = body[1]
        flags = body[2]
        off = 8
        dims = []
        for i in range(dimensionality):
            dims.append(int.from_bytes(body[off:off+self.size_lengths], 'little'))
            off += self.size_lengths
        return dims

    def parse_datatype(self, body):
        class_and_version = body[0]
        version = class_and_version >> 4
        dtclass = class_and_version & 0x0F
        bits = body[1:4]
        size = int.from_bytes(body[4:8], 'little')
        return dtclass, size, bits

    def parse_layout(self, body):
        version = body[0]
        if version in (1,2):
            raise NotImplementedError('layout v1/2 not implemented')
        layout_class = body[1]
        off = 2
        if layout_class == 0:  # compact
            size = int.from_bytes(body[off:off+2],'little'); off+=2
            data = body[off:off+size]
            return {'class':'compact', 'data':data}
        elif layout_class == 1:  # contiguous
            addr = int.from_bytes(body[off:off+self.size_offsets],'little'); off+=self.size_offsets
            addr = self.A(addr)
            size = int.from_bytes(body[off:off+self.size_lengths],'little'); off+=self.size_lengths
            return {'class':'contiguous', 'addr':addr, 'size':size}
        elif layout_class == 2:  # chunked
            dims = body[off]; off+=1
            btree_addr = int.from_bytes(body[off:off+self.size_offsets],'little'); off+=self.size_offsets
            btree_addr = self.A(btree_addr)
            chunk_dims = []
            for i in range(dims-1):
                chunk_dims.append(int.from_bytes(body[off:off+4],'little')); off+=4
            elem_size = int.from_bytes(body[off:off+4],'little'); off+=4
            return {'class':'chunked', 'btree_addr':btree_addr, 'chunk_dims':chunk_dims, 'elem_size':elem_size}
        else:
            raise NotImplementedError(f'layout class {layout_class}')

    def parse_attribute(self, body):
        version = body[0]
        off = 1
        off += 1  # reserved
        name_size = int.from_bytes(body[off:off+2],'little'); off+=2
        dt_size = int.from_bytes(body[off:off+2],'little'); off+=2
        ds_size = int.from_bytes(body[off:off+2],'little'); off+=2
        # name padded to 8-byte multiple
        name_raw = body[off:off+name_size]
        name = name_raw.rstrip(b'\x00').decode('utf-8', errors='replace')
        off += name_size
        if off % 8: off += 8 - (off%8)
        dt_body = body[off:off+dt_size]
        dtclass, dtsize, bits = self.parse_datatype(dt_body)
        off += dt_size
        if off % 8: off += 8 - (off%8)
        ds_body = body[off:off+ds_size]
        dims = self.parse_dataspace(ds_body)
        off += ds_size
        if off % 8: off += 8 - (off%8)
        value = body[off:]
        return name, dtclass, dtsize, dims, value

    def get_object_info(self, addr):
        """Return dict with dims, dtype info, layout, filters, attrs for a dataset object header."""
        messages = self.parse_object_header(addr)
        info = {'dims': None, 'dtclass': None, 'dtsize': None, 'layout': None,
                'filters': [], 'attrs': {}, 'is_group': False, 'bits': None}
        for mtype, body in messages:
            if mtype == 0x0001:
                info['dims'] = self.parse_dataspace(body)
            elif mtype == 0x0003:
                info['dtclass'], info['dtsize'], info['bits'] = self.parse_datatype(body)
            elif mtype == 0x0008:
                info['layout'] = self.parse_layout(body)
            elif mtype == 0x000B:  # filter pipeline
                info['filters'] = self.parse_filter_pipeline(body)
            elif mtype == 0x000C:  # attribute
                name, dtclass, dtsize, dims, value = self.parse_attribute(body)
                info['attrs'][name] = (dtclass, dtsize, dims, value)
            elif mtype == 0x0011:
                info['is_group'] = True
        return info

    def parse_filter_pipeline(self, body):
        version = body[0]
        nfilters = body[1]
        filters = []
        if version == 1:
            off = 8
            for i in range(nfilters):
                fid = int.from_bytes(body[off:off+2],'little'); off+=2
                name_len = int.from_bytes(body[off:off+2],'little'); off+=2
                flags = int.from_bytes(body[off:off+2],'little'); off+=2
                nvals = int.from_bytes(body[off:off+2],'little'); off+=2
                off += name_len
                vals = []
                for j in range(nvals):
                    vals.append(int.from_bytes(body[off:off+4],'little')); off+=4
                if (nvals % 2) == 1:
                    off += 4
                filters.append((fid, vals))
        else:
            off = 2
            for i in range(nfilters):
                fid = int.from_bytes(body[off:off+2],'little'); off+=2
                if fid >= 256:
                    name_len = int.from_bytes(body[off:off+2],'little'); off+=2
                else:
                    name_len = 0
                flags = int.from_bytes(body[off:off+2],'little'); off+=2
                nvals = int.from_bytes(body[off:off+2],'little'); off+=2
                off += name_len
                vals = []
                for j in range(nvals):
                    vals.append(int.from_bytes(body[off:off+4],'little')); off+=4
                filters.append((fid, vals))
        return filters

    def read_chunked_btree(self, addr, ndims_stored, results):
        """ndims_stored = number of chunk dims including the trailing element-size dim."""
        d = self.data
        assert d[addr:addr+4] == b'TREE', d[addr:addr+4]
        off = addr+4
        node_type = d[off]; off+=1
        node_level = d[off]; off+=1
        entries_used = self.u(off,2); off+=2
        off += self.size_offsets*2  # siblings
        key_size = 8 + 8*ndims_stored  # chunk size(4)+filter mask(4) + ndims_stored * 8 (offsets)
        for i in range(entries_used):
            chunk_size = self.u(off,4)
            filter_mask = self.u(off+4,4)
            koff = off+8
            offsets = []
            for k in range(ndims_stored):
                offsets.append(self.u(koff, 8)); koff += 8
            off += key_size
            child_ptr = self.A(self.u(off, self.size_offsets)); off += self.size_offsets
            if node_level == 0:
                results.append((offsets, chunk_size, filter_mask, child_ptr))
            else:
                self.read_chunked_btree(child_ptr, ndims_stored, results)
        # trailing key (not needed)

    def read_raw_data(self, info):
        layout = info['layout']
        if layout['class'] == 'contiguous':
            if layout['addr'] is None:
                return b''
            return self.data[layout['addr']: layout['addr']+layout['size']]
        elif layout['class'] == 'compact':
            return layout['data']
        elif layout['class'] == 'chunked':
            dims = info['dims']
            elem_size = layout['elem_size']
            chunk_dims = layout['chunk_dims']  # length = len(dims)
            ndims_stored = len(chunk_dims) + 1
            chunks = []
            self.read_chunked_btree(layout['btree_addr'], ndims_stored, chunks)
            # total array size
            total_elems = 1
            for dd in dims:
                total_elems *= dd
            out = bytearray(total_elems*elem_size)
            # compute strides for row-major logical array with dims as given (C order, dims[0] slowest)
            ndims = len(dims)
            strides = [0]*ndims
            acc = elem_size
            for i in reversed(range(ndims)):
                strides[i] = acc
                acc *= dims[i]
            filters = info['filters']
            for offsets, csize, fmask, ptr in chunks:
                raw = self.data[ptr:ptr+csize]
                for fid, vals in filters:
                    if fid == 1:  # deflate
                        raw = zlib.decompress(raw)
                    elif fid == 2:  # shuffle
                        elemsz = vals[0] if vals else elem_size
                        raw = self._unshuffle(raw, elemsz)
                    elif fid == 0:
                        pass
                    else:
                        raise NotImplementedError(f'filter {fid} not supported')
                # place raw bytes (chunk) into out at correct offsets
                self._place_chunk(out, raw, offsets[:ndims], chunk_dims, dims, elem_size, strides)
            return bytes(out)
        else:
            raise NotImplementedError(layout['class'])

    def _unshuffle(self, data, elem_size):
        n = len(data)//elem_size
        out = bytearray(len(data))
        for b in range(elem_size):
            col = data[b*n:(b+1)*n]
            for i in range(n):
                out[i*elem_size+b] = col[i]
        return bytes(out)

    def _place_chunk(self, out, raw, chunk_offset, chunk_dims, dims, elem_size, strides):
        ndims = len(dims)
        # iterate over the chunk's actual overlap with array bounds
        ranges = []
        for i in range(ndims):
            start = chunk_offset[i]
            end = min(start+chunk_dims[i], dims[i])
            ranges.append((start, end))
        # chunk internal strides (row-major within chunk_dims)
        cstrides = [0]*ndims
        acc = elem_size
        for i in reversed(range(ndims)):
            cstrides[i] = acc
            acc *= chunk_dims[i]
        def rec(dim, out_base, raw_base):
            if dim == ndims:
                out[out_base:out_base+elem_size] = raw[raw_base:raw_base+elem_size]
                return
            start, end = ranges[dim]
            for idx in range(start, end):
                rec(dim+1, out_base + (idx-0)*strides[dim] if False else out_base, raw_base)
        # simpler explicit loop for up to reasonable dims using nested index generation
        import itertools
        idx_ranges = [range(r[0], r[1]) for r in ranges]
        for idx in itertools.product(*idx_ranges):
            out_off = sum(idx[i]*strides[i] for i in range(ndims))
            raw_off = sum((idx[i]-chunk_offset[i])*cstrides[i] for i in range(ndims))
            out[out_off:out_off+elem_size] = raw[raw_off:raw_off+elem_size]


if __name__ == '__main__':
    r = HDF5Reader('/mnt/user-data/uploads/simulated3by3pointscattereratangle.mat')
    print('size_offsets', r.size_offsets, 'size_lengths', r.size_lengths, 'base_addr', hex(r.base_addr))
    entries = r.root_group_entries()
    for name, addr in entries:
        print(name, hex(addr))
