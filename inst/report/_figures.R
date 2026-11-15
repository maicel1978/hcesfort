# Figures of both reports. Plain ggplot2 code, meant to be edited:
# hcesfort exports no plotting function. Every figure is built from the
# table of `tables` with the same id.

library(ggplot2)

# Numbers on the axes with the thousands mark of the text (V-D25).
axis_numbers <- function() {
  scales::label_number(big.mark = term("big_mark", "format"))
}

# Dot and interval of a table of `tables`: `x` is the column of the
# estimate, `ci_low` and `ci_high` its limits, `y` the column of the
# categories (drawn top to bottom in their order). The value is printed
# beside each point, with the mark "†" when it is flagged for review
# (P9: one meaning per mark). `ref` adds a dashed vertical line at a
# reference value, or at the values of the column it names (one per
# panel); `facet` names a column of panels. `percent` draws a 0-100 axis.
# Rows without an estimate (suppressed) are not drawn. Both axes have
# titles (R5).
fig_interval <- function(d, x, y, xlab, ylab, ref = NULL, facet = NULL,
                         percent = FALSE) {
  d <- as.data.frame(d)
  d <- d[!is.na(d[[x]]), , drop = FALSE]
  d[[y]] <- factor(d[[y]], levels = rev(unique(as.character(d[[y]]))))
  mark <- if (is.null(d$mark)) "" else ifelse(is.na(d$mark), "", d$mark)
  d$.label <- paste0(format(d[[x]], trim = TRUE), mark)
  g <- ggplot(d, aes(x = .data[[x]], y = .data[[y]])) +
    geom_linerange(aes(xmin = .data$ci_low, xmax = .data$ci_high),
                   na.rm = TRUE) +
    geom_point(shape = 16, size = 2.5) +
    geom_text(aes(label = .data$.label), nudge_y = 0.3, size = 3,
              check_overlap = TRUE) +
    labs(x = xlab, y = ylab) +
    theme_minimal(base_size = 11)
  if (is.character(ref)) {
    g <- g + geom_vline(aes(xintercept = .data[[ref]]), linetype = 2)
  } else if (!is.null(ref)) {
    g <- g + geom_vline(xintercept = ref, linetype = 2)
  }
  if (!is.null(facet)) {
    g <- g + facet_wrap(facet, scales = "free_y")
  }
  limits <- if (percent) c(0, 100)
  g + scale_x_continuous(limits = limits, labels = axis_numbers())
}

# Effect of a scenario (section 6.3 of the design): two panels on shared
# rows `y`. Left, the dumbbell: the comparator (`from`, hollow) joined to
# the scenario (`to`, filled), % of households. Right, the paired
# difference (`difference`, with `ci_low` and `ci_high`) in percentage
# points, with a zero line in every band. `band` names a column of bands
# (one per scenario in R3.4). `panels` labels the two panels. Rows missing
# either point or the difference are not drawn; with none left the plot
# is empty.
fig_effect <- function(d, y, xlab, ylab, panels, band = NULL) {
  d <- as.data.frame(d)
  d <- d[!is.na(d$from) & !is.na(d$to) & !is.na(d$difference), ,
         drop = FALSE]
  if (nrow(d) == 0) {
    return(ggplot() + labs(x = xlab, y = ylab))
  }
  d[[y]] <- factor(d[[y]], levels = rev(unique(as.character(d[[y]]))))
  level_rows <- d
  level_rows$.panel <- factor(panels[[1]], levels = panels)
  diff_rows <- d
  diff_rows$.panel <- factor(panels[[2]], levels = panels)
  g <- ggplot(mapping = aes(y = .data[[y]])) +
    geom_segment(data = level_rows,
                 aes(x = .data$from, xend = .data$to, yend = .data[[y]]),
                 colour = "grey50") +
    geom_point(data = level_rows, aes(x = .data$from), shape = 1,
               size = 2.5) +
    geom_point(data = level_rows, aes(x = .data$to), shape = 16, size = 2.5) +
    geom_vline(data = data.frame(.panel = factor(panels[[2]],
                                                 levels = panels)),
               aes(xintercept = 0), linetype = 2) +
    geom_linerange(data = diff_rows, aes(xmin = .data$ci_low,
                                         xmax = .data$ci_high)) +
    geom_point(data = diff_rows, aes(x = .data$difference), shape = 16,
               size = 2.5) +
    scale_x_continuous(labels = axis_numbers()) +
    labs(x = xlab, y = ylab) +
    theme_minimal(base_size = 11) +
    theme(panel.spacing.x = grid::unit(2, "lines"))
  rows <- if (is.null(band)) NULL else vars(.data[[band]])
  g + facet_grid(rows = rows, cols = vars(.data$.panel), scales = "free",
                 space = "free_y")
}

# Weighted histogram of `x` (weights `w`), with dashed lines at `bounds`
# and a solid line at `reference` (D9: energy per AFE against the
# plausibility bounds and the reference energy).
fig_histogram <- function(d, x, w, bounds, reference, xlab, ylab,
                          bins = 40) {
  ggplot(as.data.frame(d), aes(x = .data[[x]], weight = .data[[w]])) +
    geom_histogram(bins = bins, fill = "grey70", colour = "white") +
    geom_vline(xintercept = bounds, linetype = 2) +
    geom_vline(xintercept = reference) +
    scale_x_continuous(labels = axis_numbers()) +
    scale_y_continuous(labels = axis_numbers()) +
    labs(x = xlab, y = ylab) +
    theme_minimal(base_size = 11)
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
    scale_x_continuous(breaks = function(x) unique(round(pretty(x))),
                       labels = axis_numbers()) +
    scale_y_continuous(labels = axis_numbers()) +
    labs(x = xlab, y = ylab, colour = colour_lab) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
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
