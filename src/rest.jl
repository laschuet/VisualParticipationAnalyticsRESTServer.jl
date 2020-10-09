const API_ROOT = "/api/v1"
const DATASET_ROOT = "dataset"
const HEADERS = [
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "GET; POST; OPTIONS",
    "Access-Control-Allow-Origin" => "*",
    "Content-Type" => "application/json"
]

"""
    getdatasets(req::HTTP.Request)
"""
function getdatasets(req::HTTP.Request)
    filenames = readdir(DATASET_ROOT)
    datasets = []
    for (index, filename) in enumerate(filenames)
        push!(datasets, Dict("id" => index, "name" => filename))
    end
    return datasets
end

"""
    getcontribution(req::HTTP.Request)
"""
function getcontribution(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    contributionid = HTTP.URIs.splitpath(req.target)[6]
    database = SQLite.DB("$DATASET_ROOT/$datasetname")
    return DBInterface.execute(database, "SELECT * FROM contribution WHERE id = $contributionid") |> DataFrame
end

"""
    getcontributions(req::HTTP.Request)
"""
function getcontributions(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    database = SQLite.DB("$DATASET_ROOT/$datasetname")
    return DBInterface.execute(database, "SELECT * FROM contribution ORDER BY id") |> DataFrame
end

router = HTTP.Router()
HTTP.@register(router, "GET", "$API_ROOT/datasets", getdatasets)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/contribution/*", getcontribution)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/contributions", getcontributions)

"""
    jsonhandler(req::HTTP.Request)
"""
function jsonhandler(req::HTTP.Request)
    res = HTTP.handle(router, req)
    if Tables.istable(res)
        return HTTP.Response(200, HEADERS; body=arraytable(res))
    else
        return HTTP.Response(200, HEADERS; body=JSON3.write(res))
    end
end

"""
    start(port::Integer)
"""
function start(port::Integer)
    @async HTTP.serve(jsonhandler, HTTP.Sockets.localhost, port)
    println("REST server is running at http://localhost:$port")
end
