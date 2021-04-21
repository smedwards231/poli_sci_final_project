library(car)
library(jtools)

m1 <- lm(mal_deaths ~ net_off_dev, data = df_norm_new)
m2 <- lm(mal_deaths ~ mal_dummy + net_off_dev + corrupt_est, data = df_norm_new)
m3 <- lm(mal_deaths ~ mal_dummy + net_off_dev + exports_goods_serv, data = df_norm_new)
m4 <- lm(mal_deaths ~ mal_dummy + net_off_dev + corrupt_est + rule_law_Est, data = df_norm_new)
m5 <- lm(mal_deaths ~ mal_dummy + net_off_dev + corrupt_est + rule_law_Est + exports_goods_serv, data = df_norm_new)

out <- export_summs(m1,m2,m3,m4,m5)
capture.output(out, file = "output.txt")