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

# Dot and interval of a table of `tables`: `x` is the column of the
# estimate, `ci_low` and `ci_high` its limits, `y` the column of the
# categories (drawn top to bottom in their order). `ref` adds a dashed
# vertical line at a reference value. Both axes have titles (R5).
fig_interval <- function(d, x, y, xlab, ylab, ref = NULL) {
  d <- as.data.frame(d)
  d[[y]] <- factor(d[[y]], levels = rev(unique(as.character(d[[y]]))))
  g <- ggplot(d, aes(x = .data[[x]], y = .data[[y]])) +
    geom_linerange(aes(xmin = .data$ci_low, xmax = .data$ci_high),
                   na.rm = TRUE) +
    geom_point(size = 2.5) +
    labs(x = xlab, y = ylab) +
    theme_minimal(base_size = 11)
  if (!is.null(ref)) {
    g <- g + geom_vline(xintercept = ref, linetype = 2)
  }
  g
}

# Coverage curve of the work queue (DR4), from `tables$queue`: the share
# linked (%) against the number of foods resolved in rank order, one line
# per measure. `measures` names the measures to draw (code = label); the
# point at 0 foods is the coverage reached today. `threshold` (%) is drawn
# as a dashed horizontal line.
fig_coverage_curve <- function(d, measures, threshold, xlab, ylab,
                               colour_lab) {
  long <- do.call(rbind, lapply(names(measures), function(m) {
    cum <- d[[paste0("cum_share_", m)]]
    own <- d[[paste0("share_", m)]]
    start <- cum[1] - ifelse(is.na(own[1]), 0, own[1])
    data.frame(resolved = c(0, d$rank), coverage = c(start, cum),
               measure = measures[[m]])
  }))
  long$measure <- factor(long$measure, levels = unname(measures))
  ggplot(long, aes(x = .data$resolved, y = .data$coverage,
                   colour = .data$measure)) +
    geom_hline(yintercept = threshold, linetype = 2) +
    geom_line() +
    geom_point(size = 2) +
    scale_x_continuous(breaks = unique(long$resolved)) +
    labs(x = xlab, y = ylab, colour = colour_lab) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
}
