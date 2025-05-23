% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check_data_inputs.R
\name{format_nuisance}
\alias{format_nuisance}
\title{Format nuisance}
\usage{
format_nuisance(nuisance, nS_expect = NULL, nT_expect = NULL)
}
\arguments{
\item{nuisance}{The \code{nuisance} argument input. Will be formatted to a
\code{nS}-length list.}

\item{nS_expect}{The expected number of sessions, if known.}

\item{nT_expect}{The expected number of timepoints, if known. For
multi-session data this is a session-length vector.}
}
\value{
\code{nuisance}
}
\description{
Format nuisance for \code{BayesGLM}, \code{fit_bayesglm},
\code{multiGLM}, and \code{multiGLM_fun}.
}
\keyword{internal}
