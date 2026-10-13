# meta-ros enables suitesparse, which needs openblas; scarthgap has no openblas recipe
PACKAGECONFIG:remove = "suitesparse cxsparse"
