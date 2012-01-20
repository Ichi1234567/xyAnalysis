(function() {
  var chain, estFn, exeConds, extFn, fuzzyCtl, gridXSize, gridYSize, gx, gy, lv, nameAnalysis, rsWord, symFn, symMap, typeDef, xy2polar, _2PI, _ATAN, _CEIL, _MATH, _PI, _POW, _SQRT, _emptyFn, _genInit, _loopEst, _mgr, _mgrProto, _shell, _shellProto, _slice, _toString;

  _emptyFn = function() {};

  _MATH = Math;

  _CEIL = _MATH.ceil;

  _POW = _MATH.pow;

  _SQRT = _MATH.sqrt;

  _ATAN = _MATH.atan;

  _PI = _MATH.PI;

  _2PI = 2 * _PI;

  _toString = Object.prototype.toString;

  _slice = Array.prototype.slice;

  nameAnalysis = function(name) {
    var i, prefix, prefix_i, prename, reg_i, result, _len;
    prefix = ["^data", "^opt", "^def"];
    prename = ["DATA", "OPT", "DEF"];
    result = {
      prefix: "",
      name: name
    };
    for (i = 0, _len = prefix.length; i < _len; i++) {
      prefix_i = prefix[i];
      reg_i = new RegExp(prefix_i, "g");
      (reg_i.test(name)) && (result = {
        prefix: prename[i],
        name: (prename[i] === (name.toUpperCase()) ? name : name.replace(reg_i, ""))
      }, i = _len);
    }
    return result;
  };

  typeDef = function(val) {
    var _type;
    return _type = _toString.call(val).split(" ")[1].slice(0, -1);
  };

  _genInit = function(_type) {
    var val, vals;
    vals = {
      Array: [],
      Boolean: false,
      Function: _emptyFn,
      Number: 0,
      String: "",
      Object: {}
    };
    val = vals[_type];
    val = (val != null) && typeof val !== "undefined" ? val : {};
    return val;
  };

  extFn = function(entity, exts) {
    var i;
    for (i in exts) {
      entity[i] = exts[i];
    }
    return entity;
  };

  chain = (function() {
    var __fn__;
    __fn__ = function() {};
    return function($prototype) {
      __fn__.prototype = $prototype;
      return new __fn__;
    };
  })();

  /*
      * @name _shell
  */

  _shell = function() {
    var __construct;
    __construct = function(_dataIn) {
      var i, nameInf, _INF, _datai, _name, _prefix, _publish, _type;
      _INF = {
        DEF: {},
        DATA: {},
        OPT: {}
      };
      for (i in _dataIn) {
        _datai = _dataIn[i];
        _type = typeDef(_datai);
        nameInf = nameAnalysis(i);
        _prefix = !nameInf.prefix ? "OPT" : nameInf.prefix;
        _name = nameInf.name;
        _INF["DEF"][i] = _type;
        _INF[_prefix][_name] = _datai;
      }
      _publish = {
        get: (function(name) {
          nameInf = nameAnalysis(name);
          _prefix = !nameInf.prefix ? "OPT" : nameInf.prefix;
          _name = nameInf.name;
          return _INF[_prefix][_name];
        }),
        set: (function(name, val) {
          nameInf = nameAnalysis(name);
          _prefix = !nameInf.prefix ? "OPT" : nameInf.prefix;
          _name = nameInf.name;
          _INF[_prefix][_name] = val;
          _type = typeDef(val);
          _INF["DEF"][name] = _type;
          return this;
        }),
        del: (function(name) {
          nameInf = nameAnalysis(name);
          _prefix = !nameInf.prefix ? "OPT" : nameInf.prefix;
          _name = nameInf.name;
          delete _INF[_prefix][_name];
          delete _INF["DEF"][name];
          return this;
        })
      };
      for (i in _publish) {
        this[i] = _publish[i];
      }
      return this;
    };
    __construct.prototype = chain(_shellProto);
    return __construct;
  };

  _shellProto = _shell.prototype;

  _shellProto.reset = function(name) {
    var _type, _value;
    _type = this.get("def" + name);
    _value = _genInit(_type);
    this.set(name, _value);
    return this;
  };

  _shellProto.insert = function(name, inf) {
    var _data;
    inf = typeDef(inf) === "Object" ? inf : {};
    if (typeof inf.val !== "undefined") {
      _data = this.get(name);
      inf.self = this;
      if (typeDef(inf.rule) === "Function") {
        inf.rule(_data, inf);
      } else {
        this.set(name, inf.val);
      }
    }
    return this;
  };

  _shellProto.remove = function(name, inf) {
    var _data;
    inf = typeDef(inf) === "Object" ? inf : {};
    inf.self = this;
    _data = this.get(name);
    if (typeDef(inf.rule) === "Function") {
      inf.rule(_data, inf);
    } else {
      this.del(name);
    }
    return this;
  };

  _shellProto.search = function() {
    return this;
  };

  xy2polar = function(pt) {
    var _d, _dim, _polar, _theta, _x, _y;
    _x = pt.x;
    _y = pt.y;
    _d = [0, _PI, _PI, 2 * _PI];
    _dim = [1, 2, 3, 4];
    _theta = _ATAN(_y / _x);
    _theta += _x < 0 ? (_y < 0 ? _d[2] : _d[1]) : (_y < 0 ? _d[3] : _d[0]);
    _theta = _2PI - _theta;
    _polar = {
      r: _SQRT(_POW(_x, 2) + _POW(_y, 2)),
      theta: _theta
    };
    return _polar;
  };

  gridXSize = 20;

  gridYSize = 20;

  gx = 375;

  gy = 300;

  estFn = function(inf) {
    var gxSize, gySize, zoom, _result;
    zoom = /^Number/g.test(typeDef(inf.zoom)) ? inf.zoom : 1.;
    gxSize = gridXSize * zoom;
    gySize = gridYSize * zoom;
    _result = {
      grid: [Math.floor(inf.x / gxSize), Math.floor(inf.y / gySize), parseFloat(((inf.x % gxSize) / gxSize).toFixed(5)), parseFloat(((inf.y % gySize) / gySize).toFixed(5))],
      pos: [inf.x, inf.y],
      polar: xy2polar({
        "x": inf.x - gx,
        "y": inf.y - gy
      })
    };
    return _result;
  };

  fuzzyCtl = function(gridInf) {
    return _result;
  };

  _loopEst = function(_dataIn, zoom) {
    var i, _datai, _entity, _estVal, _len, _pos_i, _result;
    _result = [];
    for (i = 0, _len = _dataIn.length; i < _len; i++) {
      _datai = _dataIn[i];
      _pos_i = !!_datai.oriData ? _datai.oriData : _datai;
      _estVal = estFn({
        "x": typeof _pos_i.x === "function" ? _pos_i.x() : _pos_i.x,
        "y": typeof _pos_i.y === "function" ? _pos_i.y() : _pos_i.y,
        "zoom": zoom
      });
      _entity = {
        oriData: _datai,
        estVal: _estVal
      };
      _result.push(_entity);
    }
    return _result;
  };

  _mgr = function(_dataIn) {
    var __construct, _chainFn, _result;
    __construct = _shell();
    _chainFn = chain(_mgrProto);
    extFn(__construct.prototype, _chainFn);
    _result = new __construct(_dataIn);
    _result.update();
    return _result;
  };

  _mgrProto = _mgr.prototype;

  _mgrProto.reset = function() {
    var _shellReset;
    _shellReset = _shellProto.reset;
    _shellReset.call(this, "data");
    _shellReset.call(this, "bucketInf");
    return this;
  };

  _mgrProto.insert = function(data, opts) {
    var _args, _inf, _shellInsert;
    if (/^Array/g.test(typeDef(data))) {
      _shellInsert = _shellProto.insert;
      _args = ["data"];
      _inf = {
        val: data,
        rule: (function(data, inf) {
          var _self;
          _self = inf.self;
          _self.set("data", data.concat(inf.val));
          return _self;
        })
      };
      _args.push(_inf);
      _shellInsert.apply(this, _args);
    }
    this.update();
    return this;
  };

  _mgrProto.remove = function(data, opts) {
    var _args, _inf, _shellRemove, _sortFn;
    _shellRemove = _shellProto.remove;
    _sortFn = function(a, b) {
      return a - b;
    };
    _args = ["data"];
    _inf = {
      val: data,
      rule: (function(data, inf) {
        var _rmData, _rmFn, _self, _type;
        _rmFn = {
          idx: (function(data, inf) {
            var i, idxa, _ref, _results;
            idxa = inf.idxa.sort(_sortFn);
            _results = [];
            for (i = _ref = idxa.length - 1; _ref <= 0 ? i < 0 : i > 0; _ref <= 0 ? i++ : i--) {
              _results.push(data.splice(idxa[i], 1));
            }
            return _results;
          }),
          _default: (function(data, inf) {
            var estVals, vals;
            vals = inf.val;
            return estVals = [];
          })
        };
        _self = inf.self;
        _rmData = inf.val;
        _type = /^Array/g.test(typeDef(_rmData)) && _rmData.length ? "_default" : "idx";
        return _rmFn[_type](data, inf);
      })
    };
    _args.push(_inf);
    _shellRemove.apply(this, _args);
    this.update();
    return this;
  };

  _mgrProto.listen = function(evt, opts) {
    var regEvt, _defFn, _evtFn, _evtName, _evts, _map, _optEvName, _optFn, _self;
    if (/^String/g.test(typeDef(evt))) {
      _self = this;
      _evts = ["zoom", "moveend"];
      _evts = _evts.join(",");
      regEvt = new RegExp(evt, "g");
      _map = _self.get("dataMap");
      if ((_map != null) && typeof _map !== "undefined" && regEvt.test(_evts)) {
        _defFn = /^Function/g.test(typeDef());
        _optEvName = "optEvt" + evt;
        _optFn = /^Function/g.test(typeDef(opts.fn)) ? opts.fn : (function() {
          _self.update();
          return this;
        });
        _evtName = "dataEvt" + evt;
        _evtFn = function() {
          var _args;
          _args = _slice.call(arguments, 0);
          _args.push(evt);
          _optFn.apply(this, _args);
          return this;
        };
        _self.set(_evtName, _evtFn);
        _map.addListener(evt, _evtFn);
      }
    }
    return this;
  };

  _mgrProto.stop = function(evt) {
    var regEvt, _evtFn, _evtName, _evts, _map;
    if (/^String/g.test(typeDef(evt))) {
      _evts = ["zoom", "moveend"];
      _evts = _evts.join(",");
      regEvt = new RegExp(evt, "g");
      _map = this.get("dataMap");
      if ((_map != null) && typeof _map !== "undefined" && regEvt.test(_evts)) {
        _evtName = "dataEvt" + evt;
        _evtFn = this.get(_evtName);
        _map.removeListener(evt, _evtFn);
      }
    }
    return this;
  };

  _mgrProto.usrs = function(settings) {
    return this;
  };

  _mgrProto.update = function() {
    var _dataIn, _dataOut, _map, _zoom;
    _dataIn = this.get("data");
    _map = this.get("dataMap");
    if ((_map != null) && typeof _map !== "undefined") _zoom = _map.getZoomLevel();
    _dataOut = _loopEst(_dataIn, _zoom);
    this.set("bucketInf", []);
    this.set("data", _dataOut);
    return this;
  };

  _mgrProto.buckets = function() {
    var beqGrid, gridInf, i, _baseInf, _buckets, _data, _datai, _len, _subBuck;
    _data = this.get("data");
    _data.sort(function(a, b) {
      var infA, infB, result;
      infA = a.estVal.grid;
      infB = b.estVal.grid;
      switch (true) {
        case (infA[0] - infB[0]) > 0:
          result = 1;
          break;
        case (infA[0] - infB[0]) < 0:
          result = -1;
          break;
        default:
          switch (true) {
            case (infA[1] - infB[1]) > 0:
              result = 1;
              break;
            case (infA[1] - infB[1]) < 0:
              result = -1;
              break;
            default:
              result = 0;
          }
      }
      return result;
    });
    _buckets = [];
    _subBuck = [_data[0]];
    _baseInf = _data[0].estVal.grid;
    for (i = 0, _len = _data.length; i < _len; i++) {
      _datai = _data[i];
      gridInf = _datai.estVal.grid;
      beqGrid = gridInf[0] === _baseInf[0] && gridInf[1] === _baseInf[1];
      if (i && beqGrid) _subBuck.push(_datai);
      if (!beqGrid) {
        _buckets.push({
          grid: [_subBuck[0].estVal.grid[0], _subBuck[0].estVal.grid[1]],
          vals: _subBuck
        });
        _subBuck = [_datai];
        _baseInf = _datai.estVal.grid;
      }
    }
    _buckets.push({
      grid: [_subBuck[0].estVal.grid[0], _subBuck[0].estVal.grid[1]],
      vals: _subBuck
    });
    this.set("bucketInf", _buckets);
    return _buckets;
  };

  rsWord = ["Math"];

  rsWord = rsWord.join();

  lv = ["fn7", "* 6", "/ 6", "% 6", "+ 5", "- 5", "< 4", "<=4", "==4", ">=4", "> 4", "!=4", "! 3", "&&2", "||1"];

  lv = lv.join();

  symMap = ["* 0", "/ 1", "% 2", "+ 3", "- 4", "< 5", "<=6", "==7", "> 9", ">=8", "!=a", "! b", "&&c", "||d", "[ e"];

  symMap = symMap.join();

  symFn = [
    (function(a, b) {
      return a * b;
    }), (function(a, b) {
      return a / b;
    }), (function(a, b) {
      return a % b;
    }), (function(a, b) {
      return a + b;
    }), (function(a, b) {
      return a - b;
    }), (function(a, b) {
      return a < b;
    }), (function(a, b) {
      return a <= b;
    }), (function(a, b) {
      return a === b;
    }), (function(a, b) {
      return a >= b;
    }), (function(a, b) {
      return a > b;
    }), (function(a, b) {
      return a !== b;
    }), (function(a) {
      return !a;
    }), (function(a, b) {
      return a && b;
    }), (function(a, b) {
      return a || b;
    }), (function(a, b) {
      return a[b];
    })
  ];

  exeConds = function(_data, token, cond) {
    var anayName, args, condi, count, fn, fnLen, i, symIdx, tokenTab, val1, val2, x, y, _bcond, _idxx, _idxy, _len, _len2, _lvx, _lvy, _opstack, _posfix, _posi, _result, _varstack, _x;
    _bcond = false;
    _opstack = [];
    _varstack = [];
    _posfix = [];
    cond = cond.split(" ");
    for (i = 0, _len = cond.length; i < _len; i++) {
      condi = cond[i];
      if (condi.length) {
        switch (true) {
          case /[\(]/g.test(condi):
          case /\[/g.test(condi):
            _opstack.push(condi);
            break;
          case /\)/g.test(condi):
            while (_opstack.length) {
              _x = _opstack.pop();
              if (_x === "(") {
                if (_opstack[_opstack.length - 1].indexOf(".") > 0 && rsWord.indexOf(_opstack[_opstack.length - 1].split(".")[0]) > -1) {
                  _x = _opstack.pop();
                  _posfix.push(_x);
                }
                break;
              } else {
                _posfix.push(_x);
              }
            }
            break;
          case /\]/g.test(condi):
            while (_opstack.length) {
              _x = _opstack.pop();
              _posfix.push(_x);
              if (_x === "[") break;
            }
            break;
          case /[\[\]]/g.test(condi):
            _posfix.push(condi);
            break;
          case /[\+\-\*\/\!\%\&\|\>\=\<]+/g.test(condi):
          case rsWord.indexOf(condi.split(".")[0]) > -1:
            _idxx = lv.indexOf(condi);
            _lvx = _idxx > -1 ? parseInt(lv.slice(_idxx + 2, _idxx + 3)) : -1.;
            y = _opstack[_opstack.length - 1];
            _idxy = lv.indexOf(y);
            _lvy = _idxy > -1 ? parseInt(lv.slice(_idxy + 2, _idxy + 3)) : -1.;
            while (_lvy >= _lvx) {
              _posfix.push(_opstack.pop());
              y = _opstack[_opstack.length - 1];
              _idxy = lv.indexOf(y);
              _lvy = _idxy > -1 ? parseInt(lv.slice(_idxy + 2, _idxy + 3)) : -1.;
            }
            _opstack.push(condi);
            break;
          case /,/g.test(condi):
            while (_opstack.length) {
              x = _opstack[_opstack.length - 1];
              if (x !== "(") {
                _posfix.push(_opstack.pop());
              } else {
                break;
              }
            }
            break;
          case /^\d[\d]*.*[\d]*$/g.test(condi):
            _posfix.push(condi);
            break;
          default:
            tokenTab = new RegExp(condi, "g");
            if (tokenTab.test(token)) _posfix.push(condi);
        }
      }
    }
    while (_opstack.length) {
      _x = _opstack.pop();
      if (_x !== "(") _posfix.push(_x);
    }
    anayName = function(_data, name, token) {
      var nsp, _result;
      nsp = true;
      /^String/g.test(typeDef(name)) && (nsp = false);
      _result = /^\d[\d]*.*[\d]*$/g.test(name) || nsp ? name : name.split(".");
      /^\d[\d]*.*[\d]*$/g.test(name) && (_result = parseFloat(_result));
      if (/^Array/g.test(typeDef(_result))) {
        name = _result;
        _result = rsWord.indexOf(name[0]) > -1 ? window[name.shift()] : _data;
        while (name.length) {
          _result = _result[name.shift()];
        }
      }
      return _result;
    };
    count = 0;
    for (i = 0, _len2 = _posfix.length; i < _len2; i++) {
      _posi = _posfix[i];
      if (!/^String/g.test(typeDef(_posi))) continue;
      if ((/[\+\-\*\/\!\%\&\|\>\=\<\[]+/g.test(_posi)) || (rsWord.indexOf(_posi.split(".")[0]) > -1)) {
        val1 = anayName(_data, _posfix[i - 1], token);
        val2 = anayName(_data, _posfix[i - 2], token);
        symIdx = symMap.indexOf(_posi);
        symIdx = parseInt(symMap.slice(symIdx + 2, symIdx + 3), 16);
        fn = symFn[symIdx];
        switch (true) {
          case symIdx === 11:
            _result = fn(val1);
            _posfix.splice(i - 1, 2, _result);
            break;
          case (symIdx === 3 || symIdx === 4) && typeof val2 === "undefined":
            _result = fn(0, val1);
            _posfix.splice(i - 1, 2, _result);
            break;
          case rsWord.indexOf(_posi.split(".")[0]) > -1:
            fn = anayName(_data, _posi, token);
            fnLen = fn.length;
            args = [];
            while (fnLen) {
              args[fnLen - 1] = /^String/g.test(typeDef(_posfix[i - fnLen])) ? _posfix[i - fnLen].replace(",", "") : _posfix[i - fnLen];
              fnLen--;
            }
            _result = fn.apply(this, args);
            _posfix.splice(i - fn.length, fn.length + 1, _result);
            break;
          default:
            _result = fn(val2, val1);
            _posfix.splice(i - 2, 3, _result);
        }
        i = 0;
        count++;
        if (count > 1000) break;
      }
    }
    _result = _posfix[0] ? _data : false;
    return _result;
  };

  _mgrProto.search = function(where, cond) {
    var i, token, _cond, _data, _datai, _len, _len2, _ref, _regs, _regsi, _replace, _result, _subResult;
    _result = [];
    _data = this.get(where);
    if (/^Array/.test(typeDef(_data)) && /^String/g.test(typeDef(cond))) {
      _cond = "";
      for (i = 0, _ref = cond.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        if (/[\+\-\*\/\!\%\&\=\|\[\]\(\)\<\>\,]/g.test(cond[i])) {
          _cond += " " + cond[i] + " ";
        } else {
          _cond += cond[i];
        }
      }
      _regs = [/\&\s+\&/g, /\|\s+\|/g, /\=\s+\=/g, /\>\s+\=/g, /\<\s+\=/g, /\!\s+\=/g];
      _replace = ["&&", "||", "==", ">=", "<=", "!="];
      for (i = 0, _len = _regs.length; i < _len; i++) {
        _regsi = _regs[i];
        _cond = _cond.replace(_regsi, _replace[i]);
      }
      _cond = _cond.replace(/[\s]+/g, " ");
      _cond = _cond.replace(/^[\s]*/g, "");
      _cond = _cond.replace(/[\s]*$/g, "");
      token = _cond;
      token = token.replace(/[^a-zA-Z_][\d\+\-\*\/\!\%\&\=\|\[\,\]\<\>]+/g, " ");
      token = token.replace(/[\(\)]+/g, " ");
      token = token.replace(/[\s]+/g, " ");
      token = token.replace(/^[\s]+/g, "");
      token = token.replace(/[\s]*$/g, "");
      for (i = 0, _len2 = _data.length; i < _len2; i++) {
        _datai = _data[i];
        _subResult = exeConds(_datai, token, _cond);
        if (!/^Boolean/.test(typeDef(_subResult))) _result.push(_subResult);
      }
    }
    return _result;
  };

  window.world = _mgr;

}).call(this);
