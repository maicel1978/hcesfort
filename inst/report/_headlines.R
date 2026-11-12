# Headlines of the report: one sentence per question, built from the
# estimates of _results.R. Each function picks the wording the data
# support (for example, it says that two intervals overlap instead of
# naming a single "greatest" risk) and stops with a message when an
# assumption of the sentence fails. The sentences, in English (en) and
# Spanish (es), are in `phrases`; the language comes from `params$lang`.

phrases <- list(
  exact = c(en = "exact in the sample, no interval",
            es = "exacto en la muestra, sin intervalo"),
  q1_top = c(
    en = "With the scenario %s, the greatest risk of inadequate intake is
      for %s: %s of households (%s).",
    es = "Con el escenario %s, el mayor riesgo de ingesta inadecuada es de
      %s: %s de los hogares (%s)."
  ),
  q1_overlap = c(
    en = "With the scenario %s, the highest estimated risk is for %s, %s of
      households (%s), but its interval overlaps that of %s (%s): the two
      cannot be ranked.",
    es = "Con el escenario %s, el mayor riesgo estimado es de %s, %s de los
      hogares (%s), pero su intervalo se solapa con el de %s (%s): no se
      pueden ordenar."
  ),
  q2 = c(
    en = "The risk for %s ranges from %s (%s) to %s (%s) across %s; %d of
      %d estimates have low precision.",
    es = "El riesgo de %s va de %s (%s) a %s (%s) según %s; %d de %d
      estimaciones tienen baja precisión."
  ),
  q3 = c(
    en = "Before fortification, %s supply %s (%s) of the %s of the apparent
      diet.",
    es = "Antes de fortificar, %s aportan el %s (%s) del %s de la dieta
      aparente."
  ),
  q4 = c(
    en = "%s reaches %s of households (%s); %s, the vehicle of narrowest
      reach, %s (%s).",
    es = "%s llega al %s de los hogares (%s); %s, el vehículo de menor
      alcance, al %s (%s)."
  ),
  q5_none = c(
    en = "Every household of the sample acquires at least one vehicle, in
      every domain.",
    es = "Todos los hogares de la muestra adquieren al menos un vehículo, en
      todos los dominios."
  ),
  q5 = c(
    en = "%s of households (%s) acquire none of the vehicles%s.",
    es = "El %s de los hogares (%s) no adquiere ninguno de los
      vehículos%s."
  ),
  q5_range = c(en = "; across the domains it ranges from %s to %s",
               es = "; según los dominios va de %s a %s"),
  q6 = c(en = "'%s' would lower the risk for %s by %s points (%s)",
         es = "'%s' reduciría el riesgo de %s en %s puntos (%s)"),
  q6_null = c(
    en = "; '%s' would not change the risk for %s detectably",
    es = "; '%s' no cambiaría el riesgo de %s de forma detectable"
  )
)

# The phrase `key` in `lang`, filled with `...`, on one line.
say <- function(key, lang, ...) {
  gsub("\\s+", " ", sprintf(phrases[[key]][[lang]], ...))
}

pct <- function(x, digits = 0) {
  ifelse(is.na(x), "NA", paste0(formatC(100 * x, format = "f",
                                        digits = digits), "%"))
}

# "95% CI a-b" (en) or "IC 95% a-b" (es), or the reason there is none.
ci_text <- function(lo, hi, level, lang, fmt = pct) {
  if (is.na(lo) || is.na(hi)) return(say("exact", lang))
  label <- c(en = paste(pct(level), "CI"), es = paste("IC", pct(level)))
  paste0(label[[lang]], " ", fmt(lo), "–", fmt(hi))
}

# Stop the report when a headline would not hold.
guard <- function(ok, message) {
  if (!isTRUE(ok)) stop("Headline guard: ", message, call. = FALSE)
  invisible(TRUE)
}

# Two estimates whose intervals do not overlap.
separated <- function(a, b) {
  !is.na(a$ci_low) && !is.na(b$ci_high) && a$ci_low > b$ci_high
}

headline_q1 <- function(q1, scenario, level, lang) {
  ref <- q1[q1$scenario == scenario & !is.na(q1$estimate), ]
  guard(nrow(ref) > 0, paste0("no estimate for the reference scenario '",
                              scenario, "'."))
  ref <- ref[order(-ref$estimate), ]
  top <- ref[1, ]
  ci <- ci_text(top$ci_low, top$ci_high, level, lang)
  if (nrow(ref) == 1 || separated(top, ref[2, ])) {
    return(say("q1_top", lang, scenario, top$nutrient, pct(top$estimate),
               ci))
  }
  say("q1_overlap", lang, scenario, top$nutrient, pct(top$estimate), ci,
      ref$nutrient[2], pct(ref$estimate[2]))
}

headline_q2 <- function(q2, nutrient, domain, lang) {
  d <- q2[q2$domain == domain & q2$nutrient == nutrient &
            !is.na(q2$estimate), ]
  guard(nrow(d) > 1, paste0("fewer than two estimates of ", nutrient,
                            " across '", domain, "'."))
  lo <- d[which.min(d$estimate), ]
  hi <- d[which.max(d$estimate), ]
  say("q2", lang, nutrient, pct(lo$estimate), lo$domain_value,
      pct(hi$estimate), hi$domain_value, domain, sum(d$low_precision),
      nrow(d))
}

headline_q3 <- function(q3, column, nutrient, level, lang) {
  d <- q3[q3$variable == column & !is.na(q3$estimate), ]
  guard(nrow(d) > 0, paste0("no food-group share for ", column, "."))
  guard(abs(sum(d$estimate) - 1) < 1e-6,
        paste0("the shares of ", column, " do not add up to 1."))
  top <- d[which.max(d$estimate), ]
  say("q3", lang, top$food_group, pct(top$estimate),
      ci_text(top$ci_low, top$ci_high, level, lang), nutrient)
}

headline_q4 <- function(q4, level, lang) {
  d <- q4[q4$level != "combined" & !is.na(q4$estimate), ]
  guard(nrow(d) > 0, "no vehicle coverage was estimated.")
  hi <- d[which.max(d$estimate), ]
  lo <- d[which.min(d$estimate), ]
  say("q4", lang, hi$vehicle, pct(hi$estimate),
      ci_text(hi$ci_low, hi$ci_high, level, lang), lo$vehicle,
      pct(lo$estimate), ci_text(lo$ci_low, lo$ci_high, level, lang))
}

headline_q5 <- function(q5, level, lang) {
  all <- q5[q5$domain == "all", ]
  guard(nrow(all) == 1, "no estimate of the households without vehicle.")
  d <- q5[q5$domain != "all" & !is.na(q5$none), ]
  if (all(c(all$none, d$none) == 0)) return(say("q5_none", lang))
  range <- if (nrow(d) > 0) {
    say("q5_range", lang, pct(min(d$none)), pct(max(d$none)))
  } else {
    ""
  }
  ci <- ci_text(all$ci_low, all$ci_high, level, lang)
  say("q5", lang, pct(all$none), ci, range)
}

# The largest fall in risk among the actions and, when there is one, an
# action whose interval includes zero (rows with se 0 are nutrients the
# action does not touch).
headline_q6 <- function(q6, level, lang) {
  d <- q6[!is.na(q6$estimate), ]
  guard(nrow(d) > 0, "no paired difference was estimated.")
  best <- d[which.min(d$estimate), ]
  guard(best$estimate < 0, "no action lowers the risk of any nutrient.")
  null <- d[d$se > 0 & !is.na(d$ci_low) & d$ci_low <= 0 & d$ci_high >= 0, ]
  points <- function(x) formatC(100 * x, format = "f", digits = 0)
  ci <- ci_text(-best$ci_high, -best$ci_low, level, lang, fmt = points)
  first <- say("q6", lang, best$action, best$nutrient,
               points(-best$estimate), ci)
  rest <- if (nrow(null) > 0) {
    say("q6_null", lang, null$action[1], null$nutrient[1])
  } else {
    ""
  }
  paste0(first, rest, ".")
}
