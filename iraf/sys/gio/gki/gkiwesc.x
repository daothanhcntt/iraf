# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<config.h>
include	<gki.h>

# GKI_WESCAPE -- Write a GKI escape instruction, used to pass device
# dependent instructions on to a graphics kernel.  This version of gki_escape
# is used in cases where the escape instruction consists of the escape header
# followed by a block of data, and it is inconvenient to have to combine the
# header and the data into one array.
#
# BOI GKI_ESCAPE L FN N DC
#
#        L(i)            5 + N
#        FN(i)           escape function code
#        N(i)            number of escape data words
#        DC(i)           escape data words

procedure gki_wescape (fd, fn, hdr, hdrlen, data, datalen)

int	fd		#I output file
int	fn		#I escape function code
short	hdr[ARB]	#I escape instruction header
int	hdrlen		#I header length, shorts
short	data[ARB]	#I escape instruction data
int	datalen		#I data length, shorts

size_t	sz_val
pointer	sp, buf
pointer	epa
int	nwords
short	gki[GKI_ESCAPE_LEN]
data	gki[1] /BOI/, gki[2] /GKI_ESCAPE/
include	"gki.com"

begin
	nwords = hdrlen + datalen

	if (IS_INLINE(fd)) {
	    call smark (sp)
	    sz_val = nwords
	    call salloc (buf, sz_val, TY_SHORT)

	    sz_val = ARB
	    call amovs (hdr, Mems[buf], sz_val)
	    sz_val = ARB
	    call amovs (data, Mems[buf+hdrlen], sz_val)

	    epa = gk_dd[GKI_ESCAPE]
	    if (epa != 0)
		call zcall3 (epa, fn, Mems[buf], nwords)

	    call sfree (sp)

	} else {
	    gki[GKI_ESCAPE_L]  = GKI_ESCAPE_LEN + nwords
	    gki[GKI_ESCAPE_N]  = nwords
	    gki[GKI_ESCAPE_FN] = fn

	    sz_val = GKI_ESCAPE_LEN * SZ_SHORT
	    call write (gk_fd[fd], gki, sz_val)
	    sz_val = hdrlen * SZ_SHORT
	    call write (gk_fd[fd], hdr, sz_val)
	    sz_val = datalen * SZ_SHORT
	    call write (gk_fd[fd], data, sz_val)
	}
end
