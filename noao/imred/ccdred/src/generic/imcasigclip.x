include	<imhdr.h>

.help imcasigclip
.nf ----------------------------------------------------------------------------
         COMBINING IMAGES: AVERAGE SIGMA CLIPPING ALGORITHM

If there is only one input image then it is copied to the output image.
If there are two input images then it is an error.  For more than two
input images they are combined by scaling and taking a weighted average while
rejecting points which deviate from the average by more than specified
factors times the expected sigma at each point.  The exposure time of the
output image is the scaled and weighted average of the input exposure times.
The average is computed in real arithmetic with trunction on output if
the output image is an integer datatype.

The average sigma clipping algorithm is applied to each image line as follows.

(1) The input image lines are scaled to account for different mean intensities.
(2) The weighted average of each point in the line is computed after rejecting
    the high and low values (the minmax combining algorithm).  This
    minimizes the influence of bad values in the initial estimate of the
    average.
(3) The sigma about the mean at each point (including the high and low values)
    is computed.  Each residual is multiplied by the square root of the
    scaling factor to compensate for the reduction in noise due to the
    intensity scaling.
(4) Each sigma is divided by the square root of the mean to account for the
    Poisson variation in the noise and the average sigma is computed.
    This average sigma is much less influenced by bad values and works well
    even with only a few images.
(5) The estimated sigma at each point is then found by multiplying the average
    sigma by the mean at that point.
(6) The most deviant point exceeding a specified factor times the estimated
    sigma is rejected.  Note that at most one value is rejected at each point.
(7) The final weighted average excluding the rejected values is computed.

PROCEDURES:

    IMC_ASIGCLIP -- Entry routine to the average sigma clipping algorithm.
    WTASIGCLIP   -- Average sigma clipping when scales and weights not equal.
    ASIGCLIP     -- Average sigma clipping when scales and weights equal.
.endhelp -----------------------------------------------------------------------


# IMC_ASIGCLIP -- Apply average sigma clipping algorithm to a set of input
# images, given by an array of image pointers, to form an output image.
# The sigma clipping, scaling, and weighting factors are determined.
# The procedure gets a line from each input image and the output line
# buffer.  A procedure is called for either the weighted or unweighted
# average sigma clipping routine to combine the image lines.
# The output image header is updated to include a scaled and weighted
# exposure time and the number of images combined.

procedure imc_asigclips (log, in, out, sig, nimages)

int	log			# Log file descriptor
pointer	in[nimages]		# Input images
pointer	out			# Output image
pointer	sig			# Sigma image
int	nimages			# Number of input images

real	low			# Low sigma cutoff
real	high			# High sigma cutoff

int	i, j, nc
pointer	sp, data, scales, zeros, wts, sigma, outdata, sigdata, v1, v2
bool	scale, imc_scales()
real	clgetr()
pointer	imgnls()
pointer	impnlr()

begin
	if (nimages == 1) {
	    call imc_copys (in[1], out)
	    return
	}

	if (nimages == 2)
	    call error (0, "Too few images for average sigma clipping")

	nc = IM_LEN(out,1)

	call smark (sp)
	call salloc (data, nimages, TY_INT)
	call salloc (scales, nimages, TY_REAL)
	call salloc (zeros, nimages, TY_REAL)
	call salloc (wts, nimages, TY_REAL)
	call salloc (sigma, nc, TY_REAL)
	call salloc (v1, IM_MAXDIM, TY_LONG)
	call salloc (v2, IM_MAXDIM, TY_LONG)
	call amovkl (long(1), Meml[v1], IM_MAXDIM)
	call amovkl (long(1), Meml[v2], IM_MAXDIM)

	# Get the sigma clipping, scaling and weighting factors.
	low = clgetr ("lowreject")
	high = clgetr ("highreject")
	scale = imc_scales ("avsigclip", log, low, high, in, out, Memr[scales],
	    Memr[zeros], Memr[wts], nimages)

	# For each line get input and ouput image lines and call a procedure
	# to perform the averge sigma clipping algorithm on the line.

	if (scale) {
	    while (impnlr (out, outdata, Meml[v1]) != EOF) {
		do i = 1, nimages {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = imgnls (in[i], Memi[data+i-1], Meml[v1])
		}
	        call wtasigclips (Memi[data], Memr[scales], Memr[zeros],
		    Memr[wts], Memr[outdata], Memr[sigma], nc, nimages,
		    low, high)
		if (sig != NULL) {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = impnlr (sig, sigdata, Meml[v1])
		    call wtsigmas (Memi[data], Memr[scales], Memr[zeros],
			Memr[wts], nimages, Memr[outdata], Memr[sigdata], nc)
		}
		call amovl (Meml[v1], Meml[v2], IM_MAXDIM)
	    }
	} else {
	    while (impnlr (out, outdata, Meml[v1]) != EOF) {
		do i = 1, nimages {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = imgnls (in[i], Memi[data+i-1], Meml[v1])
		}
	        call asigclips (Memi[data], Memr[outdata], Memr[sigma], nc,
		    nimages, low, high)
		if (sig != NULL) {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = impnlr (sig, sigdata, Meml[v1])
		    call sigmas (Memi[data], nimages, Memr[outdata],
			Memr[sigdata], nc)
		}
		call amovl (Meml[v1], Meml[v2], IM_MAXDIM)
	    }
	}

	call sfree (sp)
end


# WTASIGCLIP -- Combine input data lines using the average sigma clip algorithm
# when weights and scale factors are not equal.

procedure wtasigclips (data, scales, zeros, wts, output, sigma, npts, nlines,
	lowsigma, highsigma)

pointer	data[nlines]		# Data lines
real	scales[nlines]		# Scaling for images
real	zeros[nlines]		# Zero level for images
real	wts[nlines]		# Weights for images
real	output[npts]		# Output line (returned)
real	sigma[npts]		# Sigma line (returned)
int	npts			# Number of points per line
int	nlines			# Number of lines
real	highsigma		# High sigma rejection threshold
real	lowsigma		# Low sigma rejection threshold

int	i, j, k
real	resid, resid2, maxresid, maxresid2
real	sum, minwt, maxwt, wt, val, sig, sigall, low, high
pointer	sp, mean

begin
	call smark (sp)
	call salloc (mean, npts, TY_REAL)

	# Compute the scaled and weighted mean with and without rejecting
	# the minimum and maximum points.

	do i = 1, npts {
	    sum = 0.
	    low = Mems[data[1]+i-1] / scales[1] - zeros[1]
	    high = Mems[data[2]+i-1] / scales[2] - zeros[2]
	    if (low < high) {
		minwt = wts[1]
		maxwt = wts[2]
	    } else {
		minwt = low
		low = high
		high = minwt
		minwt = wts[2]
		maxwt = wts[1]
	    }
	    do j = 3, nlines {
		val = Mems[data[j]+i-1] / scales[j] - zeros[j]
		wt = wts[j]
		if (val < low) {
		    sum = sum + minwt * low
		    low = val
		    minwt = wt
		} else if (val > high) {
		    sum = sum + maxwt * high
		    high = val
		    maxwt = wt
		} else
		    sum = sum + wt * val
	    }
	    Memr[mean+i-1] = sum / (1 - minwt - maxwt)
	    sum = sum + minwt * low + maxwt * high
	    output[i] = sum
	}

	# Compute sigma at each point and the average line sigma.  Correct
	# individual residuals for the image scaling and the sigma at each
	# for variation in the mean intensity at that point.

	sigall = 0.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = 0.
	    do j = 1, nlines {
		resid = (Mems[data[j]+i-1]/scales[j]-zeros[j] - val) * wts[j]
		sig = sig + resid ** 2
	    }
	    if (val > 0.)
	        sigma[i] = sqrt (val)
	    else
	        sigma[i] = 1.
	    sigall = sigall + sqrt (sig) / sigma[i]
	}
	sigall = sigall / sqrt (real (nlines-1)) / npts
	do i = 1, npts
	    sigma[i] = sigall * sigma[i]

	# Reject pixels.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = sigma[i]
	    low = -lowsigma * sig
	    high = highsigma * sig

	    maxresid = (Mems[data[1]+i-1]/scales[1]-zeros[1] - val) * wts[1]
	    maxresid2 = maxresid ** 2
	    k = 1
	    do j = 2, nlines {
	        resid = (Mems[data[j]+i-1]/scales[j]-zeros[j] - val) * wts[j]
		resid2 = resid ** 2
		if (resid2 > maxresid2) {
		    maxresid = resid
		    maxresid2 = resid2
		    k = j
		}
	    }
	    if ((maxresid > high) || (maxresid < low)) {
		output[i] = (output[i] - (Mems[data[k]+i-1] / scales[k] -
		    zeros[k]) * wts[k]) / (1 - wts[k])
		Mems[data[k]+i-1] = INDEFS
	    }
	}

	call sfree (sp)
end


# ASIGCLIP -- Combine input data lines using the average sigma clip algorithm
# when weights and scale factors are equal.

procedure asigclips (data, output, sigma, npts, nlines, lowsigma, highsigma)

pointer	data[nlines]		# Data lines
real	output[npts]		# Mean line (returned)
real	sigma[npts]		# Sigma line (returned)
int	npts			# Number of points per line
int	nlines			# Number of lines
real	highsigma		# High sigma rejection threshold
real	lowsigma		# Low sigma rejection threshold

int	i, j, k
real	resid, resid2, maxresid, maxresid2
real	sum, val, sig, sigall, low, high
pointer	sp, mean

begin
	call smark (sp)
	call salloc (mean, npts, TY_REAL)

	# Compute the mean with and without rejecting the extrema.
	do i = 1, npts {
	    sum = 0.
	    low = Mems[data[1]+i-1]
	    high = Mems[data[2]+i-1]
	    if (low > high) {
		val = low
		low = high
		high = val
	    }
	    do j = 3, nlines {
		val = Mems[data[j]+i-1]
		if (val < low) {
		    sum = sum + low
		    low = val
		} else if (val > high) {
		    sum = sum + high
		    high = val
		} else
		    sum = sum + val
	    }
	    Memr[mean+i-1] = sum / (nlines - 2)
	    sum = sum + low + high
	    output[i] = sum / nlines
	}

	# Compute sigma at each point and the average line sigma.  Correct
	# the sigma at each point for variation in the mean intensity at
	# that point.

	sigall = 0.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = 0.
	    do j = 1, nlines {
		resid = Mems[data[j]+i-1] - val
		sig = sig + resid ** 2
	    }
	    if (val > 0.)
	        sigma[i] = sqrt (val)
	    else
	        sigma[i] = 1.
	    sigall = sigall + sqrt (sig) / sigma[i]
	}
	sigall = sigall / sqrt (real (nlines-1)) / npts
	do i = 1, npts
	    sigma[i] = sigall * sigma[i]

	# Reject pixels.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = sigma[i]
	    low = -lowsigma * sig
	    high = highsigma * sig

	    maxresid = Mems[data[1]+i-1] - val
	    maxresid2 = maxresid ** 2
	    k = 1
	    do j = 2, nlines {
	        resid = Mems[data[j]+i-1] - val
		resid2 = resid ** 2
		if (resid2 > maxresid2) {
		    maxresid = resid
		    maxresid2 = resid2
		    k = j
		}
	    }
	    if ((maxresid > high) || (maxresid < low)) {
		output[i] = (nlines*output[i] - Mems[data[k]+i-1]) / (nlines-1)
		Mems[data[k]+i-1] = INDEFS
	    }
	}

	call sfree (sp)
end

# IMC_ASIGCLIP -- Apply average sigma clipping algorithm to a set of input
# images, given by an array of image pointers, to form an output image.
# The sigma clipping, scaling, and weighting factors are determined.
# The procedure gets a line from each input image and the output line
# buffer.  A procedure is called for either the weighted or unweighted
# average sigma clipping routine to combine the image lines.
# The output image header is updated to include a scaled and weighted
# exposure time and the number of images combined.

procedure imc_asigclipr (log, in, out, sig, nimages)

int	log			# Log file descriptor
pointer	in[nimages]		# Input images
pointer	out			# Output image
pointer	sig			# Sigma image
int	nimages			# Number of input images

real	low			# Low sigma cutoff
real	high			# High sigma cutoff

int	i, j, nc
pointer	sp, data, scales, zeros, wts, sigma, outdata, sigdata, v1, v2
bool	scale, imc_scales()
real	clgetr()
pointer	imgnlr()
pointer	impnlr()

begin
	if (nimages == 1) {
	    call imc_copyr (in[1], out)
	    return
	}

	if (nimages == 2)
	    call error (0, "Too few images for average sigma clipping")

	nc = IM_LEN(out,1)

	call smark (sp)
	call salloc (data, nimages, TY_INT)
	call salloc (scales, nimages, TY_REAL)
	call salloc (zeros, nimages, TY_REAL)
	call salloc (wts, nimages, TY_REAL)
	call salloc (sigma, nc, TY_REAL)
	call salloc (v1, IM_MAXDIM, TY_LONG)
	call salloc (v2, IM_MAXDIM, TY_LONG)
	call amovkl (long(1), Meml[v1], IM_MAXDIM)
	call amovkl (long(1), Meml[v2], IM_MAXDIM)

	# Get the sigma clipping, scaling and weighting factors.
	low = clgetr ("lowreject")
	high = clgetr ("highreject")
	scale = imc_scales ("avsigclip", log, low, high, in, out, Memr[scales],
	    Memr[zeros], Memr[wts], nimages)

	# For each line get input and ouput image lines and call a procedure
	# to perform the averge sigma clipping algorithm on the line.

	if (scale) {
	    while (impnlr (out, outdata, Meml[v1]) != EOF) {
		do i = 1, nimages {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = imgnlr (in[i], Memi[data+i-1], Meml[v1])
		}
	        call wtasigclipr (Memi[data], Memr[scales], Memr[zeros],
		    Memr[wts], Memr[outdata], Memr[sigma], nc, nimages,
		    low, high)
		if (sig != NULL) {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = impnlr (sig, sigdata, Meml[v1])
		    call wtsigmar (Memi[data], Memr[scales], Memr[zeros],
			Memr[wts], nimages, Memr[outdata], Memr[sigdata], nc)
		}
		call amovl (Meml[v1], Meml[v2], IM_MAXDIM)
	    }
	} else {
	    while (impnlr (out, outdata, Meml[v1]) != EOF) {
		do i = 1, nimages {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = imgnlr (in[i], Memi[data+i-1], Meml[v1])
		}
	        call asigclipr (Memi[data], Memr[outdata], Memr[sigma], nc,
		    nimages, low, high)
		if (sig != NULL) {
		    call amovl (Meml[v2], Meml[v1], IM_MAXDIM)
		    j = impnlr (sig, sigdata, Meml[v1])
		    call sigmar (Memi[data], nimages, Memr[outdata],
			Memr[sigdata], nc)
		}
		call amovl (Meml[v1], Meml[v2], IM_MAXDIM)
	    }
	}

	call sfree (sp)
end


# WTASIGCLIP -- Combine input data lines using the average sigma clip algorithm
# when weights and scale factors are not equal.

procedure wtasigclipr (data, scales, zeros, wts, output, sigma, npts, nlines,
	lowsigma, highsigma)

pointer	data[nlines]		# Data lines
real	scales[nlines]		# Scaling for images
real	zeros[nlines]		# Zero level for images
real	wts[nlines]		# Weights for images
real	output[npts]		# Output line (returned)
real	sigma[npts]		# Sigma line (returned)
int	npts			# Number of points per line
int	nlines			# Number of lines
real	highsigma		# High sigma rejection threshold
real	lowsigma		# Low sigma rejection threshold

int	i, j, k
real	resid, resid2, maxresid, maxresid2
real	sum, minwt, maxwt, wt, val, sig, sigall, low, high
pointer	sp, mean

begin
	call smark (sp)
	call salloc (mean, npts, TY_REAL)

	# Compute the scaled and weighted mean with and without rejecting
	# the minimum and maximum points.

	do i = 1, npts {
	    sum = 0.
	    low = Memr[data[1]+i-1] / scales[1] - zeros[1]
	    high = Memr[data[2]+i-1] / scales[2] - zeros[2]
	    if (low < high) {
		minwt = wts[1]
		maxwt = wts[2]
	    } else {
		minwt = low
		low = high
		high = minwt
		minwt = wts[2]
		maxwt = wts[1]
	    }
	    do j = 3, nlines {
		val = Memr[data[j]+i-1] / scales[j] - zeros[j]
		wt = wts[j]
		if (val < low) {
		    sum = sum + minwt * low
		    low = val
		    minwt = wt
		} else if (val > high) {
		    sum = sum + maxwt * high
		    high = val
		    maxwt = wt
		} else
		    sum = sum + wt * val
	    }
	    Memr[mean+i-1] = sum / (1 - minwt - maxwt)
	    sum = sum + minwt * low + maxwt * high
	    output[i] = sum
	}

	# Compute sigma at each point and the average line sigma.  Correct
	# individual residuals for the image scaling and the sigma at each
	# for variation in the mean intensity at that point.

	sigall = 0.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = 0.
	    do j = 1, nlines {
		resid = (Memr[data[j]+i-1]/scales[j]-zeros[j] - val) * wts[j]
		sig = sig + resid ** 2
	    }
	    if (val > 0.)
	        sigma[i] = sqrt (val)
	    else
	        sigma[i] = 1.
	    sigall = sigall + sqrt (sig) / sigma[i]
	}
	sigall = sigall / sqrt (real (nlines-1)) / npts
	do i = 1, npts
	    sigma[i] = sigall * sigma[i]

	# Reject pixels.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = sigma[i]
	    low = -lowsigma * sig
	    high = highsigma * sig

	    maxresid = (Memr[data[1]+i-1]/scales[1]-zeros[1] - val) * wts[1]
	    maxresid2 = maxresid ** 2
	    k = 1
	    do j = 2, nlines {
	        resid = (Memr[data[j]+i-1]/scales[j]-zeros[j] - val) * wts[j]
		resid2 = resid ** 2
		if (resid2 > maxresid2) {
		    maxresid = resid
		    maxresid2 = resid2
		    k = j
		}
	    }
	    if ((maxresid > high) || (maxresid < low)) {
		output[i] = (output[i] - (Memr[data[k]+i-1] / scales[k] -
		    zeros[k]) * wts[k]) / (1 - wts[k])
		Memr[data[k]+i-1] = INDEFR
	    }
	}

	call sfree (sp)
end


# ASIGCLIP -- Combine input data lines using the average sigma clip algorithm
# when weights and scale factors are equal.

procedure asigclipr (data, output, sigma, npts, nlines, lowsigma, highsigma)

pointer	data[nlines]		# Data lines
real	output[npts]		# Mean line (returned)
real	sigma[npts]		# Sigma line (returned)
int	npts			# Number of points per line
int	nlines			# Number of lines
real	highsigma		# High sigma rejection threshold
real	lowsigma		# Low sigma rejection threshold

int	i, j, k
real	resid, resid2, maxresid, maxresid2
real	sum, val, sig, sigall, low, high
pointer	sp, mean

begin
	call smark (sp)
	call salloc (mean, npts, TY_REAL)

	# Compute the mean with and without rejecting the extrema.
	do i = 1, npts {
	    sum = 0.
	    low = Memr[data[1]+i-1]
	    high = Memr[data[2]+i-1]
	    if (low > high) {
		val = low
		low = high
		high = val
	    }
	    do j = 3, nlines {
		val = Memr[data[j]+i-1]
		if (val < low) {
		    sum = sum + low
		    low = val
		} else if (val > high) {
		    sum = sum + high
		    high = val
		} else
		    sum = sum + val
	    }
	    Memr[mean+i-1] = sum / (nlines - 2)
	    sum = sum + low + high
	    output[i] = sum / nlines
	}

	# Compute sigma at each point and the average line sigma.  Correct
	# the sigma at each point for variation in the mean intensity at
	# that point.

	sigall = 0.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = 0.
	    do j = 1, nlines {
		resid = Memr[data[j]+i-1] - val
		sig = sig + resid ** 2
	    }
	    if (val > 0.)
	        sigma[i] = sqrt (val)
	    else
	        sigma[i] = 1.
	    sigall = sigall + sqrt (sig) / sigma[i]
	}
	sigall = sigall / sqrt (real (nlines-1)) / npts
	do i = 1, npts
	    sigma[i] = sigall * sigma[i]

	# Reject pixels.
	do i = 1, npts {
	    val = Memr[mean+i-1]
	    sig = sigma[i]
	    low = -lowsigma * sig
	    high = highsigma * sig

	    maxresid = Memr[data[1]+i-1] - val
	    maxresid2 = maxresid ** 2
	    k = 1
	    do j = 2, nlines {
	        resid = Memr[data[j]+i-1] - val
		resid2 = resid ** 2
		if (resid2 > maxresid2) {
		    maxresid = resid
		    maxresid2 = resid2
		    k = j
		}
	    }
	    if ((maxresid > high) || (maxresid < low)) {
		output[i] = (nlines*output[i] - Memr[data[k]+i-1]) / (nlines-1)
		Memr[data[k]+i-1] = INDEFR
	    }
	}

	call sfree (sp)
end