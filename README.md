Quick Overview
==============
This is my try at a linking algorithm for single particle tracking, in 2D
timelapse movies. The basic idea follows from the observation that usually,
particle tracks are clearly discernible by eye, when plotting all the detected
spots in the video in a 3D plot (two spatial and one time dimensions), even
without prior knowledge of how trajectories would typically look like or which
detections are likely to be noise. Capturing this agnostic approach seems to
work well by using the 3D autocorrelation function of all the detections,
thereby giving us an idea of what trajectories would look like. Convoluting
the actual detections (viewed as a collection of delta peaks) with this
autocorrelation function produces a density function in the 3D space, where
now trajectories show up as connected clusters of high density. These can be
found by a combination of thresholding and watershed.

Usage
=====
To get started, download the repo and add everything in it to the MatLab path.
Then execute
```
trajs = find_trajs('checkACF', true);
```
which will prompt you to select a file containing detection data and run the
algorithm.

Auxiliary/Utilities
===================
The `auxiliary` folder contains some useful code snippets that either are used
by the main algorithm but are useful on their own as well (such as vol3d and
the progressbar) or that are useful in working with the main code, such as
producing a scatter plot of detections, aggregating detections from multiple
movies (see below).

The snippet `msd_from_detections.m` in principle is independent from the
linking algorithm, but works in the same framework. It estimates MSD of the
trajectories without doing the linking first. To that end, we simply exploit
the fact that the variance of the 3D autocorrelation of the detections is (as
long as it is dominated by the trajectories) the MSD. So if we are interested
only in the MSD of the particles, we can skip the linking! One drawback of this
method is that it is not clear until which lag times the obtained estimate is
accurate. On the other hand, some preliminary benchmarking on simulated data
suggests that MSD from detections and MSD from trajectories (the conventional
method) match very well for short times, while at long lag times they both
incur significant errors.

Assumptions of the algorithm
============================
Technically, the basic assumption of this algorithm about the data is that we
are dealing with a set of detections, where each detection either belongs to a
trajectory from some stationary increment process, or is noise. The process in
question is assumed to be identical for all trajectories, the noise detections
are assumed to be iid homogeneously distributed. In practice, these assumptions
do not have to be satisfied exactly, rather there are some guidelines for where
one would expect the linking to work well:
 + the crucial idea is that the correlation signal from the trajectories should
   be significantly bigger than the one from noise detections (otherwise it
   would not be clear, what to call noise in the first place!). This means there
   should be a sufficient number of trajectories in the detection volume to create
   a clean ACF, and correlations in the noise detections should be low.
 + if there are trajectories from multiple different processes, we have to have
   a way to disentangle the correlation functions. This point is still under
   development.
 + the data should be sufficiently homogeneous in time. The assumption of
   stationarity mentioned above is really one of the basic building blocks,
   since otherwise the averaged ACF would not make sense conceptually.

About the convolution
=====================
Using the convolution of the detections with the ACF is an uncontrolled
approximation. How would this work in a perfect world? We can assume the
underlying increment process to be Gaussian with zero mean (or even some
drifting mean, this would not change the argument). Then it is fully determined
by it's autocorrelation function $\gamma(t)$, which is related to the MSD $m(t)$ by the
relation
```
\gamma(t) = \frac{1}{2}\partial_t^2 m(t) + \delta(t)\partial_t m(t)\,,
```
which in its more useful discrete version reads
```
\gamma_k = \frac{1}{2}\left( m_{|k+1|} + m_{|k-1|} - 2*m_{|k|} \right)\,.
```
The MSD in turn is just the variance of the 3D autocorrelation we calculate for
this algorithm. So from this we can calculate a Gaussian likelihood for given
trajectories. Then the optimal solution to the linking problem would be to
optimize this likelihood over all possible trajectories. This however gives a
combinatorial explosion, which is the fundamental problem of linking in the
first place. For this reason, we stick with the uncontrolled approximation of
finding clusters in the convolution. This seems to work rather well, and it
makes sense intuitively. Note however, that it might lead to mislinking on
short time scales.

Aggregating movies with few trajectories
========================================
Linking movies that only have a few trajectories proves difficult, because the
correlation function picks up little signal (especially if the noise is also a
little correlated). This problem can be alleviated if there are many videos
whith similar dynamics. In that case, we can aggregate the detections from all
videos to calculate the correlation function and then use this pre-computed
correlation function on all movies individually
