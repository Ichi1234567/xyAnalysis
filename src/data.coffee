
    # data處理 START
    
    xy2polar = (pt) ->
        _x = pt.x
        _y = pt.y
        _d = [0, _PI, _PI, (2 * _PI)]
        _dim = [1, 2, 3, 4]
        _theta = _ATAN(_y / _x)
        _theta += if _x < 0 then (if _y < 0 then _d[2] else _d[1]) else (if _y < 0 then _d[3] else _d[0])
        _theta = _2PI - _theta
        _polar =
            r: _SQRT(_POW(_x, 2) + _POW(_y, 2))
            theta: _theta
        _polar


    # 評估函數(寫一下調適用demo page...)
    # x, y, zoom, convergence
    gridXSize = 20
    gridYSize = 20
    gx = 375
    gy = 300
    estFn = (inf) ->
        # zoom的啟用，還要根據mode...
        # auto(/absolute), fuzzy
        # real distance, abstract distance(<--default)
        zoom = if ((/^Number/g).test(typeDef(inf.zoom))) then (inf.zoom) else (1)
        gxSize = gridXSize * zoom
        gySize = gridYSize * zoom
        _result =
            grid: [
                Math.floor(inf.x / gxSize), Math.floor(inf.y / gySize),
                parseFloat(((inf.x % gxSize) / gxSize).toFixed(5)),
                parseFloat(((inf.y % gySize) / gySize).toFixed(5))]
            pos: [inf.x, inf.y]
            polar: xy2polar({
                "x": inf.x - gx,
                "y": inf.y - gy
            })

        _result

    fuzzyCtl = (gridInf) ->
        _result
    
    # zoom，可能可以調整成自訂數值
    _loopEst = (_dataIn, zoom) ->
        _result = []
        for _datai, i in _dataIn
            _pos_i = if (!!_datai.oriData) then (_datai.oriData) else (_datai)
            _estVal = estFn({
                "x": if (typeof _pos_i.x == "function") then _pos_i.x() else _pos_i.x,
                "y": if (typeof _pos_i.y == "function") then _pos_i.y() else _pos_i.y,
                "zoom": zoom
            })
            _entity =
                oriData: _datai
                estVal: _estVal
            _result.push(_entity)
        #for _datai, i in _result
        #    console.log("============")
        #    console.log("grid：" + _datai.estVal.grid.join())
        _result

    # data處理 END