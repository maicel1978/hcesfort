# Figures of both reports. Plain ggplot2 code, meant to be edited:
# hcesfort exports no plotting function. Every figure is built from the
# table of `tables` with the same id.

library(ggplot2)

# Dot and interval of a table of `tables`: `x` is the column of the
# estimate, `ci_low` and `ci_high` its limits, `y` the column of the
# categories (drawn top to bottom in their order). `ref` adds a dashed
# vertical line at a reference value; `facet` names a column of panels.
# Rows without an estimate (suppressed cells) are left out; estimates
# with a wide interval are drawn hollow. Both axes have titles (R5).
fig_interval <- function(d, x, y, xlab, ylab, ref = NULL, facet = NULL) {
  d <- as.data.frame(d)
  d <- d[!is.na(d[[x]]), , drop = FALSE]
  d[[y]] <- factor(d[[y]], levels = rev(unique(as.character(d[[y]]))))
  wide <- term("wide_interval", "precision_status")
  d$.hollow <- rep(FALSE, nrow(d))
  if (!is.null(d$precision_status)) d$.hollow <- d$precision_status %in% wide
  g <- ggplot(d, aes(x = .data[[x]], y = .data[[y]])) +
    geom_linerange(aes(xmin = .data$ci_low, xmax = .data$ci_high),
                   na.rm = TRUE) +
    geom_point(aes(shape = .data$.hollow), size = 2.5) +
    scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1), guide = "none") +
    labs(x = xlab, y = ylab) +
    theme_minimal(base_size = 11)
  if (!is.null(ref)) {
    g <- g + geom_vline(xintercept = ref, linetype = 2)
  }
  if (!is.null(facet)) {
    g <- g + facet_wrap(facet, scales = "free_y")
  }
  g
}

# Dumbbell (R10f): one row per category `y`, the comparator point
# (column `from`, hollow) joined to the scenario point (column `to`,
# filled) by a segment. Rows missing either point are left out. A dumbbell
# shows no uncertainty: the interval of the difference is in its table.
fig_dumbbell <- function(d, from, to, y, xlab, ylab, facet = NULL) {
  d <- as.data.frame(d)
  d <- d[!is.na(d[[from]]) & !is.na(d[[to]]), , drop = FALSE]
  d[[y]] <- factor(d[[y]], levels = rev(unique(as.character(d[[y]]))))
  g <- ggplot(d, aes(y = .data[[y]])) +
    geom_segment(aes(x = .data[[from]], xend = .data[[to]],
                     yend = .data[[y]]), colour = "grey50") +
    geom_point(aes(x = .data[[from]]), shape = 1, size = 2.5) +
    geom_point(aes(x = .data[[to]]), shape = 16, size = 2.5) +
    labs(x = xlab, y = ylab) +
    theme_minimal(base_size = 11)
  if (!is.null(facet)) {
    g <- g + facet_wrap(facet, scales = "free_y")
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
