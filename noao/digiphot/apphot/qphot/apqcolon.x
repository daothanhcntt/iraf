include <error.h>
include "../lib/apphot.h"
include "../lib/display.h"
include "../lib/noise.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

# APQCOLON -- Procedure to display and edit the quick photometry parameters.

procedure apqcolon (ap, im, cl, out, stid, ltid, cmdstr, newcbuf, newcenter,
    newsbuf, newsky, newmagbuf, newmag)

pointer	ap		# pointer to apphot structure
pointer	im		# pointer to the iraf image
int	cl		# coordinate file descriptor
int	out		# output file descriptor
int	stid		# output file sequence number
int	ltid		# coordinate file sequence number
char	cmdstr[ARB]	# command string
int	newcbuf		# new centering buffers
int	newcenter	# compute new center
int	newsbuf		# new sky fitting buffers
int	newsky		# compute new sky
int	newmagbuf	# new aperture buffers
int	newmag		# compute new magnitudes

bool	bval
int	ip, ncmd, nchars
pointer	sp, cmd, str
real	rval
bool	streq(), itob()
int	btoi(), strdic(), nscan(), apstati(), ctowrd(), open()
pointer	immap()
real	apstatr()

errchk	immap, open

begin
	# Allocate temporary space.
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get the command.
	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS)
	    return

	# Process the command
	ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, QCMDS)
	switch (ncmd) {
	case QCMD_SHOW:
	    call printf ("\n")
	    call ap_qshow (ap)
	    call printf ("\n")

	case QCMD_CBOXWIDTH:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (KY_CAPERT)
		    call pargr (2.0 * apstatr (ap, CAPERT))
		    call pargstr ("pixels")
	    } else {
		call apsetr (ap, CAPERT, rval / 2.0)
		if (stid > 1)
		    call ap_rparam (out, KY_CAPERT, rval, UN_CAPERT,
			"width of the centering box")
		newcbuf = YES
		newcenter = YES
	    }

	case QCMD_ANNULUS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (KY_ANNULUS)
		    call pargr (apstatr (ap, ANNULUS))
		    call pargstr ("pixels")
	    } else {
		call apsetr (ap, ANNULUS, rval)
		if (stid > 1)
		    call ap_rparam (out, KY_ANNULUS, rval, UN_ANNULUS,
			"inner radius of the sky annulus")
		newsbuf = YES
		newsky = YES
	    }

	case QCMD_DANNULUS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (KY_DANNULUS)
		    call pargr (apstatr (ap, DANNULUS))
		    call pargstr ("pixels")
	    } else {
		call apsetr (ap, DANNULUS, rval)
		if (stid > 1)
		    call ap_rparam (out, KY_DANNULUS, rval, UN_DANNULUS,
			"width of the sky annulus")
		newsbuf = YES
		newsky = YES
	    }

	case QCMD_APERTURES:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        call apstats (ap, APERTS, Memc[cmd], SZ_LINE)
	        call printf ("%s = %s %s\n")
		    call pargstr (KY_APERTS)
		    call pargstr (Memc[cmd])
		    call pargstr ("pixels")
	    } else {
		call apsets (ap, APERTS, Memc[cmd])
		if (stid > 1)
		    call ap_sparam (out, KY_APERTS, Memc[cmd], UN_APERTS,
			"list of aperture radii")
		newmag = YES
		newmagbuf = YES
	    }

	case QCMD_ZMAG:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (KY_ZMAG)
		    call pargr (apstatr (ap, ZMAG))
	    } else {
		call apsetr (ap, ZMAG, rval)
		if (stid > 1)
		    call ap_rparam (out, KY_ZMAG, rval, UN_ZMAG,
			"zero point of magnitude scale")
		newmag = YES
	    }

	case QCMD_EPADU:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (KY_EPADU)
		    call pargr (apstatr (ap, EPADU))
	    } else {
		call apsetr (ap, EPADU, rval)
		if (stid > 1)
		    call ap_rparam (out, KY_EPADU, rval, UN_EPADU, "gain")
		newmag = YES
	    }

	case QCMD_EXPOSURE:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call apstats (ap, EXPOSURE, Memc[str], SZ_FNAME)
		call printf ("%s = %s\n")
		    call pargstr (KY_EXPOSURE)
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		nchars = ctowrd (Memc[cmd], ip, Memc[str], SZ_FNAME)
		call apsets (ap, EXPOSURE, Memc[str])
		if (im != NULL)
		    call ap_itime (im, ap)
		if (stid > 1)
		    call ap_sparam (out, KY_EXPOSURE, Memc[str],
		        UN_EXPOSURE, "exposure time keyword")
	    }

	case QCMD_AIRMASS:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call apstats (ap, AIRMASS, Memc[str], SZ_FNAME)
		call printf ("%s = %s\n")
		    call pargstr (KY_AIRMASS)
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		nchars = ctowrd (Memc[cmd], ip, Memc[str], SZ_FNAME)
		call apsets (ap, AIRMASS, Memc[str])
		if (im != NULL)
		    call ap_airmass (im, ap)
		if (stid > 1)
		    call ap_sparam (out, KY_AIRMASS, Memc[str],
		        UN_AIRMASS, "airmass keyword")
	    }

	case QCMD_FILTER:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call apstats (ap, FILTER, Memc[str], SZ_FNAME)
		call printf ("%s = %s\n")
		    call pargstr (KY_FILTER)
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		nchars = ctowrd (Memc[cmd], ip, Memc[str], SZ_FNAME)
		call apsets (ap, FILTER, Memc[str])
		if (im != NULL)
		    call ap_filter (im, ap)
		if (stid > 1)
		    call ap_sparam (out, KY_FILTER, Memc[str],
		        UN_FILTER, "filter keyword")
	    }

	case QCMD_RADPLOTS:
	    call gargb (bval)
	    if (nscan () == 1) {
		call printf ("%s = %b\n")
		    call pargstr (KY_RADPLOTS)
		    call pargb (itob (apstati (ap, RADPLOTS)))
	    } else {
		call apseti (ap, RADPLOTS, btoi (bval))
	    }

	case QCMD_IMAGE:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    call apstats (ap, IMNAME, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS || streq (Memc[cmd], Memc[str])) {
		call printf ("%s = %s\n")
		    call pargstr (KY_IMNAME)
		    call pargstr (Memc[str])
	    } else {
		if (im != NULL) {
		    call imunmap (im)
		    im = NULL
		}
		iferr {
		    im = immap (Memc[cmd], READ_ONLY, 0)
		} then {
		    call erract (EA_WARN)
		    call printf ("Reopening image %s.\n")
			call pargstr (Memc[str])
		    im = immap (Memc[str], READ_ONLY, 0)
		} else {
		    call apsets (ap, IMNAME, Memc[cmd])
		    call ap_itime (im, ap)
		    call ap_padu (im, ap)
		    call ap_rdnoise (im, ap)
		    call ap_airmass (im, ap)
		    call ap_filter (im, ap)
		    newcbuf = YES; newcenter = YES
		    newsbuf = YES; newsky = YES
		    newmagbuf = YES; newmag = YES
		}
	    }

	case QCMD_COORDS:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    call apstats (ap, CLNAME, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS || streq (Memc[cmd], Memc[str])) {
		call printf ("%s:  %s\n")
		    call pargstr (KY_CLNAME)
		    call pargstr (Memc[str])
	    } else {
		if (cl != NULL) {
		    call close( cl)
		    cl = NULL
		}
		iferr {
		    cl = open (Memc[cmd], READ_ONLY, TEXT_FILE)
		} then {
		    cl = NULL
		    call erract (EA_WARN)
		    call apsets (ap, CLNAME, "")
		    call printf ("Coordinate file is undefined.\n")
		} else {
		    call apsets (ap, CLNAME, Memc[cmd])
		    ltid = 0
		}
	    }

	case QCMD_OUTPUT:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    call apstats (ap, OUTNAME, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS || streq (Memc[cmd], Memc[str])) {
		call printf ("%s = %s\n")
		    call pargstr (KY_OUTNAME)
		    call pargstr (Memc[str])
	    } else {
		if (out != NULL) {
		    call close (out)
		    out = NULL
		    if (stid <= 1)
			call delete (Memc[str])
		}
		iferr {
		    out = open (Memc[cmd], READ_ONLY, TEXT_FILE)
		} then {
		    call erract (EA_WARN)
		    call printf ("Reopening output file: %s\n")
			call pargstr (Memc[str])
		    if (Memc[str] != EOS)
			out = open (Memc[str], APPEND, TEXT_FILE) 
		    else
		        out = NULL
		} else {
		    call apsets (ap, OUTNAME, Memc[cmd])
		    stid = 1
		}
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)
end