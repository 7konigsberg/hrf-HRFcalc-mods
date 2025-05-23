% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/HRF_calc.R
\name{HRF_main}
\alias{HRF_main}
\title{Canonical (double-gamma) HRF}
\usage{
HRF_main(t, a1 = 6, b1 = 1, a2 = NULL, b2 = NULL, c = 1/6, o = 0)
}
\arguments{
\item{t}{time vector (in seconds). Must be equally spaced.}

\item{a1}{delay of response. Default: \code{6}}

\item{b1}{response dispersion. Default: \code{1}}

\item{a2}{delay of undershoot. Default: \code{16/6*a1 = 16}}

\item{b2}{dispersion of undershoot. Default: \code{b1 = 1}}

\item{c}{scale of undershoot. Default: \code{1/6}}

\item{o}{onset of response (in seconds). Default: \code{0}}
}
\value{
HRF vector corresponding to time vector t
}
\description{
Calculate the HRF from a time vector and parameters. Optionally compute the
first or second derivative of the HRF instead. Form of HRF is similar to SPM
but here the response and undershoot are scaled so the difference of the HRFs
peaks at 1 and -c
}
\examples{
upsample <- 100
HRF_main(seq(0, 30, by=1/upsample))

}
