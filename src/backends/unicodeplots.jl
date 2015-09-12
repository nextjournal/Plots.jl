
# https://github.com/Evizero/UnicodePlots.jl

immutable UnicodePlotsPackage <: PlottingPackage end

# -------------------------------

function expandLimits!(lims, x)
  e1, e2 = extrema(x)
  lims[1] = min(lims[1], e1)
  lims[2] = max(lims[2], e2)
  nothing
end


# do all the magic here... build it all at once, since we need to know about all the series at the very beginning
function rebuildUnicodePlot!(plt::Plot)

  # figure out the plotting area xlim = [xmin, xmax] and ylim = [ymin, ymax]
  sargs = plt.seriesargs
  xlim = [Inf, -Inf]
  ylim = [Inf, -Inf]
  for d in sargs
    expandLimits!(xlim, d[:x])
    expandLimits!(ylim, d[:y])
  end
  x = Float64[xlim[1]]
  y = Float64[ylim[1]]

  # create a plot window with xlim/ylim set, but the X/Y vectors are outside the bounds
  iargs = plt.initargs
  width, height = iargs[:size]
  o = UnicodePlots.createPlotWindow(x, y; width = width,
                                height = height,
                                title = iargs[:title],
                                # labels = iargs[:legend],
                                xlim = xlim,
                                ylim = ylim)

  # set the axis labels
  UnicodePlots.xlabel!(o, iargs[:xlabel])
  UnicodePlots.ylabel!(o, iargs[:ylabel])

  # now use the ! functions to add to the plot
  for d in sargs
    addUnicodeSeries!(o, d, iargs[:legend])
  end

  # save the object
  plt.o = o
end


# add a single series
function addUnicodeSeries!(o, d::Dict, addlegend::Bool)

  # get the function, or special handling for step/bar/hist
  lt = d[:linetype]
  stepstyle = :post
  if lt == :line
    func = UnicodePlots.lineplot!
  elseif lt == :dots || d[:marker] != :none
    func = UnicodePlots.scatterplot!
  elseif lt == :step
    func = UnicodePlots.stairs!
  elseif lt == :stepinverted
    func = UnicodePlots.stairs!
    stepstyle = :pre
  else
    error("Linestyle $lt not supported by UnicodePlots")
  end
  
  # get the series data and label
  x, y = [collect(float(d[s])) for s in (:x, :y)]
  label = addlegend ? d[:label] : ""

  # if we happen to pass in allowed color symbols, great... otherwise let UnicodePlots decide
  color = d[:color] in UnicodePlots.autoColors ? d[:color] : :auto

  # add the series
  func(o, x, y; color = color, name = label, style = stepstyle)
end


# -------------------------------


function plot(pkg::UnicodePlotsPackage; kw...)
  plt = Plot(nothing, pkg, 0, Dict(kw), Dict[])

  # do we want to give a new default size?
  if !haskey(plt.initargs, :size) || plt.initargs[:size] == PLOT_DEFAULTS[:size]
    plt.initargs[:size] = (60,20)
  end

  plt
end

function plot!(::UnicodePlotsPackage, plt::Plot; kw...)
  d = Dict(kw)
  if d[:linetype] in (:sticks, :bar)
    d = barHack(; d...)
  elseif d[:linetype] == :hist
    d = barHack(; histogramHack(; d...)...)
  end
  push!(plt.seriesargs, d)
  plt
end

function Base.display(::UnicodePlotsPackage, plt::Plot)
  rebuildUnicodePlot!(plt)
  show(plt.o)
end

# -------------------------------

function savepng(::UnicodePlotsPackage, plt::PlottingObject, fn::String, args...) # = error("currently unsupported")
  display(plt)
  @osx_only begin
    run(`screencapture -w $fn`)
    return
  end
  error("Can only savepng on osx with UnicodePlots.")
end

# -------------------------------

# create the underlying object (each backend will do this differently)
function buildSubplotObject!(::UnicodePlotsPackage, subplt::Subplot)
  error("UnicodePlots doesn't support subplots")
end


function Base.display(::UnicodePlotsPackage, subplt::Subplot)
  error("UnicodePlots doesn't support subplots")
end
