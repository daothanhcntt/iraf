# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<config.h>
include	<gki.h>

# GKI_INLINE_KERNEL -- Identify a graphics stream for use with an inline
# kernel, i.e., with a kernel linked into the same process as the high level
# code which calls the GKI procedures.  At present there may be at most one
# inline kernel at a time.  The entry point addresses of the kernel procedures
# are passed in the array DD.  Subsequent GKI calls for the named stream will
# result in direct calls to the inline kernel without encoding and decoding
# GKI instructions, hence this is the most efficient mode of operation.

procedure gki_inline_kernel (stream, dd)

int	stream			# graphics stream to be redirected
pointer	dd[ARB]			# device driver for the kernel
size_t	sz_val
include	"gki.com"

begin
	gk_type[stream] = TY_INLINE
	sz_val = LEN_GKIDD
	call amovp (dd, gk_dd, sz_val)
end
