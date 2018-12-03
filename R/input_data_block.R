rescale <- function(x, x.min, x.max, n.divs) {
  range <- x.max - x.min + 0.0000001
  dist <- x - x.min
  floor(dist*n.divs / range)
}

# Example
x.min <- min(your.x.values)
x.max <- max(your.x.values)
n.divs <- 30 # number of divisions (blocks) you want in the x-coordinate
x.new <- lapply(your.x.vector, function(x) rescale(x, x.min, x.max, n.cells))