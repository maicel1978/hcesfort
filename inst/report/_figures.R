# Figures of the report. Plain ggplot2 code, meant to be edited: hcesfort
# exports no plotting function. Every figure is a dot with its interval,
# so that no estimate is shown without its uncertainty.

library(ggplot2)

# Dot and interval. `d` has the columns `estimate`, `ci_low`, `ci_high`
# and the ones named in `y`, `colour` and `facet`; estimates without an
# interval (exact in the sample) are drawn as a dot only. Estimates with
# low precision, when the column exists, are drawn hollow.
fig_dot <- function(d, y, xlab, colour = NULL, facet = NULL,
                    percent = TRUE) {
  d <- as.data.frame(d)
  d$hollow <- if (is.null(d$low_precision)) FALSE else d$low_precision
  d$.colour <- if (is.null(colour)) "all" else as.character(d[[colour]])
  dodge <- ggplot2::position_dodge(width = 0.5)
  g <- ggplot(d, aes(x = .data$estimate, y = .data[[y]],
                     colour = .data$.colour)) +
    geom_linerange(aes(xmin = .data$ci_low, xmax = .data$ci_high),
                   position = dodge, na.rm = TRUE) +
    geom_point(aes(shape = .data$hollow), size = 2.5, position = dodge) +
    scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1), guide = "none") +
    labs(x = xlab, y = NULL, colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = if (is.null(colour)) "none" else "bottom") +
    guides(colour = guide_legend(ncol = 1))
  if (percent) {
    g <- g + scale_x_continuous(labels = function(x) paste0(100 * x, "%"))
  }
  if (!is.null(facet)) {
    g <- g + facet_wrap(facet, scales = "free_y")
  }
  g
}
