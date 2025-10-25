
var Module;

if (typeof Module === 'undefined') Module = eval('(function() { try { return Module || {} } catch(e) { return {} } })()');

if (!Module.expectedDataFileDownloads) {
  Module.expectedDataFileDownloads = 0;
  Module.finishedDataFileDownloads = 0;
}
Module.expectedDataFileDownloads++;
(function() {
 var loadPackage = function(metadata) {

  var PACKAGE_PATH;
  if (typeof window === 'object') {
    PACKAGE_PATH = window['encodeURIComponent'](window.location.pathname.toString().substring(0, window.location.pathname.toString().lastIndexOf('/')) + '/');
  } else if (typeof location !== 'undefined') {
      // worker
      PACKAGE_PATH = encodeURIComponent(location.pathname.toString().substring(0, location.pathname.toString().lastIndexOf('/')) + '/');
    } else {
      throw 'using preloaded data can only be done on a web page or in a web worker';
    }
    var PACKAGE_NAME = 'game.data';
    var REMOTE_PACKAGE_BASE = 'game.data';
    if (typeof Module['locateFilePackage'] === 'function' && !Module['locateFile']) {
      Module['locateFile'] = Module['locateFilePackage'];
      Module.printErr('warning: you defined Module.locateFilePackage, that has been renamed to Module.locateFile (using your locateFilePackage for now)');
    }
    var REMOTE_PACKAGE_NAME = typeof Module['locateFile'] === 'function' ?
    Module['locateFile'](REMOTE_PACKAGE_BASE) :
    ((Module['filePackagePrefixURL'] || '') + REMOTE_PACKAGE_BASE);

    var REMOTE_PACKAGE_SIZE = metadata.remote_package_size;
    var PACKAGE_UUID = metadata.package_uuid;

    function fetchRemotePackage(packageName, packageSize, callback, errback) {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', packageName, true);
      xhr.responseType = 'arraybuffer';
      xhr.onprogress = function(event) {
        var url = packageName;
        var size = packageSize;
        if (event.total) size = event.total;
        if (event.loaded) {
          if (!xhr.addedTotal) {
            xhr.addedTotal = true;
            if (!Module.dataFileDownloads) Module.dataFileDownloads = {};
            Module.dataFileDownloads[url] = {
              loaded: event.loaded,
              total: size
            };
          } else {
            Module.dataFileDownloads[url].loaded = event.loaded;
          }
          var total = 0;
          var loaded = 0;
          var num = 0;
          for (var download in Module.dataFileDownloads) {
            var data = Module.dataFileDownloads[download];
            total += data.total;
            loaded += data.loaded;
            num++;
          }
          total = Math.ceil(total * Module.expectedDataFileDownloads/num);
          if (Module['setStatus']) Module['setStatus']('Downloading data... (' + loaded + '/' + total + ')');
        } else if (!Module.dataFileDownloads) {
          if (Module['setStatus']) Module['setStatus']('Downloading data...');
        }
      };
      xhr.onerror = function(event) {
        throw new Error("NetworkError for: " + packageName);
      }
      xhr.onload = function(event) {
        if (xhr.status == 200 || xhr.status == 304 || xhr.status == 206 || (xhr.status == 0 && xhr.response)) { // file URLs can return 0
          var packageData = xhr.response;
          callback(packageData);
        } else {
          throw new Error(xhr.statusText + " : " + xhr.responseURL);
        }
      };
      xhr.send(null);
    };

    function handleError(error) {
      console.error('package error:', error);
    };

    function runWithFS() {

      function assert(check, msg) {
        if (!check) throw msg + new Error().stack;
      }
      Module['FS_createPath']('/', '.git', true, true);
      Module['FS_createPath']('/.git', 'branches', true, true);
      Module['FS_createPath']('/.git', 'hooks', true, true);
      Module['FS_createPath']('/.git', 'info', true, true);
      Module['FS_createPath']('/.git', 'logs', true, true);
      Module['FS_createPath']('/.git/logs', 'refs', true, true);
      Module['FS_createPath']('/.git/logs/refs', 'heads', true, true);
      Module['FS_createPath']('/.git/logs/refs', 'remotes', true, true);
      Module['FS_createPath']('/.git/logs/refs/remotes', 'origin', true, true);
      Module['FS_createPath']('/.git', 'objects', true, true);
      Module['FS_createPath']('/.git/objects', 'info', true, true);
      Module['FS_createPath']('/.git/objects', 'pack', true, true);
      Module['FS_createPath']('/.git', 'refs', true, true);
      Module['FS_createPath']('/.git/refs', 'heads', true, true);
      Module['FS_createPath']('/.git/refs', 'remotes', true, true);
      Module['FS_createPath']('/.git/refs/remotes', 'origin', true, true);
      Module['FS_createPath']('/.git/refs', 'tags', true, true);
      Module['FS_createPath']('/', 'img', true, true);
      Module['FS_createPath']('/', 'libs', true, true);
      Module['FS_createPath']('/', 'maps', true, true);
      Module['FS_createPath']('/', 'sounds', true, true);
      Module['FS_createPath']('/', 'src', true, true);

      function DataRequest(start, end, crunched, audio) {
        this.start = start;
        this.end = end;
        this.crunched = crunched;
        this.audio = audio;
      }
      DataRequest.prototype = {
        requests: {},
        open: function(mode, name) {
          this.name = name;
          this.requests[name] = this;
          Module['addRunDependency']('fp ' + this.name);
        },
        send: function() {},
        onload: function() {
          var byteArray = this.byteArray.subarray(this.start, this.end);

          this.finish(byteArray);

        },
        finish: function(byteArray) {
          var that = this;

        Module['FS_createDataFile'](this.name, null, byteArray, true, true, true); // canOwn this data in the filesystem, it is a slide into the heap that will never change
        Module['removeRunDependency']('fp ' + that.name);

        this.requests[this.name] = null;
      }
    };

    var files = metadata.files;
    for (i = 0; i < files.length; ++i) {
      new DataRequest(files[i].start, files[i].end, files[i].crunched, files[i].audio).open('GET', files[i].filename);
    }


    var indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
    var IDB_RO = "readonly";
    var IDB_RW = "readwrite";
    var DB_NAME = "EM_PRELOAD_CACHE";
    var DB_VERSION = 1;
    var METADATA_STORE_NAME = 'METADATA';
    var PACKAGE_STORE_NAME = 'PACKAGES';
    function openDatabase(callback, errback) {
      try {
        var openRequest = indexedDB.open(DB_NAME, DB_VERSION);
      } catch (e) {
        return errback(e);
      }
      openRequest.onupgradeneeded = function(event) {
        var db = event.target.result;

        if(db.objectStoreNames.contains(PACKAGE_STORE_NAME)) {
          db.deleteObjectStore(PACKAGE_STORE_NAME);
        }
        var packages = db.createObjectStore(PACKAGE_STORE_NAME);

        if(db.objectStoreNames.contains(METADATA_STORE_NAME)) {
          db.deleteObjectStore(METADATA_STORE_NAME);
        }
        var metadata = db.createObjectStore(METADATA_STORE_NAME);
      };
      openRequest.onsuccess = function(event) {
        var db = event.target.result;
        callback(db);
      };
      openRequest.onerror = function(error) {
        errback(error);
      };
    };

    /* Check if there's a cached package, and if so whether it's the latest available */
    function checkCachedPackage(db, packageName, callback, errback) {
      var transaction = db.transaction([METADATA_STORE_NAME], IDB_RO);
      var metadata = transaction.objectStore(METADATA_STORE_NAME);

      var getRequest = metadata.get("metadata/" + packageName);
      getRequest.onsuccess = function(event) {
        var result = event.target.result;
        if (!result) {
          return callback(false);
        } else {
          return callback(PACKAGE_UUID === result.uuid);
        }
      };
      getRequest.onerror = function(error) {
        errback(error);
      };
    };

    function fetchCachedPackage(db, packageName, callback, errback) {
      var transaction = db.transaction([PACKAGE_STORE_NAME], IDB_RO);
      var packages = transaction.objectStore(PACKAGE_STORE_NAME);

      var getRequest = packages.get("package/" + packageName);
      getRequest.onsuccess = function(event) {
        var result = event.target.result;
        callback(result);
      };
      getRequest.onerror = function(error) {
        errback(error);
      };
    };

    function cacheRemotePackage(db, packageName, packageData, packageMeta, callback, errback) {
      var transaction_packages = db.transaction([PACKAGE_STORE_NAME], IDB_RW);
      var packages = transaction_packages.objectStore(PACKAGE_STORE_NAME);

      var putPackageRequest = packages.put(packageData, "package/" + packageName);
      putPackageRequest.onsuccess = function(event) {
        var transaction_metadata = db.transaction([METADATA_STORE_NAME], IDB_RW);
        var metadata = transaction_metadata.objectStore(METADATA_STORE_NAME);
        var putMetadataRequest = metadata.put(packageMeta, "metadata/" + packageName);
        putMetadataRequest.onsuccess = function(event) {
          callback(packageData);
        };
        putMetadataRequest.onerror = function(error) {
          errback(error);
        };
      };
      putPackageRequest.onerror = function(error) {
        errback(error);
      };
    };

    function processPackageData(arrayBuffer) {
      Module.finishedDataFileDownloads++;
      assert(arrayBuffer, 'Loading data file failed.');
      assert(arrayBuffer instanceof ArrayBuffer, 'bad input to processPackageData');
      var byteArray = new Uint8Array(arrayBuffer);
      var curr;

        // copy the entire loaded file into a spot in the heap. Files will refer to slices in that. They cannot be freed though
        // (we may be allocating before malloc is ready, during startup).
        if (Module['SPLIT_MEMORY']) Module.printErr('warning: you should run the file packager with --no-heap-copy when SPLIT_MEMORY is used, otherwise copying into the heap may fail due to the splitting');
        var ptr = Module['getMemory'](byteArray.length);
        Module['HEAPU8'].set(byteArray, ptr);
        DataRequest.prototype.byteArray = Module['HEAPU8'].subarray(ptr, ptr+byteArray.length);

        var files = metadata.files;
        for (i = 0; i < files.length; ++i) {
          DataRequest.prototype.requests[files[i].filename].onload();
        }
        Module['removeRunDependency']('datafile_game.data');

      };
      Module['addRunDependency']('datafile_game.data');

      if (!Module.preloadResults) Module.preloadResults = {};

      function preloadFallback(error) {
        console.error(error);
        console.error('falling back to default preload behavior');
        fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE, processPackageData, handleError);
      };

      openDatabase(
        function(db) {
          checkCachedPackage(db, PACKAGE_PATH + PACKAGE_NAME,
            function(useCached) {
              Module.preloadResults[PACKAGE_NAME] = {fromCache: useCached};
              if (useCached) {
                console.info('loading ' + PACKAGE_NAME + ' from cache');
                fetchCachedPackage(db, PACKAGE_PATH + PACKAGE_NAME, processPackageData, preloadFallback);
              } else {
                console.info('loading ' + PACKAGE_NAME + ' from remote');
                fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE,
                  function(packageData) {
                    cacheRemotePackage(db, PACKAGE_PATH + PACKAGE_NAME, packageData, {uuid:PACKAGE_UUID}, processPackageData,
                      function(error) {
                        console.error(error);
                        processPackageData(packageData);
                      });
                  }
                  , preloadFallback);
              }
            }
            , preloadFallback);
        }
        , preloadFallback);

      if (Module['setStatus']) Module['setStatus']('Downloading...');

    }
    if (Module['calledRun']) {
      runWithFS();
    } else {
      if (!Module['preRun']) Module['preRun'] = [];
      Module["preRun"].push(runWithFS); // FS is not initialized yet, wait for it
    }

  }
  loadPackage({"package_uuid":"b040dcff-213e-4837-bcca-8ed5670f6c1a","remote_package_size":225861,"files":[{"filename":"/.git/HEAD","crunched":0,"start":0,"end":21,"audio":false},{"filename":"/.git/config","crunched":0,"start":21,"end":277,"audio":false},{"filename":"/.git/description","crunched":0,"start":277,"end":350,"audio":false},{"filename":"/.git/hooks/applypatch-msg.sample","crunched":0,"start":350,"end":828,"audio":false},{"filename":"/.git/hooks/commit-msg.sample","crunched":0,"start":828,"end":1724,"audio":false},{"filename":"/.git/hooks/fsmonitor-watchman.sample","crunched":0,"start":1724,"end":6450,"audio":false},{"filename":"/.git/hooks/post-update.sample","crunched":0,"start":6450,"end":6639,"audio":false},{"filename":"/.git/hooks/pre-applypatch.sample","crunched":0,"start":6639,"end":7063,"audio":false},{"filename":"/.git/hooks/pre-commit.sample","crunched":0,"start":7063,"end":8706,"audio":false},{"filename":"/.git/hooks/pre-merge-commit.sample","crunched":0,"start":8706,"end":9122,"audio":false},{"filename":"/.git/hooks/pre-push.sample","crunched":0,"start":9122,"end":10496,"audio":false},{"filename":"/.git/hooks/pre-rebase.sample","crunched":0,"start":10496,"end":15394,"audio":false},{"filename":"/.git/hooks/pre-receive.sample","crunched":0,"start":15394,"end":15938,"audio":false},{"filename":"/.git/hooks/prepare-commit-msg.sample","crunched":0,"start":15938,"end":17430,"audio":false},{"filename":"/.git/hooks/push-to-checkout.sample","crunched":0,"start":17430,"end":20213,"audio":false},{"filename":"/.git/hooks/sendemail-validate.sample","crunched":0,"start":20213,"end":22521,"audio":false},{"filename":"/.git/hooks/update.sample","crunched":0,"start":22521,"end":26171,"audio":false},{"filename":"/.git/index","crunched":0,"start":26171,"end":28478,"audio":false},{"filename":"/.git/info/exclude","crunched":0,"start":28478,"end":28718,"audio":false},{"filename":"/.git/logs/HEAD","crunched":0,"start":28718,"end":28885,"audio":false},{"filename":"/.git/logs/refs/heads/main","crunched":0,"start":28885,"end":29052,"audio":false},{"filename":"/.git/logs/refs/remotes/origin/HEAD","crunched":0,"start":29052,"end":29219,"audio":false},{"filename":"/.git/objects/pack/pack-8556f4b85f9aa77bb4fbbae2230c3136dc3893e2.idx","crunched":0,"start":29219,"end":33539,"audio":false},{"filename":"/.git/objects/pack/pack-8556f4b85f9aa77bb4fbbae2230c3136dc3893e2.pack","crunched":0,"start":33539,"end":110443,"audio":false},{"filename":"/.git/objects/pack/pack-8556f4b85f9aa77bb4fbbae2230c3136dc3893e2.rev","crunched":0,"start":110443,"end":110959,"audio":false},{"filename":"/.git/packed-refs","crunched":0,"start":110959,"end":111130,"audio":false},{"filename":"/.git/refs/heads/main","crunched":0,"start":111130,"end":111171,"audio":false},{"filename":"/.git/refs/remotes/origin/HEAD","crunched":0,"start":111171,"end":111201,"audio":false},{"filename":"/LICENSE","crunched":0,"start":111201,"end":112264,"audio":false},{"filename":"/README.md","crunched":0,"start":112264,"end":113201,"audio":false},{"filename":"/conf.lua","crunched":0,"start":113201,"end":113338,"audio":false},{"filename":"/img/character-8x8.png","crunched":0,"start":113338,"end":113451,"audio":false},{"filename":"/img/characterSpriteSheet.png","crunched":0,"start":113451,"end":113791,"audio":false},{"filename":"/img/explosion.png","crunched":0,"start":113791,"end":126448,"audio":false},{"filename":"/img/flag.png","crunched":0,"start":126448,"end":126577,"audio":false},{"filename":"/img/fullSqare.png","crunched":0,"start":126577,"end":126682,"audio":false},{"filename":"/img/square.png","crunched":0,"start":126682,"end":126792,"audio":false},{"filename":"/libs/anim8.lua","crunched":0,"start":126792,"end":135284,"audio":false},{"filename":"/libs/camera.lua","crunched":0,"start":135284,"end":141939,"audio":false},{"filename":"/libs/push.lua","crunched":0,"start":141939,"end":150925,"audio":false},{"filename":"/main.lua","crunched":0,"start":150925,"end":152513,"audio":false},{"filename":"/maps/map_0.MP","crunched":0,"start":152513,"end":153025,"audio":false},{"filename":"/maps/map_1.MP","crunched":0,"start":153025,"end":153537,"audio":false},{"filename":"/maps/map_2.MP","crunched":0,"start":153537,"end":154049,"audio":false},{"filename":"/maps/map_3.MP","crunched":0,"start":154049,"end":154561,"audio":false},{"filename":"/maps/map_4.MP","crunched":0,"start":154561,"end":155073,"audio":false},{"filename":"/maps/map_5.MP","crunched":0,"start":155073,"end":155584,"audio":false},{"filename":"/maps/map_emptyTemplate.MP","crunched":0,"start":155584,"end":156096,"audio":false},{"filename":"/sounds/explosion.mp3","crunched":0,"start":156096,"end":191424,"audio":true},{"filename":"/sounds/jump.wav","crunched":0,"start":191424,"end":198354,"audio":true},{"filename":"/sounds/landed.wav","crunched":0,"start":198354,"end":199798,"audio":true},{"filename":"/sounds/nextMap.wav","crunched":0,"start":199798,"end":212302,"audio":true},{"filename":"/src/map.lua","crunched":0,"start":212302,"end":220371,"audio":false},{"filename":"/src/player.lua","crunched":0,"start":220371,"end":225861,"audio":false}]});

})();
