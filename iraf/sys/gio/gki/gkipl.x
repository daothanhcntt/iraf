# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<config.h>
include	<gki.h>

# GKI_POLYLINE -- Output a polyline.
#
# BOI GKI_POLYLINE L N P
#    
#        L(i)            4 + (N * 2)
#        N(i)            number of points in the polyline
#        P(Np)           list of points (x,y pairs)

procedure gki_polyline (fd, points, npts)

int	fd			# output file
short	points[ARB]		# polyline
int	npts			# number of (x,y) points in polyline

size_t	sz_val
pointer	epa
short	gki[GKI_POLYLINE_LEN]
data	gki[1] /BOI/, gki[2] /GKI_POLYLINE/
include	"gki.com"

begin
	if (IS_INLINE(fd)) {
	    epa = gk_dd[GKI_POLYLINE]
	    if (epa != 0)
		call zcall2 (epa, points, npts)
	} else {
	    gki[GKI_POLYLINE_L] = GKI_POLYLINE_LEN + (npts * 2)
	    gki[GKI_POLYLINE_N] = npts

	    sz_val = GKI_POLYLINE_LEN * SZ_SHORT
	    call write (gk_fd[fd], gki, sz_val)
	    sz_val = (npts * 2) * SZ_SHORT
	    call write (gk_fd[fd], points, sz_val)
	}
end
