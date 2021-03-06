% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MatLDA_Grid.R
\name{MatLDA_Grid}
\alias{MatLDA_Grid}
\title{Fits the \eqn{J}-class penalized matrix-normal model for a two-dimensional grid of tuning parameters. Used for tuning parameter selection. }
\usage{
MatLDA_Grid(X, class, lambda1, lambda2, quiet = TRUE, Xval = NULL,
  classval = NULL, k.iter = 100, cov.tol = 1e-05, m.tol = 1e-05,
  full.tol = 1e-06)
}
\arguments{
\item{X}{An \eqn{r \times c \times N} array of training set predictors.}

\item{class}{\eqn{N}-vector of training set class labels; should be numeric from \eqn{\left\{1,...,J\right\}}.}

\item{lambda1}{A vector of non-negative candidate tuning parameters for the mean penalty.}

\item{lambda2}{A vector of non-negative candidate tuning parameters for the Kronecker penalty.}

\item{quiet}{Logical. Should the objective function value be printed at each update? Default is \code{TRUE}. Note that \code{quiet=FALSE} will increase computational time.}

\item{Xval}{An \eqn{r \times c \times N_{\rm val}} array of validation set predictors. Default is \code{NULL}. }

\item{classval}{\eqn{N_{\rm val}}-vector of validation set class labels; should be numeric from \eqn{\left\{1,...,J\right\}}.Default is \code{NULL}.}

\item{k.iter}{Maximum number of iterations for full blockwise coordinate descent algorithm. Default is 100.}

\item{cov.tol}{Convergence tolerance for graphical lasso subalgorithms; passed to \code{glasso}. Default is \eqn{1e^{-5}}.}

\item{m.tol}{Convergence tolerance for mean update alternating minimization algorithm. Default is \eqn{1e^{-5}}. It is recommended to track the objective function value using \code{quiet = FALSE} and adjust tolerance if necessary.}

\item{full.tol}{Convergence tolerance for full blockwise coordinate descent algorithm; based on decrease in objective function value. Default is \eqn{1e^{-6}}. It is recommended to track the objective function value using \code{quiet = FALSE} and adjust tolerance if necessary. }
}
\value{
\item{Val.mat}{A matrix of dimension \code{length}(lambda1) \eqn{\times}\code{length}(lambda2) with validation set misclassification propotions.}

\item{G.mat}{A matrix of dimension \code{length}(lambda1) \eqn{\times}\code{length}(lambda2) with the number of pairwise mean differences that are zero, i.e., a larger entry corresponds to a more sparse model.}

\item{U.mat}{A matrix of dimension \code{length}(lambda1) \eqn{\times}\code{length}(lambda2) with the number of zeros in \eqn{\hat{U}}.}

\item{V.mat}{A matrix of dimension \code{length}(lambda1) \eqn{\times}\code{length}(lambda2) with the number of zeros in \eqn{\hat{V}}.}
}
\description{
A function for fitting the penalized matrix normal model for a two-dimensional grid of tuning parameters. Meant to be used with a validation set to select tuning parameters. Can also be used inside a \eqn{k}-fold cross-validation function where the training set is the data outside the \eqn{k}th fold and the validation set is comprised of the \eqn{k}th fold sample data. 
}

\references{
\itemize{
\item Molstad, A. J., and Rothman, A. J. (2018). A penalized likelihood method for classification with matrix-valued predictors. \emph{Journal of Computational and Graphical Statistics}.
}
}



\examples{

## Generate realizations of matrix-normal random variables
## set sample size, dimensionality, number of classes, 
## and marginal class probabilities

N = 75
N.test = 150
N.val = 75

N.total = N + N.test + N.val

r = 16
p = 16
C = 3

pi.list = rep(1/C, C)

## create class means
M.array = array(0, dim=c(r, p, C))
M.array[3:4, 3:4, 1] = 1
M.array[5:6, 5:6, 2] = .5
M.array[3:4, 3:4, 3] = -2
M.array[5:6, 5:6, 3] = -.5


## create covariance matrices U and V
Uinv = matrix(0, nrow=r, ncol=r)
for (i in 1:r) {
	for (j in 1:r) {
		Uinv[i,j] = .5^abs(i-j)
	}
}

eoU = eigen(Uinv)
Uinv.sqrt = tcrossprod(tcrossprod(eoU$vec, 
diag(eoU$val^(1/2))),eoU$vec)

Vinv = matrix(.5, nrow=p, ncol=p)
diag(Vinv) = 1 
eoV = eigen(Vinv)
Vinv.sqrt = tcrossprod(tcrossprod(eoV$vec, 
diag(eoV$val^(1/2))),eoV$vec)

## generate N.total realizations of matrix-variate normal data
set.seed(10)
dat.array = array(0, dim=c(r,p,N.total))
class.total = numeric(length=N.total)
for(jj in 1:N.total){
	class.total[jj] = sample(1:C, 1, prob=pi.list)
	dat.array[,,jj] = tcrossprod(crossprod(Uinv.sqrt, 
	matrix(rnorm(r*p), nrow=r)),
	Vinv.sqrt) + M.array[,,class.total[jj]]
}

## store generated data 
X = dat.array[,,1:N]
X.val = dat.array[,,(N+1):(N+N.val)]
X.test = dat.array[,,(N+N.val+1):N.total]

class = class.total[1:N]
class.val = class.total[(N+1):(N+N.val)]
class.test = class.total[(N+N.val+1):N.total]

## fit two-dimensional grid of tuning parameters; 
## measure classification accuracy on validation set
lambda1 = c(2^seq(-5, 0, by=1))
lambda2 = c(2^seq(-8, -4, by=1))
fit.grid = MatLDA_Grid(X=X, class=class, lambda1=lambda1, 
	lambda2=lambda2, quiet=TRUE,
	Xval=X.val, classval= class.val,
	k.iter = 100, cov.tol=1e-5, m.tol=1e-5, full.tol=1e-6)

## identify minimum misclassification proportion; 
## select tuning parameters corresponding to 
## smallest model at minimum misclassification proportion
CV.mat = fit.grid$Val.mat
G.mat = fit.grid$G.mat*(CV.mat==min(CV.mat))
ind1 = (which(G.mat==max(G.mat), arr.ind=TRUE))[,2]
ind2 = (which(G.mat==max(G.mat), arr.ind=TRUE))[,1]
out = unique(ind2[which(ind2==max(ind2))])
lambda1.cv = lambda1[out]
out2 = unique(max(ind1[ind2==out]))
lambda2.cv = lambda2[out2]

## refit model with sinlge tuning parameter pair
out = MatLDA(X=X, class=class, lambda1=lambda1.cv, 
	lambda2=lambda2.cv, quiet=FALSE,
	Xval=X.test, classval= class.test,
	k.iter = 100, cov.tol=1e-5, m.tol=1e-5, full.tol=1e-6)

## print misclassification proportion on test set 
out$Val

## print images of estimated mean differences
dev.new(width=10, height=3)
par(mfrow=c(1,3))
image(t(abs(out$M[,,1] - out$M[,,2]))[,r:1], 
main=expression(paste("|", hat(mu)[1], "-", hat(mu)[2], "|")), 
col = grey(seq(1, 0, length = 100)))
image(t(abs(out$M[,,1] - out$M[,,3]))[,r:1], 
main=expression(paste("|", hat(mu)[1], "-", hat(mu)[3], "|")), 
col = grey(seq(1, 0, length = 100)))
image(t(abs(out$M[,,2] - out$M[,,3]))[,r:1], 
main=expression(paste("|", hat(mu)[2], "-", hat(mu)[3], "|")), 
col = grey(seq(1, 0, length = 100)))

}