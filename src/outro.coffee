    # OVERLAY_MANAGER 所需的METHODs or VARIBALEs START
    # OVERLAY_MANAGER 所需的METHODs or VARIBALEs END

    # OVERLAY_MANAGER START
    _mgr = (_dataIn) ->
        __construct = _shell()
        _chainFn = chain(_mgrProto)
        extFn(__construct.prototype, _chainFn)
        _result = (new __construct(_dataIn))
        _result.update()
        _result

    _mgrProto = _mgr.prototype
    _mgrProto.reset = () ->
        _shellReset = _shellProto.reset
        _shellReset.call(@, "data")
        _shellReset.call(@, "bucketInf")
        # 更新
        @

    _mgrProto.insert = (data, opts) ->
        if (/^Array/g).test(typeDef(data))
            _shellInsert = _shellProto.insert
            _args = ["data"]
            #_args = [
            #    "data",
            #    {
            #        val: [5, 6, 7, 8]
            #    }]
            _inf =
                val: data,
                rule: ((data, inf) ->
                    _self = inf.self
                    _self.set("data", data.concat(inf.val))
                    _self
                )
            _args.push(_inf)
            _shellInsert.apply(@, _args)
        # 更新
        @.update()
        @

    _mgrProto.remove = (data, opts) ->
        _shellRemove = _shellProto.remove
        _sortFn = (a, b) ->
            return a - b
        _args = ["data"]
        _inf =
            val: data,
            rule: ((data, inf) ->
                _rmFn =
                    idx: ((data, inf) ->
                        idxa = (inf.idxa).sort(_sortFn)
                        for i in [(idxa.length - 1)...0]
                            data.splice(idxa[i], 1)
                    ),
                    _default: ((data, inf) ->
                        vals = inf.val
                        estVals = []
                        # 用global estimate value, 做排序後在移除(<--用來省部份loop時間)
                        # data的結果，是根據local estimate value排序後的結果
                        # 所以data也需要做global estimate排序
                        #for val_i i in vals
                        #    estVals.push(estFn({}))
                        #estVals = estVals.sort(_sortFn)
                        #for i in [(data.length - 1)...0]
                        #    for j in [(estVals.length - 1)...0]
                    )
                _self = inf.self
                _rmData = inf.val
                _type = if ((/^Array/g).test(typeDef(_rmData)) && _rmData.length) then "_default" else "idx"
                _rmFn[_type](data, inf)
            )
        _args.push(_inf)
        _shellRemove.apply(@, _args)
        # 更新
        @.update()
        @

    _mgrProto.listen = (evt, opts) ->
        if (/^String/g).test(typeDef(evt))
            # 基本上，應該只會用到這2種地圖事件
            _self = @
            _evts = ["zoom", "moveend"]
            _evts = _evts.join(",")
            regEvt = new RegExp(evt, "g")
            _map = _self.get("dataMap")
            if (_map? and typeof _map != "undefined" and regEvt.test(_evts))
                _defFn = ((/^Function/g).test(typeDef()))
                # 定義listen function
                # 只定義最後要幹嘛，如何去取得資料，資料轉換等...不做
                # 那邊使用options的data
                _optEvName = "optEvt"+ evt
                _optFn = if ((/^Function/g).test(typeDef(opts.fn))) then (opts.fn) else (() ->
                    _self.update()
                    @
                )
                _evtName = "dataEvt" + evt
                _evtFn = () ->
                    _args = _slice.call(arguments, 0)
                    _args.push(evt)
                    _optFn.apply(@, _args)
                    @
                    
                # 存到_INF，以便stop的時候，停止監聽
                _self.set(_evtName, _evtFn)
                # balala開始監聽
                _map.addListener(evt, _evtFn)
        @

    _mgrProto.stop = (evt) ->
        if (/^String/g).test(typeDef(evt))
            _evts = ["zoom", "moveend"]
            _evts = _evts.join(",")
            regEvt = new RegExp(evt, "g")
            _map = @.get("dataMap")
            if (_map? and typeof _map != "undefined" and regEvt.test(_evts))
                _evtName = "dataEvt" + evt
                _evtFn = @.get(_evtName)
                # balala停止監聽
                _map.removeListener(evt, _evtFn)
        @

    _mgrProto.usrs = (settings) ->
        @

    _mgrProto.update = () ->
        _dataIn = @.get("data")
        _map = @.get("dataMap")
        _zoom = _map.getZoomLevel() if (_map? and typeof _map isnt "undefined")
        # 更新資料
        _dataOut = _loopEst(_dataIn, _zoom)
        @.set("bucketInf", [])
        @.set("data", _dataOut)
        @

    _mgrProto.buckets = () ->
        _data = @.get("data")
        _data.sort((a, b) ->
            # .grid之後要改成名稱變數
            # 而且，也許還可以加上...fuzzy
            infA = a.estVal.grid
            infB = b.estVal.grid
            
            # s -> h ->l
            switch(true)
                when ((infA[0] - infB[0]) > 0)
                    result = 1
                when ((infA[0] - infB[0]) < 0)
                    result = -1
                else
                    switch(true)
                        when ((infA[1] - infB[1]) > 0)
                            result = 1
                        when ((infA[1] - infB[1]) < 0)
                            result = -1
                        else
                            result = 0
            result
        )

        _buckets = []
        _subBuck = [_data[0]]
        _baseInf = _data[0].estVal.grid
        for _datai, i in _data
            #console.log(_datai.estVal.grid)
            gridInf = _datai.estVal.grid
            beqGrid = gridInf[0] is _baseInf[0] and gridInf[1] is _baseInf[1]
            if i and beqGrid
                _subBuck.push(_datai)
            if !beqGrid
                _buckets.push({
                    grid: [_subBuck[0].estVal.grid[0], _subBuck[0].estVal.grid[1]]
                    vals: _subBuck
                })
                _subBuck = [_datai]
                _baseInf = _datai.estVal.grid

        _buckets.push({
            grid: [_subBuck[0].estVal.grid[0], _subBuck[0].estVal.grid[1]]
            vals: _subBuck
        })
        @.set("bucketInf", _buckets)

        _buckets

    # select a from b where c (in db)
    # -> search all? from ("buckets" || "data") where condition
    rsWord = ["Math"]
    rsWord = rsWord.join()
    lv = [
        "fn7",
        "* 6", "/ 6", "% 6",
        "+ 5", "- 5",
        "< 4", "<=4", "==4", ">=4", "> 4", "!=4",
        "! 3",
        "&&2",
        "||1",
    ]
    lv = lv.join()
    symMap = [
        "* 0", "/ 1", "% 2",
        "+ 3", "- 4",
        "< 5", "<=6", "==7", "> 9", ">=8", "!=a"
        "! b",
        "&&c",
        "||d",
        "[ e"
    ]
    symMap = symMap.join()
    symFn = [
        ((a, b) ->
            a * b),
        ((a, b) ->
            a / b),
        ((a, b) ->
            a % b),
        ((a, b) ->
            a + b),
        ((a, b) ->
            a - b),
        ((a, b) ->
            a < b),
        ((a, b) ->
            a <= b),
        ((a, b) ->
            a == b),
        ((a, b) ->
            a >= b),
        ((a, b) ->
            a > b),
        ((a, b) ->
            a != b),
        ((a) ->
            !a),
        ((a, b) ->
            a && b),
        ((a, b) ->
            a || b),
        ((a, b) ->
            a[b])
    ]
    exeConds = (_data, token, cond) ->
        _bcond = false
        _opstack = []
        _varstack = []
        _posfix = []
        cond = cond.split(" ")
        for condi, i in cond
            if (condi.length)
                #debugger
                #console.log(condi)
                #console.log(_posfix.join())
                #console.log(_opstack.join())
                switch (true)
                    when ((/[\(]/g).test(condi)), ((/\[/g).test(condi))
                        _opstack.push(condi)
                    when ((/\)/g).test(condi))
                        #console.log("--- in ) ---")
                        while (_opstack.length)
                            _x = _opstack.pop()
                            if (_x == "(")
                                if (_opstack[_opstack.length - 1].indexOf(".") > 0 &&rsWord.indexOf(_opstack[_opstack.length - 1].split(".")[0]) > -1)
                                    _x = _opstack.pop()
                                    _posfix.push(_x)
                                break
                            else
                                _posfix.push(_x)
                        #console.log(_opstack.join())
                    when ((/\]/g).test(condi))
                        #console.log("--- in ) ---")
                        while (_opstack.length)
                            _x = _opstack.pop()
                            _posfix.push(_x)
                            if (_x == "[")
                                break
                        #console.log(_opstack.join())
                    when ((/[\[\]]/g).test(condi))
                        _posfix.push(condi)
                    when ((/[\+\-\*\/\!\%\&\|\>\=\<]+/g).test(condi)), (rsWord.indexOf(condi.split(".")[0]) > -1)
                        #console.log("--- in " + condi + " ---")
                        _idxx = lv.indexOf(condi)
                        _lvx = if (_idxx > -1) then (parseInt(lv.slice((_idxx + 2), (_idxx + 3)))) else (-1)
                        y = _opstack[_opstack.length - 1]
                        _idxy = lv.indexOf(y)
                        _lvy = if (_idxy > -1) then parseInt(lv.slice((_idxy + 2), (_idxy + 3))) else (-1)
                        #console.log(lv)
                        #console.log("idxx：" + lv.indexOf(condi) + lv.slice((_idxx + 2), (_idxx + 2)))
                        #console.log(y)
                        #console.log("lv1：" + _lvx)
                        #console.log("lv2：" + _lvy)
                        while (_lvy >= _lvx)
                            _posfix.push(_opstack.pop())
                            y = _opstack[_opstack.length - 1]
                            _idxy = lv.indexOf(y)
                            _lvy = if (_idxy > -1) then parseInt(lv.slice((_idxy + 2), (_idxy + 3))) else (-1)
                            #console.log("lv1：" + _lvx)
                            #console.log("lv2：" + _lvy)
                        _opstack.push(condi)
                        #console.log(_opstack.join())
                    when ((/,/g).test(condi))
                        while (_opstack.length)
                            x = _opstack[_opstack.length - 1]
                            if (x != "(")
                                _posfix.push(_opstack.pop())
                            else
                                break
                            #_posfix.push(condi)
                    when ((/^\d[\d]*.*[\d]*$/g).test(condi))
                        #console.log("--- in " + condi + " ---")
                        _posfix.push(condi)
                    else
                        tokenTab = new RegExp(condi, "g")
                        if (tokenTab.test(token))
                            #console.log("--- in token ---")
                            _posfix.push(condi)

        while (_opstack.length)
            _x = _opstack.pop()
            if (_x != "(")
                _posfix.push(_x)
        #console.log(_posfix.join(" "))
        anayName = (_data, name, token) ->
            #console.log("------- in anay -------")
            #console.log(name)
            nsp = true
            ((/^String/g).test(typeDef(name)) && (nsp = false))
            _result = if ((/^\d[\d]*.*[\d]*$/g).test(name) || nsp) then (name) else name.split(".")
            ((/^\d[\d]*.*[\d]*$/g).test(name) && (_result = parseFloat(_result)))
            #_result = if ((/^\d[\d]*.*[\d]*$/g).test(name)) then parseFloat(name) else name.split(".")
            if ((/^Array/g).test(typeDef(_result)))
                name = _result
                _result = if (rsWord.indexOf(name[0]) > -1) then (window[name.shift()]) else (_data)
                while name.length
                    _result = _result[name.shift()]
            _result
        # for test
        count = 0
        for _posi, i in _posfix
            if (!(/^String/g).test(typeDef(_posi)))
                continue
            if (((/[\+\-\*\/\!\%\&\|\>\=\<\[]+/g).test(_posi)) || (rsWord.indexOf(_posi.split(".")[0]) > -1))
                #console.log(_posfix.join())
                val1 = anayName(_data, _posfix[(i - 1)], token)
                val2 = anayName(_data, _posfix[(i - 2)], token)
                symIdx = symMap.indexOf(_posi)
                symIdx = parseInt(symMap.slice((symIdx + 2), (symIdx + 3)), 16)
                fn = symFn[symIdx]
            
                #console.log("==========================")
                #console.log(i + "："+ _posi)
                #console.log(fn)
                #console.log(val1)
                #console.log(val2)
                switch (true)
                    # !=
                    when (symIdx == 11)
                        _result = fn(val1)
                        _posfix.splice((i - 1), 2, _result)
                    # +, - (for sign)
                    when ((symIdx == 3 or symIdx == 4) && typeof val2 == "undefined")
                        _result = fn(0, val1)
                        _posfix.splice((i - 1), 2, _result)
                    # reserve word
                    when (rsWord.indexOf(_posi.split(".")[0]) > -1)
                        #console.log("in reserve word")
                        fn = anayName(_data, _posi, token)
                        fnLen = fn.length
                        args = []
                        while (fnLen)
                            args[fnLen - 1] = if ((/^String/g).test(typeDef(_posfix[i - fnLen]))) then ((_posfix[i - fnLen]).replace(",", "")) else (_posfix[i - fnLen])
                            fnLen--
                        #console.log(_posfix.join())
                        #console.log(args)
                        _result = fn.apply(this, args)
                        _posfix.splice((i - fn.length), (fn.length + 1), _result)
                    else
                        _result = fn(val2, val1)
                        _posfix.splice((i - 2), 3, _result)
                i = 0
                # for test,
                # if count > 1000, break the loop
                count++
                if (count > 1000)
                    break
        #console.log(_posfix)

        _result = if (_posfix[0]) then (_data) else (false)
        _result


    _mgrProto.search = (where, cond) ->
        _result = []
        _data = @.get(where)
        # find key
        if ((/^Array/).test(typeDef(_data)) and (/^String/g).test(typeDef(cond)))
            _cond = ""
            for i in [0...cond.length]
                #console.log((/[\+\-\*\/\!\%\&\|\(\)]/g).test(cond[i]))
                if ((/[\+\-\*\/\!\%\&\=\|\[\]\(\)\<\>\,]/g).test(cond[i]))
                    _cond += " " + cond[i] + " "
                else
                    _cond += cond[i]

            _regs = [
                /\&\s+\&/g, /\|\s+\|/g,
                /\=\s+\=/g, /\>\s+\=/g, /\<\s+\=/g, /\!\s+\=/g
            ]
            _replace = [
                "&&", "||", "==", ">=", "<=", "!="
            ]
            for _regsi, i in _regs
                _cond = _cond.replace(_regsi, _replace[i])
            _cond = _cond.replace(/[\s]+/g, " ")
            _cond = _cond.replace(/^[\s]*/g, "")
            _cond = _cond.replace(/[\s]*$/g, "")
            #console.log(_cond)

            token = _cond
            token = token.replace(/[^a-zA-Z_][\d\+\-\*\/\!\%\&\=\|\[\,\]\<\>]+/g, " ")
            token = token.replace(/[\(\)]+/g, " ")
            token = token.replace(/[\s]+/g, " ")
            token = token.replace(/^[\s]+/g, "")
            token = token.replace(/[\s]*$/g, "")
            #console.log(token)
            for _datai, i in _data
                _subResult = exeConds(_datai, token, _cond)
                if (!(/^Boolean/).test(typeDef(_subResult)))
                    _result.push(_subResult)
                #break
        _result

    # OVERLAY_MANAGER END
    
    window.world = _mgr
