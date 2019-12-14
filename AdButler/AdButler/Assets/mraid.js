(function (){
    var mraid = window.mraid = {};

    // ------------------------------------------------------------------------------
    //                      MRAID Constants
    // ------------------------------------------------------------------------------

    var STATES = mraid.STATES = {
        "LOADING" : "loading",
        "DEFAULT" : "default",
        "EXPANDED" : "expanded",
        "RESIZED" : "resized",
        "HIDDEN" : "hidden"
    };

    var PLACEMENT_TYPES = mraid.PLACEMENTS = {
        "INLINE" : "inline",
        "INTERSTITIAL" : "interstitial"
    };

    var POSITIONS = mraid.POSITIONS = {
        "CENTER" : "center",
        "TOP_LEFT" : "top-left",
        "TOP_CENTER" : "top-center",
        "TOP_RIGHT" : "top-right",
        "BOTTOM_LEFT" : "bottom-left",
        "BOTTOM_CENTER" : "bottom-center",
        "BOTTOM_RIGHT" : "bottom-right"
    };

    var ORIENTATIONS = mraid.ORIENTATIONS = {
        "PORTRAIT" : "portrait",
        "LANDSCAPE" : "landscape",
        "NONE" : "none"
    };

    var EVENTS = mraid.EVENTS = {
        "READY" : "ready",
        "SIZE_CHANGE" : "sizeChange",
        "STATE_CHANGE" : "stateChange",
        "VIEWABLE_CHANGE" : "viewableChange",
        "ERROR" : "error"
    };

    var FEATURES = mraid.FEATURES = {
        "SMS" : "sms",
        "TEL" : "tel",
        "STORE_PICTURE" : "storePicture",
        "INLINE_VIDEO" : "inlineVideo",
        "CALENDAR" : "calendar"
    };

    var NATIVE_ENDPOINTS = mraid.NATIVE_ENDPOINTS = {
        "EXPAND" : "expand",
        "OPEN" : "open",
        "PLAY_VIDEO" : "playVideo",
        "RESIZE" : "resize",
        "STORE_PICTURE" : "storePicture",
        "CREATE_CALENDAR_EVENT" : "createCalendarEvent",
        "CALL_NUMBER" : "callNumber",
        "SET_ORIENTATION_PROPERTIES" : "setOrientationProperties",
        "SET_RESIZE_PROPERTIES" : "setResizeProperties",
        "SET_EXPAND_PROPERTIES" : "setExpandProperties",
        "REPORT_DOM_SIZE" : "reportDOMSize",
        "REPORT_JS_LOG" : "reportJSLog",
        "CLOSE" : "close",
    }

    // ------------------------------------------------------------------------------
    //                      Members
    // ------------------------------------------------------------------------------
    var state = STATES.LOADING;
    var listeners = []; // contains arrays of listeners for each event type
    var placementType = PLACEMENT_TYPES.INLINE;
    var supportedFeatures = [];
    mraid.debug = true;

    var orientationProperties = {
        "allowOrientationChange": false,
        "forceOrientation": ORIENTATIONS.NONE
    }

    var expandProperties = {
        "width": 0,
        "height": 0,
        "useCustomClose": false,
        "isModal": true // in mraid 2.0 this will always be true.  in 1.0 it could be false
    }

    var resizeProperties = {
        "width": undefined,
        "height": undefined,
        "offsetX": undefined,
        "offsetY": undefined,
        "customClosePosition": POSITIONS.TOP_RIGHT,
        "allowOffscreen": true
    }

    var version = "2.0";
    var defaultPosition = { x: 0, y:0, height:50, width:50 };
    var currentPosition = { x: 0, y:0, height:50, width:50 };
    var maxSize = { x: 0, y:0, height:0, width:0 };
    var screenSize = { x: 0, y:0, height:0, width:0 };
    var isViewable = false;

    // ------------------------------------------------------------------------------
    //                      MRAID specific functions
    // ------------------------------------------------------------------------------

    mraid.addEventListener = function(event, listener){
        if(listeners.containsListener(event, listener)){
            warning('addEventListener - this function already registered for (' + event + ') event.');
            return;
        }
        log('addEventListener (event = ' + event + ')');
        listeners[event] = listeners[event] || [];
        listeners[event].push(listener);
    }

    mraid.removeEventListener = function(event, listener){
        listeners.removeListener(event, listener);
    }

    mraid.createCalendarEvent = function(params){
        log('createCalendarEvent');
        invokeSDK(NATIVE_ENDPOINTS.CREATE_CALENDAR_EVENT, JSON.stringify(params));
    }

    mraid.close = function(){
        log('close');
        invokeSDK(NATIVE_ENDPOINTS.CLOSE);
    }

    mraid.expand = function(uri){
        if(placementType !== PLACEMENT_TYPES.INLINE || (state !== STATES.DEFAULT && state !== STATES.RESIZED)){
            warning('expand called while in invalid state.');
            return;
        }
        log('expand');
        invokeSDK(NATIVE_ENDPOINTS.EXPAND, uri);
    }

    mraid.getCurrentPosition = function(){
        log('getCurrentPosition');
        return currentPosition;
    }

    mraid.getDefaultPosition = function(){
        log('getDefaultPosition');
        return defaultPosition;
    }

    mraid.getExpandProperties = function(){
        log('getExpandProperties');
        return expandProperties;
    }

    mraid.getMaxSize = function(){
        log('getMaxSize');
        return maxSize;
    }

    mraid.getOrientationProperties = function (){
        log('getOrientationProperties');
        return orientationProperties;
    }

    mraid.getPlacementType = function(){
        log('getPlacementType');
        return placementType;
    }

    mraid.getResizeProperties = function(){
        log('getResizeProperties');

        return resizeProperties;

    }

    mraid.getScreenSize = function(){
        log('getScreenSize');
        return screenSize;
    }

    mraid.getState = function(){
        log('getState (state = ' + state + ")");
        return state;
    }

    mraid.getVersion = function(){
        log('getVersion');
        return version;
    }

    mraid.isViewable = function(){
        log('isViewable - ' + isViewable);
        return isViewable;
    }

    mraid.open = function(uri){
        log('open');
        invokeSDK(NATIVE_ENDPOINTS.OPEN, uri);
    }

    mraid.playVideo = function(uri){
        log('playVideo');
        invokeSDK(NATIVE_ENDPOINTS.PLAY_VIDEO, uri);
    }

    mraid.resize = function(){
        log('resize - ' + JSON.stringify(resizeProperties));
        if(state == STATES.EXPANDED){
            error("Resize called while in expanded state.", true);
        }
        if(resizeProperties.allowOffscreen === true){
            var pos = resizeProperties.customClosePosition || "top-right";
            var frame = currentPosition;
            var valid = true;
            if(pos.indexOf("right") >= 0){
                var offscreenLeft = frame.x + resizeProperties.width + resizeProperties.offsetX > screenSize.width - 50;
                var offscreenRight = frame.x + resizeProperties.width + resizeProperties.offsetX < 50;
                if(offscreenLeft || offscreenRight) {
                    valid = false;
                }
            }
            if(pos.indexOf("left") >= 0){
                var offscreenLeft = frame.x + resizeProperties.offsetX < 0;
                var offscreenRight = frame.x + resizeProperties.offsetX > screenSize.width - 50;
                if(offscreenLeft || offscreenRight) {
                    valid = false
                }
            }
            if(pos.indexOf("top") >= 0){
                mraid.log(JSON.stringify(currentPosition), true);
                mraid.log(JSON.stringify(resizeProperties), true);
                var offscreenTop = frame.y + resizeProperties.offsetY < 0;
                var offscreenBottom = frame.y + resizeProperties.offsetY > screenSize.height - 50;
                if(offscreenTop || offscreenBottom) {
                    valid = false
                }
            }
            if(pos.indexOf("bottom") >= 0){
                var offscreenTop = frame.y + resizeProperties.height + resizeProperties.offsetY < 50;
                var offscreenBottom = frame.y + resizeProperties.height + resizeProperties.offsetY > screenSize.height - 50;
                if(offscreenTop || offscreenBottom) {
                    valid = false
                }
            }
            if(!valid){
                error("Current resize properties would result in the close region being off screen. Ignoring resize.", true);
            }
        }
        if(resizeProperties.width && resizeProperties.height){
            invokeSDK(NATIVE_ENDPOINTS.RESIZE);
        }else{
            error("Resize properties must be set before calling mraid.resize()", true);
        }
    }

    mraid.setExpandProperties = function(properties){
        log('setExpandProperties');
        setProperties('setExpandProperties', expandProperties, properties)
        invokeSDK(NATIVE_ENDPOINTS.SET_EXPAND_PROPERTIES, JSON.stringify(properties))
    }

    mraid.setOrientationProperties = function(properties) {
        log('setOrientationProperties');
        setProperties('setOrientationProperties', orientationProperties, properties);
        invokeSDK(NATIVE_ENDPOINTS.SET_ORIENTATION_PROPERTIES, JSON.stringify(properties))
    }

    mraid.setResizeProperties = function(properties){
        log('setResizeProperties - ' + JSON.stringify(properties));
        setProperties('setResizeProperties', resizeProperties, properties);
        invokeSDK(NATIVE_ENDPOINTS.SET_RESIZE_PROPERTIES, JSON.stringify(properties))
    }

    mraid.storePicture = function(uri){
        log('storePicture');
        invokeSDK(NATIVE_ENDPOINTS.STORE_PICTURE, uri);
    }

    mraid.supports = function(feature){
        log('supports - ' + feature + ' : ' + (supportedFeatures[feature] === true));
        return supportedFeatures[feature]=== true;
    }

    mraid.useCustomClose = function(val){
        log('useCustomClose');
        expandProperties.useCustomClose = val;
        invokeSDK(NATIVE_ENDPOINTS.SET_EXPAND_PROPERTIES, JSON.stringify(expandProperties))
    }

    // ------------------------------------------------------------------------------
    //                      Called by Native Code
    // ------------------------------------------------------------------------------

    mraid.setState = function(toState){
        log("setState (" + toState + ")" );
        if(state != toState){
            state = toState;
            mraid.fireEvent(EVENTS.STATE_CHANGE, state);
        }
    }

    mraid.fireEvent = function(event, args){
        log("fire event (" + event + ")");
        if(listeners.containsEvent(event)){
            listeners.invoke(event, args);
        }
    }

    mraid.setSupports = function(feature, isSupported){
        log("set feature " + feature + " " + isSupported);
        supportedFeatures[feature] = isSupported;
    }

    mraid.setPlacementType = function(type){
        if(type == PLACEMENT_TYPES.INLINE || type == PLACEMENT_TYPES.INTERSTITIAL) {
            placementType = type;
        }
    }

    mraid.setCurrentPosition = function(pos){
        log("set current position " + JSON.stringify(pos));
        currentPosition = pos;
    }

    mraid.setDefaultPosition = function(pos){
        log("set default position " + JSON.stringify(pos));
        defaultPosition = pos;
    }

    mraid.setMaxSize = function(size){
        log("set max size " + JSON.stringify(size));
        maxSize = size;
    }

    mraid.setScreenSize = function(size){
        log("set screen size - " + JSON.stringify(size));
        screenSize = size;
    }

    mraid.setVersion = function(ver){
        log("set version - " + ver);
        version = ver;
    }

    mraid.setIsViewable = function(val){
        log("set is viewable - " + val);
        isViewable = val;
    }

    // ------------------------------------------------------------------------------
    //                      Helper Functions
    // ------------------------------------------------------------------------------

    document.addEventListener("DOMContentLoaded", function(event) {
        var detectedSize = findLargestElement();
        invokeSDK(NATIVE_ENDPOINTS.REPORT_DOM_SIZE, JSON.stringify( detectedSize ));
    });

    function invokeSDK(endpoint, args) {
        var iframe = document.createElement("IFRAME");
        var qs = args != null ? '?args=' + encodeURIComponent(args) : '';
        iframe.setAttribute("src", "mraid://" + endpoint + qs);
        document.documentElement.appendChild(iframe);
        iframe.parentNode.removeChild(iframe);
        iframe = null;
    };

    mraid.findLargestElement = function(){
        return findLargestElement();
    }

    function findLargestElement() {
        // Get all elements that have width defined (we can consider their height as well
        var elements = document.querySelectorAll("body > *");
        var largestWidth = 0;
        var largestHeight = 0;
        // Loop through them
        Array.prototype.forEach.call(elements, function(elem) {
            var compStyle = window.getComputedStyle(elem)
            if(compStyle.display != "none" && compStyle.visibility != "hidden") {
                // DOM may not have loaded, so we have to read the actual style property
                var w = parseInt(elem.offsetWidth);
                var h = parseInt(elem.offsetHeight);
                largestWidth = Math.max(largestWidth, w);
                largestHeight = Math.max(largestHeight, h);
            }
        });
        return {width:largestWidth, height:largestHeight};
    };

    function setProperties(caller, ogProperties, newProperties){
        // do some validation for specific cases, like required fields, or fields with allowed values.
        switch(caller){
            case "setOrientationProperties":
                if(newProperties.forceOrientation && Object.keys(ORIENTATIONS).indexOf(newProperties.forceOrientation.toUpperCase()) < 0){
                    error(caller + ' - property (forceOrientation) invalid value. ' + newProperties.forceOrientation, true);
                }
                break;
            case "setExpandProperties":
                // nothing custom required here.
                break;
            case "setResizeProperties":
                newProperties.width = parseInt(newProperties.width);
                newProperties.height = parseInt(newProperties.height);
                newProperties.offsetX = parseInt(newProperties.offsetX);
                newProperties.offsetY = parseInt(newProperties.offsetY);

                if(isNaN(newProperties.width)){
                    error(caller + ' - property (width) must be an integer, and is required.', true);
                }else if(newProperties.width < 50){
                    error(caller + ' - property (width) must be at least 50 dp.', true);
                }

                if(isNaN(newProperties.height)){
                    error(caller + ' - property (height) must be an integer, and is required.', true);
                }else if(newProperties.height < 50){
                    error(caller + ' - property (height) must be at least 50 dp.', true);
                }

                if(isNaN(newProperties.offsetX)){
                    error(caller + ' - property (offsetX) must be an integer, and is required.', true);
                }

                if(isNaN(newProperties.offsetY)){
                    error(caller + ' - property (offsetY) must be an integer, and is required.', true);
                }

                if(isNaN(newProperties.allowOffscreen)){
                    if(newProperties.width > screenSize.width || newProperties.height > screenSize.height){
                        error(caller + ' - cannot set the width or height greater than screensize if "allowOffscreen" is false', true);
                    }
                }

                if(newProperties.customClosePosition === true && Object.values(POSITIONS).indexOf(newProperties.customClosePosition) < 0){
                    error(caller + ' - property (customClosePosition) invalid value.  Default is "top-right"', true);
                }
                break;
        }

        // generic validation.
        for(var property in newProperties){
            // check if the property was not invalidated above, and make sure we aren't finding any inherited properties
            if(newProperties.hasOwnProperty(property) && newProperties[property] !== undefined){
                if(!ogProperties.hasOwnProperty(property)){
                    // original does not have this property, so it is invalid.
                    error(caller + ' - property (' + property + ') does not exist.')
                }
                else {
                    // We are through the gauntlet.  Go ahead and set the property for the original.
                    ogProperties[property] = newProperties[property];
                }
            }
        }
    }

    listeners.invoke = function(event, args){
        listeners[event].forEach(function(listener){
            switch(event){
                case EVENTS.READY:
                    listener();
                    break;
                case EVENTS.STATE_CHANGE:
                    listener(args);
                    break;
                case EVENTS.SIZE_CHANGE:
                    listener(args.width, args.height);
                    break;
                case EVENTS.VIEWABLE_CHANGE:
                    listener(args);
                    break;
                case EVENTS.ERROR:
                    listener(args);
                    break;
            }
        });
    }

    listeners.containsEvent = function(event){
        return Array.isArray(listeners[event]);
    }

    listeners.containsListener = function(event, listener){
        var listenerString = String(listener);
        if(Array.isArray(listeners[event])){
            listeners[event].forEach(function(listener){
                var thisStr = String(listener);
                if(thisStr === listenerString){
                    return true;
                }
            });
        }
        return false;
    }

    listeners.removeListener = function(event, listener){
        var listenerString = String(listener);
        var index = -1;
        if(Array.isArray(listeners[event])){
            listeners[event].forEach(function(listener){
                var thisStr = String(listener);
                if(thisStr === listenerString){
                    log("removing event listener (" + event + ")");
                    index = listeners[event].indexOf(listener);
                }
            });
        }
        if(index > 0){
            listeners[event].splice(index, 1);
        }
    }

    mraid.log = function(str){
        invokeSDK(NATIVE_ENDPOINTS.REPORT_JS_LOG, str);
    }

    function log(str){
        if(mraid.debug){
            console.log('mraid.js::' + str);
            invokeSDK(NATIVE_ENDPOINTS.REPORT_JS_LOG, str);
        }
    }

    function error(str, throws){
        if(mraid.debug) {
            invokeSDK(NATIVE_ENDPOINTS.REPORT_JS_LOG, "ERROR -- " + str);
        }
        console.error('mraid.js::' + str);
        if(throws){
            throw new Error("mraid.js::" + str);
        }
    }

    function warning(str){
        if(mraid.debug){
            console.warn('mraid.js::' + str);
        }
    }
    mraid.log("mraid.js loaded");
})();
