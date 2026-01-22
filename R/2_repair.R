.is_intersection.geom <- function(ctdf, pc, next_pc) {
    ac = ctdf[.putative_cluster == pc, location] |>
        st_union() |>
        st_convex_hull()

    bc = ctdf[.putative_cluster == next_pc, location] |>
        st_union() |>
        st_convex_hull()

    o = st_intersects(ac, bc)

    any(lengths(o) > 0)
}


.is_intersection.knn <- function(ctdf, pc, next_pc) {
    x = ctdf[.putative_cluster %chin% c(pc, next_pc)]

    xy = x[, st_coordinates(location)]

    y = x$.putative_cluster

    n = nrow(x)

    n_min = min(tabulate(y))
    if (n_min < 3) {
        return(FALSE)
    }

    k = floor(sqrt(n))
    k = min(k, 15L, n - 1, n_min - 1)
    k = max(k, 2L)

    nn = FNN::get.knn(xy, k = k)$nn.index
    mix = mean(y[nn] != rep.int(y, times = k))

    p = mean(y == 1)
    mix_exp = 2 * p * (1 - p)

    mix >= 0.6 * mix_exp
}

.is_intersection <- function(ctdf, pc, next_pc) {
    if (.is_intersection.geom(ctdf, pc, next_pc)) {
        return(TRUE)
    } else {
        return(.is_intersection.knn(ctdf, pc, next_pc))
    }
}


.spatial_repair <- function(ctdf, time_contiguity) {
    olap = ctdf[!is.na(.putative_cluster), .(pc = .putative_cluster)] |> unique()

    olap[, next_pc := shift(pc, type = "lead")]

    olap[, is_overlap := .is_intersection(ctdf, pc, next_pc), by = .I]

    olap[,
        new_putative_cluster := cumsum(
            !shift(is_overlap, type = "lag", fill = FALSE)
        )
    ]

    setnames(olap, 'pc', '.putative_cluster')

    ctdf[
        olap,
        on = ".putative_cluster",
        .putative_cluster := i.new_putative_cluster
    ]

    # insure temporal contiguity
    if (time_contiguity) {
        ctdf[,
            .putative_cluster := {
                f = nafill(.putative_cluster, type = "locf")
                b = nafill(.putative_cluster, type = "nocb")
                fifelse(f == b, f, .putative_cluster)
            }
        ]
    }
}

#' Repair spatially overlapping adjacent putative clusters
#'
#' Iteratively merges temporally adjacent putative clusters whose convex hulls intersect.
#' This operates on the `.putative_cluster` column created by [slice_ctdf()] and updates it in-place.
#'
#' If `time_contiguity = TRUE`, missing `.putative_cluster` values between identical
#' forward- and backward-filled labels are filled, so each cluster becomes
#' temporally contiguous (short spatial outliers inside a cluster are absorbed).
#'
#' @param ctdf A `ctdf` object. Must contain `.putative_cluster` (typically produced by [slice_ctdf()]).
#' @param time_contiguity Logical; if `TRUE`, enforce temporal contiguity within clusters by filling
#' internal gaps as described above. Default is `TRUE`.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'

spatial_repair <- function(ctdf, time_contiguity = TRUE) {
    .check_ctdf(ctdf)

    repeat {
        n_prev = max(ctdf$.putative_cluster, na.rm = TRUE)

        .spatial_repair(ctdf, time_contiguity = time_contiguity)

        if (max(ctdf$.putative_cluster, na.rm = TRUE) == n_prev) break
    }

    ctdf[,
        .putative_cluster := .as_inorder_int(.putative_cluster)
    ]
}


#' Repair temporally overlapping putative clusters
#'
#' Merges `.putative_cluster` labels whose (trimmed) time domains overlap.
#' For each putative cluster, a time interval `[lo, hi]` is estimated from the
#' `timestamp` distribution after trimming a small fraction from each tail to
#' reduce sensitivity to single-point temporal outliers. Any clusters with
#' overlapping intervals are merged (transitively) using connected components on
#' an overlap graph.
#'
#' @param ctdf A `ctdf` object. Must contain `timestamp` and `.putative_cluster`.
#' @param trim Numeric in `[0, 0.5)`. Maximum fraction trimmed from each tail when
#'   estimating each cluster's time domain. The effective trim per cluster is
#'   `min(trim, 1 / n_i)` where `n_i` is the number of points in that cluster.
#'
#' @details
#' Clusters are merged using connected components of an *interval overlap graph*:
#' an undirected graph with one vertex per `.putative_cluster`, and an edge
#' between two vertices  if their trimmed time intervals overlap.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'
#' @export
temporal_repair <- function(ctdf, trim = 0.01) {
    x = ctdf[!is.na(.putative_cluster)]

    .trim_by_n = function(n, trim_max = trim, k = 1) {
        # keep at least k points potentially trimmed from each tail,
        # never exceed trim_max
        p = k / pmax(n, 1)
        pmin(trim_max, p)
    }

    dom = x[,
        {
            tr = .trim_by_n(.N, trim_max = trim)

            .(
                lo = quantile(timestamp, probs = tr, type = 8),
                hi = quantile(timestamp, probs = 1 - tr, type = 8),
                t_key = median(timestamp)
            )
        },
        by = .putative_cluster
    ]
    dom[, width := pmax(hi - lo, 0)]

    dom2 = copy(dom)
    setnames(dom2, paste0(names(dom), '2'))

    setkey(dom, lo, hi)
    setkey(dom2, lo2, hi2)

    pairs =
        foverlaps(
            x = dom,
            y = dom2,
            by.x = c("lo", "hi"),
            by.y = c("lo2", "hi2"),
            type = "any",
            mult = "all",
            nomatch = 0
        )[.putative_cluster < .putative_cluster2]

    pairs[, ov := pmax(0, pmin(hi, hi2) - pmax(lo, lo2))]

    edges = pairs[
        ov > 0,
        .(
            from = .putative_cluster,
            to = .putative_cluster2
        )
    ]

    g = igraph::graph_from_data_frame(
        edges,
        directed = FALSE,
        vertices = data.table(name = dom$.putative_cluster)
    )

    cc = igraph::components(g)$membership

    map = data.table(
        .putative_cluster = names(cc) |> as.integer(),
        merged = cc
    )[order(.putative_cluster)]

    dom[map, on = .(.putative_cluster), new_putative_cluster := i.merged]

    setorder(dom, t_key, lo)

    dom[, new_putative_cluster := .as_inorder_int(new_putative_cluster)]
    dom[, new_putative_cluster := new_putative_cluster + min(.putative_cluster)]

    ctdf[
        dom,
        on = .(.putative_cluster),
        .putative_cluster := new_putative_cluster
    ]

    ctdf[,
        .putative_cluster := .as_inorder_int(.putative_cluster)
    ]
}


.tail_repair <- function(ctdf) {
    x = ctdf[!is.na(.putative_cluster)]

    o = x[,
        {
            tr =
                st_as_sf(.SD) |>
                mutate(location_prev = lag(location)) |>
                dplyr::filter(!st_is_empty(location_prev)) |>
                rowwise() |>
                mutate(
                    track = rbind(
                        st_coordinates(location_prev),
                        st_coordinates(location)
                    ) |>
                        st_linestring() |>
                        list() |>
                        st_sfc()
                ) |>
                sf::st_set_geometry("track")

            nc = st_crosses(tr) |> sapply(length)
            list(ncrosses = nc, .id = .id[-1])
        },
        by = .putative_cluster
    ]

    o = o[,
        {
            any_cross = ncrosses > 0

            if (!any(any_cross)) {
                list(.i = .id)
            } else {
                core_seg = cummax(any_cross) & rev(cummax(rev(any_cross)))
                i1 = which(core_seg)[1]
                i2 = tail(which(core_seg), 1)

                ids = .id
                drop = !(seq_along(ids) >= i1 & seq_along(ids) <= i2)

                list(.i = ids[drop])
            }
        },
        by = .putative_cluster
    ]

    ctdf[.id %in% o$.i, .putative_cluster := NA]

    # rm n = 1
    x = ctdf[!is.na(.putative_cluster), .N, .putative_cluster][N <= 1]
    ctdf[.putative_cluster %in% x$.putative_cluster, .putative_cluster := NA]

    ctdf[, .putative_cluster := .as_inorder_int(.putative_cluster)]
}

#' Repair putative clusters by trimming track tails
#'
#' Removes leading and trailing "tail" portions of each `.putative_cluster` based on self-crossings
#' of the within-cluster track. The intent is to keep only the locally revisited core of a cluster
#'  and drop commuting legs at the both beginning and end.
#'
#' @details
#' If the track has any self-crossing steps, the kept "core" is defined as the contiguous block of
#' steps between the first and last crossing; all points outside this block are set to `NA` in
#' `.putative_cluster`. If a cluster has no self-crossings at all, the entire cluster is dropped
#' (all its points are set to `NA`).
#'
#' @param ctdf A `ctdf` object. Must contain `.id`, `timestamp`, `location`, and `.putative_cluster`.
#'
#' @return The input `ctdf`, invisibly, with `.putative_cluster` updated in-place.
#'
#' @export
tail_repair <- function(ctdf) {
    .check_ctdf(ctdf)

    repeat {
        n_prev = max(ctdf$.putative_cluster, na.rm = TRUE)

        .tail_repair(ctdf)

        if (max(ctdf$.putative_cluster, na.rm = TRUE) == n_prev) break
    }

    ctdf[,
        .putative_cluster := .as_inorder_int(.putative_cluster)
    ]
}
