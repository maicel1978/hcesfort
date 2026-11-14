# Published rows of Tables I and II of the NCHS data presentation standards
# for proportions: Parker JD, Talih M, Malec DJ, et al. Vital Health Stat
# 2(175), 2017 (revised 2021), Table I p. 8 and Table II p. 9 (PDF md5
# 2ae6002af069bb55f555e2e271f1908d). Typed by hand from the PDF; percent
# scale as published. `decision` is the published decision of each row
# (footnotes of the tables and text of pp. 8-9): "suppress" (relative CI
# width above 130%), "review" (fewer than 8 degrees of freedom),
# "complement" (presented with a note that its complement is suppressed),
# "present". Used by the tests of the Korn-Graubard interval (12d.3) and of
# flag_presentation() (12d.4).
nchs_published_rows <- function() {
  utils::read.csv(text = "
table,page,group,n,n_effective,percent,se,lower,upper,df,decision
I,8,Non-Hispanic white elevated,460,583.0,0.5,0.29,0.1,1.6,15,present
I,8,Non-Hispanic white normal,460,583.0,99.5,0.29,98.4,99.9,15,present
I,8,Non-Hispanic black elevated,447,145.3,2.0,1.17,0.3,6.4,13,suppress
I,8,Non-Hispanic black normal,447,145.3,98.0,1.17,93.6,99.7,13,complement
I,8,Non-Hispanic Asian elevated,164,124.8,0.9,0.83,0.0,5.1,13,suppress
I,8,Non-Hispanic Asian normal,164,124.8,99.1,0.83,94.9,100.0,13,complement
I,8,Hispanic elevated,589,946.8,2.5,0.51,1.4,4.1,15,present
I,8,Hispanic normal,589,946.8,97.5,0.51,95.9,98.6,15,present
II,9,Men Hispanic,169,124.0,52.2,4.49,42.0,62.3,11,present
II,9,Men Non-Hispanic white,384,246.0,38.6,3.10,32.0,45.6,15,present
II,9,Men Non-Hispanic black,195,242.2,34.9,3.06,28.3,42.1,12,present
II,9,Men Non-Hispanic Asian,74,108.7,47.8,4.79,36.0,59.7,7,review
II,9,Women Hispanic,184,152.0,36.1,3.89,27.7,45.1,12,present
II,9,Women Non-Hispanic white,466,296.4,34.3,2.76,28.4,40.5,15,present
II,9,Women Non-Hispanic black,175,235.3,25.1,2.83,18.8,32.2,12,present
II,9,Women Non-Hispanic Asian,82,108.4,25.0,4.16,15.8,36.2,7,review
", strip.white = TRUE)
}
