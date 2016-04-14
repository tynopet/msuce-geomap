# Тут жопа, надо рефакторить
class Map
  constructor: ->
    do @initMap
    do @bindListeners

  initMap: =>
    #Карта 
    centerLatLng = new (google.maps.LatLng)(55.857, 37.690)
    mapOptions = 
      center: centerLatLng
      zoom: 17
    #Первый параметр - id карты, 2-ой - json с настройками
    @map = new (google.maps.Map)(document.getElementById('myMap'), mapOptions)
    do @addClickListener

  addClickListener: =>
    # Добавим событие на клик (ставить маркер)
    google.maps.event.addListener @map, 'click', (latlng) =>
      # Если есть какие-то маркеры - стираем нахер их
      if @markers
        disposeObjects @markers
        @markers = []
      x = latlng.latLng.lng()
      # x - широта
      y = latlng.latLng.lat()
      # y - долгота
      @createMarker x, y

  # Создание маркера и добавление события на открытие окна
  createMarker: (x, y) =>
    unless @markers
      @markers = []
    #Запилим маркер
    marker = new (google.maps.Marker)(
      position: new (google.maps.LatLng)(y, x)
      map: @map)
    #Добавим маркер в массив
    @markers.push marker


  draw: =>
    unless @markers
      alert 'Сначала поставьте точку!'
      return
    unless $('#length').val() or $('#height').val()
      alert 'Заполните все поля!'
      return
    # Создаем точки для прямоугольника
    @createMarker @markers[0].position.lng() + parseFloat($('#length').val()), @markers[0].position.lat()
    @createMarker @markers[0].position.lng() + parseFloat($('#length').val()), @markers[0].position.lat() + parseFloat($('#height').val())
    @createMarker @markers[0].position.lng(), @markers[0].position.lat() + parseFloat($('#height').val())
    # Загоняем их в путь
    path = []
    @markers.forEach (m) =>
      path.push 
        lat: m.position.lat()
        lng: m.position.lng()
    # Если что-то нарисовано - стираем нахуй
    if @polygon
      @polygon.setMap null
    @drawPoly path

  drawLine: (path) =>
    line = new google.maps.Polyline
      path: path
      geodesic: true
      strokeColor: '#FF0000'
      strokeOpacity: 1.0
      strokeWeight: 1
    line.setMap @map
    return line

  drawPoly: (path) =>
    @polygon = new google.maps.Polygon
      path:          path
      strokeColor:   '#FF0000'
      strokeOpacity: 0.8
      strokeWeight:  3
      fillColor:     '#FF0000'
      fillOpacity:   0.35
    @polygon.setMap @map

  # lat - y, lng - x
  drawGrid: =>
    verticalLength = parseFloat($('#verticalLength').val())
    horizontalLength = parseFloat($('#horizontalLength').val())
    unless @markers
      alert 'Сначала поставьте точку!'
      return
    unless verticalLength or horizontalLength
      alert 'Заполните все поля!'
      return
    if @linesX
      @disposeObjects @linesX
    if @linesY
      @disposeObjects @linesY
    @linesX = []
    @linesY = []

    # Строим горизонтальные линии
    i = @markers[0].position.lat()
    while i < @markers[3].position.lat()
      path = [{ lat: i, lng: @markers[0].position.lng() }, { lat: i, lng: @markers[1].position.lng() }]
      @linesX.push @drawLine path
      i += verticalLength
    # Строим вертикальные линии
    i = @markers[0].position.lng()
    while i < @markers[1].position.lng()
      path = [{ lat: @markers[0].position.lat(), lng: i }, { lat: @markers[3].position.lat(), lng: i }]
      @linesY.push @drawLine path
      i += horizontalLength
    do @checkPoints

  checkPoints: =>
    @points = []
    for linex in @linesX
      for liney in @linesY
        @points.push @findCrossPoint linex, liney

  findCrossPoint: (line1, line2) ->
    # Тут треш с уравнением прямой и поиском точки пересечения
    n1 = line1.getPath().getAt(1).lng() - line1.getPath().getAt(0).lng()
    n2 = line1.getPath().getAt(1).lat() - line1.getPath().getAt(0).lat()
    n3 = line2.getPath().getAt(1).lng() - line2.getPath().getAt(0).lng()
    n4 = line2.getPath().getAt(1).lat() - line2.getPath().getAt(0).lat()

    x = ((n3 * n2 * line1.getPath().getAt(0).lng()) + (n1 * n3 * (line2.getPath().getAt(0).lat() - line1.getPath().getAt(0).lat())) - (n4 * n1 * line2.getPath().getAt(0).lng())) / ((n3 * n2) - (n4 * n1))
    y = ((n2 / n1) * (x - line1.getPath().getAt(0).lng())) + line1.getPath().getAt(0).lat()
    return [y, x]

  sendData: =>
    if @points and @points.length != 0
      $('#ajax').html('<img id="ajax-gif" src="ajax.gif" width="30px" height="30px">')
      $.ajax
        type: 'POST'
        url: '/gmaps'
        data: 'points=' + JSON.stringify(@points)
        success: (data) ->
          if data.success == 'yep'
            $('#ajax-gif').remove()
            window.location.href = '/gmaps/download'
    else 
      alert 'Вы не нарисовали сетку!'


  disposeObjects: (objects) ->
    objects.forEach (o) ->
      o.setMap null


  bindListeners: =>
    # Реакция на клик очистить кнопку
    $('#clearMap').click =>
      @disposeObjects @markers
      if @polygon
        @polygon.setMap null
      @markers = []
    # Реакция на найти маркер
    $('#findPoint').click =>
      if $('#lng').val() and $('#lat').val()
        marker = @createMarker $('#lng').val(), $('#lat').val()
        @map.setCenter(marker.getPosition())
      else
        alert('Введите все координаты');
    # Реакция на кнопку нарисовать
    $('#drawPolygon').click =>
      do @draw 
    # Реакция на клик по рисованию сетки
    $('#drawGrid').click =>
      do @drawGrid
    # Скачаем файл
    $('#downloadFile').click =>
      do @sendData

#Чтобы ошибка не падала
google.maps.event.addDomListener window, 'load', -> new Map()