library(tidyverse)
library(stringr)

data <- read_csv("data.csv") %>%
# data <- read_csv("data.csv") %>%
# data <- read_csv("data.csv") %>%
  group_by(Experimento, Filtro, Corrida, Cache, Archivo, Alto, Ancho) %>%
  summarise(
    Ciclos = min(Ciclos),
    n_iteraciones = n()
  ) %>%
  mutate(TipoFiltro = str_extract(Filtro, "\\w*"),
         Implementacion = str_extract(Filtro, "\\w*$"))

# resumenData <- data %>%
#   group_by(Experimento, Filtro, Cache, Archivo, TipoFiltro) %>%
#   summarise(
#     CiclosPromedio = mean(Ciclos),
#     CiclosMediana = median(Ciclos),
#     ErrorStd = sd(Ciclos)/sqrt(n()),
#     n = n()
#   ) %>%
#   ungroup()


# Exp1
# Fig1 En la img mas grande todos los 0 y asm
filtrosFig1a = c("Bordes ASM", "Bordes C O0", "Bordes C O1", "Bordes C O2", "Bordes C O3") 
filtrosFig1b = c("Nivel ASM", "Nivel C O0", "Nivel C O1", "Nivel C O2", "Nivel C O3") 
filtrosFig1c = c("Rombos ASM 8px word", "Rombos C O0", "Rombos C O1", "Rombos C O2", "Rombos C O3") 

data %>%
  filter(
    Experimento == "CvsASM",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% filtrosFig1a
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
    geom_boxplot() +
    scale_y_log10() +
    ylab("Log(Ciclos)") +
    theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
    ggtitle("Bordes")

ggsave("../doc/img/Fig1a.pdf")

data %>%
  filter(
    Experimento == "CvsASM",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% filtrosFig1b
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
    geom_boxplot() +
    scale_y_log10() +
    ylab("Log(Ciclos)") +
    theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
    ggtitle("Nivel")

ggsave("../doc/img/Fig1b.pdf")

data %>%
  filter(
    Experimento == "CvsASM",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% filtrosFig1c
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
    geom_boxplot() +
    scale_y_log10() +
    ylab("Log(Ciclos)") +
    theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
    scale_x_discrete(labels = c("Rombos ASM", "Rombos C O0", "Rombos C O1", "Rombos C O2", "Rombos C O3")) +
    ggtitle("Rombos")

ggsave("../doc/img/Fig1c.pdf")

filtrosFig1d = c("Rombos ASM 8px word", "Rombos C O3",
                 "Bordes ASM", "Bordes C O3",
                 "Nivel ASM", "Nivel C O3") 

data %>%
  filter(
    Experimento == "CvsASM",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% filtrosFig1d
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
    geom_boxplot() +
    scale_y_log10() +
    ylab("Log(Ciclos)") +
    theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
    scale_x_discrete(
      labels = c(
        "Bordes ASM", "Bordes C O3",
        "Nivel ASM", "Nivel C O3",
        "Rombos ASM", "Rombos C O3") 
        ) +
    ggtitle("O3 vs ASM")

ggsave("../doc/img/Fig1d.pdf")

# Fig2 Proporcion asm/03 en funcion del tamanio de imagen
filtrosFig2 = c("Bordes ASM", "Nivel ASM", "Rombos ASM 8px word",
                "Bordes C O3", "Nivel C O3", "Rombos C O3") 

data %>%
  filter(Experimento == "CvsASM", Cache == "cached", Filtro %in% filtrosFig2) %>%
  mutate(Implementacion = case_when(Implementacion == "word" ~ "ASM", T ~ Implementacion)) %>%
  ggplot(aes(x = Alto*Ancho, y = Ciclos, group = Filtro, color = Implementacion)) + 
    geom_point() +
    geom_smooth(method = "lm", se = T) +
    facet_wrap(~TipoFiltro, scales = "free_x") +
    scale_y_log10() +
    scale_x_log10() +
    ylab("Log(Ciclos)") +
    xlab("Log(Ancho*Alto)")

ggsave("../doc/img/Fig2.pdf")

# Exp2
# Fig Bordes ASM ciclos cacheado y no cacheado en funcion del tamanio de img
filtrosFig3 = c("Bordes ASM", "Bordes C O3")

data %>%
  filter(Experimento == "ASM_cachedImg", Filtro %in% filtrosFig3) %>%
  ggplot(aes(x = Alto*Ancho, y = Ciclos, group = Cache, color = Cache)) + 
  geom_point() +
  geom_smooth(method = "lm", se = T) +
  facet_wrap(~Filtro, scales = "free_x") +
  scale_y_log10() +
  scale_x_log10() +
  ylab("Log(Ciclos)") +
  xlab("Log(Ancho*Alto)")

ggsave("../doc/img/Fig3.pdf")

# Exp3
# Comparar las distintas implementaciones
data %>%
  filter(
    Experimento == "ASM_differentImplementations",
    Archivo == "BigFish.2048x1200.bmp",
    str_detect(Filtro, "Bordes ASM")
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
  geom_boxplot() +
  scale_y_log10() +
  ylab("Log(Ciclos)") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
  ggtitle("Bordes")

ggsave("../doc/img/Fig4a.pdf")

data %>%
  filter(
    Experimento == "ASM_differentImplementations",
    Archivo == "BigFish.2048x1200.bmp",
    str_detect(Filtro, "Nivel ASM")
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
  geom_boxplot() +
  scale_y_log10() +
  scale_x_discrete(labels=c("Nivel ASM doble ciclo", "Nivel ASM simple ciclo")) +
  ylab("Log(Ciclos)") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
  ggtitle("Nivel")

ggsave("../doc/img/Fig4b.pdf")

data %>%
  filter(
    Experimento == "ASM_differentImplementations",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% c("Rombos ASM 4px word", "Rombos ASM 4px word mod64 cmp", "Rombos ASM 4px word mod64 shift")
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
  geom_boxplot() +
  scale_y_log10() +
  ylab("Log(Ciclos)") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
  ggtitle("Rombos 4px por ciclo")

ggsave("../doc/img/Fig4c1.pdf")

data %>%
  filter(
    Experimento == "ASM_differentImplementations",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% c("Rombos ASM 4px word", "Rombos ASM 4px word OOO")
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
  geom_boxplot() +
  scale_y_log10() +
  ylab("Log(Ciclos)") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
  ggtitle("Rombos OOO")

ggsave("../doc/img/Fig4c2.pdf")

data %>%
  filter(
    Experimento == "ASM_differentImplementations",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% c("Rombos ASM 4px word", "Rombos ASM 8px word", "Rombos ASM 8px byte", "Rombos ASM 16px byte")
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
  geom_boxplot() +
  scale_y_log10() +
  ylab("Log(Ciclos)") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
  ggtitle("Rombos parelelización")

ggsave("../doc/img/Fig4c3.pdf")

data %>%
  filter(
    Experimento == "ASM_differentImplementations",
    Archivo == "BigFish.2048x1200.bmp",
    Filtro %in% c("Rombos ASM 16px byte", "Rombos ASM 16px byte pblendvb")
  ) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) +
  geom_boxplot() +
  scale_y_log10() +
  ylab("Log(Ciclos)") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust = 1)) +
  ggtitle("Rombos pblendvb")

ggsave("../doc/img/Fig4c4.pdf")


data <- read_csv("dataE2.csv") %>%
  # data <- read_csv("data.csv") %>%
  # data <- read_csv("data.csv") %>%
  group_by(Experimento, Filtro, Corrida, Cache, Archivo, Alto, Ancho) %>%
  summarise(
    Ciclos = min(Ciclos),
    n_iteraciones = n()
  ) %>%
  ungroup() %>%
  mutate(TipoFiltro = str_extract(Filtro, "\\w*"),
         Implementacion = str_extract(Filtro, "\\w*$"),
         Filtro = case_when(
           Filtro == "Bordes ASM doble ciclo" ~ "Bordes ASM por columnas",
           Filtro == "Bordes ASM" ~ "Bordes ASM por filas"
         ))


data %>%
  ggplot(aes(x = Alto*Ancho, y = Ciclos, group = Filtro, color = Filtro)) + 
  geom_point() +
  geom_smooth(method = "lm", se = T) +
  scale_y_log10() +
  scale_x_log10() +
  ylab("Log(Ciclos)") +
  xlab("Log(Ancho*Alto)")

ggsave("../doc/img/FigExp2.pdf")

data %>%
  mutate(Pixeles = Alto*Ancho) %>%
  ggplot(aes(x = Filtro, y = Ciclos, group = Filtro)) + 
  geom_boxplot() +
  facet_wrap(~Pixeles, scales = "free_x") +
  scale_y_log10() +
  ylab("Log(Ciclos)") +
  xlab("Log(Ancho*Alto)")


