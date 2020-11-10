library(tidyverse)
library(yaml)

config <- here::here("config/config.yml") %>%
    read_yaml()
runRegEx <- paste(str_split(config$runs, " ")[[1]], collapse = "|")

counts <- here::here("data/aligned/counts/counts.out") %>%
    read_tsv(comment = "#") %>%
    pivot_longer(
        cols = ends_with("bam"),
        names_to = "Filename",
        values_to = "Count"
    ) %>%
    mutate(
        Filename = str_remove_all(Filename, "data/aligned/bam/"),
        Filename = str_remove_all(Filename, "/Aligned.sortedByCoord.out.bam")
    ) %>%
    separate(Filename, into = c("Run", "id", "sample"), sep = "/")

counts %>%
    group_by(
        Geneid, Chr, Start, End, Strand, Length, id, sample
    ) %>%
    summarise(Count = sum(Count), .groups = "drop") %>%
    unite(Filename, id, sample, sep = "/") %>%
    pivot_wider(names_from = Filename, values_from = Count) %>%
    write_tsv(
        here::here("data/aligned/counts/merged_counts.out")
    )
    
