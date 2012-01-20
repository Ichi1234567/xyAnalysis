    # UTIL_VAR START

    _emptyFn = () -> 
    _MATH = Math
    _CEIL = _MATH.ceil
    _POW = _MATH.pow
    _SQRT = _MATH.sqrt
    _ATAN = _MATH.atan
    _PI = _MATH.PI
    _2PI = 2 * _PI
    _toString = Object.prototype.toString
    _slice = Array.prototype.slice

    # UTIL_VAR END

    # ROUTEINS START
    
    # 名字分析
    nameAnalysis = (name) ->
        prefix = ["^data", "^opt", "^def"]
        prename = ["DATA", "OPT", "DEF"]
        result =
            prefix: ""
            name: name
        for prefix_i, i in prefix
            reg_i = new RegExp(prefix_i, "g")
            (reg_i.test(name)) && (
                result =
                    prefix: prename[i],
                    name: (if prename[i] == (name.toUpperCase()) then name else name.replace(reg_i, ""))
                i = _len
            )
        result

    # 型別判斷
    typeDef = (val) ->
        _type = _toString.call(val).split(" ")[1].slice(0, -1)

    # 各型別初始
    _genInit = (_type) ->
        vals =
            Array: [],
            Boolean: false,
            Function: _emptyFn,
            Number: 0,
            String: "",
            Object: {}
        val = vals[_type]
        val = if (val? and typeof val isnt "undefined") then val else {}
        val

    # 擴充
    extFn = (entity, exts) ->
        for i of exts
            entity[i] = exts[i]
        entity

    # ROUTEINS END
    
    # CHAIN START
    
    chain = (() ->
        # recycled empty callback
        # used to avoid constructors execution
        # while extending
        __fn__ = () -> 
        
        # chain function
        ($prototype) ->
            # associate the object/prototype
            # to the __proto__.prototype
            # __fn__ == __proto__
            __fn__.prototype = $prototype
            # and create a chain
            new __fn__
    )()
    
    # CHAIN END
    
    # SHELL START
    ###
    * @name _shell
    ###
    _shell = () ->
        __construct = (_dataIn) ->
            _INF =
                DEF: {},
                DATA: {},
                OPT: {}

            for i of _dataIn
                _datai = _dataIn[i]
                _type = typeDef(_datai)
                nameInf = nameAnalysis(i)
                _prefix = if (not nameInf.prefix) then "OPT" else nameInf.prefix
                _name = nameInf.name
                _INF["DEF"][i] = _type
                _INF[_prefix][_name] = _datai

            _publish =
                get: ((name) ->
                    nameInf = nameAnalysis(name)
                    _prefix = if (not nameInf.prefix) then "OPT" else nameInf.prefix
                    _name = nameInf.name
                    _INF[_prefix][_name]
                ),
                set: ((name, val) ->
                    nameInf = nameAnalysis(name)
                    _prefix = if (not nameInf.prefix) then "OPT" else nameInf.prefix
                    _name = nameInf.name
                    _INF[_prefix][_name] = val
                    _type = typeDef(val)
                    _INF["DEF"][name] = _type
                    @
                ),
                del: ((name) ->
                    nameInf = nameAnalysis(name)
                    _prefix = if (not nameInf.prefix) then "OPT" else nameInf.prefix
                    _name = nameInf.name
                    delete _INF[_prefix][_name]
                    delete _INF["DEF"][name]
                    @
                )

            for i of _publish
                @[i] = _publish[i]
            @
        __construct.prototype = chain(_shellProto)
        __construct

    _shellProto = _shell.prototype

    _shellProto.reset = (name) ->
        _type = @.get(("def" + name))
        _value = _genInit(_type)
        @.set(name, _value)
        @

    _shellProto.insert = (name, inf) ->
        inf = if (typeDef(inf) == "Object") then (inf) else ({})
        if (typeof inf.val != "undefined")
            _data = @.get(name)
            inf.self = @
            if (typeDef(inf.rule) == "Function")
                inf.rule(_data, inf)
            else
                @.set(name, inf.val)
        @

    _shellProto.remove = (name, inf) ->
        inf = if (typeDef(inf) == "Object") then (inf) else ({})
        inf.self = @
        _data = @.get(name)
        if (typeDef(inf.rule) == "Function")
            inf.rule(_data, inf)
        else
            @.del(name)
        @

    _shellProto.search = () -> @
    # SHELL END