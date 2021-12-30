################################################################################
################################################################################
### Aureliano Sancho Souza Paiva
### 
### ============================================================================
### ERA5 / ERA5 Land - 2m TEMPERATURE 
### ============================================================================

library(raster) ; library(rgdal) ;library(ncdf4) ; library(sf);library(sp);
library(stringr); library(data.table); library(maptools) ; library(lubridate)
library(ecmwfr)

nc <- nc_open("/Users/aurelianosancho/Documents/GitHub/teste_cornershop/chile_temp.nc") 


dname <- names(nc$var)[2] 
temp <- brick(nc[[1]], varname=dname, stopIfNotEqualSpaced=FALSE)

poly <- sf::read_sf("/Users/aurelianosancho/Downloads/chl_adm_bcn_20211008_shp/chl_admbnda_adm3_bcn_20211008.shp")

erat.df <- as.data.frame(temp, xy=TRUE, centroids=TRUE)

erat.df$era5.id <- as.numeric(rownames(erat.df)) 

erat.df <- data.table(erat.df)

erat.shp <- st_as_sf(erat.df, coords = c("x", "y"), crs = "+proj=longlat +datum=WGS84 +no_defs")
erat.shp <- sf::st_transform(erat.shp, st_crs(poly))


## SELECT THE POINTS LOCATED INSIDE 
erat.br = erat.shp[poly, ]
nrow(data.frame(erat.br)) 

#=========================================================================##
##== IDENTIFY THE CLOSEST ERA5 GRID-CENTROID FROM EACH OS.GRID-CENTROID ==##
#=========================================================================##

## GET THE NEAREST ERA5 GRID CELL FOR EACH OS.GRID
grid.era = st_join(poly, erat.br)
grid.era


rest <- data.frame(grid.era)

rest <- rest[,c("ADM2_ES",
                "X2019.10.17", "X2019.10.18", "X2019.10.19",
                "X2019.10.20", "X2019.10.21")]

group_rest <- rest %>% group_by(ADM2_ES)

group_rest = group_rest %>% summarise(
  day_17 = mean(X2019.10.17, na.rm = T),
  day_18 = mean(X2019.10.18, na.rm = T),
  day_19 = mean(X2019.10.19, na.rm = T),
  day_20 = mean(X2019.10.20, na.rm = T),
  day_21 = mean(X2019.10.21, na.rm = T)
)

group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Santiago","Provincia de Santiago")
group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Valparaíso","Provincia de Valparaíso")
group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Chacabuco","Provincia de Chacabuco")
group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Concepción","Provincia de Concepción")
group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Elqui","Provincia de Elqui")
group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Cordillera","Provincia de Cordillera")
group_rest$ADM2_ES = str_replace(group_rest$ADM2_ES,"Maipo","Provincia de Maipo")

res <- data.frame(county_origin=character(),
                  temperature = double(),
                  Date=integer(),
                  stringsAsFactors=FALSE)
for (i in 2:6){
  df = group_rest[,c(1,i)]
  df$Date <- 15+i
  colnames(df) <- colnames(res)
  res <- rbind(res, df)
}


write.csv(res,"/Users/aurelianosancho/Documents/GitHub/teste_cornershop/chile_temp.csv")


