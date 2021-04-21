using CSV
using DataFrames
using StatsBase
using TableView
using Statistics
using LinearAlgebra
using Plots
using GLM
using Plotly


#import data
df = CSV.read("final_df_2.csv", DataFrame, header = true)
wdi_df = CSV.read("wdi_data_new.csv", DataFrame, header = true)

"""Locates the indices that contain the official wdi indicator estimate, rather than
percentile rank, standard error, etc. """
function find_estimate_indices()
    indices = Vector{}() #initialize vector of indices
    for i in 1:length(wdi_df[3])
        val = wdi_df[3][i]
        if val[end-7:end] == "Estimate" #only want indices that contain the string "Estimate"
            push!(indices, i)
        end
    end
    return indices
end

indices = find_estimate_indices()
cols = [1,3,17,18,19,20,21,22,23] #country name, indicator, and years 2011-2017
new_wdi = wdi_df[indices, cols]

""" Locates indices of the countries present in the malaria dataset (df) """
function find_country_of_interest_indices(df, new_wdi)
    indices = Vector{Int64}()
    for i in 1:length(new_wdi[1])
        for j in 1:length(df[1])
            if new_wdi[i,1] == df[j,2]
                if i ∉ indices #only find unique indices
                    push!(indices, i)
                end
            end
        end
    end
    return indices
end

countries = find_country_of_interest_indices(df, new_wdi)

final_wdi = new_wdi[countries,:]

""" Returns list of the indicator names present in the Indicator_Name column of
final_wdi """
function get_indicator_names()
    indicators = Vector{String}()
    for indicator in 1:length(final_wdi[2])
        if final_wdi[indicator,2] ∉ indicators
            push!(indicators, final_wdi[indicator,2])
        end
    end
    return indicators
end

indicators = get_indicator_names()

#import new data (done in Excel)
wdi_new = CSV.read("final_wdi_new.csv", DataFrame, header = true)

fulldf = innerjoin(df, wdi_new, makeunique = true, on =:Country_Name)

""" Returns rows with the correct year since the dataframe were joined only
by country name """
function get_indices_final()
    indices_final = Vector{Int}()
    for i in 1:length(fulldf[:,1])
        if fulldf[i,1] == fulldf[i,27]
            push!(indices_final, i)
        end
    end
    return indices_final
end

indices_final = get_indices_final()
final_df = fulldf[indices_final,:]
final_df = select!(final_df, Not(:Time_1)) #get rid of redundant column

""" Computes the a column vector with the averages of a list containing columns of interest """
function avg_indicator(columns_of_interest)
    avgs = Vector{}()
    for i in 1:length(final_df[32])
        count = 0
        sum = 0
        for val in columns_of_interest
            sum += final_df[i,val]
            count += 1
        end
        avg = sum/count
        push!(avgs, avg)
    end
    return avgs
end

""" Writes a text file of all correlations between all vectors in final_df
dataframe (contains indicators of interest), catches errors
for column vectors that contain missing values or for which correlations can't
be computed (i.e. returns MethodError) """

function print_all_correlations()
    open("corr_vals.txt", "w") do io
        for i in 1:34
            for j in 1:34
                try
                    correlation = cor(final_df[i], final_df[j])
                    write(io, "$i \t $j \n $correlation \n")
                catch y
                    if isa(y, MethodError)
                        continue
                    elseif isa(y, missing)
                        continue
                    end
                end
            end
        end
    end
end

""" Similar to print_all_correlations() but returns a vector of unique
values which can be sorted """

function find_all_correlations()
    all_corrs = Vector{Float64}()
    for i in 1:34, j in 1:34
        try
            correlation = cor(final_df[i], final_df[j])
            if correlation ∉ all_corrs
                push!(all_corrs, correlation)
            end
        catch y
            if isa(y, MethodError)
                continue
            end
        end
    end
    return all_corrs
end

all_cor = find_all_correlations()
vals = sort([abs(i) for i in all_cor], rev = true)

""" Prints output from find_all_correlations into a text file """

function print_unique_corrs()
    open("all_cors.txt", "w") do io
        for i in vals
            write(io, "$i \n")
        end
    end
end

""" Locates column vectors which contain missing values to ensure
those columns are excluded from future analyses (missing values get messy,
not dealing with them for this project)"""
function get_missing_indices()
    missing_vals = Vector{}()
    for j in 1:size(final_df, 2)
        for i in 1:size(final_df, 1)
            if ismissing(final_df[i,j])
                if j ∉ missing_vals
                    push!(missing_vals, j)
                end
            end
        end
    end
    return missing_vals
end

missing_indices = get_missing_indices()
exclude_indices = union(missing_indices, [1,2,3]) #also excludes year, country name, country code
final_df_not_missing = final_df[:, Not(exclude_indices)]

#easier to look at correlations with showtable function
#showtable(cor(Matrix(final_df_not_missing)))

""" Prints the column names of final_df to a text file, note: can be called
multiple times as dataframe updates and column names change """
function print_cols_final_df()
    open("col_names.txt", "w") do io
        for col in 1:length(names(final_df))
            write(io, "$col \t $(names(final_df)[col]) \n")
        end
    end
end

function compute_col_correlations(j)
    for i in 4:33
        println(cor(final_df[j], final_df[i]), "\t $i")
    end
end

""" Creates vector containing new column names for final_df_not_missing """
function name_new_cols()
    f = open("new_col_regress.txt", "r")
    names_cols = readlines(f)
    new_cols = Vector{String}()
    for line in names_cols
        line = split(line)
        push!(new_cols, line[2])
    end
    return new_cols
end

""" Creates vector of old column names to be replaced """
function name_old_cols()
    f = open("col_names_df_not_missing.txt", "r")
    names_cols = readlines(f)
    old_cols = Vector{String}()
    for line in names_cols
        line = split(line, "\t")
        push!(old_cols, strip(line[2]))
    end
    return old_cols
end

#renames columns
new_cols = name_new_cols()
old_cols = name_old_cols()
for i in 1:length(old_cols)
    rename!(final_df_not_missing, old_cols[i] => new_cols[i])
end

#creates copy -- will take norm of each col for df_norm later
df_norm = copy(final_df_not_missing)

""" Converts all int64 columns present in dataframe to float values for use in
future analyses"""
function convert_to_float()
    for col in 1:size(df_norm, 2)
        df_norm[col] = convert.(Float64,df_norm[col])
    end
end

convert_to_float()

#normalize the data for regressions
for col in eachcol(df_norm)
    normalize!(col)
end

""" Prints out text files for all possible regression analyses examining malaria deaths
with the normalized data in df_norm"""
function print_regressions()
    for i in propertynames(df_norm)
        result = lm((@eval @formula(mal_deaths ~ $i)), df_norm)
        open("regression_$i.txt", "w") do io
            write(io, "Regression for $i \n $result")
        end
    end
end

print_regressions()


function print_multivar_regression()
    result = lm( @formula(mal_deaths ~ net_off_dev + gov_effectiveness_est), df_norm)
    open("multivariate_regression.txt", "w") do io
        write(io, "Multivariate Regression \n $result")
    end
end

print_multivar_regression()

function col_mean(col)
    sum = 0
    count = 0
    for i in final_df_not_missing[col]
        sum += i
        count += 1
    end
    return sum/count
end

summarystats(final_df_not_missing[:mal_deaths])

function create_mal_dummy()
    dummy = Vector{Int}()
    for i in 1:length(final_df_not_missing[:mal_deaths])
        if final_df_not_missing[i, :mal_deaths] < 34.136688
            push!(dummy, 0)
        else
            push!(dummy, 1)
        end
    end
    return dummy
end

df_norm[:mal_dummy] = create_mal_dummy()

CSV.write("df_norm_new.csv", df_norm)
