$.Slider = (options, element) ->
  @$el = $(element)
  @_init options


  # Default Settings
$.Slider.defaults =
  current     : 0 # index of Current slide
  bgincrement : 50 # background offset in px
  interval    : 4000 # Interval between slides in autoplay mod
  #~
  autoplay    : false # Autoplay
  parallax    : true # On/Off parallax effect (killin` css3)
  autoHeight  : false # If true - will size wrap to highest slide
  useIcons    : false # In true - will add to navigation span class as data-ion in slide
  #~
  autoDir     : 'right' # Slide to right when in Autoplay mod
  prefix      : '' # Separate your sliders by adding prefix
  #~
  class       : # Use your own classes for elements (Defaults as in CSslider)
    slide     : '.da-slide' # Slide slide
    current   : 'da-slide-current' # Current slide
    navigation: '.da-dots' # Dot navigation wrap
    next      : '.da-arrows-next' # Next button
    prev      : '.da-arrows-prev' # Prev button
  #~
  animation   : # Name of end animation !!!Be careful, slider listen to this animation events!!!
    toRight   : 'to-r' # Animation to right
    toLeft    : 'to-l' # Animation to ledt



  # Slider Body
$.Slider:: =
  _init: (options) ->

    ### Define options ###
    @o = $.extend(true, {}, $.Slider.defaults, options)


    @$slides = @$el.children(@o.class.slide)
    @slidesCount = @$slides.length
    @current = @o.current
    @current = 0  if @current < 0 or @current >= @slidesCount
    @$slides.eq(@current).addClass @o.class.current


    ### Construct navigation###
    $navigation = $(@o.class.navigation)
    i = 0
    while i < @slidesCount
      if @o.useIcons is false
        $navigation.append "<span/>"
      else
        ico = @$slides.eq(i).data('ico')
        $navigation.append "<span class='#{ico}'/>"
      ++i

    @$navigation = $navigation
    @$pages = $("span", $navigation)
    @$navNext = $(@o.class.next, @$el.parent())
    @$navPrev = $(@o.class.prev, @$el.parent())

    ### Height Calculating ###
    @elHeight = (sl)->
      $height = 0
      for el in sl
        if $height < $(el).height()
          $height = $(el).height()
      return $height

    ### Max Height ###
    if @o.autoHeight is true
      _self = @
      @$el.height(@elHeight(@$slides)).trigger("sliderReady")
      $(window).resize ->
        _self.$el.height(_self.elHeight(_self.$slides))

    ### get animation ###
    @isAnimating = false
    @bgpositer = 0
    @cssAnimations = cssSupport('transition')
    @cssTransitions = cssSupport('animation')

    @$el.addClass "fb" if @cssAnimations is false or @cssTransitions is false
    @_updatePage()

    # load the events
    @_loadEvents()

    # slideshow
    @_startSlideshow()  if @o.autoplay

  _navigate: (page, dir) ->
    $current = @$slides.eq(@current)
    $next = undefined
    _self = this
    return false  if @current is page or @isAnimating
    @isAnimating = true

    # check direction
    classTo = undefined
    classFrom = undefined
    d = undefined
    unless dir
      (if (page > @current) then d = "next" else d = "prev")
    else
      d = dir
    if @cssTransitions and @cssAnimations
      if d is "next"
        classTo = @o.prefix+"to-l"
        classFrom = @o.prefix+"from-r"
        ++@bgpositer
      else
        classTo = @o.prefix+"to-r"
        classFrom = @o.prefix+"from-l"
        --@bgpositer
      @$el.css "background-position", @bgpositer * @o.bgincrement + "% 0%"
    @current = page
    $next = @$slides.eq(@current)
    if @cssTransitions and @cssAnimations
      rmClasses = @o.prefix+"to-l "+@o.prefix+"from-r "+@o.prefix+"to-r "+@o.prefix+"from-l"
      $current.removeClass rmClasses
      $next.removeClass rmClasses
      $current.addClass classTo
      $next.addClass classFrom
      $current.removeClass @o.class.current
      $next.addClass @o.class.current

    # fallback
    if not @cssAnimations or not @cssTransitions
      $next.css("left", (if (d is "next") then "100%" else "-100%")).stop().animate
        left: "0%"
      , 1000, ->
        _self.isAnimating = false
      $next.addClass @o.class.current
      $current.stop().animate
        left: (if (d is "next") then "-100%" else "100%")
      , 1000, ->
        $current.removeClass _self.o.class.current

    @_updatePage()

  _updatePage: ->
    @$pages.removeClass @o.class.current
    @$pages.eq(@current).addClass @o.class.current

  _startSlideshow: ->
    _self = this
    @slideshow = setTimeout(->
      page = (if (_self.current < _self.slidesCount - 1) then page = _self.current + 1 else page = 0)
      if _self.o.autoDir is 'left'
        page = (if (_self.current > 0) then page = _self.current - 1 else page = _self.slidesCount - 1)
        _self._navigate page, "prev"
      else
        _self._navigate page, "next"
      _self._startSlideshow()  if _self.o.autoplay
    , @o.interval)

  page: (idx) ->
    return false  if idx >= @slidesCount or idx < 0
    if @o.autoplay
      clearTimeout @slideshow
      @o.autoplay = false
    @_navigate idx

  _loadEvents: ->
    _self = this
    @$pages.on "click", (event) ->
      _self.page $(this).index()
      false

    @$navNext.on "click", (event) ->
      if _self.o.autoplay
        clearTimeout _self.slideshow
        _self.o.autoplay = false
      page = (if (_self.current < _self.slidesCount - 1) then page = _self.current + 1 else page = 0)
      _self._navigate page, "next"
      false

    @$navPrev.on "click", (event) ->
      if _self.o.autoplay
        clearTimeout _self.slideshow
        _self.o.autoplay = false
      page = (if (_self.current > 0) then page = _self.current - 1 else page = _self.slidesCount - 1)
      _self._navigate page, "prev"
      false

    if @cssTransitions
      _self = @
      unless @o.bgincrement
        @$el.on "webkitAnimationEnd.slider animationend.slider OAnimationEnd.slider", (event) ->
          _self.isAnimating = false  if event.originalEvent.animationName is _self.o.animation.toRight or event.originalEvent.animationName is _self.o.animation.toLeft

      else
        @$el.on "webkitTransitionEnd.slider transitionend.slider OTransitionEnd.slider", (event) ->
          _self.isAnimating = false  if event.target.id is _self.$el.attr("id")

# Checkin` css3 support without modernizr
cssSupport = (type)->
  b = document.body or document.documentElement
  s = b.style
  p = type
  return true  if typeof s[p] is "string"

  # Tests for vendor specific prop
  v = ["Moz", "Webkit", "Khtml", "O", "ms"]
  p = p.charAt(0).toUpperCase() + p.substr(1)

  i = 0

  while i < v.length
    return true  if typeof s[v[i] + p] is "string"
    i++
  false

# Log
logError = (message) ->
  console.error message  if @console

$.fn.slider = (options) ->
  if typeof options is "string"
    args = Array::slice.call(arguments_, 1)
    @each ->
      instance = $.data(this, "cslider")
      unless instance
        logError "cannot call methods on slider prior to initialization; " + "attempted to call method '" + options + "'"
        return
      if not $.isFunction(instance[options]) or options.charAt(0) is "_"
        logError "no such method '" + options + "' for slider instance"
        return
      instance[options].apply instance, args

  else
    @each ->
      instance = $.data(this, "slider")
      $.data this, "slider", new $.Slider(options, this)  unless instance

  this
