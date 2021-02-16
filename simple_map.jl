using ArchGDAL; const AG = ArchGDAL
using ZipFile
using DataFrames
using Plots

function set_crs(geom::ArchGDAL.AbstractGeometry)
    # source = AG.importPROJ4("+proj=longlat +datum=NAD83")
    source = AG.getspatialref(geom)
    target = AG.importPROJ4("+proj=merc +datum=WGS84")
    # target = AG.importEPSG(4362)
    AG.createcoordtrans(source, target) do transform  
        AG.transform!(geom, transform)    
    end
end

function select_geom(df)
    for cols in names(df)
        if typeof(df[!,cols]) == Array{ArchGDAL.IGeometry,1}
            return columnindex(df, Symbol(cols))
        end
    end
end

"Draft a thematic map with dataframe as input"
function draft(shp)
    geom = shp[:, select_geom(shp)]
    plot(geom)
end

data = begin
    url = "https://www2.census.gov/geo/tiger/TIGER2019/COUNTY/tl_2019_us_county.zip"
    r = ZipFile.Reader(download(url))
    for f in r.files
        write(f.name, read(f))
    end
    AG.read("tl_2019_us_county.shp")
end

data = AG.read("tl_2019_us_county.shp")

layer = AG.getlayer(data, 0)
table = AG.Table(layer)
df = DataFrame(table)
periphery = [2, 15, 60, 66, 69, 72, 78]
# periphery = ["American Samoa", 
#             "Puerto Rico", 
#             "Alaska", 
#             "United States Virgin Islands",
#             "Commonwealth of the Northern Mariana Islands",
#             "Guam",
#             "Hawaii"]

mainland = filter(:STATEFP => x -> parse(Int, x) ∉ periphery, df)

mainland."" = set_crs.(mainland[:,:""])

colors = [palette(:matter, 78)[x] for x in parse.(Int, mainland.STATEFP)]
plot(mainland.:"", color = hcat(colors...))

# TODO 
# Add some demographic data and have a section where you connect to the 
# census api
# Map some publically available raster data for certain land use and do some
# analysis on that
