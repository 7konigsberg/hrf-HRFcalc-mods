#' multiGLM0
#'
#' Performs classical GLM for task fMRI activation, comparing multiple designs
#'
#' @param BOLD,design,nuisance Session-length list of numeric matrices/arrays,
#'  each with volumes along the first dimension.
#' @param design_canonical TO DO
#' @inheritParams verbose_Param
#' @param meanTol,varTol Tolerance for mean, variance and SNR of each data location.
#'  Locations which do not meet these thresholds are masked out of the analysis.
#'  Default: \code{1e-6} for mean and variance, \code{50} for SNR.
# Note: \code{snrTol} currently not in use, but SNR maps are returned for visualization.
#'
#' @return A list with elements
#'  \describe{
#'    \item{bestmodel}{...}
#'    \item{Fstat}{...}
#'    \item{pvalF}{...}
#'  }
#'
#' @importFrom matrixStats colVars
#' @importFrom parallel detectCores makeCluster clusterMap stopCluster
#' @importFrom stats as.formula var
#' @importFrom fMRItools is_1 nuisance_regression scale_timeseries
#'
#' @export
multiGLM_fun <- function(
  BOLD,
  design,
  # Below arguments shared with `mutliGLM_cifti`.
  nuisance=NULL,
  design_canonical=NULL,
  verbose = 1,
  meanTol = 1e-6,
  varTol = 1e-6#,
  #snrTol = 50,
  #emTol = 1e-3
  ){

  scale_design <- FALSE

  # Argument checks. -----------------------------------------------------------
  ### Simple parameters. -------------------------------------------------------
  # In a separate function because these checks are shared with `BayesGLM`.
  BayesGLM_argChecks(
    Bayes=FALSE,
    verbose = verbose,
    meanTol = meanTol,
    varTol = varTol
  )

  # Modeled after `BayesGLM` ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #   But note that `BOLD`, `design`, and `nuisance` will be
  #   matrix/array rather than lists.
  ### Check `BOLD`. ------------------------------------------------------------
  nS <- 1
  if(nS!=1) stop("Not supported: multi-session in `multiGLM_fun`.")
  ### Check `design`. ----------------------------------------------------------
  # Make `design` a sessions-length list of design matrices.
  #   Get `nK`, `field_names`, and `do$perLocDesign`. Check for consistent dims
  #   across sessions.
  x <- format_design(design, scale_design=scale_design, nS_expect=nS)
  design <- x$design[[1]]
  nT <- x$nT
  nK <- x$nK
  nD <- x$nD
  field_names <- x$field_names
  design_names <- x$design_names
  x$per_location_design <- FALSE #workaround for multiGLM_fun since the multiple design matrices are not per-location in this case
  if(x$per_location_design) stop("Not supported: per-location design in `multiGLM_fun`.")
  rm(x)

  ### Get `session_names`. -----------------------------------------------------
  session_names <- "single_sess"
  names(BOLD) <- session_names
  names(design) <- session_names

  ### Check `nuisance`. --------------------------------------------------------
  if (!is.null(nuisance)) {
    nuisance <- format_nuisance(nuisance, nS_expect=nS, nT_expect=nT)[[1]]

    if (!is.null(names(nuisance)) && !all(names(nuisance) == session_names)) {
      #warning("Ignoring `names(nuisance)`; use `session_names` in `make_design`.")
    }
  }

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  valid_cols <- apply(design, 2, function(r){!all(is.na(r))})
  if (any(valid_cols==0)) { stop("Some tasks are missing from every session.") }

  any_bad_design_cols <- any(is.na(c(design[,valid_cols,])))
  if (any(is.na(c(design[,valid_cols,])))) {
    if (any_bad_design_cols) {
      stop("`design` has some sessions & tasks for which some data values ",
        "are `NA`. Partially missing data is not allowed. (Missing tasks ",
        "should have all `NA`.)")
    }
  }

  ### Get `nV`. ----------------------------------------------------------------
  nV <- list(T=NULL, D=nrow(BOLD))

  # QC mask. -------------------------------------------------------------------
  # Mask based on quality control metrics of the BOLD data.
  mask_qc <- do_QC(
    list(BOLD),
    meanTol=meanTol, varTol=varTol, verbose=verbose>0
  ) #, snrTol=snrTol)
  if (!any(mask_qc$mask)) { stop("No locations meeeting `meanTol` and `varTol`.") }
  if (any(!mask_qc$mask)) { BOLD <- BOLD[,mask_qc,drop=FALSE] }

  # Scale, nuisance regress, and/or concatenate session data. ------------------

  # Check for intercepts and flat columns in design and nuisance matrices.
  # Stop if any zero-var, zero-mean column exists.
  des_is_flat <- apply(abs(design) < 1e-8, 2, all)
  if (any(des_is_flat)) {
    stop("The design matrix has at least one column that is ",
      "flat (all values are near-zero).")
  }

  # Detect zero-var, nonzero-mean columns.
  des_is_intercept <- apply(design, c(2,3), var) < 1e-8
  if (any(colSums(des_is_intercept) > 1)) {
    stop("At least one design matrix has more than one intercept ",
      "column. That means they are collinear, which will cause problems ",
      "during GLM model estimation. Please fix.")
  }
  des_has_intercept <- any(des_is_intercept)

  # For nuisance: detect zero-var, nonzero-mean columns.
  if (!is.null(nuisance)) {
    nuis_is_intercept <- matrixStats::colVars(nuisance) < 1e-8
    nuis_has_intercept <- any(nuis_is_intercept)
  } else {
    nuis_has_intercept <- FALSE
  }

  #collect data and design matrices
  nK2 <- if (is.null(nuisance)) { 0 } else { ncol(nuisance) } #number of nuisance regressors

  # [TO DO] centering?

  # # Center design matrix.
  # des_means <- rep(colMeans(design[,valid_cols,,drop=FALSE]), nV$mdata)
  # design[,valid_cols,] <- design[,valid_cols,,drop=FALSE] - des_means

  result <- GLM_multi(y=t(BOLD), X=design, X2=nuisance, Xc=design_canonical, verbose=verbose)
}
