using CSV
using DataFrames
using StatsBase
using TableView
using Statistics

mal_death = CSV.read("malaria-death-rates.csv", DataFrame, header = true)
mal_end = CSV.read("malaria_endemic.csv", DataFrame, header = true)

colnames = [
"Time",
"Country_Name",
"Country_Code",
"Domestic_credit_provided_by_financial_sector_(% of GDP)",
"Exports_of_goods_and_services_(% of GDP)",
"External_debt_stocks_total_(DOD, current US)",
"Foreign_direct_investment_net_inflows_(BoP, current US)",
"GDP_(current US)",
"GDP_growth_(annual %)",
"Gross_capital_formation_(% of GDP)",
"High-technology_exports_(% of manufactured exports)",
"Immunization_measles_(% of children ages 12-23 months)",
"Imports_of_goods_and_services_(% of GDP)",
"Income_share_held_by_lowest_20%",
"Life_expectancy_at birth_total_(years)",
"Mortality_rate_under-5_(per 1,000 live births)",
"Net official development assistance and official aid received (current US)",
"Population growth (annual %)",
"Poverty headcount ratio at 1.90 a day (2011 PPP) (% of population)",
"Poverty headcount ratio at national poverty lines (% of population)",
"Prevalence of HIV, total (% of population ages 15-49)",
"Tax revenue (% of GDP)",
"Time required to start a business (days)",
"Total debt service (% of exports of goods, services and primary income)",
"Urban population growth (annual %)"]

rename!(mal_end, colnames) #get rid of $ in names

#showtable(describe(mal_end)) #get descriptive stats of mal_end dataframe

#merge datasets to include malaria incidence
colnames_inc = Vector{String}()
for name in names(mal_death)
    push!(colnames_inc, name)
end

colnames_inc[1] = "Country_Name"
colnames_inc[3] = "Time"
colnames_inc[4] = "Malaria_deaths"

rename!(mal_death, colnames_inc)
fulldf = join(mal_end, mal_death, makeunique = true, on = :Country_Name)

indices = Vector{Int}()
for i in 1:length(fulldf[:,1])
    if fulldf[i,1] == fulldf[i,27]
        push!(indices, i)
    end
end

final_df = fulldf[indices,:]

open("col_names.txt", "w") do io
    for col in 1:length(names(final_df))
        write(io, "$col \t $(names(final_df)[col]) \n")
    end
end

cor(final_df[25],final_df[28])

df = CSV.read("final_df_2.csv", DataFrame, header = true)

for j in 1:length(df[1,:])
    replace(df[:,j], NaN=>missing)
end
